use strict;
use warnings;
use Data::Monad::Maybe qw/just nothing/;
use Data::Monad::Base::Sugar;
use Test::More;
use Test::Warnings qw(warning);

my $data = just { hage => { debu => { me => 1 } } };

sub get_key($) {
    my ($key) = @_;
    sub {
        my $data = shift;
        return nothing unless ref $data eq 'HASH';
        exists $data->{$key} ? just $data->{$key} : nothing;
    };
}

{
    # Check that nothing->value returns undef instead of
    # dying with 'Not an ARRAY reference'
    like warning {
        ok ! (my @val = nothing->value);
    }, qr/nothing has no values/;
}

{
    my $maybe = $data->flat_map(get_key 'hage')
                     ->flat_map(get_key 'debu')
                     ->flat_map(get_key 'me');
    ok ! $maybe->is_nothing;
    is $maybe->value, 1;
}

{
    my $maybe = $data->flat_map(get_key 'hage')
                     ->flat_map(get_key 'yase')
                     ->flat_map(get_key 'me');
    ok $maybe->is_nothing;
}

{
    ok just(1, 2, 3)->flat_map(sub {
        is_deeply [@_], [1, 2, 3];
        nothing;
    })->map(sub { "DUMMY" })->is_nothing;
}

{
    ok +Data::Monad::Maybe->zero->is_nothing;
    ok +Data::Monad::Maybe->zero->flat_map(sub { just 1 })->is_nothing;
    ok just(1)->flat_map(sub { Data::Monad::Maybe->zero })->is_nothing;
}

{
    ok Data::Monad::Base::Sugar::for {
        pick \my $just => sub { just 1 };
        satisfy { $just >= 10 };
        yield { $just };
    }->is_nothing;

    is Data::Monad::Base::Sugar::for {
        pick \my $just => sub { just 15 };
        satisfy { $just >= 10 };
        yield { $just };
    }->value, 15;
}

done_testing;
