## TODO: -returning => [], meaning return a list of arrayrefs containing primKeys


package DBIx::DataModel::Source::Table;

use warnings;
no warnings 'uninitialized';
use strict;
use mro 'c3';
use parent 'DBIx::DataModel::Source';
use Carp;
use Storable             qw/freeze/;
use Scalar::Util         qw/refaddr reftype/;
use Scalar::Does         qw/does/;
use Module::Load         qw/load/;
use List::MoreUtils      qw/none/;

use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

sub _singleInsert {
  my ($self, %options) = @_; 

  # check that this is called as instance method
  my $class = ref $self or croak "_singleInsert called as class method";

  # get dbh option
  my ($dbh, %dbh_options) = $self->schema->dbh;
  my $returning_through = $dbh_options{returning_through} || '';

  # check special case "-returning => {}", not to be handled in _rawInsert
  my $ref_returning = ref $options{-returning} || '';
  my $wants_consolidated_hash = $ref_returning eq 'HASH'
                                && ! keys %{$options{-returning}};
  delete $options{-returning} if $wants_consolidated_hash;

  # do we need to retrieve the primary key ourselves ?
  my @prim_key_cols = $class->primary_key;
  my @prim_key_vals;
  my $should_retrieve_prim_key =  (none {defined $self->{$_}} @prim_key_cols)
                               && ! exists $options{-returning};

  # add a RETURNING clause if needed, to later retrieve the primary key
  if ($should_retrieve_prim_key) {
    if ($returning_through eq 'INOUT') { # example: Oracle
      @prim_key_vals = (undef) x @prim_key_cols;
      my %returning;
      @returning{@prim_key_cols} = \(@prim_key_vals);
      $options{-returning} = \%returning;
    }
    elsif ($returning_through eq 'FETCH') { # example: PostgreSQL
      $options{-returning} = \@prim_key_cols;
    }
    # else : do nothing, we will use "last_insert_id"
  }

  # call database insert
  my $sth = $self->_rawInsert(%options);

  # get back the "returning" values, if any
  my @returned_vals;
  if ($options{-returning} && !does($options{-returning}, 'HASH')) {
    @returned_vals = $sth->fetchrow_array;
    $sth->finish;
  }

  # if needed, retrieve the primary key
  if ($should_retrieve_prim_key) {
    if ($returning_through eq 'INOUT') { # example: Oracle
      @{$self}{@prim_key_cols} = @prim_key_vals;
    }
    elsif ($returning_through eq 'FETCH') { # example: PostgreSQL
      @{$self}{@prim_key_cols} = @returned_vals;
    }
    else {
      my $n_columns = @prim_key_cols;
      not ($n_columns > 1) 
        or croak "cannot ask for last_insert_id: primary key in $class "
               . "has $n_columns columns";
      my $pk_col = $prim_key_cols[0];
      $self->{$pk_col} = $self->_get_last_insert_id($pk_col);
    }
  }

  # return value
  if ($wants_consolidated_hash) {
    my %result;
    $result{$_} = $self->{$_} for @prim_key_cols;
    return \%result;
  }
  elsif (@returned_vals) {
    return @returned_vals;
  }
  else {
    return @{$self}{@prim_key_cols};
  }
}


sub _rawInsert {
  my ($self, %options) = @_; 
  my $class  = ref $self or croak "_rawInsert called as class method";
  my $metadm = $class->metadm;

  # clone $self as mere unblessed hash (for SQLA) and extract ref to $schema 
  my %values = %$self;
  my $schema = delete $values{__schema};
  # THINK: this cloning %values = %$self is inefficient because data was 
  # already cloned in Statement::insert(). But it is quite hard to improve :-((


  # cleanup $options
  if ($options{-returning}) {
    my $reftype = reftype $options{-returning} || '';
    if ($reftype eq 'HASH' && !keys %{$options{-returning}}) {
      delete $options{-returning};
    }
  }

  # perform the insertion
  my $sqla         = $schema->sql_abstract;
  my ($sql, @bind) = $sqla->insert(
    -into   => $metadm->db_from,
    -values => \%values,
    %options,
   );

  $schema->_debug(do {no warnings 'uninitialized';
                      $sql . " / " . CORE::join(", ", @bind);});
  my $method = $schema->dbi_prepare_method;
  my $sth    = $schema->dbh->$method($sql);
  $sqla->bind_params($sth, @bind);
  $sth->execute();

  return $sth;
}


sub _get_last_insert_id {
  my ($self, $col) = @_;
  my $class               = ref $self;
  my ($dbh, %dbh_options) = $self->schema->dbh;
  my $table               = $self->metadm->db_from;

  my $id
      # either callback given by client ...
      = $dbh_options{last_insert_id} ? 
          $dbh_options{last_insert_id}->($dbh, $table, $col)

      # or catalog and/or schema given by client ...
      : (exists $dbh_options{catalog} || exists $dbh_options{schema}) ?
          $dbh->last_insert_id($dbh_options{catalog}, $dbh_options{schema},
                               $table, $col)

      # or plain call to last_insert_id() with all undefs
      :   $dbh->last_insert_id(undef, undef, undef, undef);

  return $id;
}



sub _weed_out_subtrees {
  my ($self) = @_; 
  my $class = ref $self;

  # which "components" were declared through Schema->Composition(...)
  my %is_component = map {($_ => 1)} $class->metadm->components;

  my %subrecords;
  my $sqla = $self->schema->sql_abstract;

  # deal with references
  foreach my $k (keys %$self) {
    next if $k eq '__schema';
    my $v = $self->{$k};
    if (ref $v) {

      # if the reference is a component name, do a nested insert
      if ($is_component{$k}) {
        $subrecords{$k} = $v;
        delete $self->{$k};
      }

      # various cases where the ref will be handled by SQL::Abstract::More
      elsif (
        # an arrayref which is an array of values or a "bind value with type"
        # -- see L<DBIx::Class::ResultSet/"DBIC BIND VALUES">
        (does($v, 'ARRAY') && ($sqla->{array_datatypes} ||
                                 $sqla->is_bind_value_with_type($v)))
        ||
        # literal SQL in the form $k => \ ["FUNC(?)", $v]
        (does($v, 'REF') && does($$v, 'ARRAY'))
       ){
        # do nothing (pass the ref to SQL::Abstract::More)
      }

      # otherwise it is probably wrong data
      else {
        carp "unexpected reference $k in record, deleted";
        delete $self->{$k};
      }
    }
  }

  return keys %subrecords ? \%subrecords : undef;
}



sub has_invalid_columns {
  my ($self) = @_;
  my $results = $self->apply_column_handler('validate');
  my @invalid;			# names of invalid columns
  while (my ($k, $v) = each %$results) {
    push @invalid, $k if defined($v) and not $v;
  }
  return @invalid ? \@invalid : undef;
}





#------------------------------------------------------------
# Internal utility functions
#------------------------------------------------------------

sub _insert_subtrees {
  my ($self, $subrecords, %options) = @_;
  my $class = ref $self;
  my %results;

  while (my ($role, $arrayref) = each %$subrecords) {
    reftype $arrayref eq 'ARRAY'
      or croak "Expected an arrayref for component role $role in $class";
    next if not @$arrayref;

    # insert via the "insert_into_..." method
    my $meth = "insert_into_$role";
    $results{$role} = [$self->$meth(@$arrayref, %options)];

    # also reinject in memory into source object
    $self->{$role} = $arrayref; 
  }

  return \%results;
}


# 'insert class method only available if schema is in singleton mode;
# this method is delegated to the ConnectedSource class.
sub insert {
  my $class = shift;
  not ref($class) 
    or croak "insert() should be called as class method";

  my $metadm      = $class->metadm;
  my $meta_schema = $metadm->schema;
  my $schema      = $meta_schema->class->singleton;
  my $cs_class    = $meta_schema->connected_source_class;
  load $cs_class;
  $cs_class->new($metadm, $schema)->insert(@_);
}




#------------------------------------------------------------
# update and delete
#------------------------------------------------------------

# update() and delete(): differentiate between usage as
# $obj->update(), or $class->update(@args). In both cases, we then
# delegate to the ConnectedSource class

sub delete {
  my ($self, @args) = @_;

  my $metadm      = $self->metadm;
  my $meta_schema = $metadm->schema;
  my $schema;

  if (ref $self) { # if called as $obj->$method()
    not @args or croak "delete() : too many arguments";
    @args = ($self);
    $schema = delete $self->{__schema};
  }

  # if in single-schema mode, or called as $class->delete(@args)
  $schema ||= $meta_schema->class->singleton;

  # delegate to the connected_source class
  my $cs_class    = $meta_schema->connected_source_class;
  load $cs_class;
  $cs_class->new($metadm, $schema)->delete(@args);
}


sub update  {
  my ($self, @args) = @_;

  my $metadm      = $self->metadm;
  my $meta_schema = $metadm->schema;
  my $schema;

  if (ref $self) { 
    if (@args) { # if called as $obj->update({field => $val, ...})
      # will call $class->update(@prim_key, {field => $val, ...}
      unshift @args, $self->primary_key;
    }
    else { # if called as $obj->update()
      # will call $class->update($self)
      @args = ($self);
    }
    $schema = delete $self->{__schema};
  }

  # if in single-schema mode, or called as $class->update(@args)
  $schema ||= $meta_schema->class->singleton;

  # delegate to the connected_source class
  my $cs_class = $meta_schema->connected_source_class;
  load $cs_class;
  $cs_class->new($metadm, $schema)->update(@args);
}


1; # End of DBIx::DataModel::Source::Table

__END__




=head1 NAME

DBIx::DataModel::Source::Table - Parent for Table classes

=head1 DESCRIPTION

This is the parent class for all table classes created through

  $schema->Table($classname, ...);

=head1 METHODS

Methods are documented in 
L<DBIx::DataModel::Doc::Reference|DBIx::DataModel::Doc::Reference>.
This module implements

=over

=item L<DefaultColumns|DBIx::DataModel::Doc::Reference/DefaultColumns>

=item L<ColumnType|DBIx::DataModel::Doc::Reference/ColumnType>

=item L<ColumnHandlers|DBIx::DataModel::Doc::Reference/ColumnHandlers>

=item L<AutoExpand|DBIx::DataModel::Doc::Reference/AutoExpand>

=item L<autoUpdateColumns|DBIx::DataModel::Doc::Reference/autoUpdateColumns>

=item L<noUpdateColumns|DBIx::DataModel::Doc::Reference/noUpdateColumns>

=item L<fetch|DBIx::DataModel::Doc::Reference/fetch>

=item L<fetch_cached|DBIx::DataModel::Doc::Reference/fetch_cached>

=item L<insert|DBIx::DataModel::Doc::Reference/insert>

=item L<_singleInsert|DBIx::DataModel::Doc::Reference/_singleInsert>

=item L<_rawInsert|DBIx::DataModel::Doc::Reference/_rawInsert>

=item L<update|DBIx::DataModel::Doc::Reference/update>

=item L<hasInvalidColumns|DBIx::DataModel::Doc::Reference/hasInvalidColumns>

=back


=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT etat.ge.ch> >>


=head1 COPYRIGHT & LICENSE

Copyright 2006..2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



