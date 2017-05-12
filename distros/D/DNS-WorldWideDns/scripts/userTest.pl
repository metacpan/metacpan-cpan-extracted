#!/usr/bin/perl

use lib '../lib';
use strict;
use Test::More  tests=>7;
use DNS::WorldWideDns;
use Exception::Class;
use Getopt::Long;



GetOptions(
    'username=s' => \my $username,
    'password=s' => \my $password,
    'domain=s' => \my $domain,
);


if ($username eq "" || $password eq "" || $domain eq "") {
    print "Usage: perl userTest.pl --username=myuser --password=mypass --domain=example.com\n\n";
    print <<STOP;
    This script is the primary test of this module. Normal tests wouldn't work since you must have
    a paid account with worldwidedns.net in order to run the tests. These tests will not harm your
    acount in any way provided you use a domain name that doesn't exist, or that you own that is
    not currently in your worldwidedns.net account. DO NOT use a domain that is already in your
    worldwidedns.net account or IT WILL BE DESTROYED.
STOP
    exit;
}

my $dns = DNS::WorldWideDns->new($username,$password);


# testing adds
my $returnCode = eval { $dns->addDomain($domain) };
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
ok($returnCode, 'Add reported success.');

my $domains = eval{$dns->getDomains};
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
is($domains->{$domain}, 'Primary', 'The new domain is in the list of domains.');


#testing updates
my $domainProperties = {
    hostmaster  => 'you.'.$domain,
    retry       => 3600,
    refresh     => 3600,
    expire      => 3600,
    ttl         => 3600,
    secureTransfer => '',
    records     => [
        {
            name    => 'www',
            type    => 'CNAME',
            ttl     => 4321,
            data    => $domain,
        },
        {
            name    => '@',
            type    => 'A',
            ttl     => 3600,
            data    => '1.2.3.4',
        },
        {
            name    => 'mail',
            type    => 'CNAME',
            data    => 'mail.'.$domain.'.',
        },
        {
            name    => '@',
            type    => 'MX',
            ttl     => 5000,
            data    => '10 smtp.mail.'.$domain.'.',
        }
    ]
};

$returnCode = eval {$dns->updateDomain($domain, $domainProperties)};
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
ok($returnCode, 'Updating reported success.');



# testing reads
$domainProperties = eval {$dns->getDomain($domain)};
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
is($domainProperties->{hostmaster}, 'you.'.$domain, 'Properties updated.');
foreach my $record (@{$domainProperties->{records}}) {
    if ($record->{type} eq 'MX') {
        is($record->{data}, '10 smtp.mail.'.$domain.'.', 'Records updated.');
    }
}


# testing deletes
$returnCode = eval {$dns->deleteDomain($domain)};
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
ok($returnCode, 'Deleting reported success.');
$domains = eval{$dns->getDomains};
if (my $e = Exception::Class->caught) {
    print "An error occured.\n";
    print "URL:     ".$e->url."\n";
    print "CODE:    ".$e->code."\n";
    print "MESSAGE: ".$e->error."\n";
}
ok(!exists $domains->{$domain}, 'The domain is no longer in the list.');


