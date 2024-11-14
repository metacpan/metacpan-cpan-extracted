#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';

use Data::Annotation;

my %definition = (
   default => 'reject',
   'default-chain' => 'foo',
   chains => {
      foo => {
         rules => [
            {
               return => 'accept',
               condition => {
                  eq => [ '.from', '=foobar@example.com' ],
               },
            }
         ],
      },
      bar => {
         default => 'reject',
         rules => [
            {
               return => 'accept',
               condition => {
                  '=~' => [ '.to', '=(?mxs:\A barbaz)' ],
               },
            },
         ],
      },
      baz => {
         default => 'reject',
         rules => [
            {
               return => 'accept',
               condition => {
                  '=~' => [ '.to', '=(?mxs:\A baz)' ],
               },
            },
         ],
      },
      galook => {
         rules => [
            {
               return => 'accept',
               condition => {
                  '=~' => [ '.to', '=(?mxs:\A galook)' ],
               },
            },
         ],
      },
   },
);
my $da = Data::Annotation->new(%definition);
isa_ok($da, 'Data::Annotation');

my $data = {from => 'foobar@example.com', to => 'barbaz@whatever.com'};

is($da->evaluate(foo => $data), 'accept', 'evaluate foo');
is($da->evaluate(bar => $data), 'accept', 'evaluate bar');
is($da->evaluate(inexistent => $data), 'accept', 'evaluate foo as fallback for inexistent');
is($da->evaluate(baz => $data), 'reject', 'evaluate baz');
is($da->evaluate(galook => $data), 'reject', 'evaluate galook');

done_testing();
