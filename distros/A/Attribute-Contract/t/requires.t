use strict;
use warnings;

use Test::More;
use Test::Fatal;

package MyClass;

use Attribute::Contract -types => [qw/ClassName Int Str slurpy HashRef Dict/];

sub new : ContractRequires(ClassName, slurpy Dict[foo => Int]) {
}

sub method : ContractRequires(ClassName, Str) {
}

package main;

subtest 'constructor' => sub {
    ok !exception { MyClass->new('foo' => 1) };
};

subtest 'invalid constructor' => sub {
    like exception { MyClass->new('foo' => 'haha') },
      qr/constraint "Dict\[foo=>Int\]"/;
};

subtest 'correct basic params' => sub {
    ok !exception { MyClass->method('foo') };
};

subtest 'invalid basic params' => sub {
    like exception { MyClass->method([]) }, qr/type constraint "Str"/;
};

done_testing;
