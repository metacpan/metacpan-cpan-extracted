#!/usr/bin/perl -w

use strict;
use Net::DNS;
use DBI;

require 'conf.pl';

my ($db_src, $db_user, $db_pass) = conf();

my $dbh = DBI->connect($db_src, $db_user, $db_pass, { RaiseError => 1, PrintError => 1});

print "Reverse Zone for inserting into DnsZone: ";
my $domain = <>;
chomp($domain);
unless ($domian =~ /\d+\.in\-addr\.arpa$/) {
    print "Reverse Zone needs to be in the .in-addr.arpa format\n";
    exit 1;
}
print "User to add $domain for: ";
my $user = <>;
chomp($user);
my $uid = $dbh->selectrow_array("select id from users where username = ?", undef, $user);
unless ($uid =~ /^\d+$/) {
    print "Unknown user\n";
    $dbh->disconnect();
    exit 1;
}
if ($dbh->selectrow_array("select id from domains where domain = ? and owner = ?", undef, $domain, $uid)) {
    print "$user already has $domain\n";
    $dbh->disconnect();
    exit 1;
}
print "From which nameserver do you want to transfer the zone for $domain: ";
my $nameserver = <>;
chomp($nameserver);
print "Performing Zone transfer...\n";

my $res = new Net::DNS::Resolver;
$res->nameservers($nameserver);
my @zone = $res->axfr($domain);

my $rrsoa = shift @zone;
die "first record not SOA" if $rrsoa->type ne 'SOA';
#$rrsoa->print;

print "Which restrictions do you want to place on the user:\n";
print "How many PTR records can he have: ";
my $ptr_rec = <>;
chomp($ptr_rec);
unless ($ptr_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}

print "Do you want the SOA to be locked (n): ";
my $answer = <>;
chomp($answer);
my $lock = 0;
$lock = 1 if $answer =~ /^y$/i;

print "Inserting records into db...\n";
$dbh->do("insert into domains (id, domain, owner) values ('', ?, ?)", undef, $domain, $uid);
my $dom_id = $dbh->selectrow_array("select id from domains where domain = ? and owner = ?", undef, $domain, $uid);
#printf("insert into domains (id, domain, owner) values ('','%s','%s')\n", $domain, $uid);
$dbh->do("insert into soa (domain, auth_ns, email, serial, refresh, default_ttl, expire, retry, rec_lock) values (?,?,?,?,?,?,?,?,?)", undef, $dom_id, $rrsoa->mname, $rrsoa->rname, $rrsoa->serial, $rrsoa->refresh, $rrsoa->ttl, $rrsoa->expire, $rrsoa->retry, $lock);
$dbh->do("insert into rec_count (domain, A_count, AAAA_count, CNAME_count, MX_count, NS_count, PTR_count, TXT_count) values (?,0,0,0,0,?,0)", undef, $dom_id, $ptr_rec);

foreach my $rr (@zone) {
    for ($rr->type) {
	if (/^PTR$/) {
	    print "PTR: ", $rr->name, " ", $rr->ptrdname, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_PTR (id, domain, name, ptrdname, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->ptrdname, $rr->ttl, $rec_lock);	    
	} else {
	    print "UNKNOWN\n";
	}
    }
}

print "$domain succesfully imported\n";

$dbh->disconnect();


sub rec_lock {
    my $lock = 0;
    print "Do you want this record to be locked (n): ";
    my $answer = <>;
    chomp($answer);
    $lock = 1 if $answer =~ /^y$/i;
    return $lock;
}
