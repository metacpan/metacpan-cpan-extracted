use strict;
use warnings;
use Data::Monad::List;
use Data::Monad::Base::Sugar;
use Benchmark;

sub normal_99 {
    my @ret;
    for my $x (1 .. 9) {
        for my $y (1 .. 9) {
            push @ret, [$x, $y => $x * $y];
        }
    }
    return \@ret
}

sub blessed_99 {
    my @ret;
    my $range = bless [1 .. 9], 'SlowList';
    sub SlowList::list { @{shift()} }

    for my $x ($range->list) {
        for my $y ($range->list) {
            push @ret, [$x, $y => $x * $y];
        }
    }
    return \@ret
}

sub recursive_99 {
    sub Recur::l1 {
        my $x = shift or return;
        Recur::l2($x => 1 .. 9), Recur::l1(@_);
    }
    sub Recur::l2 {
        my $x = shift;
        my $y = shift or return;
        [$x, $y => $x * $y], Recur::l2($x => @_);
    };

    return [Recur::l1(1 .. 9)];
}

sub closure_recursive_99 {
    my $l1; $l1 = sub {
        my $x = shift or return;
        my $l2; $l2 = sub {
            my $y = shift or return;
            [$x, $y => $x * $y], $l2->(@_);
        };
        $l2->(1 .. 9), $l1->(@_);
    };
    [$l1->(1 .. 9)];
}

sub closure_recursive_2_99 {
    my $l1; $l1 = sub {
        my $x = shift or return;
        my $l2; $l2 = sub {
            my $x = shift;
            my $y = shift or return;
            [$x, $y => $x * $y], $l2->($x => @_);
        };
        $l2->($x => 1 .. 9), $l1->(@_);
    };
    [$l1->(1 .. 9)];
}

sub blessed_recursive_99 {
    sub BRecur::l1 {
        my $self = shift;
        my $x = shift or return;
        $self->l2($x => 1 .. 9), $self->l1(@_);
    }
    sub BRecur::l2 {
        my $self = shift;
        my $x = shift;
        my $y = shift or return;
        [$x, $y => $x * $y], $self->l2($x => @_);
    };

    return [bless({}, 'BRecur')->l1(1 .. 9)];
}

sub monad_99 {
    return Data::Monad::Base::Sugar::for {
        pick \my $x, sub { scalar_list(1 .. 9) };
        pick \my $y, sub { scalar_list(1 .. 9) };
        yield { $x, $y => $x * $y }
    };
}

Benchmark::cmpthese(10000 => {
    normal_99 => \&normal_99,
    blessed_99 => \&blessed_99,
    monad_99  => \&monad_99,
    recur_99 => \&recursive_99,
});

Benchmark::cmpthese(10000 => {
    recur_99 => \&recursive_99,
    c_recur_99 => \&closure_recursive_99,
    b_recur_99 => \&blessed_recursive_99,
    monad_99  => \&monad_99,
});

Benchmark::cmpthese(10000 => {
    c_recur_99 => \&closure_recursive_99,
    c_recur_2_99 => \&closure_recursive_2_99,
    monad_99  => \&monad_99,
});

__END__

% perl -Ilib eg/bench.pl
              Rate   monad_99   recur_99 blessed_99  normal_99
monad_99    1721/s         --       -84%       -90%       -91%
recur_99   10989/s       538%         --       -33%       -40%
blessed_99 16393/s       852%        49%         --       -10%
normal_99  18182/s       956%        65%        11%         --
              Rate   monad_99 c_recur_99 b_recur_99   recur_99
monad_99    1802/s         --       -71%       -81%       -84%
c_recur_99  6135/s       240%         --       -37%       -47%
b_recur_99  9709/s       439%        58%         --       -16%
recur_99   11494/s       538%        87%        18%         --
               Rate     monad_99 c_recur_2_99   c_recur_99
monad_99     1832/s           --         -66%         -70%
c_recur_2_99 5405/s         195%           --         -12%
c_recur_99   6135/s         235%          13%           --
