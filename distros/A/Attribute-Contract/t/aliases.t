use strict;
use warnings;

use Test::More;
use Test::Fatal;

package MyClass;

use Attribute::Contract
  -types => [qw/ClassName Str/],
  -names => {requires => 'In', ensures => 'Out'};

sub method : In(ClassName, Str) Out(Str) {
    {}
}

package main;

subtest 'work with requires aliases' => sub {
    like exception { MyClass->method([]) },
      qr/constraint "Str"/;
};

subtest 'work with ensures aliases' => sub {
    like exception { MyClass->method('123') },
      qr/constraint "Str"/;
};

done_testing;
