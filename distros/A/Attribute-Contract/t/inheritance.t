use strict;
use warnings;

use Test::More;
use Test::Fatal;

package MyClass;

use Attribute::Contract -types => [qw/ClassName Str/];

sub method : ContractRequires(ClassName, Str) {
}

package MyChildClass;
use base 'MyClass';

package MyChildClassWithOverwrite;
use base 'MyClass';
use Attribute::Contract;

sub method { }

package main;

subtest 'inherit contract' => sub {
    like exception { MyChildClass->method([]) },
      qr/\[\] did not pass type constraint "Str"/;
};

subtest 'inherit contract via overriden methods' => sub {
    like exception { MyChildClassWithOverwrite->method([]) },
      qr/\[\] did not pass type constraint "Str/;
};

subtest 'not allow contract change' => sub {
    like exception {
        eval "package MyMisbehavingChildClass;"
          . "use base 'MyClass'; sub method: ContractRequires(); 1"
          or die $@;
    }, qr/Changing contract of method 'method' in .*? is not allowed/;
};

done_testing;
