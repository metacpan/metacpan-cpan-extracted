package DBIx::DataModel::Meta::Source::Table;
use strict;
use warnings;
use parent "DBIx::DataModel::Meta::Source";
use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils;

use Carp;
use Params::Validate qw/HASHREF ARRAYREF SCALAR/;
use List::MoreUtils  qw/any/;
use Scalar::Does     qw/does/;

use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

sub new {
  my $class = shift;

  # the real work occurs in parent class
  my $self = $class->_new_meta_source(

    # more spec for Params::Validate
    { column_types        => {type => HASHREF, default => {}},
      column_handlers     => {type => HASHREF, default => {}},
      db_name             => {type => SCALAR},
      where               => {type => HASHREF|ARRAYREF, optional => 1},

      auto_insert_columns => {type => HASHREF, default => {}},
      auto_update_columns => {type => HASHREF, default => {}},
      no_update_columns   => {type => HASHREF, default => {}},

    },

    # method to call in schema for building @ISA
    'table_parent',

    # original args
    @_
   );

  my $types = delete $self->{column_types};
  while (my ($type_name, $columns_aref) = each %$types) {
    $self->define_column_type($type_name, @$columns_aref);
  }

  return $self;
}


sub db_from {
  my $self = shift;
  return $self->{db_name};
}


sub where {
  my $self  = shift;

  return $self->{where};
}

sub components {
  my $self  = shift; 

  return @{$self->{components} || []};
}



sub define_navigation_method {
  my ($self, $method_name, @path) = @_;
  @path or croak "define_navigation_method: not enough arguments";

  # last arg may be a hashref of parameters to be passed to select()
  my $pre_args;
  $pre_args = pop @path if ref $path[-1];

  # build the method body
  my $method_body = sub {
    my ($self, @args) = @_;

    # if called without args, and just one role, and that role 
    # was previously expanded, then return the cached version
    if (@path == 1 && !@args) {
      my $cached = $self->{$path[0]};
      return $cached if $cached;
    }

    # otherwise, build a query
    unshift @args, %$pre_args if $pre_args;
    my $statement = $self->join(@path); # Source::join, not Schema::join

    # return either the resulting rows, or the query statement
    return ref $self ? $statement->select(@args)   # when instance method
                     : $statement->refine(@args);  # when class method
  };

  # install the method
  DBIx::DataModel::Meta::Utils->define_method(
    class => $self->{class},
    name  => $method_name,
    body  => $method_body,
   );
}


sub define_column_type {
  my ($self, $type_name, @columns) = @_;

  my $type = $self->{schema}->type($type_name) 
    or croak "unknown column type : $type_name";

  foreach my $column (@columns) {
    $self->define_column_handlers($column, %{$type->{handlers}})
  }

  return $self;
}


sub define_column_handlers {
  my ($self, $column_name, %handlers) = @_;

  while (my ($handler_name, $body) = each %handlers) {
    my $handler  = $body;
    my $previous = $self->{column_handlers}{$column_name}{$handler_name};
    if ($previous) {
      # compose new coderef with previous coderef
      $handler 
        = $handler_name eq 'from_DB' ? sub {$body->(@_); $previous->(@_)}
                                     : sub {$previous->(@_); $body->(@_)};
    }
    $self->{column_handlers}{$column_name}{$handler_name} = $handler;
  }

  return $self;
}


sub define_auto_expand {
  my ($self, @component_names) = @_;

  # check that we only auto_expand on components
  my @components = $self->components;
  foreach my $component_name (@component_names) {
    any {$component_name eq $_} @components
      or croak "cannot auto_expand on $component_name: not a composition";
  }

  # closure to iterate on the components
  my $body = sub {
    my ($self, $want_recurse) = @_;
    foreach my $component_name (@component_names) {
      my $r = $self->expand($component_name); # result can be an object ref 
                                              # or an array ref
      if ($r and $want_recurse) {
	$r = [$r] unless does($r, 'ARRAY');
	$_->auto_expand($want_recurse) foreach @$r;
      }
    }
  };

  # install the method
  DBIx::DataModel::Meta::Utils->define_method(
    class          => $self->{class},
    name           => 'auto_expand',
    body           => $body,
    check_override => 0,
   );

  return $self;
}


1;

