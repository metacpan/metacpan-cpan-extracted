package Deferred;

use strict;
use warnings;
use Context::Vars ();

# A queue of callbacks, run later, in an order the test chooses. Wired, it
# wraps each callback when it is queued, as a loop that captures contexts
# would. Unwired, it keeps the callback as given, as every loop does today.

sub new {
    my ($class, %opt) = @_;
    return bless { wired => $opt{wired} ? 1 : 0, queue => [], errors => [] }, $class;
}

sub later {
    my ($self, $cb) = @_;
    push @{ $self->{queue} }, $self->{wired} ? Context::Vars->wrap($cb) : $cb;
    return;
}

sub pending { scalar @{ $_[0]{queue} } }
sub errors  { @{ $_[0]{errors} } }

# Runs the queued callbacks in the order given by their positions in the
# queue, then empties it. With no order, first in, first out.
sub run_all {
    my ($self, @order) = @_;
    my @queue = @{ $self->{queue} };
    @order = (0 .. $#queue) unless @order;
    $self->{queue} = [];
    for my $i (@order) {
        eval { $queue[$i]->(); 1 } or push @{ $self->{errors} }, $@;
    }
    return scalar @order;
}

# Runs until nothing more is queued, callbacks queued by callbacks included.
sub drain {
    my ($self) = @_;
    my $n = 0;
    $n += $self->run_all while $self->pending;
    return $n;
}

1;
