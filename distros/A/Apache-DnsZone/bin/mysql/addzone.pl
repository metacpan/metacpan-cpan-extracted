#!/usr/bin/perl -w

use strict;
use Net::DNS;
use DBI;

require 'conf.pl';

my ($db_src, $db_user, $db_pass) = conf();

my $dbh = DBI->connect($db_src, $db_user, $db_pass, { RaiseError => 1, PrintError => 1});

print "Domain for inserting into DnsZone: ";
my $domain = <>;
chomp($domain);
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
print "How many A records can he have: ";
my $a_rec = <>;
chomp($a_rec);
unless ($a_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}
print "How many AAAA records can he have: ";
my $aaaa_rec = <>;
chomp($aaaa_rec);
unless ($aaaa_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}
print "How many CNAME records can he have: ";
my $cname_rec = <>;
chomp($cname_rec);
unless ($cname_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}
print "How many MX records can he have: ";
my $mx_rec = <>;
chomp($mx_rec);
unless ($mx_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}
print "How many NS records can he have: ";
my $ns_rec = <>;
chomp($ns_rec);
unless ($ns_rec =~ /^\d+$/) {
    print "needed to be a number\n";
    $dbh->disconnect();
    exit 1;
}
print "How many TXT records can he have: ";
my $txt_rec = <>;
chomp($txt_rec);
unless ($txt_rec =~ /^\d+$/) {
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
$dbh->do("insert into rec_count (domain, A_count, AAAA_count, CNAME_count, MX_count, NS_count, TXT_count) values (?,?,?,?,?,?)", undef, $dom_id, $a_rec, $aaaa_rec, $cname_rec, $mx_rec, $ns_rec, $txt_rec);

foreach my $rr (@zone) {
    for ($rr->type) {
	if (/^A$/) {
	    print "A: ", $rr->name, " ", $rr->address, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_A (id, domain, name, address, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->address, $rr->ttl, $rec_lock);	    
	} elsif (/^AAAA$/) {
	    print "AAAA: ", $rr->name, " ", $rr->address, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_AAAA (id, domain, name, address, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->address, $rr->ttl, $rec_lock);	    
	} elsif (/^CNAME$/) {
	    print "CNAME: ", $rr->name, " ", $rr->cname, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_CNAME (id, domain, name, cname, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->cname, $rr->ttl, $rec_lock);	    
	} elsif (/^MX$/) {
	    print "MX: ", $rr->name, " ", $rr->exchange,  " ", $rr->preference, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_MX (id, domain, name, exchanger, preference, ttl, rec_lock) values ('',?,?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->exchange, $rr->preference, $rr->ttl, $rec_lock);
	} elsif (/^NS$/) {
	    print "NS: ", $rr->name, " ", $rr->nsdname, " ", $rr->ttl, "\n";
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_NS (id, domain, name, nsdname, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->nsdname, $rr->ttl, $rec_lock);
	} elsif (/^SOA$/) {
	    print "SOA not supposed to be here!\n";
	} elsif (/^TXT$/) {
	    print "TXT: ", $rr->name, " '", $rr->txtdata, "' ", $rr->ttl, "\n"; 
	    my $rec_lock = rec_lock();
	    $dbh->do("insert into records_TXT (id, domain, name, txtdata, ttl, rec_lock) values ('',?,?,?,?,?)", undef, $dom_id, $rr->name, $rr->txtdata, $rr->ttl, $rec_lock);	    
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
