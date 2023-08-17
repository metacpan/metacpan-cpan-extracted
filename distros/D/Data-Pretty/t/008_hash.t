#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 9;

use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

my $DOTS = "." x 20;

is(dump({}), "{}", 'dump hash');
is(dump({ a => 1}), "{ a => 1 }", 'dump hash');
is(dump({ 1 => 1}), "{ 1 => 1 }", 'dump hash');
is(dump({strict => 1, shift => 2, abc => 3, -f => 4 }),
    "{ -f => 4, abc => 3, shift => 2, strict => 1 }", 'dump hash sorted properties');
is(dump({supercalifragilisticexpialidocious => 1, a => 2}),
    "{ a => 2, supercalifragilisticexpialidocious => 1 }", 'dump hash long property');
is(dump({supercalifragilisticexpialidocious => 1, a => 2, b => $DOTS})."\n", <<EOT);
{
    a => 2,
    b => "$DOTS",
    supercalifragilisticexpialidocious => 1,
}
EOT
is(dump({aa => 1, B => 2}), "{ aa => 1, B => 2 }", 'dump hash');
is(dump({a => 1, bar => $DOTS, baz => $DOTS, foo => 2 })."\n", <<EOT);
{
    a => 1,
    bar => "$DOTS",
    baz => "$DOTS",
    foo => 2,
}
EOT
is(dump({a => 1, "b-z" => 2}), qq({ a => 1, "b-z" => 2 }), 'dump smart quotes');
