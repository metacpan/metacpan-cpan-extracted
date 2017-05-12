#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Business::CPI::Gateway::Test;
use Business::CPI::Base::Account;
use Test::More;
use Test::Exception;
use DateTime;

my @attrs = qw(
      id gateway_id full_name first_name last_name
      login email birthdate registration_date phone
      is_business_account address business return_url
);
my $class = 'Business::CPI::Base::Account';

# Test class meta
{
    ok($class->can('new'), 'Class can be instantiated');

    for my $attr (@attrs) {
        ok($class->can($attr), qq{class has attribute $attr});
    }

    isa_ok($class, 'Business::CPI::Base::Account');
}

# Test wrong instantiation
{
    my $gtw = Business::CPI::Gateway::Test->new;
    my $obj;
    throws_ok { $obj = $class->new( birthdate => 'bogus', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string to birthdate attribute';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( birthdate => '01/01/2000', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string that looks like date to birthdate attribute';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( birthdate => '2000-01-01', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string that looks like date to birthdate attribute (again)';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( registration_date => 'bogus', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string to registration_date attribute';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( registration_date => '01/01/2000', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string that looks like date to registration_date attribute';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( registration_date => '2000-01-01', _gateway => $gtw ) } qr{DateTime}, 'attempting to set a string that looks like date to registration_date attribute (again)';
    ok(!$obj, 'object is undefined');
    throws_ok { $obj = $class->new( email => 'a@@b', _gateway => $gtw ) } qr{EmailAddress}, 'attempting to set an invalid email';
    ok(!$obj, 'object is undefined');
}

# Test correct instantiation
{
    my $obj;
    lives_ok {
        $obj = $class->new(
            id                => 'app0id014213',
            first_name        => 'John',
            last_name         => 'Smith',
            email             => 'john@smith.com',
            birthdate          => DateTime->now->subtract(years => 25),
            registration_date => DateTime->now,
            phone             => '11 00001111',
            address           => {
                street     => 'Av. Paulista',
                number     => '123',
                complement => '7º andar',
                district   => 'Bairro X',
                city       => 'São Paulo',
                state      => 'SP',
                country    => 'br',
            },
            business => {
                corporate_name => 'Aware Ltda.',
                trading_name   => 'Aware',
                phone          => '11 11110000',
                address        => {
                    street     => 'Alameda Santos',
                    number     => '321',
                    complement => '3º andar',
                    district   => 'Bairro Y',
                    city       => 'São Paulo',
                    state      => 'SP',
                    country    => 'br',
                },
            },
            return_url => 'http://mrsmith.com',
            _gateway => Business::CPI::Gateway::Test->new,
        );
    } 'build the object correctly now';

    isa_ok($obj, $class);
    is($obj->return_url, 'http://mrsmith.com', 'return url is correct');
    is($obj->full_name, 'John Smith', 'name is correct');
    isa_ok($obj->birthdate, 'DateTime');
    isa_ok($obj->business, 'Business::CPI::Base::Account::Business');
    isa_ok($obj->address, 'Business::CPI::Base::Account::Address');
    is($obj->address->street, 'Av. Paulista', "address seems to be correct");
    is($obj->business->trading_name, 'Aware', "business seems to be correct");
    is($obj->business->address->street, 'Alameda Santos', "business' address seems to be correct");

    for my $attr (@attrs) {
        ok($obj->can($attr), qq{object has attribute $attr});
    }

    throws_ok {
        $class->new(
            id         => 'app0id014213',
            first_name => 'John',
            last_name  => 'Smith',
            email      => 'john@smith.com',
            birthdate  => DateTime->now->subtract(years => 25),
            phone      => '11 00001111',
            address    => {
                street     => 'Av. Paulista',
                number     => '123',
                complement => '7º andar',
                district   => 'Bairro X',
                city       => 'São Paulo',
                state      => 'SP',
                country    => 'br',
            },
            business => {
                corporate_name => 'Aware Ltda.',
                trading_name   => 'Aware',
                phone          => '11 11110000',
                address        => {
                    street     => 'Alameda Santos',
                    number     => '321',
                    complement => '3º andar',
                    district   => 'Bairro Y',
                    city       => 'São Paulo',
                    state      => 'SP',
                    country    => 'br',
                },
            },
            return_url => 'http://mrsmith.com',
        );
    } qr/missing.*_gateway/i, 'die unless _gateway is defined';
}

done_testing();
