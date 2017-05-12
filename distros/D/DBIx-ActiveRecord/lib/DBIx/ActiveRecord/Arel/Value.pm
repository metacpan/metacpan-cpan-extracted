package DBIx::ActiveRecord::Arel::Value;
use strict;
use warnings;

sub new {
    my ($self, $value) = @_;
    bless {value => $value}, $self;
}

sub placeholder {
    my $self = shift;
    if (ref $self->{value} eq 'ARRAY') {
        return join(', ', map {'?'} @{$self->{value}});
    }
    '?';
}

sub binds {
    my $self = shift;
    ref $self->{value} eq 'ARRAY' ? @{$self->{value}} : $self->{value};
}

1;
