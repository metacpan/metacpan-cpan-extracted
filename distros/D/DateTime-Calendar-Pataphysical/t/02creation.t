use strict;
BEGIN { $^W = 1 }

use Test::More tests => 21;
use DateTime::Calendar::Pataphysical;

#########################

my $d = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 10, day => 9 );
isa_ok($d, "DateTime::Calendar::Pataphysical", 'date creation');
is( $d->year , 130, '... correct year' );
is( $d->month,  10, '... correct month' );
is( $d->day  ,   9, '... correct day' );

my $d2 = $d->clone;
isa_ok($d2, "DateTime::Calendar::Pataphysical", 'date cloning');
is( $d2->year , 130, '... correct year' );
is( $d2->month,  10, '... correct month' );
is( $d2->day  ,   9, '... correct day' );

$d = DateTime::Calendar::Pataphysical
            ->new( year => 130, month => 10, day => 29 );
isa_ok($d, "DateTime::Calendar::Pataphysical", 'imaginary date creation');
is( $d->year , 130, '... correct year' );
is( $d->month,  10, '... correct month' );
is( $d->day  ,  29, '... correct day' );

$d->set( day => 2 );
is( $d->year , 130, 'setting day: correct year' );
is( $d->month,  10, '... correct month' );
is( $d->day  ,   2, '... correct day' );

$d->set( month => 5 );
is( $d->year , 130, 'setting month: correct year' );
is( $d->month,   5, '... correct month' );
is( $d->day  ,   2, '... correct day' );

$d->set( year => 132 );
is( $d->year , 132, 'setting year: correct year' );
is( $d->month,   5, '... correct month' );
is( $d->day  ,   2, '... correct day' );
