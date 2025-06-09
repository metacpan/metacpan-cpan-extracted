package DBIx::QuickORM::Iterator;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak/;

sub new;

use DBIx::QuickORM::Util::HashBase qw{
    generator
    items
    generator_done
    index
    +ready
    +is_ready
};

sub new {
    my $class = shift;
    my ($gen, $ready) = @_;

    my $self = bless({GENERATOR() => $gen, READY => $ready}, $class);
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    croak "Generator is required" unless $self->{+GENERATOR};

    croak "Generator must be a code reference, got '$self->{+GENERATOR}'" unless ref($self->{+GENERATOR}) eq 'CODE';

    $self->{+INDEX} = 0;
    $self->{+ITEMS} = [];

    $self->{+GENERATOR_DONE} = 0;
}

sub first {
    my $self = shift;
    $self->{+INDEX} = 0;
    $self->next;
}

sub list {
    my $self = shift;
    local $self->{+INDEX} = 0;

    my $set = $self->{+ITEMS};
    $self->_grow until $self->{+GENERATOR_DONE};

    return @$set;
}

sub ready {
    my $self = shift;
    my $cb = $self->{+READY} or return 1;
    return $self->{+IS_READY} ||= $cb->();
}

sub next {
    my $self = shift;

    my $idx = $self->{+INDEX};
    my $set = $self->{+ITEMS};

    unless ($idx < @$set) {
        return if $self->{+GENERATOR_DONE};
        return unless $self->_grow;
    }

    $self->{+INDEX}++;
    return $set->[$idx];
}

sub last {
    my $self = shift;

    my $set = $self->{+ITEMS};

    $self->_grow until $self->{+GENERATOR_DONE};

    $self->{+INDEX} = scalar @$set;

    return unless @$set;
    return $set->[-1];
}

sub _grow {
    my $self = shift;

    return 0 if $self->{+GENERATOR_DONE};

    my $add = $self->{+GENERATOR}->();

    unless (defined $add) {
        $self->{+GENERATOR_DONE} = 1;
        return 0;
    }

    push @{$self->{+ITEMS}} => $add;
    return 1;
}

1;
