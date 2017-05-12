package CPAN::Flatten::Distribution;
use strict;
use warnings;
use Module::CoreList;
use CPAN::Flatten::Distribution::Emitter;

use parent 'CPAN::Flatten::Tree';

sub is_dummy {
    shift->{dummy};
}

sub dummy {
    my $self = shift;
    my $class = ref $self;
    $class->new(distfile => $self->distfile, dummy => 1);
}

sub provides {
    shift->{provides} || [];
}

sub requirements {
    shift->{requirements} || [];
}

sub distfile {
    shift->{distfile};
}

sub name {
    my $distfile = shift->distfile or return;
    $distfile =~ s{^./../}{};
    $distfile =~ s{\.(?:tar\.gz|zip|tgz|tar\.bz2)$}{};
    $distfile;
}

use constant STOP => -1;

sub providing {
    my ($self, $package, $version) = @_;

    my $providing;
    $self->walk_down(sub {
        my ($node, $depth) = @_;
        $providing = $node->_providing_by_myself($package, $version);
        return STOP if $providing;
    });
    return $providing;
}

sub _providing_by_myself {
    my ($self, $package, $version) = @_;
    for my $provide (@{$self->provides}) {
        return $self if $provide->{package} eq $package;
    }
    return;
}

sub emit {
    my ($self, $fh) = @_;
    CPAN::Flatten::Distribution::Emitter->emit($self, $fh);
}

sub equals {
    my ($self, $that) = @_;
    $self->distfile && $that->distfile and $self->distfile eq $that->distfile;
}

1;
