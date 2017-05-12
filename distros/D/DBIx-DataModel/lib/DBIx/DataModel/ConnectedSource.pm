#----------------------------------------------------------------------
package DBIx::DataModel::ConnectedSource;
#----------------------------------------------------------------------
# see POD doc at end of file

use warnings;
use strict;
use Carp;
use Params::Validate qw/validate ARRAYREF HASHREF/;
use Scalar::Util     qw/reftype refaddr/;
use Acme::Damn       qw/damn/;
use Module::Load     qw/load/;
use Scalar::Does     qw/does/;
use Storable         qw/freeze/;

use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils;

use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}


sub new {
  my ($class, $meta_source, $schema) = @_;

  my $self = bless {meta_source => $meta_source, schema => $schema}, $class;
}


# accessors
DBIx::DataModel::Meta::Utils->define_readonly_accessors(
  __PACKAGE__, qw/meta_source schema/,
);

# additional accessor; here, 'metadm' is a synonym for 'meta_source'
sub metadm { 
  my $self = shift;
  return $self->{meta_source};
}

# several methods are delegated to the Statement class.
foreach my $method (qw/select bless_from_DB/) {
  no strict 'refs';
  *{$method} = sub {
    my $self = shift;

    my $stmt_class = $self->{schema}->metadm->statement_class;
    load $stmt_class;
    my $statement  = $stmt_class->new($self);
    return $statement->$method(@_);
  };
}



sub fetch {
  my $self = shift;
  my %select_args;

  # if last argument is a hashref, it contains arguments to the select() call
  no warnings 'uninitialized';
  if ((reftype $_[-1] || '') eq 'HASH') {
    %select_args = %{pop @_};
  }

  return $self->select(-fetch => \@_, %select_args);
}


sub fetch_cached {
  my $self = shift;
  my $dbh_addr    = refaddr $self->schema->dbh;
  my $freeze_args = freeze \@_;
  return $self->{meta_source}{fetch_cached}{$dbh_addr}{$freeze_args}
           ||= $self->fetch(@_);
}





#----------------------------------------------------------------------
# INSERT
#----------------------------------------------------------------------

sub insert {
  my $self = shift;

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
    foreach my $data_row (@records) {
      does ($data_row, 'ARRAY')
        or croak "data row after a header row should be an arrayref";
      @$data_row == @$header_row
        or croak "number of items in data row not same as header row";
      my %real_record;
      @real_record{@$header_row} = @$data_row;
      $data_row = \%real_record;
    }
  }

  # insert each record, one by one
  my @results;
  my $meta_source        = $self->{meta_source};
  my %no_update_column   = $meta_source->no_update_column;
  my %auto_insert_column = $meta_source->auto_insert_column;
  my %auto_update_column = $meta_source->auto_update_column;

  my $source_class = $self->{meta_source}->class;
  while (my $record = shift @records) {

    # TODO: shallow copy in order not to perturb the caller
    # BUT : if the insert injects a primary key, we want to retrieve it !
    # SO => contradiction
    # $record = {%$record} unless $got_records_as_arrayrefs;

    # bless, apply column handers and remove unwanted cols
    bless $record, $source_class;
    $record->apply_column_handler('to_DB');
    delete $record->{$_} foreach keys %no_update_column;
    while (my ($col, $handler) = each %auto_insert_column) {
      $record->{$col} = $handler->($record, $source_class);
    }
    while (my ($col, $handler) = each %auto_update_column) {
      $record->{$col} = $handler->($record, $source_class);
    }

    # inject schema
    $record->{__schema} = $self->{schema};

    # remove subtrees (will be inserted later)
    my $subrecords = $record->_weed_out_subtrees;

    # do the insertion. Result depends on %$options.
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


#----------------------------------------------------------------------
# UPDATE
#----------------------------------------------------------------------

my $update_spec = {
  -set   => {type => HASHREF},
  -where => {type => HASHREF|ARRAYREF},
};



sub update {
  my $self = shift;
  my $schema = $self->{schema};
  my $sqla   = $schema->sql_abstract;

  # parse arguments
  @_ or croak "update() : not enough arguments";
  my $is_positional_args = ref $_[0] || $_[0] !~ /^-/;
  my %args;
  if ($is_positional_args) {
    (reftype $_[-1] || '') eq 'HASH'
      or croak "update(): expected a hashref as last argument";
    $args{-set}   = pop @_;
    $args{-where} = [-key => @_] if @_;
  }
  else {
    %args = validate(@_, $update_spec);
  }

  # some shortcuts
  my $meta_source  = $self->{meta_source};
  my $source_class = $meta_source->class;

  # build a shallow copy of $args{-set}, bless it and call 'to_DB' handlers
  my $to_set = {%{$args{-set}}, __schema => $self->schema};
  $self->_maybe_inject_primary_key($to_set, \%args);
  bless $to_set, $source_class;

  # call column handlers : no_update, auto_update, to_DB
  my %no_update_column = $meta_source->no_update_column;
  delete $to_set->{$_} foreach keys %no_update_column;
  my %auto_update_column = $meta_source->auto_update_column;
  while (my ($col, $handler) = each %auto_update_column) {
    $to_set->{$col} = $handler->($to_set, $source_class);
  }
  $to_set->apply_column_handler('to_DB');

  # detect references to foreign objects
  my @sub_refs;
  foreach my $key (grep {$_ ne '__schema'} keys %$to_set) {
    my $val     = $to_set->{$key};
    my $reftype = reftype($val)
      or next;
    push @sub_refs, $key
      if $reftype eq 'HASH'
        ||( $reftype eq 'ARRAY' 
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

  # if this is a single record update (no '-where' arg), build -where from pkey
  my $where = $args{-where};
  if (!$where) {
    my @primary_key = $self->{meta_source}->primary_key;
    $where = {map {$_ => delete $to_set->{$_}} @primary_key};
  }

  # TODO : recursive update (or insert)

  # remove ref to $schema and unbless (back to a raw hashref)
  delete $to_set->{__schema};
  damn $to_set;

  # database request
  my ($sql, @bind) = $sqla->update(
    -table => $meta_source->db_from,
    -set   => $to_set,
    -where => $where,
   );
  $schema->_debug(do {no warnings 'uninitialized'; 
                      $sql . " / " . CORE::join(", ", @bind);});
  my $method = $schema->dbi_prepare_method;
  my $sth    = $schema->dbh->$method($sql);
  $sqla->bind_params($sth, @bind);
  $sth->execute();
}



#----------------------------------------------------------------------
# DELETE
#----------------------------------------------------------------------

my $delete_spec = {
  -where => {type => HASHREF|ARRAYREF},
};

sub delete {
  my $self = shift;

  # parse arguments
  @_ or croak "delete() : not enough arguments";
  my $is_positional_args = ref $_[0] || $_[0] !~ /^-/;
  my %args;
  my $to_delete = {};
  if ($is_positional_args) {
    if ((reftype $_[0] || '') eq 'HASH') { # @_ contains a hashref to delete
      @_ == 1 
        or croak "delete() : too many arguments";
      $to_delete = {%{$_[0]}}; # shallow copy
    }
    else {                         # @_ contains a primary key to delete
      $args{-where} = [-key => @_];
    }
  }
  else {
    %args = validate(@_, $delete_spec);
  }

  $self->_maybe_inject_primary_key($to_delete, \%args);

  my $meta_source  = $self->{meta_source};
  my $source_class = $meta_source->class;
  my $where        = $args{-where};

  # if this is a delete of a single record ...
  if (!$where) {
    # cascaded delete
    foreach my $component_name ($meta_source->components) {
      my $components = $to_delete->{$component_name} or next;
      does($components, 'ARRAY')
        or croak "delete() : component $component_name is not an arrayref";
      $_->delete foreach @$components;
    }
    # build $where from primary key
    $where = {map {$_ => $to_delete->{$_}} $self->{meta_source}->primary_key};
  }

  else {
    # otherwise, it will be a bulk delete, no handlers applied
  }

  # database request
  my $schema = $self->{schema};
  my ($sql, @bind) = $schema->sql_abstract->delete(
    -from => $meta_source->db_from,
    -where => $where,
   );
  $schema->_debug($sql . " / " . CORE::join(", ", @bind) );
  my $method = $schema->dbi_prepare_method;
  my $sth    = $schema->dbh->$method($sql);
  $sth->execute(@bind);
}


#----------------------------------------------------------------------
# JOIN
#----------------------------------------------------------------------

sub join {
  my ($self, $first_role, @other_roles) = @_;

  # direct references to utility objects
  my $schema      = $self->schema;
  my $metadm      = $self->metadm;
  my $meta_schema = $schema->metadm;

  # find first join information
  my $class  = $metadm->class;
  my $path   = $metadm->path($first_role)
    or croak "could not find role $first_role in $class";

  # build search criteria on %$self from first join information
  my (%criteria, @left_cols);
  my $prefix;
  while (my ($left_col, $right_col) = each %{$path->{on}}) {
    $prefix ||= $schema->placeholder_prefix;
    $criteria{$right_col} = "$prefix$left_col";
    push @left_cols, $left_col;
  }

  # choose source (just a table or build a join) 
  my $source = @other_roles  ? $meta_schema->define_join($path->{to}{name},
                                                         @other_roles)
                             : $path->{to};

  # build args for the statement
  my $connected_source = (ref $self)->new($source, $schema);
  my @stmt_args = ($connected_source, -where => \%criteria);

  # keep a reference to @left_cols so that Source::join can bind them
  push @stmt_args, -_left_cols => \@left_cols;

  # TODO: should add -select_as => 'firstrow' if all multiplicities are 1

  # build and return the new statement
  my $statement = $meta_schema->statement_class->new(@stmt_args);
  return $statement;
}


#----------------------------------------------------------------------
# Utilities
#----------------------------------------------------------------------


sub _maybe_inject_primary_key {
  my ($self, $record, $args) = @_;

  # if primary key was supplied separately, inject it into the record
  my $where = $args->{-where};
  if (does($where, 'ARRAY') && $where->[0] eq '-key') {
    # got the primary key in the form -where => [-key => @pk_vals]
    my @pk_cols = $self->{meta_source}->primary_key;
    my @pk_vals = @{$where}[1 .. $#$where];
    @pk_cols == @pk_vals
      or croak sprintf "got %d cols in primary key, expected %d",
                        scalar(@pk_vals), scalar(@pk_cols);
    @{$record}{@pk_cols} = @pk_vals;
    delete $args->{-where};
  }
}


1;


__END__

=encoding ISO8859-1

=head1 NAME

DBIx::DataModel::ConnectedSource - metasource and schema paired together

=head1 DESCRIPTION

A I<connected source> is a pair of a C<$schema> and C<$meta_source>.
The meta_source holds information about the data structure, and the schema
holds a connection to the database.

=head1 METHODS

Methods are documented in 
L<DBIx::DataModel::Doc::Reference/"CONNECTED SOURCES">


=head2 Constructor

=head3 new

  my $connected_source 
    = DBIx::DataModel::ConnectedSource->new($meta_source, $schema);


=head2 Accessors

=head3 meta_source

=head3 schema

=head3 metadm


=head2 Data retrieval

=head3 select

=head3 fetch

=head3 fetch_cached

=head3 join


=head2 Data manipulation

=head3 insert

=head3 update

=head3 delete


=cut


