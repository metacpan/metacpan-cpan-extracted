package DBIx::ActiveRecord::Arel::Order;
use strict;
use warnings;

sub new {
    my ($self, $type, $column) = @_;
    bless {type => $type, column => $column}, $self;
}

sub build {
    my $self = shift;
    my $t = $self->{type};
    $t = " $t" if $t;
    $self->{column}->name.$t;
}

sub reverse {
    my $self = shift;
    if ($self->{type} eq 'DESC') {
      $self->{type} = "";
    } else {
      $self->{type} = "DESC";
    }
}

1;
