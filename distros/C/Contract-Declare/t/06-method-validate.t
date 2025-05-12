use strict;
use warnings;

use Test::More;
use Contract::Declare;

{
    package DummyType;
    sub new { bless {}, shift }
    sub compiled_check { sub { 1 } }
}

{
    package BrokenType;
    sub new { bless {}, shift }
    # НЕТ compiled_check
}

{
    package MyInterface;
    use Contract::Declare;
    use Test::More;

    eval {
        contract 'MyInterface' => interface {
            method valid_method => DummyType->new, returns(DummyType->new);
        };
    };
    ok(!$@, 'Valid method definition passed');

    eval {
        contract 'MyInterface' => interface {
            method bad_input => 'string', returns(DummyType->new);
        };
    };
    like($@, qr/Contract violation: input argument/, 'Caught bad input type');

    eval {
        contract 'MyInterface' => interface {
            method bad_return => DummyType->new, returns('string');
        };
    };
    like($@, qr/Contract violation: each return type/, 'Caught bad return type');

    eval {
        contract 'MyInterface' => interface {
            method bad_output => DummyType->new, returns(BrokenType->new);
        };
    };
    like($@, qr/Contract violation: each return type/, 'Caught broken return type');
}

done_testing();