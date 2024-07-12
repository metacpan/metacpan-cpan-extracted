use 5.010;
use strict;
use warnings;

use Data::Gimei::Random;

use Test2::Bundle::More;

{    # default seed
    my @results;
    my $r = Data::Gimei::Random->new;

    $r->next_int(42);    # must not throw error
}

{    # next_int
    my $expected;
    my $r = Data::Gimei::Random->new;

    $r->set_seed(42);
    $expected = $r->next_int(1024);

    $r->set_seed(42);
    is $r->next_int(1024),   $expected;
    isnt $r->next_int(1024), $expected;

    $r->set_seed(43);
    isnt $r->next_int(1024), $expected;
}

done_testing;
