package DBIx::ActiveRecord::Arel::Native;
use strict;
use warnings;

sub new {
    my ($self, $func) = @_;
    bless {func => $func}, $self;
}

sub placeholder {
    my $self = shift;
    return $self->{func};
}

sub name {shift->placeholder}

sub binds {@{[]}}
1;
