use Test::More qw(no_plan);

use strict;
use warnings;
use Attribute::Generator;

sub gen_basic :Generator {
    for(1, 2, 3, 'foo', 'bar', 6) {
        yield $_;
    }
}

sub gen_arguments :Generator {
    my(@list) = @_;
    for(@list) {
        yield $_ + 1;
    }
}

sub gen_nest :Generator {
    my($stream) = @_;
    while(defined(my $ev = $stream->next)) {
        yield "=$ev=";
    }
}

sub gen_list :Generator {
    yield 1,2,3;
    yield 5,6;
}

{ # Basic
    my $gen = gen_basic();

    is($gen->next, 1);
    is($gen->next, 2);
    is($gen->next, 3);
    is($gen->next, 'foo');
    is($gen->next, 'bar');
    is($gen->next, 6);
    is($gen->next, undef);
    is($gen->next, undef);
}

{ # with arguments
    my $gen = gen_arguments(3,2,1);

    is($gen->next, 4);
    is($gen->next, 3);
    is($gen->next, 2);
    is($gen->next, undef);
}

{ # mixed
    my $gen1 = gen_basic();
    my $gen2 = gen_arguments(7,6,5,4,3,2);
    is($gen1->next, 1);
    is($gen2->next, 8);
    is($gen1->next, 2);
    is($gen2->next, 7);
    is($gen1->next, 3);
    is($gen2->next, 6);
    is($gen1->next, 'foo');
    is($gen2->next, 5);
    is($gen1->next, 'bar');
    is($gen2->next, 4);
    is($gen1->next, 6);
    is($gen2->next, 3);
    is($gen1->next, undef);
    is($gen2->next, undef);
}

{ # nested
    my $gen = gen_arguments(1, 2);
    $gen = gen_nest($gen);
    is($gen->next, '=2=');
    is($gen->next, '=3=');
    is($gen->next, undef);
}

{ # yield list
    my $gen = gen_list();
    is_deeply([$gen->next], [1,2,3]);
    is_deeply([$gen->next], [5,6]);
}

1;
