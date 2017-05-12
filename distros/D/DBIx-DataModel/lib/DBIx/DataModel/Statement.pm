#----------------------------------------------------------------------
package DBIx::DataModel::Statement;
#----------------------------------------------------------------------
# see POD doc at end of file

use warnings;
use strict;
use Carp;
use List::Util       qw/min first/;
use List::MoreUtils  qw/firstval any/;
use Scalar::Util     qw/weaken refaddr reftype dualvar/;
use Params::Validate qw/validate ARRAYREF HASHREF/;
use POSIX            qw/LONG_MAX/;
use Acme::Damn       qw/damn/;
use Clone            qw/clone/;
use Try::Tiny;

use DBIx::DataModel;
use DBIx::DataModel::Meta::Utils;
use namespace::clean;

{no strict 'refs'; *CARP_NOT = \@DBIx::DataModel::CARP_NOT;}

use overload

  # overload the stringification operator so that Devel::StackTrace is happy;
  # also useful to show the SQL (if in sqlized state)
  '""' => sub {
    my $self = shift;
    my $string = try {my ($sql, @bind) = $self->sql;
                       __PACKAGE__ . "($sql // " . join(", ", @bind) . ")"; }
              || overload::StrVal($self);
  }
;


# sequence of states. Stored as dualvars for both ordering and printing
use constant {
  NEW      => dualvar(1, "new"     ),
  REFINED  => dualvar(2, "refined" ),
  SQLIZED  => dualvar(3, "sqlized" ),
  PREPARED => dualvar(4, "prepared"),
  EXECUTED => dualvar(5, "executed"),
};



#----------------------------------------------------------------------
# PUBLIC METHODS
#----------------------------------------------------------------------

sub new {
  my ($class, $connected_source, %other_args) = @_;

  # check $connected_source
  $connected_source 
    && $connected_source->isa('DBIx::DataModel::ConnectedSource')
    or croak "invalid connected_source for DBIx::DataModel::Statement->new()";

  # build the object
  my $self = bless {status           => NEW,
                    args             => {},
                    pre_bound_params => {},
                    bound_params     => [],
                    connected_source => $connected_source}, $class;

  # add placeholder_regex
  my $prefix = $connected_source->schema->{placeholder_prefix};
  $self->{placeholder_regex} = qr/^\Q$prefix\E(.+)/;

  # parse remaining args, if any
  $self->refine(%other_args) if %other_args;

  return $self;
}


# accessors
DBIx::DataModel::Meta::Utils->define_readonly_accessors(
  __PACKAGE__, qw/connected_source status/,
);
sub meta_source {shift->{connected_source}->meta_source}
sub schema      {shift->{connected_source}->schema}



# THINK : not documented yet, is this method useful ?
sub reset {
  my ($self, %other_args) = @_;

  my $new = (ref $self)->new($self->{connected_source}, %other_args);
  %$self = (%$new);

  return $self;
}




#----------------------------------------------------------------------
# PUBLIC METHODS IN RELATION WITH SELECT()
#----------------------------------------------------------------------


sub sql {
  my ($self) = @_;

  $self->{status} >= SQLIZED
    or croak "can't call sql() when in status $self->{status}";

  return wantarray ? ($self->{sql}, @{$self->{bound_params}})
                   : $self->{sql};
}


sub bind {
  my ($self, @args) = @_;

  # arguments can be a list, a hashref or an arrayref
  if (@args == 1) {
    for (reftype($args[0]) || "") {
      /^HASH$/  and do {@args = %{$args[0]}; last;};
      /^ARRAY$/ and do {my $i = 0; @args = map {($i++, $_)} @{$args[0]}; last};
      #otherwise
      croak "unexpected arg type to bind()";
    }
  }
  elsif (@args == 3) { # name => value, \%datatype (see L<DBI/bind_param>)
    # transform into ->bind($name => [$value, \%datatype])
    @args = ($args[0], [$args[1], $args[2]]);
  }
  elsif (@args % 2 == 1) {
    croak "odd number of args to bind()";
  }

  # do bind (different behaviour according to status)
  my %args = @args;
  if ($self->{status} < SQLIZED) {
    while (my ($k, $v) = each %args) {
      $self->{pre_bound_params}{$k} = $v;
    }
  }
  else {
    while (my ($k, $v) = each %args) {
      my $indices = $self->{param_indices}{$k} 
        or next; # silently ignore that binding (named placeholder unused)
      $self->{bound_params}[$_] = $v foreach @$indices;
    }
  }

  return $self;
}


sub refine {
  my ($self, %more_args) = @_;

  $self->{status} <= REFINED
    or croak "can't refine() when in status $self->{status}";
  $self->{status} = REFINED;

  my $args = $self->{args};

  while (my ($k, $v) = each %more_args) {

  SWITCH:
    for ($k) {

      # -where : combine with previous 'where' clauses in same statement
      /^-where$/ and do {
        my $sqla = $self->schema->sql_abstract;
        $args->{-where} = $sqla->merge_conditions($args->{-where}, $v);
        last SWITCH;
      };

      # -fetch : special select() on primary key
      /^-fetch$/ and do {
        # build a -where clause on primary key
        my $primary_key = ref($v) ? $v : [$v];
        my @pk_columns  = $self->meta_source->primary_key;
        @pk_columns
          or croak "fetch: no primary key in source " . $self->meta_source;
        @pk_columns == @$primary_key
          or croak sprintf "fetch from %s: primary key should have %d values",
                           $self->meta_source, scalar(@pk_columns);
        List::MoreUtils::all {defined $_} @$primary_key
          or croak "fetch from " . $self->meta_source . ": "
                 . "undefined val in primary key";

        my %where = ();
        @where{@pk_columns} = @$primary_key;
        my $sqla = $self->schema->sql_abstract;
        $args->{-where} = $sqla->merge_conditions($args->{-where}, \%where);

        # want a single record as result
        $args->{-result_as} = "firstrow";

        last SWITCH;
      };

      # -columns : store in $self->{args}{-columns}; can restrict previous list
      /^-columns$/ and do {
        my @cols = ref $v ? @$v : ($v);
        if (my $old_cols = $args->{-columns}) {
          unless (@$old_cols == 1 && $old_cols->[0] eq '*' ) {
            foreach my $col (@cols) {
              any {$_ eq $col} @$old_cols
                or croak "can't restrict -columns on '$col' (was not in the) "
                       . "previous -columns list";
            }
          }
        }
        $args->{-columns} = \@cols;
        last SWITCH;
      };


      # other args are just stored, will be used later
      /^-( order_by       | group_by  | having    | for
         | union(?:_all)? | intersect | except    | minus
         | result_as      | post_SQL  | pre_exec  | post_exec  | post_bless
         | limit          | offset    | page_size | page_index
         | column_types   | prepare_attrs         | dbi_prepare_method
         | _left_cols     | where_on
         )$/x
         and do {$args->{$k} = $v; last SWITCH};

      # otherwise
      croak "invalid arg : $k";

    } # end SWITCH
  } # end while

  return $self;
}




sub sqlize {
  my ($self, @args) = @_;

  $self->{status} < SQLIZED
    or croak "can't sqlize() when in status $self->{status}";

  # merge new args into $self->{args}
  $self->refine(@args) if @args;

  # shortcuts
  my $args         = $self->{args};
  my $meta_source  = $self->meta_source;
  my $source_where = $meta_source->{where};
  my $sql_abstract = $self->schema->sql_abstract;
  my $result_as    = $args->{-result_as} || "";


  # build arguments for SQL::Abstract::More
  $self->refine(-where => $source_where) if $source_where;
  my @args_to_copy = qw/-columns -where
                        -union -union_all -intersect -except -minus
                        -order_by -group_by -having
                        -limit -offset -page_size -page_index/;
  my %sqla_args = (-from         => clone($meta_source->db_from),
                   -want_details => 1);
  defined $args->{$_} and $sqla_args{$_} = $args->{$_} for @args_to_copy;
  $sqla_args{-columns} ||= $meta_source->default_columns;
  $sqla_args{-limit}   ||= 1
    if $result_as eq 'firstrow' && $self->schema->autolimit_firstrow;

  # "-for" (e.g. "update", "read only")
  if ($result_as ne 'subquery') {
    if ($args->{-for}) {
      $sqla_args{-for} = $args->{-for};
    }
    elsif (!exists $args->{-for}) {
      $sqla_args{-for} = $self->schema->select_implicitly_for;
    }
  }

  # EXPERIMENTAL: "where_on"
  if (my $where_on = $args->{-where_on}) {
    # retrieve components of the join
    my ($join_op, $first_table, @other_join_args) = @{$sqla_args{-from}};
    $join_op eq '-join'
      or croak "datasource for '-where_on' was not a join";
    my %by_dest_table = reverse @other_join_args;

    # insert additional conditions into appropriate places
    while (my ($table, $additional_cond) = each %$where_on) {
      my $join_cond = $by_dest_table{$table}
        or croak "-where_on => {'$table' => ..}: this table is not in the join";
      $join_cond->{condition}
        = $sql_abstract->merge_conditions($join_cond->{condition},
                                          $additional_cond);
    }

    # TODO: should be able to use paths and aliases as keys, instead of 
    # database table names.
    # TOCHECK: is this stuff still compatible with the bind() method ?
  }

  # generate SQL
  my $sqla_result = $sql_abstract->select(%sqla_args);

  # maybe post-process the SQL
  if ($args->{-post_SQL}) {
    ($sqla_result->{sql}, @{$sqla_result->{bind}})
      = $args->{-post_SQL}->($sqla_result->{sql}, @{$sqla_result->{bind}});
  }

  # keep $sql / @bind / aliases in $self, and set new status
  $self->{bound_params} = $sqla_result->{bind};
  $self->{$_} = $sqla_result->{$_} for qw/sql aliased_tables aliased_columns/;
  $self->{status}       = SQLIZED;

  # analyze placeholders, and replace by pre_bound params if applicable
  if (my $regex = $self->{placeholder_regex}) {
    for (my $i = 0; $i < @{$self->{bound_params}}; $i++) {
      $self->{bound_params}[$i] =~ $regex 
        and push @{$self->{param_indices}{$1}}, $i;
    }
  }
  $self->bind($self->{pre_bound_params}) if $self->{pre_bound_params};

  # compute callback to apply to data rows
  my $callback = $self->{args}{-post_bless};
  weaken(my $weak_self = $self);   # weaken to avoid a circular ref in closure
  $self->{row_callback} = sub {
    my $row = shift;
    $weak_self->bless_from_DB($row);
    $callback->($row) if $callback;
  };

  return $self;
}



sub prepare {
  my ($self, @args) = @_;

  my $meta_source = $self->meta_source;

  $self->sqlize(@args) if @args or $self->{status} < SQLIZED;

  $self->{status} == SQLIZED
    or croak "can't prepare() when in status $self->{status}";

  # log the statement and bind values
  $self->schema->_debug("PREPARE $self->{sql} / @{$self->{bound_params}}");

  # call the database
  my $dbh          = $self->schema->dbh or croak "Schema has no dbh";
  my $method       = $self->{args}{-dbi_prepare_method}
                  || $self->schema->dbi_prepare_method;
  my @prepare_args = ($self->{sql});
  if (my $prepare_attrs = $self->{args}{-prepare_attrs}) {
    push @prepare_args, $prepare_attrs;
  }
  $self->{sth}  = $dbh->$method(@prepare_args);

  # new status and return
  $self->{status} = PREPARED;
  return $self;
}



sub execute {
  my ($self, @bind_args) = @_;

  # if not prepared yet, prepare it
  $self->prepare              if $self->{status} < PREPARED;

  # TODO: DON'T REMEMBER why the line below was here. Keep it around for a while ...
  push @bind_args, offset => $self->{offset}  if $self->{offset};

  $self->bind(@bind_args)      if @bind_args;

  # shortcuts
  my $args = $self->{args};
  my $sth  = $self->{sth};

  # previous row_count, row_num and reuse_row are no longer valid
  delete $self->{reuse_row};
  delete $self->{row_count};
  $self->{row_num} = $self->offset;

  # pre_exec callback
  $args->{-pre_exec}->($sth)   if $args->{-pre_exec};

  # check that all placeholders were properly bound to values
  my @unbound;
  while (my ($k, $indices) = each %{$self->{param_indices} || {}}) {
    exists $self->{bound_params}[$indices->[0]] or push @unbound, $k;
  }
  not @unbound 
    or croak "unbound placeholders (probably a missing foreign key) : "
            . CORE::join(", ", @unbound);

  # bind parameters and execute
  my $sqla = $self->schema->sql_abstract;
  $sqla->bind_params($sth, @{$self->{bound_params}});
  $sth->execute;

  # post_exec callback
  $args->{-post_exec}->($sth)  if $args->{-post_exec};

  $self->{status} = EXECUTED;
  return $self;
}


sub select {
  my $self = shift;

  $self->refine(@_) if @_;

  my $args = $self->{args}; # all combined args

  my $callbacks = CORE::join ", ", grep {exists $args->{$_}} 
                                        qw/-pre_exec -post_exec -post_bless/;

 SWITCH:
  my ($result_as, @key_cols) 
    = ref $args->{-result_as} ? @{$args->{-result_as}}
                              : ($args->{-result_as} || "rows");
  for ($result_as) {

    # CASE statement : the DBIx::DataModel::Statement object 
    /^statement$/i and do {
        delete $self->{args}{-result_as};
        return $self;
      };

    # for all other cases, must first sqlize the statement
    $self->sqlize if $self->{status} < SQLIZED;

    # CASE sql : just return the SQL and bind values
    /^sql$/i        and do {
      not $callbacks 
        or croak "$callbacks incompatible with -result_as=>'sql'";
      return $self->sql;
    };

    # CASE subquery : return a ref to an arrayref with SQL and bind values
    /^subquery$/i        and do {
      not $callbacks 
        or croak "$callbacks incompatible with -result_as=>'subquery'";
      my ($sql, @bind) = $self->sql;
      return \ ["($sql)", @bind];
    };

    # for all other cases, must first execute the statement
    $self->execute;

    # CASE sth : return the DBI statement handle
    /^sth$/i        and do {
        not $args->{-post_bless}
          or croak "-post_bless incompatible with -result_as=>'sth'";
        return $self->{sth};
      };

    # CASE rows : all data rows (this is the default)
    /^(rows|arrayref)$/i  and return $self->all;

    # CASE firstrow : just the first row
    /^firstrow$/i   and return $self->_next_and_finish;

    # CASE hashref : all data rows, put into a hashref
    /^hashref$/i   and do {
      @key_cols or @key_cols = $self->meta_source->primary_key
        or croak "-result_as=>'hashref' impossible: no primary key";
      my %hash;
      while (my $row = $self->next) {
        my @key;
        foreach my $col (@key_cols) {
          my $val = $row->{$col};
          $val = '' if not defined $val; # $val might be 0, so no '||'
          push @key, $val;
        }
        my $last_key_item = pop @key;
        my $node          = \%hash;
        $node = $node->{$_} ||= {} foreach @key;
        $node->{$last_key_item} = $row;
      }
      $self->{sth}->finish;
      return \%hash;
    };

    # CASE fast_statement : creates a reusable row
    /^fast[-_]statement$/i and do {
        $self->_build_reuse_row;
        return $self;
      };

    # CASE flat_arrayref : flattened columns from each row
    /^flat(?:_array(?:ref)?)?$/ and do {
      $self->_build_reuse_row;
      my @vals;
      my $hash_key_name = $self->{sth}{FetchHashKeyName} || 'NAME';
      my $cols = $self->{sth}{$hash_key_name};
      while (my $row = $self->next) {
        push @vals, @{$row}{@$cols};
      }
      $self->{sth}->finish;
      return \@vals;
    };


    # OTHERWISE
    croak "unknown -result_as value: $_"; 
  }
}


sub row_count {
  my ($self) = @_;

  if (! exists $self->{row_count}) {
    $self->sqlize if $self->{status} < SQLIZED;
    my ($sql, @bind) = $self->sql;

    # get syntax used for LIMIT clauses ...
    my $sqla = $self->schema->sql_abstract;
    my ($limit_sql, undef, undef) = $sqla->limit_offset(0, 0);
    $limit_sql =~ s/([()?*])/\\$1/g;

    # ...and use it to remove the LIMIT clause and associated bind vals, if any
    if ($limit_sql =~ /ROWNUM/) { # special case for Oracle syntax, complex ...
                                  # see source code of SQL::Abstract::More
      $limit_sql =~ s/%s/(.*)/;
      if ($sql =~ s/^$limit_sql/$1/) {
        splice @bind, -2;
      }
    }
    elsif ($sql =~ s[\b$limit_sql][]i) { # regular LIMIT/OFFSET syntaxes
      splice @bind, -2;
    }

    # decide if the SELECT COUNT should wrap the original SQL in a subquery;
    # this is needed with clauses like below that change the number of rows
    my $should_wrap = $sql =~ /\b(UNION|INTERSECT|MINUS|EXCEPT|DISTINCT)\b/i;

    # if no wrap required, attempt to directly substitute COUNT(*) for the 
    # column names ...but if it fails, wrap anyway
    $should_wrap ||= ! ($sql =~ s[^SELECT\b.*?\bFROM\b][SELECT COUNT(*) FROM]i);

    # wrap SQL if needed, using  a subquery alias because it's required for 
    # some DBMS (like PostgreSQL)
    $should_wrap and  $sql = "SELECT COUNT(*) FROM "
                           . $sqla->table_alias("( $sql )", "count_wrapper");

    # log the statement and bind values
    $self->schema->_debug("PREPARE $sql / @bind");

    # call the database
    my $dbh    = $self->schema->dbh or croak "Schema has no dbh";
    my $method = $self->schema->dbi_prepare_method;
    my $sth    = $dbh->$method($sql);
    $sth->execute(@bind);
    ($self->{row_count}) = $sth->fetchrow_array;
    $sth->finish;
  }

  return $self->{row_count};
}


sub row_num {
  my ($self) = @_;
  return $self->{row_num};
}

sub next {
  my ($self, $n_rows) = @_;

  $self->execute if $self->{status} < EXECUTED;

  my $sth      = $self->{sth}          or croak "absent sth in statement";
  my $callback = $self->{row_callback} or croak "absent callback in statement";

  if (not defined $n_rows) {  # if user wants a single row
    # fetch a single record, either into the reusable row, or into a fresh hash
    my $row = $self->{reuse_row} ? ($sth->fetch ? $self->{reuse_row} : undef)
                                 : $sth->fetchrow_hashref;
    if ($row) {
      $callback->($row);
      $self->{row_num} +=1;
    }
    return $row;
  }
  else {                      # if user wants an arrayref of size $n_rows
    $n_rows > 0            or croak "->next() : invalid argument, $n_rows";
    not $self->{reuse_row} or croak "reusable row, cannot retrieve several";
    my @rows;
    while ($n_rows--) {
      my $row = $sth->fetchrow_hashref or last;
      push @rows, $row;
    }
    $callback->($_) foreach @rows;
    $self->{row_num} += @rows;
    return \@rows;
  }

  # NOTE: ->next() returns a $row, while ->next(1) returns an arrayref of 1 row
}


sub all {
  my ($self) = @_;

  # just call next() with a huge number
  return $self->_next_and_finish(POSIX::LONG_MAX);
}


sub page_size   { shift->{args}{-page_size}  || POSIX::LONG_MAX  }
sub page_index  { shift->{args}{-page_index} || 1                }
sub offset      { shift->{offset}            || 0                }


sub page_count {
  my ($self) = @_;

  my $row_count = $self->row_count or return 0;
  my $page_size = $self->page_size || 1;

  return int(($row_count - 1) / $page_size) + 1;
}


sub page_boundaries {
  my ($self) = @_;

  my $first = $self->offset + 1;
  my $last  = min($self->row_count, $first + $self->page_size - 1);
  return ($first, $last);
}


sub page_rows {
  my ($self) = @_;
  return $self->_next_and_finish($self->page_size);
}


sub bless_from_DB {
  my ($self, $row) = @_;

  # inject ref to $schema if in multi-schema mode
  $row->{__schema} = $self->schema unless $self->schema->{is_singleton};

  # bless into appropriate class
  bless $row, $self->meta_source->class;
  # apply handlers
  $self->{from_DB_handlers} or $self->_compute_from_DB_handlers;
  while (my ($column_name, $handler) 
           = each %{$self->{from_DB_handlers}}) {
    exists $row->{$column_name}
      and $handler->($row->{$column_name}, $row, $column_name, 'from_DB');
  }

  return $row;
}


#----------------------------------------------------------------------
# PRIVATE METHODS IN RELATION WITH SELECT()
#----------------------------------------------------------------------

sub _build_reuse_row {
  my ($self) = @_;

  $self->{status} == EXECUTED
    or croak "cannot _build_reuse_row() when in state $self->{status}";

  # create a reusable hash and bind_columns to it (see L<DBI/bind_columns>)
  my %row;
  my $hash_key_name = $self->{sth}{FetchHashKeyName} || 'NAME';
  $self->{sth}->bind_columns(\(@row{@{$self->{sth}{$hash_key_name}}}));
  $self->{reuse_row} = \%row; 
}


sub _next_and_finish {
  my $self = shift;
  my $row_or_rows = $self->next( @_ ); # pass original parameters
  $self->{sth}->finish;
  return $row_or_rows;
}

sub _compute_from_DB_handlers {
  my ($self) = @_;
  my $meta_source    = $self->meta_source;
  my $meta_schema    = $self->schema->metadm;
  my %handlers       = $meta_source->_consolidate_hash('column_handlers');
  my %aliased_tables = $meta_source->aliased_tables;

  # iterate over aliased_columns
  while (my ($alias, $column) = each %{$self->{aliased_columns} || {}}) {
    my $table_name;
    $column =~ s{^([^()]+)     # supposed table name (without parens)
                  \.           # followed by a dot
                  (?=[^()]+$)  # followed by supposed col name (without parens)
                }{}x
      and $table_name = $1;
    if (!$table_name) {
      $handlers{$alias} = $handlers{$column};
    }
    else {
      $table_name = $aliased_tables{$table_name} || $table_name;

      my $table   = $meta_schema->table($table_name)
                 || (firstval {($_->{db_name} || '') eq $table_name}
                              ($meta_source, $meta_source->ancestors))
                 || (firstval {uc($_->{db_name} || '') eq uc($table_name)}
                              ($meta_source, $meta_source->ancestors))
        or croak "unknown table name: $table_name";

      $handlers{$alias} = $table->{column_handlers}->{$column};
    }
  }

  # handlers may be overridden from args{-column_types}
  if (my $col_types = $self->{args}{-column_types}) {
    while (my ($type_name, $columns) = each %$col_types) {
      ref $columns or $columns = [$columns];
      my $type = $self->schema->metadm->type($type_name)
        or croak "no such column type: $type_name";
      $handlers{$_} = $type->{handlers} foreach @$columns;
    }
  }

  # just keep the "from_DB" handlers
  my $from_DB_handlers = {};
  while (my ($column, $col_handlers) = each %handlers) {
    my $from_DB_handler = $col_handlers->{from_DB} or next;
    $from_DB_handlers->{$column} = $from_DB_handler;
  }
  $self->{from_DB_handlers} = $from_DB_handlers;

  return $self;
}



1; # End of DBIx::DataModel::Statement

__END__

=head1 NAME

DBIx::DataModel::Statement - DBIx::DataModel statement objects

=head1 DESCRIPTION

The purpose of a I<statement> object is to retrieve rows from the
database and bless them as objects of appropriate classes.

Internally the statement builds and then encapsulates a C<DBI>
statement handle (sth).

The design principles for statements are described in the
L<DESIGN|DBIx::DataModel::Doc::Design/"STATEMENT OBJECTS"> section of
the manual (purpose, lifecycle, etc.).

=head1 METHODS

=head2 new

  my $statement 
    = DBIx::DataModel::Statement->new($connected_source, %options);

This is the statement constructor; C<$connected_source> is an
instance of L<DBIx::DataModel::ConnectedSource>. 
If present, C<%options> are delegated
to the L<refine()|DBIx::DataModel::Doc::Reference/refine()> method.

Explicit calls to the statement constructor are exceptional;
the usual way to create a statement is through 
L<ConnectedSource::select()|DBIx::DataModel::Doc::Reference/ConnectedSource::select()>.


=head1 PRIVATE METHOD NAMES

The following methods or functions are used
internally by this module and 
should be considered as reserved names, not to be
redefined in subclasses :

=over

=item _bless_from_DB

=item _compute_from_DB_handlers

=back


