package DBIx::ActiveRecord::Arel::NakidWhere;
use strict;
use warnings;

sub new {
    my ($self, $statement, $value) = @_;
    bless {statement => $statement, value => $value}, $self;
}

sub build {
    my $self = shift;
    return ($self->{statement}, $self->{value});
}

1;
