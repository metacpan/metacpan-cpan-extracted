#!perl -T

use Test::More tests => 2;

use Date::Holidays::CN;

my $h = cn_holidays('2006');

is( $h->{'1225'}, '圣诞节', 'Xmas' );
is( $h->{'0214'}, '情人节', 'valentine\'s day' );
