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
    package BadInterface;
    use Contract::Declare;
    use Test::More;
    
    eval {
        contract 'BadInterface' => interface {
            method broken_method => 'not_a_type', returns(DummyType->new);
        };
    };
    like($@, qr/Contract violation/, 'caught bad input type');
}

{
    package BadReturnInterface;
    use Contract::Declare;
    use Test::More;
    
    eval {
        contract 'BadReturnInterface' => interface {
            method another_method => DummyType->new, returns('not_a_type');
        };
    };
    like($@, qr/Contract violation/, 'caught bad return type');
}

done_testing();