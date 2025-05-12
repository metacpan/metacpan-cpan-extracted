use strict;
use warnings;
use Test::More;
use Contract::Declare;

$ENV{CONTRACT_DECLARE_CHECK_TYPES} = 1;

{
    package DummyType;
    sub new { bless {}, shift }
    sub compiled_check { sub { $_[0] =~ /^\d+$/ } }
}

{
    package ArgInterface;
    use Contract::Declare;
    
    contract 'ArgInterface' => interface {
        method add_number => (DummyType->new), returns(DummyType->new);
    };
}

{
    package ArgImpl;
    sub new { bless {}, shift }
    sub add_number { my ($self, $n) = @_; return $n + 1 }
}

my $obj = ArgInterface->new(ArgImpl->new);

is($obj->add_number(1), 2, 'correct arg passes');

eval { $obj->add_number('oops') };
like($@, qr/Contract violation/, 'caught bad argument');

eval { $obj->add_number(1,2) };
like($@, qr/Contract violation/, 'caught wrong arg count');

done_testing();