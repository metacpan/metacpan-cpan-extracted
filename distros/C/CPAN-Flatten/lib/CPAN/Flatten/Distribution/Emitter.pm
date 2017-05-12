package CPAN::Flatten::Distribution::Emitter;
use strict;
use warnings;

use constant STOP => -1;

sub new {
    my ($class, %opt) = @_;
    bless {%opt}, $class;
}

sub print : method {
    my ($self, $indent, $message) = @_;
    my $fh = $self->{fh};
    print {$fh} "  " x $indent, $message, "\n";
}

sub emit {
    my ($self, $distribution, $fh) = @_;
    $self = $self->new(fh => $fh) unless ref $self;

    $distribution->walk_down(sub {
        my ($dist, $depth) = @_;
        return if $dist->is_root;
        return if $dist->is_dummy;
        my @children = $dist->children;
        $self->print(0, $dist->distfile);
        $self->print(1, $_->distfile) for @children;
    });
}

1;
