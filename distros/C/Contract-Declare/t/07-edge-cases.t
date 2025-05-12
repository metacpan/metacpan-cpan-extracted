use strict;
use warnings;
use Test::More;
use Contract::Declare;

$ENV{CONTRACT_DECLARE_CHECK_TYPES} = 1;

{
    package DummyType;
    sub new { bless {}, shift }
    sub compiled_check { sub { 1 } }
}

{
    package EdgeInterface;
    use Contract::Declare;
    
    contract 'EdgeInterface' => interface {
        method no_args => returns(DummyType->new);
        method multi_args => DummyType->new, DummyType->new, returns(DummyType->new, DummyType->new);
    };
}

{
    package EdgeImpl;
    sub new { bless {}, shift }
    sub no_args { return 1 }
    sub multi_args { my ($self, $a, $b) = @_; return ($a, $b) }
}

my $obj = EdgeInterface->new(EdgeImpl->new);

is($obj->no_args, 1, 'no_args method works');

my ($a, $b) = $obj->multi_args(5, 10);
is($a, 5, 'multi_args first return');
is($b, 10, 'multi_args second return');

done_testing();