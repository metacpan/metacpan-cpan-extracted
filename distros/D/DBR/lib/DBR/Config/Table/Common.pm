package DBR::Config::Table::Common;

use strict;
use base 'DBR::Common';
use Carp;

sub alias{
      my $self = shift;
      my $set = shift;
      if($set){
	    croak "Cannot set the alias on a table object twice" if defined( $self->{alias} ); # I want this to fail obnoxiously
	    return $self->{alias} = $set;
      }

      return $self->{alias};

}

sub validate { 1 }

sub sql  {
      my $self = shift;
      my $name  = $self->name;
      my $alias = $self->alias;

      my $sql = $name;
      $sql   .= ' AS ' . $alias if $alias;

      return $sql;
}

1;
