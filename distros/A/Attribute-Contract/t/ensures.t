use strict;
use warnings;

use Test::More;
use Test::Fatal;

package MyClass;

use Attribute::Contract -types => [qw/Str/];

sub method : ContractEnsures(Str) {
    'ok';
}

package MyClassInvalid;

use Attribute::Contract -types => [qw/Str/];

sub method : ContractEnsures(Str) {
    [];
}

package main;

subtest 'correct return value' => sub {
    ok !exception { MyClass->method() };
};

subtest 'invalid return value' => sub {
    like exception { MyClassInvalid->method() },
      qr/\[\] did not pass type constraint "Str"/;
};

done_testing;
