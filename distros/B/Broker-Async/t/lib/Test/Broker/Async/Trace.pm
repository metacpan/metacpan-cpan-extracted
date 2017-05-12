package Test::Broker::Async::Trace;
use strict;
use warnings;
use Future;
use Scalar::Util qw( weaken );
use Class::Tiny qw(), {
    _live    => sub { {} },
    futures  => sub { {} },
    started  => sub { [] },
};

sub live {
    my ($self)  = @_;
    my @started = @{ $self->started };

    my @live =
        map  { $_->[0]                   }
        sort { $a->[1] <=> $b->[1]       }
        map  { [$_, index($_, @started)] }
             keys %{ $self->_live };

    return \@live;
}

sub worker {
    weaken(my $self = shift);
    my $code = $_[0] ||= sub { Future->new };

    return sub {
        my ($id) = @_;
        my $future = $code->(@_);

        push @{ $self->started }, $id;
        $self->_live->{$id}   = $future;
        $self->futures->{$id} = $future;

        return $future->on_ready(sub{
            delete $self->_live->{$id};
        });
    };
}

1;
