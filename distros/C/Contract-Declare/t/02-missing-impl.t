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
    package BrokenInterface;
    use Contract::Declare;
    
    contract 'BrokenInterface' => interface {
        method missing_method => returns(DummyType->new);
    };
}

{
    package PartialImpl;
    sub new { bless {}, shift }
    # нет метода missing_method
}

eval { BrokenInterface->new(PartialImpl->new) };
like($@, qr/Contract violation: Implementation does not provide method/, 'caught missing method');

done_testing();