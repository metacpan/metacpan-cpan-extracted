#----------------------------------------------------------------------
package DBIx::DataModel::Source;
#----------------------------------------------------------------------

# see POD doc at end of file

use warnings;
no warnings 'uninitialized';
use strict;
use mro 'c3';
use Carp;
use List::MoreUtils qw/firstval/;
use Module::Load    qw/load/;

use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

#----------------------------------------------------------------------
# RUNTIME PUBLIC METHODS
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
  @primary_key = @{$self}{@primary_key} if ref $self;

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


# several class methods, only available if in single-schema mode;
# such methods are delegated to the ConnectedSource class.
foreach my $method (qw/select fetch fetch_cached bless_from_DB/) {
  no strict 'refs';
  *{$method} = sub {
    my $class = shift;
    not ref($class) 
      or croak "$method() should be called as class method";

    my $metadm      = $class->metadm;
    my $meta_schema = $metadm->schema;
    my $schema      = $meta_schema->class->singleton;
    my $cs_class    = $meta_schema->connected_source_class;
    load $cs_class;
    my $cs          = $cs_class->new($metadm, $schema);
    return $cs->$method(@_);
  };
}






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


sub join {
  my ($self, $first_role, @other_roles) = @_;

  my $metadm      = $self->metadm;
  my $meta_schema = $metadm->schema;
  my $schema      = $self->schema;
  my $class       = $meta_schema->connected_source_class;
  load $class;
  my $conn_src    = $class->new($metadm, $schema);
  my $statement   = $conn_src->join($first_role, @other_roles);

  # if called as an instance method
  if (ref $self) {
    my $left_cols = $statement->{args}{-_left_cols}
      or die "statement had no {left_cols} entry";

    # check that all foreign keys are present
    my $missing = join ", ", grep {not exists $self->{$_}} @$left_cols;
    not $missing
      or croak "cannot follow role '$first_role': missing column '$missing'";

    # bind to foreign keys
    $statement->bind(map {($_ => $self->{$_})} @$left_cols);
  }

  # else if called as class method
  else {
    if ($DBIx::DataModel::COMPATIBILITY > 1.99) {
      carp 'join() was called as class method on a Table; instead, you should '
         . 'call $schema->table($name)->join(...)';
    }
  }

  return $statement;
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

=item L<primKey|DBIx::DataModel::Doc::Reference/primKey>

=back


=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat  ge  chE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2008 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

