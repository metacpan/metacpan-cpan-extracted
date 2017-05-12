#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use DBI;
use JSON;
use URI::Escape;
# use some more strange modules here ...

my $q = CGI::->new();

if(update($q)) {
    print $q->header('text/plain');
    print "OK";
} else {
    print $q->header('text/plain');
    print "ERROR";
}

sub update {
    my $q = shift;
    my $group_id = $q->param('group_id');
    my $queue = $q->param('queue');

    return unless $queue && $group_id;

    $queue = URI::Escape::uri_unescape($queue);
    my $JSON = JSON::->new()->utf8();
    my $queue_ref = $JSON->decode($queue);
    $queue = undef;

    # the current jantior is on top of the list
    my $current_janitor = $queue_ref->[0]->{'username'};

    # the last janitor is at the end of the list
    my $prev_janitor = $queue_ref->[-1]->{'username'};

    # WARNING: This script will break if the current janitor is disabled ... then he won't be in the list at all.
    my $dbh = Your::App::DB::connect();

    my ($sql, $sth);

    # Step0.1: Preparation, get the last day someone was on duty
    # If there are any gaps (missing days) before this date we don't care
    # because we can't possibly know who was on duty then.
    $sql = 'SELECT date FROM accounting_standby WHERE date < DATE(NOW()) ORDER BY date DESC LIMIT 1';
    $sth = $dbh->prepare($sql);
    return unless $sth;

    $sth->execute() or return;

    my $last_date_on_duty = $sth->fetchrow_array();

    $sth->finish();
    $sth = undef;

    # Step0.2: Replace user names with accounting ids
    $sql = 'SELECT id FROM accounting_users WHERE name = ? ORDER BY id LIMIT 1';
    $sth = $dbh->prepare($sql);
    return unless $sth;
    $sth->execute($current_janitor)
        or return;
    $current_janitor = $sth->fetchrow_array();
    return unless $current_janitor;

    $sth->execute($prev_janitor)
        or return;
    $prev_janitor = $sth->fetchrow_array();
    return unless $prev_janitor;

    $sth->finish();
    $sth = undef;

    # Step1: Fill empty slots before now with the last person on duty
    $sql = 'UPDATE accounting_standby SET user_id = ? WHERE date < DATE(NOW()) AND date > ? AND user_id = 0';
    $sth = $dbh->prepare($sql)
        or return;
    $sth->execute($prev_janitor,$last_date_on_duty)
        or return;
    $sth->finish();

    # Step2: Fill current slot with the new person on duty
    # WARNING: This won't work properly on weekends and holidays
    $sql = "UPDATE accounting_standby SET user_id = ? WHERE date = DATE(NOW())";
    my $hour = (localtime())[2];
    $sth = $dbh->prepare($sql)
        or return;
    $sth->execute($current_janitor)
        or return;
    $sth->finish();

    return 1;
}
