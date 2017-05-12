package Gauge::Role;
use autodie;
use feature qw(say);
use strict;
use utf8;
use warnings qw(all);

use Any::Moose q(::Role);
use Parallel::ForkManager;
use File::Temp;

requires qw(run);

has fork_manager=> (
    is      => 'ro',
    isa     => 'Parallel::ForkManager',
    lazy    => 1,
    default => sub {
        Parallel::ForkManager->new(shift->parallel);
    },
);
has parallel    => (is => 'ro', isa => 'Int', default => 4);
has queue       => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has split       => (
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef[Str]]',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my @split;
        for my $i (0 .. $#{$self->queue}) {
            my $j = $i % $self->parallel;
            push @{$split[$j]}, $self->queue->[$i];
        }
        return \@split;
    },
);

sub run_forked {
    my ($self, $cb, $on_begin, $on_end) = @_;

    my $pm = $self->fork_manager;
    for my $queue (@{$self->split}) {
        my $pid = $pm->start and next;

        $on_begin->()
            if 'CODE' eq ref $on_begin;

        for my $url (@{$queue}) {
            $cb->($url);
        }

        $on_end->()
            if 'CODE' eq ref $on_end;

        $pm->finish;
    }
    $pm->wait_all_children;

    return;
}

1;
