#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 7;

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    is $value1 <=> $value2, 0, '1.2 USD <=> 1.2 USD';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.3, 'USD' );
    is $value1 <=> $value2, -1, '1.2 USD <=> 1.3 USD';
}

{
    my $value1 = 1.4;
    my $value2 = Data::Currency->new( 1.3, 'USD' );
    is $value1 <=> $value2, 1, '1.4 <=> 1.3 USD';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    cmp_ok $value1, 'eq', $value2, '1.2 USD cmp 1.2 USD';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.3, 'USD' );
    cmp_ok $value1, 'lt', $value2, '1.2 USD cmp 1.3 USD';
}

{
    my $value1 = Data::Currency->new( 1.3, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    cmp_ok $value1, 'gt', $value2, '1.2 USD cmp 1.3 USD';
}


{
    my $value1 = '$1.30';
    my $value2 = Data::Currency->new( 1.3, 'USD' );
    cmp_ok $value1, 'eq', $value2, '$1.3 cmp $1.3';
}

