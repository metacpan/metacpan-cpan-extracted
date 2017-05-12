#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Business::CPI::Base::Account::Address;
use Test::More;
use Test::Exception;
use DateTime;

my @attrs = qw/street number complement district city state country zip_code/;
my $class = 'Business::CPI::Base::Account::Address';

# Test class meta
{
    ok($class->can('new'), 'Class can be instantiated');

    for my $attr (@attrs) {
        ok($class->can($attr), qq{class has attribute $attr});
    }
}

# Test building the object
{
    my $obj;
    my %data = (
        street     => 'Av. Paulista',
        number     => '123',
        complement => 'x',
        district   => 'W/e',
        city       => 'São Paulo',
        state      => 'SP',
        zip_code   => '123',
        country    => 'br',
    );
    lives_ok {
        $obj = $class->new(%data);
    } 'Object is built ok';

    isa_ok($obj, $class);
    for (keys %data) {
        is($obj->$_, $data{$_}, $_ . ' is set ok');
    }

    is($obj->line1, 'Av. Paulista, 123 - x', 'Line 1 of the address is ok');
    is($obj->line2, 'W/e', 'Line 2 of the address is ok');
}

done_testing();
