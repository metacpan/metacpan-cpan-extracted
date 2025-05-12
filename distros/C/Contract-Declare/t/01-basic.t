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
    package MyInterface;
    use Contract::Declare;
    
    contract 'MyInterface' => interface {
        method get_value => returns(DummyType->new);
    };
}

{
    package MyImpl;
    sub new { bless {}, shift }
    sub get_value { return 42 }
}

my $obj = MyInterface->new(MyImpl->new);

is($obj->get_value, 42, 'basic method call works');

done_testing();