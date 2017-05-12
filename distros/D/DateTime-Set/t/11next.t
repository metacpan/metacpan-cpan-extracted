#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 4;

use DateTime;
use DateTime::Set;
# use warnings;

#======================================================================
# next method
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

{
    my $set =
        DateTime::Set->from_recurrence
                ( next =>
                  sub { $_[0]->truncate( to => 'day' )->add( days => 1 ) }
                );

    my $dt = DateTime->new( year  => 2000,
                            month => 10,
                            day   => 1,
                          );

    my $next_dt = $set->next($dt);

    is( $next_dt->ymd, '2000-10-02',
        'next day is 2000-10-02' );

    is( $set->next($next_dt)->ymd, '2000-10-03',
        'next day is 2000-10-03' );
}

{
    # previous-only recurrence

    my $set =
        DateTime::Set->from_recurrence
                ( previous =>
                  sub { $_[0]->truncate( to => 'day' )->subtract( days => 1 ) }
                );

    my $dt = DateTime->new( year  => 2000,
                            month => 10,
                            day   => 1,
                          );

    my $next_dt = $set->next($dt);

    is( $next_dt->ymd, '2000-10-02',
        'next day is 2000-10-02' );

    is( $set->next($next_dt)->ymd, '2000-10-03',
        'next day is 2000-10-03' );
}
