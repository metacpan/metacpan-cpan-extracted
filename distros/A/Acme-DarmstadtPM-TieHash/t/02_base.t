#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use constant ADT => 'Acme::DarmstadtPM::TieHash';

use_ok(ADT);

tie my %hash,ADT,sub{$_[0] + $_[-1]};

is($hash{[1,5]},6,'Check [1,5]');
is($hash{[1,5]},6,'Check [1,5]');
is($hash{[2,3,5]},7,'Check [2,3,5]');
is($hash{[2,5]},7,'Check [2,5]');
is($hash{[2,3]},5,'Check [2,3]');

ok $hash{[1,5]};
ok exists $hash{[1,5]};
is delete $hash{[1,5]}, 6, 'delete hash key';

my %check = (
    '235' => 7,
    '23'  => 5,
    '25'  => 7,
);

my @keys = keys %hash;
is scalar( @keys ), 3, 'three keys in %hash';

is_deeply [ sort map { join '', @{$_} }@keys ], [ sort keys %check ], 'Check remaining keys';

while ( my ($key, $value) = each %hash ) {
    my $tmp_key = join '', @{$key};
    is $value, $check{$tmp_key}, "Check value for $key";
}

untie %hash;

done_testing();
