package DBIx::QuickORM::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000004';

use parent 'SQL::Abstract';

sub select {
    my $self = shift;

    my @bind_names;
    local $self->{bind_names} = \@bind_names;

    my ($stmt, @bind) = $self->SUPER::select(@_);

    return ($stmt, \@bind, \@bind_names);
}

sub where {
    my $self = shift;

    my @bind_names;
    local $self->{bind_names} = \@bind_names;

    my ($stmt, @bind) = $self->SUPER::where(@_);

    return ($stmt, \@bind, \@bind_names);
}

sub _render_bind {
    my $self = shift;
    my (undef, $bind) = @_;
    push @{$self->{bind_names}} => $bind->[0] if $self->{bind_names};
    return $self->SUPER::_render_bind(@_);
}

1;
