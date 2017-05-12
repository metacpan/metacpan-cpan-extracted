#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 3;

use Any::Renderer;

use constant OUTPUT_DEFAULT => q[\ {
    bar   [
        [0] "foo1",
        [1] "foo2",
        [2] "foo3"
    ],
    foo   "bar"
}];

use constant OUTPUT_INDENT_10 => q[\ {
          bar   [
                    [0] "foo1",
                    [1] "foo2",
                    [2] "foo3"
          ],
          foo   "bar"
}];



my $r  = Any::Renderer->new( 'Data::Printer');
my $r2 = Any::Renderer->new( 'Data::Printer', {indent=>10});


ok( $r, 'Object Creation' );

my $hash = {
    foo => 'bar',
    bar => ['foo1','foo2','foo3']
};


ok($r->render($hash) eq OUTPUT_DEFAULT, 'Output - Default');

ok( $r2->render($hash) eq OUTPUT_INDENT_10, 'Output - Indent 10');




