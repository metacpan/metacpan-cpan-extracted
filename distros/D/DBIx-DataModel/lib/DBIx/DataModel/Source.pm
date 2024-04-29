#----------------------------------------------------------------------
package DBIx::DataModel::Source;
#----------------------------------------------------------------------

# see POD doc at end of file

use warnings;
no warnings 'uninitialized';
use strict;
use mro 'c3';
use List::MoreUtils              qw/firstval/;
use Module::Load                 qw/load/;
use Scalar::Util                 qw/refaddr/;
use Storable                     qw/freeze/;
use DBIx::DataModel::Carp;
use DBIx::DataModel::Meta::Utils qw/does/;

use namespace::clean;



#----------------------------------------------------------------------
# accessors
#----------------------------------------------------------------------

sub schema {
  my $self  = shift;
  return (ref $self && $self->{__schema})
         || $self->metadm->schema->class->singleton;
}


sub primary_key {
  my $self = shift; 

  # get primary key columns
  my @primary_key = $self->metadm->primary_key;

  # if called as instance method, get values in those columns
  @primary_key = @{$self}{@primary_key} if !$self->_is_called_as_class_method;

  # choose what to return depending on context
  if (wantarray) {
    return @primary_key;
  }
  else {
    @primary_key == 1
      or croak "cannot return a multi-column primary key in a scalar context";
    return $primary_key[0];
  }
}

#----------------------------------------------------------------------
# select and fetch
#----------------------------------------------------------------------

# methods delegated to the Statement class
foreach my $method (qw/select bless_from_DB/) {
  no strict 'refs';
  *{$method} = sub {
    my $self = shift;

    $self->_is_called_as_class_method
      or croak "$method() should be called as a class method";

    my $stmt_class = $self->metadm->schema->statement_class;
    load $stmt_class;
    my $statement  = $stmt_class->new($self);
    return $statement->$method(@_);
  };
}


sub fetch {
  my $self = shift;

  $self->_is_called_as_class_method
    or croak "fetch() should be called as a class method";

  my %select_args;

  # if last argument is a hashref, it contains arguments to the select() call
  no warnings 'uninitialized';
  if (does $_[-1], 'HASH') {
    %select_args = %{pop @_};
  }

  return $self->select(-fetch => \@_, %select_args);
}


sub fetch_cached {
  my $self = shift;
  my $dbh_addr    = refaddr $self->schema->dbh;
  my $freeze_args = freeze \@_;
  return $self->metadm->{fetch_cached}{$dbh_addr}{$freeze_args}
           ||= $self->fetch(@_);
}



#----------------------------------------------------------------------
# join
#----------------------------------------------------------------------


sub join {
  my ($self, $first_role, @other_roles) = @_;

  # direct references to utility objects
  my $schema      = $self->schema;
  my $meta_schema = $schema->metadm;

  # find first join information
  my $path   = $self->metadm->path($first_role)
    or croak "could not find role $first_role in " . $self->metadm->class;

  # build search criteria on %$self from first join information
  my (%criteria, @left_cols);
  my $prefix = $schema->placeholder_prefix;
  while (my ($left_col, $right_col) = each %{$path->{on}}) {
    $criteria{$right_col} = "$prefix$left_col";
    push @left_cols, $left_col;
  }

  # choose meta_source (just a table or build a join) 
  my $meta_source = @other_roles  ? $meta_schema->define_join($path->{to}{name},
                                                              @other_roles)
                                  : $path->{to};

  # build args for the statement
  my $source = bless {__schema => $schema}, $meta_source->class;
  my @stmt_args = ($source, -where => \%criteria);

  # TODO: should add -select_as => 'firstrow' if all multiplicities are 1

  # build and return the new statement
  my $statement = $meta_schema->statement_class->new(@stmt_args);

  if (!$self->_is_called_as_class_method) { # called as instance method
    # check that all foreign keys are present
    my $missing = join ", ", grep {not exists $self->{$_}} @left_cols;
    not $missing
      or croak "cannot follow role '$first_role': missing column '$missing'";

    # bind to foreign keys
    $statement->bind(map {($_ => $self->{$_})} @left_cols);
  }

  return $statement;
}


#----------------------------------------------------------------------
# column handlers and column expansion
#----------------------------------------------------------------------


sub expand {
  my ($self, $path, @options) = @_;
  $self->{$path} = $self->$path(@options);
}

sub auto_expand {} # overridden in subclasses through define_auto_expand()


sub apply_column_handler {
  my ($self, $handler_name, $objects) = @_;

  my $targets         = $objects || [$self];
  my %column_handlers = $self->metadm->_consolidate_hash('column_handlers');
  my $results         = {};

  # iterate over all registered columnHandlers
 COLUMN:
  while (my ($column_name, $handlers) = each %column_handlers) {

    # is $handler_name registered in this column ?
    my $handler = $handlers->{$handler_name} or next COLUMN;

    # apply that handler to all targets that possess the $column_name
    foreach my $obj (@$targets) {
      my $result = exists $obj->{$column_name}  
         ? $handler->($obj->{$column_name}, $obj, $column_name, $handler_name)
         : undef;
      if ($objects) { push(@{$results->{$column_name}}, $result); }
      else          { $results->{$column_name} = $result;         }
    }
  }

  return $results;
}


#----------------------------------------------------------------------
# utilities
#----------------------------------------------------------------------


sub _is_called_as_class_method {
  my $self = shift;

  # class method call in the usual Perl sense
  return 1 if ! ref $self; 

  # fake class method call : an object with only one field '__schema'
  my @k = keys %$self;
  return @k == 1 && $k[0] eq '__schema';
}


sub TO_JSON {
  my $self = shift;
  my $clone = {%$self};
  delete $clone->{__schema};
  return $clone;
}


1; # End of DBIx::DataModel::Source

__END__

=head1 NAME

DBIx::DataModel::Source - Abstract parent for Table and Join

=head1 DESCRIPTION

Abstract parent class for
L<DBIx::DataModel::Source::Table|DBIx::DataModel::Source::Table> and
L<DBIx::DataModel::Source::Join|DBIx::DataModel::Source::Join>. For
internal use only.


=head1 METHODS

Methods are documented in
L<DBIx::DataModel::Doc::Reference|DBIx::DataModel::Doc::Reference>.
This module implements

=over

=item L<MethodFromJoin|DBIx::DataModel::Doc::Reference/MethodFromJoin>

=item L<schema|DBIx::DataModel::Doc::Reference/schema>

=item L<db_table|DBIx::DataModel::Doc::Reference/db_table>

=item L<selectImplicitlyFor|DBIx::DataModel::Doc::Reference/selectImplicitlyFor>

=item L<blessFromDB|DBIx::DataModel::Doc::Reference/blessFromDB>

=item L<select|DBIx::DataModel::Doc::Reference/select>

=item L<applyColumnHandler|DBIx::DataModel::Doc::Reference/applyColumnHandler>

=item L<expand|DBIx::DataModel::Doc::Reference/expand>

=item L<autoExpand|DBIx::DataModel::Doc::Reference/autoExpand>

=item L<join|DBIx::DataModel::Doc::Reference/join>

=item L<primary_key|DBIx::DataModel::Doc::Reference/primary_key>

=back


=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat  ge  chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2008 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

