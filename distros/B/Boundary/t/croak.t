use strict;
use warnings;
use Test::More;
 
use Boundary ();

subtest 'basic' => sub {
    eval { Boundary::croak('hello') };
    like $@, qr/^hello/;
};

subtest 'croak message suffix' => sub {
    eval {
        local $Boundary::CROAK_MESSAGE_SUFFIX = ' world';
        Boundary::croak('hello')
    };
    like $@, qr/^hello world/;
};

done_testing;
