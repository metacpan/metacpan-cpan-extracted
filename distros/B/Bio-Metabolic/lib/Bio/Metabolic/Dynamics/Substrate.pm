package Bio::Metabolic::Dynamics::Substrate;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.06';

sub Bio::Metabolic::Substrate::var {
    my $self = shift;
    $self->{var} = shift if @_;

    $self->{var} = Math::Symbolic::Variable->new( $self->name )
      unless defined $self->{var};
    return $self->{var};
}

sub Bio::Metabolic::Substrate::fix {
    my $self  = shift;
    my $value = shift;

    return $self->var->value($value);
}

sub Bio::Metabolic::Substrate::release {
    shift->var->value(undef);
}
