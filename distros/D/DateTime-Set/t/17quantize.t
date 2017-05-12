#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 1;

use DateTime::Set;
use DateTime::SpanSet;

my $months = DateTime::Set->from_recurrence(
    next => sub {
            $_[0]->truncate( to => 'month' )
                 ->add( months => 1 );
        } );

my $spanset = DateTime::SpanSet->from_spans(
    spans => [
        DateTime::Span->from_datetimes(
                start => DateTime->new( year => 2000, month => 3, day => 15 ),
                before => DateTime->new( year => 2001 ),
           ),
        DateTime::Span->from_datetimes(
                start => DateTime->new( year => 2004 ),
                end => DateTime->new( year => 2005 ),
           ),
      ] );

# quantize to months

my $month_set = $spanset->map(
    sub {
        ( $_->intersection( $months ),
          $months->current( $_->min ) )
     }
  )->start_set;

is ( "" . $month_set->{set},
     "2000-03-01T00:00:00,2000-04-01T00:00:00,2000-05-01T00:00:00,".
     "2000-06-01T00:00:00,2000-07-01T00:00:00,2000-08-01T00:00:00,".
     "2000-09-01T00:00:00,2000-10-01T00:00:00,2000-11-01T00:00:00,".
     "2000-12-01T00:00:00,2004-01-01T00:00:00,2004-02-01T00:00:00,".
     "2004-03-01T00:00:00,2004-04-01T00:00:00,2004-05-01T00:00:00,".
     "2004-06-01T00:00:00,2004-07-01T00:00:00,2004-08-01T00:00:00,".
     "2004-09-01T00:00:00,2004-10-01T00:00:00,2004-11-01T00:00:00,".
     "2004-12-01T00:00:00,2005-01-01T00:00:00" ,
     "spanset was quantized to a set"
);


