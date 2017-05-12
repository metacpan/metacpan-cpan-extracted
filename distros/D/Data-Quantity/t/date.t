#!/usr/bin/perl 

use strict;
use Test;

BEGIN { plan tests => 16, todo => [] }

use Data::Quantity::Time::Date;

my $someday;
ok( $someday = Data::Quantity::Time::Date->new( 2500000 ) );
ok( $someday->readable('dd Month yy') eq '31 August 2132' );

my $sameday = Data::Quantity::Time::Date->new_instance;
$sameday->set_from_string( '2132-08-31' );
ok( $someday->value eq $sameday->value );

ok( $someday->previous->value == $someday->value - 1 );
ok( $someday->next->value == $someday->value + 1 );

my $previous;
ok( $previous = $someday->previous );
ok( $previous->value eq $someday->previous->value );

ok( $someday->previous->readable('dd Month yy') eq '30 August 2132' );
ok( $someday->next->readable('dd Month yy') eq '1 September 2132' );

my $ynm_q;
ok( $ynm_q = $someday->year_and_month );

my $year;
ok( $year = $ynm_q->year );
ok( $year->readable() eq '2132' );
ok( $ynm_q->year->readable() eq '2132' );

ok( $ynm_q->first_day->readable('dd Month yy') eq '1 August 2132' );
ok( $someday->next->year_and_month->last_day->readable('dd Month yy') eq '30 September 2132' );

ok( $someday->last_second->value - $someday->first_second->value + 1 == (24*60*60) );

