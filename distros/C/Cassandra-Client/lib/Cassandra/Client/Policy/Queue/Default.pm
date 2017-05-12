package Cassandra::Client::Policy::Queue::Default;
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args)= @_;

    my $max_entries= $args{max_entries} || 0; # Default: never overflow

    return bless {
        max_entries => 0+ $max_entries,
        has_any     => 0, # We're using this as a count.
        queue       => [],
    }, $class;
}

sub enqueue {
    my ($self, $item)= @_;

    if ($self->{max_entries} && $self->{has_any} >= $self->{max_entries}) {
        return "command queue full: $self->{has_any} entries";
    }

    push @{$self->{queue}}, $item;
    $self->{has_any}++;
    return;
}

sub dequeue {
    my ($self)= @_;
    my $item= shift @{$self->{queue}};
    $self->{has_any}= 0+@{$self->{queue}};
    return $item;
}

1;
