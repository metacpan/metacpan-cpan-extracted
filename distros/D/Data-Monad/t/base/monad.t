use strict;
use warnings;
use Test::More;

{
    package Identity1;
    use parent qw/Data::Monad::Base::Monad/;

    sub unit {
        my $class = shift;
        bless [@_], $class
    }

    sub flat_map {
        my ($self, $f) = @_;
        $f->(@$self);
    }
}

{
    package Identity2;
    use parent qw/Data::Monad::Base::Monad/;

    sub unit {
        my $class = shift;
        bless [@_], $class
    }

    sub map {
        my ($self, $f) = @_;
        bless [$f->(@$self)], ref $self;
    }

    sub flatten {
        my $self = shift;
        @$self;
    }
}

for my $monad (qw/Identity1 Identity2/) {
    is_deeply $monad->unit(1, 2, 3), [1, 2, 3];

    my $mm = $monad->unit($monad->unit(qw/x y/));
    is_deeply $mm->flatten, [qw/x y/];

    is_deeply $monad->unit(qw/3 2/)->map(sub { map { '+' x $_ } @_ }),
              ["+++", "++"];

    is_deeply $monad->unit(qw/3 2/)
                    ->flat_map(sub { $monad->unit(map { '+' x $_ } @_) }),
              ["+++", "++"];
}

done_testing;
