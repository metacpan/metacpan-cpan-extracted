#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Dancer::Template::Tiny;

my $template   = "[% FOREACH num IN nums %]\n[% num %]\n[% END %]";
my $exp_result = "\n1\n\n2\n\n3\n"; # sure lots of spaces...

my $engine = Dancer::Template::Tiny->new();
my $result = $engine->render( \$template, { nums => [ 1, 2, 3 ] } );

is( $result, $exp_result, 'Correct rendering of FOREACH' );

$template   = 'hello [% var %]';
$exp_result = 'hello world';
$result     = $engine->render( \$template, { var => 'world' } );

is( $result, $exp_result, 'Correct rendering of basic variable' );

# TODO: test for files
# TODO: test for fails when missing variables hashref
