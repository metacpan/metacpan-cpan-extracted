#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use Test::More;

use lib dirname(__FILE__);
use MyTestUA;

use App::CPANCoverBadge;

my $badger = App::CPANCoverBadge->new( ua => MyTestUA->new, sql => 1 );
isa_ok $badger, 'App::CPANCoverBadge';

my %tests = (
    'red' => {
        code  => 404,
        value => '22.0',
    },
    'types-reneeb' => {
        code  => 200,
        value => '100.0',
    },
    'does-not-exist' => {
        code  => 404,
        value => undef,
    },
);

for my $dist ( sort keys %tests ) {
    my $value = $badger->_get_cpancover_rating( $dist );
    is $value, $tests{$dist}->{value}, $dist;
}


done_testing();

