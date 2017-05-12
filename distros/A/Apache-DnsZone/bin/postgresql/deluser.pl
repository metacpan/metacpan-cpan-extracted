#!/usr/bin/perl

use strict;
use DBI;
use Term::ReadKey;
use Email::Valid;

require 'conf.pl';

my ($db_src, $db_user, $db_pass) = conf();

my $dbh = DBI->connect($db_src, $db_user, $db_pass, { RaiseError => 1, PrintError => 1});

print "Username to delete: ";
my $user = <>;
chomp($user);

my $uid = $dbh->selectrow_array("select id from users where username = ?", undef, $user);

unless ($uid) {
    print "Need a real user\n";
    $dbh->disconnect();
    exit 1;
}

if ($dbh->selectrow_array("select id from domains where owner = ?", undef, $uid)) {
    print "$user has domains - do you want to delete these(n): ";
    my $answer = <>;
    chomp($answer);
    my $lock = 1 if $answer =~ /^y$/i;
    if (!$lock) {
	print "Will not delete $user...\n";
	$dbh->disconnect();
	exit 1;
    }
    my $sth = $dbh->prepare("select id, domain from domains where owner = ?");
    $sth->execute($uid);
    while (my ($dom_id, $domain) = $sth->fetchrow_array()) {
	print "Deleting $domain...\n";
	delete_recursive($dom_id);
    }
    $sth->finish();
}

$dbh->do("delete from users where username = ?", undef, $user);
print "$user deleted...\n";

$dbh->disconnect();

sub delete_recursive {
    my $dom_id = shift;
    $dbh->do("delete from rec_count where domain = ?", undef, $dom_id);
    $dbh->do("delete from soa where domain = ?", undef, $dom_id);
    $dbh->do("delete from records_A where domain = ?", undef, $dom_id);
    $dbh->do("delete from records_CNAME where domain = ?", undef, $dom_id);
    $dbh->do("delete from records_MX where domain = ?", undef, $dom_id);
    $dbh->do("delete from records_NS where domain = ?", undef, $dom_id);
    $dbh->do("delete from records_TXT where domain = ?", undef, $dom_id);
    $dbh->do("delete from domains where id = ?", undef, $dom_id);
}
