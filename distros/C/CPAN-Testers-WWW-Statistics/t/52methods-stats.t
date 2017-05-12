#!perl

use strict;
use warnings;

use Test::More;
use CPAN::Testers::WWW::Statistics;

use lib 't';
use CTWS_Testing;

if(CTWS_Testing::has_environment()) { plan tests    => 7; }
else                                { plan skip_all => "Environment not configured"; }

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );

my %names = (
    'stro@cpan.org'     => [ 'Serguei Trouchelle (STRO)', 1742, 538 ],
    'barbie@cpan.org'   => [ 'barbie + cpan org', 0, 0 ]
);

for my $name (keys %names) {
    my @values = $obj->tester($name);
    is_deeply(\@values, $names{$name}, "tester name matches: $name");
}

$obj->tester_loader();

my $address = $obj->address;
is(scalar(keys %$address),10,'found correct number of address entries');
is($obj->known_s(),10,'found correct number of address entries (count)');

my $profile = $obj->profile;
is(scalar(keys %$profile),9,'found correct number of profile entries');
is($obj->known_t(),9,'found correct number of profile entries (count)');
