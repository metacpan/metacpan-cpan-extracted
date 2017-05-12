use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::All;

note("--- synopsis");

{
    my $lens = Data::Focus::Lens::HashArray::All->new;
    my $hash = {foo => 1, bar => 2};
    
    my $result_hash = focus($hash)->over($lens, sub { $_[0] * 10 });
    
    is_deeply $result_hash, {foo => 10, bar => 20};
    
    my $array = [1, 2, 3];
    my $result_array = focus($array)->over($lens, sub { $_[0] * 100 });
    
    is_deeply $result_array, [100, 200, 300];
}

done_testing;
