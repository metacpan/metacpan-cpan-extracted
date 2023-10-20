#!perl
use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 3;
# print "1..3\n";

use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

my $a = 42;
my @a = (\$a);

my $d = dump($a, $a, \$a, \\$a, "$a", $a+0, \@a);

is( "$d", '(42, 42, \42, \\\\42, 42, 42, [\42])' );

$d = dump(\\$a, \$a, $a, \@a);
is( "$d", '(\\\\42, \42, 42, [\42])' );

# not really a scalar test, but anyway
$a = [];
$d = dump(\$a, $a);

is( "$d", q(do {
    my $a = \[];
    ($a, $$a);
}) );

