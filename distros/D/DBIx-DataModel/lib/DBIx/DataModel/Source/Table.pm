## TODO: -returning => [], meaning return a list of arrayrefs containing primKeys


package DBIx::DataModel::Source::Table;

use warnings;
no warnings 'uninitialized';
use strict;
use parent 'DBIx::DataModel::Source';
use Module::Load                 qw/load/;
use List::MoreUtils              qw/none/;
use Params::Validate             qw/validate_with HASHREF/;
use DBIx::DataModel::Meta::Utils qw/does/;
use Carp::Clan                   qw[^(DBIx::DataModel::|SQL::Abstract)];

use namespace::clean;


#------------------------------------------------------------
# insert
#------------------------------------------------------------

sub insert {
  my $self = shift;

  $self->_is_called_as_class_method
    or croak "insert() should be called as a class method";
  my $class = ref $self || $self;

  # end of list may contain options, recognized because option name is a scalar
  my $options      = $self->_parse_ending_options(\@_, qr/^-returning$/);
  my $want_subhash = does($options->{-returning}, 'HASH');

  # records to insert
  my @records = @_;
  @records or croak "insert(): no record to insert";

  my $got_records_as_arrayrefs = does($records[0], 'ARRAY');

  # if data is received as arrayrefs, transform it into a list of hashrefs.
  # NOTE : this is a bit stupid; a more efficient implementation
  # would be to prepare one single DB statement and then execute it on
  # each data row, or even SQL like INSERT ... VALUES(...), VALUES(..), ...
  # (supported by some DBMS), but that would require some refactoring 
  # of _singleInsert and _rawInsert.
  if ($got_records_as_arrayrefs) {
    my $header_row = shift @records;
    my $n_headers  = @$header_row;
    foreach my $data_row (@records) {
      does($data_row, 'ARRAY')
        or croak "data row after a header row should be an arrayref";
      my $n_vals = @$data_row;
      $n_vals == $n_headers
        or croak "insert([\@headers],[\@row1],...): "
                ."got $n_vals values for $n_headers headers";
      my %real_record;
      @real_record{@$header_row} = @$data_row;
      $data_row = \%real_record;
    }
  }

  # insert each record, one by one
  my @results;
  my $meta_source        = $self->metadm;
  my %no_update_column   = $meta_source->no_update_column;
  my %auto_insert_column = $meta_source->auto_insert_column;
  my %auto_update_column = $meta_source->auto_update_column;

  my $schema = $self->schema;
  while (my $record = shift @records) {

    # TODO: shallow copy in order not to perturb the caller
    # BUT : if the insert injects a primary key, we want to retrieve it !
    # SO => contradiction
    # $record = {%$record} unless $got_records_as_arrayrefs;

    # bless, apply column handers and remove unwanted cols
    bless $record, $class;
    $record->apply_column_handler('to_DB');
    delete $record->{$_} foreach keys %no_update_column;
    while (my ($col, $handler) = each %auto_insert_column) {
      $record->{$col} = $handler->($record, $class);
    }
    while (my ($col, $handler) = each %auto_update_column) {
      $record->{$col} = $handler->($record, $class);
    }

    # inject schema
    $record->{__schema} = $schema;

    # remove subtrees (they will be inserted later)
    my $subrecords = $record->_weed_out_subtrees;

    # do the insertion. The result depends on %$options.
    my @single_result = $record->_singleInsert(%$options);

    # NOTE: at this point, $record is expected to hold its own primary key

    # insert the subtrees into DB, and keep the return vals if $want_subhash
    if ($subrecords) {
      my $subresults = $record->_insert_subtrees($subrecords, %$options);
      if ($want_subhash) {
        does($single_result[0], 'HASH')
          or die "_single_insert(..., -returning => {}) "
               . "did not return a hashref";
        $single_result[0]{$_} = $subresults->{$_} for keys %$subresults;
      }
    }

    push @results, @single_result;
  }

  # choose what to return according to context
  return @results if wantarray;             # list context
  return          if not defined wantarray; # void context
  carp "insert({...}, {...}, ..) called in scalar context" if @results > 1;
  return $results[0];                       # scalar context
}


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

  # clone $self as mere unblessed hash (for SQLA) and extract ref to $schema 
  my %values = %$self;
  my $schema = delete $values{__schema};
  # THINK: this cloning %values = %$self is inefficient because data was 
  # already cloned in Statement::insert(). But it is quite hard to improve :-((


  # cleanup $options
  if ($options{-returning}) {
    if (does($options{-returning}, 'HASH') && !keys %{$options{-returning}}) {
      delete $options{-returning};
    }
  }

  # perform the insertion
  my $sqla         = $schema->sql_abstract;
  my ($sql, @bind) = $sqla->insert(
    -into   => $self->db_from,
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
  my $table               = $self->db_from;

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
        (ref $v eq 'REF' && does($$v, 'ARRAY'))
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



sub _insert_subtrees {
  my ($self, $subrecords, %options) = @_;
  my $class = ref $self;
  my %results;

  while (my ($role, $arrayref) = each %$subrecords) {
    does $arrayref, 'ARRAY'
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


#------------------------------------------------------------
# delete
#------------------------------------------------------------

my $delete_spec = {
  -where => {type => HASHREF, optional => 0},
};


sub _parse_delete_args {
  my $self = shift;

  my @pk_cols = $self->metadm->primary_key;
  my $where;
  my @cascaded;

  if ($self->_is_called_as_class_method) {
    # parse arguments
    @_ or croak "delete() as class method: not enough arguments";

    my $uses_named_args = ! ref $_[0] && $_[0] =~ /^-/;
    if ($uses_named_args) {
      my %args = validate_with(params      => \@_,
                               spec        => $delete_spec,
                               allow_extra => 0);
      $where = $args{-where};
    }
    else { # uses positional args
      if (does $_[0], 'HASH') { # called as: delete({fields})
        my $hash = shift;
        @{$where}{@pk_cols} = @{$hash}{@pk_cols};
        !@_ or croak "delete() : too many arguments";
      }
      else { # called as: delete(@primary_key)
        my ($n_vals, $n_keys) = (scalar(@_), scalar(@pk_cols));
        $n_vals == $n_keys
          or croak "delete(): got $n_vals cols in primary key, expected $n_keys";
        @{$where}{@pk_cols} = @_;
      }
      my $missing = join ", ", grep {!defined $where->{$_}} @pk_cols;
      croak "delete(): missing value for $missing" if $missing;
    }
  }
  else { # called as instance method

    # build $where from primary key
    @{$where}{@pk_cols} = @{$self}{@pk_cols};

    # cascaded delete
  COMPONENT_NAME:
    foreach my $component_name ($self->metadm->components) {
      my $components = $self->{$component_name} or next COMPONENT_NAME;
      does($components, 'ARRAY')
        or croak "delete() : component $component_name is not an arrayref";
      push @cascaded, @$components;
    }
  }

  return ($where, \@cascaded);
}


sub delete {
  my $self = shift;

  my $schema             = $self->schema;
  my ($where, $cascaded) = $self->_parse_delete_args(@_);

  # perform cascaded deletes for components within $self
  $_->delete foreach @$cascaded;

  # perform this delete
  my ($sql, @bind) = $schema->sql_abstract->delete(
    -from  => $self->db_from,
    -where => $where,
   );
  $schema->_debug($sql . " / " . CORE::join(", ", @bind) );
  my $method = $schema->dbi_prepare_method;
  my $sth    = $schema->dbh->$method($sql);
  $sth->execute(@bind);
}


#------------------------------------------------------------
# update
#------------------------------------------------------------

my $update_spec = {
  -set   => {type => HASHREF, optional => 0},
  -where => {type => HASHREF, optional => 0},
};


sub _parse_update_args  { # returns ($schema, $to_set, $where)
  my $self = shift;

  my ($to_set, $where);

  if ($self->_is_called_as_class_method) {
    @_
      or croak "update() as class method: not enough arguments";

    my $uses_named_args = ! ref $_[0] && $_[0] =~ /^-/;
    if ($uses_named_args) {
      my %args = validate_with(params      => \@_,
                               spec        => $update_spec,
                               allow_extra => 0);
      ($to_set, $where) = @args{qw/-set -where/};
    }
    else { # uses positional args: update([@primary_key], {fields_to_update})
      does $_[-1], 'HASH'
        or croak "update(): expected a hashref as last argument";
      $to_set = { %{pop @_} };  # shallow copy
      my @pk_cols = $self->metadm->primary_key;
      if (@_) {
        my ($n_vals, $n_keys) = (scalar(@_), scalar(@pk_cols));
        $n_vals == $n_keys
          or croak "update(): got $n_vals cols in primary key, expected $n_keys";
        @{$where}{@pk_cols} = @_;
      }
      else {
        # extract primary key from hashref
        @{$where}{@pk_cols} = delete @{$to_set}{@pk_cols};
      }
    }
  }
  else { # called as instance method
    my %clone = %$self;

    # extract primary key from object
    $where->{$_} = delete $clone{$_} foreach $self->metadm->primary_key;

    if (!@_) {        # if called as $obj->update()
      delete $clone{__schema};
      $to_set = \%clone;
    }
    elsif (@_ == 1) { # if called as $obj->update({field => $val, ...})
      does $_[0], 'HASH'
        or croak "update() as instance method: unexpected argument";
      $to_set = $_[0];
    }
    else {
      croak "update() as instance method: too many arguments";
    }
  }

  return ($to_set, $where);
}


sub _apply_handlers_for_update {
  my ($self, $to_set, $where) = @_;

  # class of the invocant
  my $class  = ref $self || $self;

  # apply no_update and auto_update
  my %no_update_column = $self->metadm->no_update_column;
  delete $to_set->{$_} foreach keys %no_update_column;
  my %auto_update_column = $self->metadm->auto_update_column;
  while (my ($col, $handler) = each %auto_update_column) {
    $to_set->{$col} = $handler->($to_set, $class);
  }

  # apply 'to_DB' handlers. Need temporary bless as an object
  my $schema = $self->schema;
  $to_set->{__schema} = $schema; # in case the handlers need it
  bless $to_set, $class;
  $to_set->apply_column_handler('to_DB');
  delete $to_set->{__schema};
  $schema->unbless($to_set);


  # detect references to foreign objects
  my $sqla = $schema->sql_abstract;
  my @sub_refs;
  foreach my $key (keys %$to_set) {
    my $val     = $to_set->{$key};
    next if !ref $val;
    push @sub_refs, $key
      if does($val, 'HASH')
        ||( does($val, 'ARRAY')
              && !$sqla->{array_datatypes}
              && !$sqla->is_bind_value_with_type($val) );
    # reftypes SCALAR or REF are OK; they are used by SQLA for verbatim SQL
  }

  # remove references to foreign objects
  if (@sub_refs) {
    carp "data passed to update() contained nested references : ",
      CORE::join ", ", sort @sub_refs;
    delete @{$to_set}{@sub_refs};
  }

  # THINK : instead of removing references to foreign objects, one could
  # maybe perform recursive updates (including insert/update/delete of child
  # objects)
}




sub update  {
  my $self = shift;

  # prepare datastructures for generating the SQL
  my ($to_set, $where) = $self->_parse_update_args(@_);
  $self->_apply_handlers_for_update($to_set, $where);

  # database request
  my $schema       = $self->schema;
  my $sqla         = $schema->sql_abstract;
  my ($sql, @bind) = $sqla->update(
    -table => $self->db_from,
    -set   => $to_set,
    -where => $where,
   );
  $schema->_debug(do {no warnings 'uninitialized';
                      $sql . " / " . CORE::join(", ", @bind);});
  my $prepare_method = $schema->dbi_prepare_method;
  my $sth            = $schema->dbh->$prepare_method($sql);
  $sqla->bind_params($sth, @bind);
  return $sth->execute(); # will return the number of updated records
}


#------------------------------------------------------------
# utility methods
#------------------------------------------------------------

sub db_from {
  my $self = shift;

  my $db_from   = $self->metadm->db_from;
  my $db_schema = $self->schema->db_schema;

  # prefix table with $db_schema if non-empty and there is no hardwired db_schema
  return $db_schema && $db_from !~ /\./ ? "$db_schema.$db_from" : $db_from;
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

sub _parse_ending_options {
  my ($class_or_self, $args_ref, $regex) = @_;

  # end of list may contain options, recognized because option name is a
  # scalar matching the given regex
  my %options;
  while (@$args_ref >= 2 && !ref $args_ref->[-2] 
                         && $args_ref->[-2] && $args_ref->[-2] =~ $regex) {
    my ($opt_val, $opt_name) = (pop @$args_ref, pop @$args_ref);
    $options{$opt_name} = $opt_val;
  }
  return \%options;
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

=item L<db_from|DBIx::DataModel::Doc::Reference/db_from>

=back


=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT etat.ge.ch> >>


=head1 COPYRIGHT & LICENSE

Copyright 2006..2017 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


