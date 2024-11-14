#!/usr/bin/perl
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';  # substitute with previous line when done

use Data::Annotation::Expression qw< evaluator_factory >;
use Data::Annotation::Util qw< o >;

my $o1 = o({foo => 'bar', baz => 'whatever', galook => '(?mxs:\Awhat)'});
isa_ok($o1, 'Data::Annotation::Overlay');

my $ev1 = evaluator_factory(
   {
      and => [
         { eq   => [qw< .foo =bar    >] },
         { '=~' => [qw< .baz .galook >] },
      ],
   }
);

isa_ok($ev1, 'CODE');
ok($ev1->($o1), 'successful evaluation');
ok(! $ev1->(o({foo => 'bar', baz => 'ever', galook => '(?mxs:\Awhat)'})),
   'evaluation to false');

done_testing();
