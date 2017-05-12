use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;
use Data::Focus::Lens::Composite;

sub lens {
    Data::Focus::Lens::HashArray::Index->new(index => shift);
}

my $target = {
    foo => [
        {bar => "buzz"}
    ]
};
my $lens1 = lens("foo");
my $lens2 = lens(0);
my $lens3 = lens("bar");

subtest "synopsis" => sub {
    ####
    my $composite1 = Data::Focus::Lens::Composite->new($lens1, $lens2, $lens3);
    
    ## or
    
    my $composite2 = $lens1 . $lens2 . $lens3;
    
    ## Then, you can write
    
    my $value1 = focus($target)->get($composite1);
    my $value2 = focus($target)->get($composite2);
    
    ## instead of
    
    my $value3 = focus($target)->get($lens1, $lens2, $lens3);

    ## $value1 == $value2 == $value3

    ####
    isa_ok $composite1, "Data::Focus::Lens";
    isa_ok $composite1, "Data::Focus::Lens::Composite";
    isa_ok $composite2, "Data::Focus::Lens";
    isa_ok $composite2, "Data::Focus::Lens::Composite";
    is $value1, "buzz";
    is $value2, "buzz";
    is $value3, "buzz";
};

subtest "lens associative law" => sub {
    my $com1 = ($lens1 . $lens2) . $lens3;
    my $com2 = $lens1 . ($lens2 . $lens3);
    is focus($target)->get($com1), "buzz";
    is focus($target)->get($com2), "buzz";
};

subtest "empty composite lens" => sub {
    my $lens = Data::Focus::Lens::Composite->new();
    isa_ok $lens, "Data::Focus::Lens::Composite";
    is_deeply focus($target)->get($lens), {foo => [{bar => "buzz"}]}, "empty composite lens is Identity lens";
};

subtest "lens coercion" => sub {
    foreach my $case (
        {lens => Data::Focus::Lens::Composite->new("foo", 0, "bar")},
        {lens => $lens1 . 0 . "bar"},
        {lens => "foo" . (0 . $lens3)}
    ) {
        is focus($target)->get($case->{lens}), "buzz";
    }
};

done_testing;
