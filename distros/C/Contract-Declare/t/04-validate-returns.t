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
    package ReturnInterface;
    use Contract::Declare;
    
    contract 'ReturnInterface' => interface {
        method get_value => returns(DummyType->new);
    };
}

{
    package ReturnImplBad;
    sub new { bless {}, shift }
    sub get_value { return "not a number" }
}

my $obj = ReturnInterface->new(ReturnImplBad->new);

eval { $obj->get_value };
like($@, qr/Contract violation/, 'caught bad return value');

done_testing();