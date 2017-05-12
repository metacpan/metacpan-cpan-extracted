#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use DBI;
use JSON;
use URI::Escape;

my $db_hostname = 'localhost';
my $db_database = 'simple';
my $db_username = 'simple';
my $db_password = 'toosimple';

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

    my $dsn = "DBI:mysql:database=$db_database;host=$db_hostname;user=$db_username;password=$db_password";
    my $dbh = DBI->connect($dsn);

    my $sql = <<EOS;
CREATE TABLE IF NOT EXISTS `standby_queue` (
  `id` int(16) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `cellphone` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
EOS
    $dbh->do($sql);

    $sql = 'TRUNCATE TABLE standby_queue';
    my $sth = $dbh->prepare($sql)
        or return;
    $sth->execute()
        or return;
    $sth->finish();

    $sql = 'INSERT INTO standby_queue (name,cellphone) VALUES(?,?)';
    $sth = $dbh->prepare($sql)
        or return;
    foreach my $user (@$queue_ref) {
        $sth->execute($user->{'name'},$user->{'cellphone'})
            or return;
        # if this user has an alternated number defined insert it, too
        if($user->{'phone_alt'}) {
            $sth->execute($user->{'name'}.' (Fallback)',$user->{'phone_alt'});
        }
    }
    $sth->finish();

    $dbh->disconnect();

    return 1;
}
