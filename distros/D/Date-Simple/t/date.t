#!/usr/bin/perl -w
use strict;
use Test::More tests => 227;

use Date::Simple;

#------------------------------------------------------------------------------
# Check validate method
#------------------------------------------------------------------------------
use strict;
use warnings;

my $d;

#1
ok( $d = Date::Simple->new( 2000, 12, 25 ) );
ok( not Date::Simple->new( 2000, 13, 25 ) );
ok( not Date::Simple->new( 2000, 0,  25 ) );
ok( not Date::Simple->new( 2000, 12, 32 ) );
ok( not Date::Simple->new( 2000, 12, 0 ) );
ok( $d = Date::Simple->new( 1996, 02, 29 ) );
ok( not Date::Simple->new( 1900, 02, 29 ) );

#8
ok( $d = Date::Simple->new('2000-12-25') );
ok( not Date::Simple->new('2000-13-25') );
ok( not Date::Simple->new('2000-00-25') );
ok( not Date::Simple->new('2000-12-32') );
ok( not Date::Simple->new('2000-12-00') );
ok( $d = Date::Simple->new('1996-02-29') );
ok( not Date::Simple->new('1900-02-29') );

#------------------------------------------------------------------------------
# Check new method with parameters
#------------------------------------------------------------------------------

#15
ok( not Date::Simple->new( 2000, 2, 30 ) );
ok( $d = Date::Simple->new( 2000, 2, 28 ) );
ok( my $d2 = Date::Simple->new('2000-02-28') );

#18
is( $d,   $d2 );
is( 2000, $d->year );
is( 2,    $d->month );
is( 28,   $d->day );

ok( "$d" eq "2000-02-28" );

#------------------------------------------------------------------------------
# Date arithmetic
#------------------------------------------------------------------------------
#23
ok( $d += 7 );
is( "$d", "2000-03-06" );

ok( $d -= 14 );
is( "$d", "2000-02-21" );

is( $d cmp "2001-07-01", -1, 'cmp check' );
is( $d <=> [ 2001, 7, 1 ], -1, '<=> check' );

ok( $d2 = $d + 7 );
is( "$d2", "2000-02-28" );

#31
is( $d2->prev, "2000-02-27" );
is( $d2->next, "2000-02-29" );

is( $d2 - $d, 7 );

is( ( $d + 0 ), $d );
is( ( $d + -3 ), ( $d - 3 ) );
is( ( $d - -3 ), ( $d + 3 ) );

#------------------------------------------------------------------------------
# try again with another date
#------------------------------------------------------------------------------

ok( $d = Date::Simple->new('1998-02-28') );

ok( 1998 == $d->year );
ok( 2 == $d->month );
ok( 28 == $d->day );

ok( $d += 7 );
is( "$d", "1998-03-07" );

ok( $d -= 14 );
is( "$d", "1998-02-21" );

ok( $d2 = $d + 7 );
is( "$d2", "1998-02-28" );

is( $d2->prev, "1998-02-27" );
is( $d2->next, "1998-03-01" );

ok( $d = Date::Simple->new('1972-01-17') );
is( $d->year,  1972 );
is( $d->month, 1 );
is( $d->day,   17 );

is( $d->format, '1972-01-17' );

# Don't assume much about how this locale spells 'Jan'.
ok( $d->format('%d %b %Y') =~ m/17 \D+ 1972/ );
is( $d->format('Foo'), 'Foo' );

use Date::Simple ( 'date', 'd8' );

$d = Date::Simple->new( 1996, 10, 13 );

ok( $d == Date::Simple->new( [ 1996, 10, 13 ] ) );
ok( $d > date( 1996, 10, 12 ) );
ok( date('1996-10-12') <= $d );
is( Date::Simple->new( 2000, 3, 12 ) - d8(19690219), 11344 );

ok( $d = Date::Simple->new( 2000, 2, 12 ) );
ok( $d = $d + 17 );
is( $d->strftime("%Y %m %d"), "2000 02 29" );
$d += 1;
is( $d->as_d8, "20000301", 'as_d8()' );
is( $d - Date::Simple::ymd( 2000, 2, 12 ), 18, 'ymd()' );
is( ( $d - 18 )->format("%Y %m %d"), "2000 02 12" );

is( Date::Simple::ymd( 1966, 10, 15 )->day_of_week, 6 );
is( Date::Simple::ymd( 2401, 3,  1 )->day_of_week,  4 );
is( Date::Simple::ymd( 2401, 2,  28 )->day_of_week, 3 );
is( Date::Simple::ymd( 2400, 3,  1 )->day_of_week,  3 );
is( Date::Simple::ymd( 2400, 2,  29 )->day_of_week, 2 );
is( Date::Simple::ymd( 2400, 2,  28 )->day_of_week, 1 );
is( Date::Simple::ymd( 2101, 3,  1 )->day_of_week,  2 );
is( Date::Simple::ymd( 2101, 2,  28 )->day_of_week, 1 );
is( Date::Simple::ymd( 2100, 3,  1 )->day_of_week,  1 );
is( Date::Simple::ymd( 2100, 2,  28 )->day_of_week, 0 );
is( Date::Simple::ymd( 2001, 3,  1 )->day_of_week,  4 );
is( Date::Simple::ymd( 2001, 2,  28 )->day_of_week, 3 );
is( Date::Simple::ymd( 2000, 3,  1 )->day_of_week,  3 );
is( Date::Simple::ymd( 2000, 2,  29 )->day_of_week, 2 );
is( Date::Simple::ymd( 2000, 2,  28 )->day_of_week, 1 );
is( Date::Simple::ymd( 1901, 3,  1 )->day_of_week,  5 );
is( Date::Simple::ymd( 1901, 2,  28 )->day_of_week, 4 );
is( Date::Simple::ymd( 1900, 3,  1 )->day_of_week,  4 );
is( Date::Simple::ymd( 1900, 2,  28 )->day_of_week, 3 );
is( Date::Simple::ymd( 1801, 3,  1 )->day_of_week,  0 );
is( Date::Simple::ymd( 1801, 2,  28 )->day_of_week, 6 );
is( Date::Simple::ymd( 1800, 3,  1 )->day_of_week,  6 );
is( Date::Simple::ymd( 1800, 2,  28 )->day_of_week, 5 );
is( Date::Simple::ymd( 1701, 3,  1 )->day_of_week,  2 );
is( Date::Simple::ymd( 1701, 2,  28 )->day_of_week, 1 );
is( Date::Simple::ymd( 1700, 3,  1 )->day_of_week,  1 );
is( Date::Simple::ymd( 1700, 2,  28 )->day_of_week, 0 );
is( Date::Simple::ymd( 1601, 3,  1 )->day_of_week,  4 );
is( Date::Simple::ymd( 1601, 2,  28 )->day_of_week, 3 );
is( Date::Simple::ymd( 1600, 3,  1 )->day_of_week,  3 );
is( Date::Simple::ymd( 1600, 2,  29 )->day_of_week, 2 );
is( Date::Simple::ymd( 1600, 2,  28 )->day_of_week, 1, 'lala' );

foreach (
    [ 1969, 2,  19, 1 ],
    [ 1975, 6,  14, 1 ],
    [ 1999, 0,  1,  0 ],
    [ 1999, 1,  1,  1 ],
    [ 1999, 2,  28, 1 ],
    [ 1999, 2,  29, 0 ],
    [ 1999, 4,  31, 0 ],
    [ 1999, 4,  30, 1 ],
    [ 1999, 8,  1,  1 ],
    [ 1999, 8,  31, 1 ],    # produced '1999 09 00' due to buggy POSIX.xs
                            # in perl 5.005_63 and 5.5.560.
    [ 1999, 8,  32, 0 ],
    [ 1999, 12, 31, 1 ],
    [ 1999, 13, 1,  0 ],
    [ 2000, 1,  1,  1 ],
    [ 2000, 2,  12, 1 ],
    [ 2000, 2,  28, 1 ],
    [ 2000, 2,  29, 1 ],
    [ 2000, 3,  1,  1 ],
    [ 2001, 2,  29, 0 ],
    [ 2004, 2,  29, 1 ],
    [ 2100, 2,  29, 0 ],
  ) {
    $d = Date::Simple->new( @$_[ 0, 1, 2 ] );
    is( ( $d ? 1 : 0 ), $$_[3] );
    if ( $$_[3] ) {
        is( $d->year,  $$_[0] );
        is( $d->month, $$_[1] );
        is( $d->day,   $$_[2] );
        is( $d->strftime("%Y %m %d"),
            sprintf( "%04d %02d %02d", @$_[ 0, 1, 2 ] ) );
        is(
            join( ' ', $d->as_ymd ),
            join(
                ' ',
                Date::Simple::days_to_ymd(
                    Date::Simple::ymd_to_days( @$_[ 0, 1, 2 ] )
                )
            )
        );
    }
}

ok( Date::Simple::today() , 'lala');
is( Date::Simple::days_in_month( 2001, 10 ), 31 );

ok( d8('20021206') == 20021206);
ok( d8('20021206') eq '20021206' );
ok( d8('20021206') eq '2002-12-06' );
ok( d8('20021206') ne 'bla' );
ok( d8('20021206') != 123 );

$d = Date::Simple->new('1972-04-28');
my $d8  = Date::Simple::D8->new('1972-04-28');
my $iso = Date::Simple::ISO->new('1972-04-28');
my $fmt = Date::Simple::Fmt->new( '%d-%m-%Y', '1972-04-28' );

isa_ok( $d,   'Date::Simple' );
isa_ok( $d8,  'Date::Simple::D8' );
isa_ok( $iso, 'Date::Simple::ISO' );
isa_ok( $fmt, 'Date::Simple::Fmt' );

is( "$d",   '1972-04-28', 'Normal overloaded stringify' );
is( "$d8",  '19720428',   'D8 overloaded stringify' );
is( "$iso", '1972-04-28', 'ISO overloaded stringify' );
is( "$fmt", '28-04-1972', 'Fmt overloaded stringify' );

is( $d->as_str,   '1972-04-28', 'Normal as_str' );
is( $d8->as_str,  '19720428',   'D8 as_str' );
is( $iso->as_str, '1972-04-28', 'ISO as_str' );
is( $fmt->as_str, '28-04-1972', 'Fmt as_str' );

is( $d->as_d8,   '19720428', 'Normal as_d8' );
is( $d8->as_d8,  '19720428', 'D8 as_d8' );
is( $iso->as_d8, '19720428', 'ISO as_d8' );
is( $fmt->as_d8, '19720428', 'Fmt as_d8' );

is( $d->as_iso,   '1972-04-28', 'Normal as_iso' );
is( $d8->as_iso,  '1972-04-28', 'D8 as_iso' );
is( $iso->as_iso, '1972-04-28', 'ISO as_iso' );
is( $fmt->as_iso, '1972-04-28', 'Fmt as_iso' );

is( $d->as_str('<%Y><%m><%d>'),   '<1972><04><28>', 'Normal as_str(FMT)' );
is( $d8->as_str('<%Y><%m><%d>'),  '<1972><04><28>', 'D8 as_str(FMT)' );
is( $iso->as_str('<%Y><%m><%d>'), '<1972><04><28>', 'ISO as_str(FMT)' );
is( $fmt->as_str('<%Y><%m><%d>'), '<1972><04><28>', 'Fmt as_str(FMT)' );

$d   = Date::Simple->new();
$d8  = Date::Simple::D8->new();
$iso = Date::Simple::ISO->new();
$fmt = Date::Simple::Fmt->new('%d-%m-%Y');

isa_ok( $d,   'Date::Simple' );
isa_ok( $d8,  'Date::Simple::D8' );
isa_ok( $fmt, 'Date::Simple::Fmt' );
isa_ok( $iso, 'Date::Simple::ISO' );

my ( $Y, $M, $D ) = (localtime)[ 5, 4, 3 ];
$Y += 1900;
$M += 1;
$_ = sprintf "%02d", $_ for $M, $D;

is( "$d",   "$Y-$M-$D", 'Normal overloaded stringify' );
is( "$d8",  "$Y$M$D",   'D8 overloaded stringify' );
is( "$iso", "$Y-$M-$D", 'ISO overloaded stringify' );
is( "$fmt", "$D-$M-$Y", 'Fmt overloaded stringify' );

