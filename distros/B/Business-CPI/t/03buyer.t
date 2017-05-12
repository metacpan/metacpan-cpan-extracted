#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Business::CPI::Base::Buyer;

# TEST NO ADDRESS
{
    my $buyer = Business::CPI::Base::Buyer->new({
        email => 'buyer@andrewalker.net',
        name  => 'Mr. Buyer',
    });

    ok($buyer, 'the $buyer object is defined');
    isa_ok($buyer, 'Business::CPI::Base::Buyer');
    ok(! defined $buyer->address_street, 'street field is empty when not set in builder');
}

# TEST WHOLE ADDRESS
{
    my %address = (
        address_street     => 'Street 1',
        address_number     => '25b',
        address_district   => 'My neighbourhood',
        address_complement => 'Apartment 05',
        address_city       => 'Happytown',
        address_state      => 'SP',
        address_country    => 'BR',
    );

    my $buyer = Business::CPI::Base::Buyer->new({
        email              => 'buyer@andrewalker.net',
        name               => 'Mr. Buyer',
        %address,
    });

    $address{address_country} = 'br'; # it correctly coerces to lowercase

    ok($buyer, 'the $buyer object is defined');
    isa_ok($buyer, 'Business::CPI::Base::Buyer');

    for (sort keys %address) {
        is($buyer->$_, $address{$_}, "$_ is properly defined in the \$buyer object");
    }
}

# TEST COUNTRY COERSION
{
    my %address = (
        address_street     => 'Street 1',
        address_number     => '25b',
        address_district   => 'My neighbourhood',
        address_complement => 'Apartment 05',
        address_city       => 'Happytown',
        address_state      => 'SP',
        address_country    => 'Brazil',
    );

    my $buyer = Business::CPI::Base::Buyer->new({
        email              => 'buyer@andrewalker.net',
        name               => 'Mr. Buyer',
        %address,
    });

    ok($buyer, 'the $buyer object is defined');
    isa_ok($buyer, 'Business::CPI::Base::Buyer');

    is($buyer->address_country, 'br', "address_country is properly stored in the \$buyer object");
}

# TEST WRONG COUNTRY
{
    my %address = (
        address_line1   => 'Street2, 35',
        address_line2   => 'Neighbourhood X',
        address_city    => 'Happytown',
        address_state   => 'SP',
        address_country => 'BRA',
    );

    my $buyer = eval {
        Business::CPI::Base::Buyer->new({
            email              => 'buyer@andrewalker.net',
            name               => 'Mr. Buyer',
            %address,
        })
    };

    ok(!$buyer, 'the $buyer object is not defined when country is wrong');
    ok($@, "there was an error building");
    like($@, qr/did not pass type constraint "Country"/, 'the error was for the correct reason');
}

# TEST DEFAULT ADDRESS LINE1, LINE2
{
    my %address = (
        address_street     => 'Street 1',
        address_number     => '25',
        address_district   => 'My neighbourhood',
        address_complement => 'Apartment 05',
        address_city       => 'Happytown',
        address_state      => 'SP',
        address_country    => 'BR',
    );

    my $buyer = Business::CPI::Base::Buyer->new({
        email              => 'buyer@andrewalker.net',
        name               => 'Mr. Buyer',
        %address,
    });

    ok($buyer, 'the $buyer object is defined');
    isa_ok($buyer, 'Business::CPI::Base::Buyer');

    is($buyer->address_line1, "Street 1, 25", "Line 1 is correct");
    is($buyer->address_line2, "My neighbourhood - Apartment 05", "Line 2 is correct");
}

# TEST CUSTOM ADDRESS LINE1, LINE2
{
    my %address = (
        address_line1   => 'Street2, 35',
        address_line2   => 'Neighbourhood X',
        address_city    => 'Happytown',
        address_state   => 'SP',
        address_country => 'BR',
    );

    my $buyer = Business::CPI::Base::Buyer->new({
        email              => 'buyer@andrewalker.net',
        name               => 'Mr. Buyer',
        %address,
    });

    ok($buyer, 'the $buyer object is defined');
    isa_ok($buyer, 'Business::CPI::Base::Buyer');

    is($buyer->address_line1, $address{address_line1}, "Line 1 is correct");
    is($buyer->address_line2, $address{address_line2}, "Line 2 is correct");
    ok(! defined $buyer->address_street, "Street address is not defined when not set");
}

done_testing;
