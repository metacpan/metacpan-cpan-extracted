package DBIx::ActiveRecord::Arel::SubQuery;
use strict;
use warnings;

sub new {
    my ($self, $arel) = @_;
    bless {arel => $arel}, $self;
}

sub placeholder {
    my $self = shift;
    return $self->{arel}->to_sql;
}

sub binds {
    my $self = shift;
    $self->{arel}->binds;
}

1;
