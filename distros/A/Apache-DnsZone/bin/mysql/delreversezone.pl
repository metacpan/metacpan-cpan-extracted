#!/usr/bin/perl -w

use strict;
use DBI;

require 'conf.pl';

my ($db_src, $db_user, $db_pass) = conf();

my $dbh = DBI->connect($db_src, $db_user, $db_pass, { RaiseError => 1, PrintError => 1});

print "User to delete domain from: ";
my $user = <>;
chomp($user);
print "Domain to delete from $user: ";
my $domain = <>;
chomp($domain);
unless ($domain =~ /\d+\.in\-addr\.arpa$/) {
    print "Domain needs to be a reverse zone\n";
    exit 1;
}

my $uid = $dbh->selectrow_array("select id from users where username = ?", undef, $user);
unless ($uid =~ /^\d+$/) {
    print "Unknown user\n";
    $dbh->disconnect();
    exit 1;
}

my $dom_id = $dbh->selectrow_array("select id from domains where domain = ? and owner = ?", undef, $domain, $uid);
unless ($dom_id =~ /^\d+$/) {
    print "Unknown domain\n";
    $dbh->disconnect();
    exit 1;
}

$dbh->do("delete from rec_count where domain = ?", undef, $dom_id);
$dbh->do("delete from soa where domain = ?", undef, $dom_id);
$dbh->do("delete from records_PTR where domain = ?", undef, $dom_id);
$dbh->do("delete from domains where id = ?", undef, $dom_id);

print "$domain succesfully deleted\n";

$dbh->disconnect();
