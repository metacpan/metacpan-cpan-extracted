#!/usr/bin/perl

# This should match the code in the synopsis (excepting the test stuff)

use strict;
use warnings;

BEGIN {

  use Test::More tests => 16;

  use_ok( 'DateTime' );
  use_ok( 'DateTimeX::Duration::SkipDays' );

}

my $skip_days = q(

Christmas
Christmas Eve
RRULE:FREQ=WEEKLY;BYDAY=SA,SU

);

my $skip_x_days = 30;
my $start_date = DateTime->new( 'year' => 2011, 'month' => 12, 'day' => 1 );

my $s = DateTimeX::Duration::SkipDays->new( { 'parse_dates' => $skip_days, 'start_date' => $start_date, } );

my ( $span, $skipped ) = $s->add( $skip_x_days );

ok( $span->start->ymd eq '2011-12-01', 'Start date is correct (2011-12-01)' );
ok( $span->end->ymd   eq '2012-01-12', 'End date is correct (2012-01-12)' );

my $iter = $skipped->iterator;

my %skipped_days = (

  '2011-12-03' => 1,
  '2011-12-04' => 1,
  '2011-12-10' => 1,
  '2011-12-11' => 1,
  '2011-12-17' => 1,
  '2011-12-18' => 1,
  '2011-12-24' => 1,
  '2011-12-25' => 1,
  '2011-12-31' => 1,
  '2012-01-01' => 1,
  '2012-01-07' => 1,
  '2012-01-08' => 1,

);

while ( my $dt = $iter->next ) {

  ok( exists $skipped_days{ $dt->min->ymd }, 'Skipped ' . $dt->min->ymd );

}
