package DBIx::DataModel::Meta::Source::Join;
use strict;
use warnings;
use Params::Validate qw/HASHREF ARRAYREF/;

use parent "DBIx::DataModel::Meta::Source";

use namespace::clean;

sub new {
  my $class = shift;

  # the real work occurs in parent class
  $class->_new_meta_source(

    # more spec for Params::Validate
    { sqla_join_args => {type => ARRAYREF} },

    # method to call in schema for building @ISA
    'join_parent',

    # original args
    @_
   );
}


sub db_from {
  my $self = shift;

  return [-join => @{$self->{sqla_join_args}}];
}

sub where {
  my $self = shift;
  return;
}

1;
