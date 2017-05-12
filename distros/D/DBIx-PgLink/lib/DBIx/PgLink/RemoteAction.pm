package DBIx::PgLink::RemoteAction;

# Connector role
# PL/Perl function interface for remote operations (query, exec, trigger fn)

use Moose::Role;
use MooseX::Method;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Types;
use Data::Dumper;
use Memoize;


requires 'load_accessor'; # from Accessor role
requires 'data_type_to_local'; # from TypeMapper role
requires 'resolve_converter_method'; # from TypeMapper role


# cached wrapper
sub load_accessor_cached {
  my $self = shift;
  return $self->load_accessor(@_);
};

# cache to the session end
memoize 'load_accessor_cached';


sub _bind_user_params {
  my ($self, $sth, $pv, $pt) = @_;

  trace_msg('WARNING', 'Number of bind values does not match number of parameter types') 
    if $#{$pv} != $#{$pt} && @{$pt};

  my $i = 0;
  for my $v (@{$pv}) {
    my $t = $pt->[$i++]; # user-supplied type name (vendor or standard)

    # conversion
    if (defined $t) {
      my $sub = $self->data_type_to_local($t)->{conv_to_remote_coderef};
      $sub->( $self->adapter, $v ) if $sub;
    }
    
    my $type_code = defined $t
      ? $self->sql_type_name_to_code->{$t} # SQL Standard type code
      : undef; 

    if (defined $type_code) {
      $sth->bind_param($i, $v, {TYPE=>$type_code});
      trace_msg('INFO', "Bind[$i/$type_code]: " . defined $v ? $v : 'NULL') if trace_level >= 3;
    } else {
      $sth->bind_param($i, $v);
      trace_msg('INFO', "Bind[$i]: " . defined $v ? $v : 'NULL') if trace_level >= 3;
    }
  }
}


method _remote_statement => named (
  query_text   => { isa=>'Str', required=>1 },
  param_values => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], },
  param_types  => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], },
) => sub {
  my ($self, $p) = @_;

  my $adapter = $self->adapter;

  trace_msg('INFO', "Prepare on " . $self->conn_name . ":\n$p->{query_text}")
    if trace_level >= 2;

  my $sth = $adapter->prepare_cached($p->{query_text});

  $self->_bind_user_params(
    $sth,
    $p->{param_values},
    $p->{param_types},
  );

  return $sth;
};


# return untyped resultset
method remote_query => named (
  query_text   => { isa=>'Str', required=>1 },
  param_values => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], }, 
  param_types  => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], },
) => sub {
  my ($self, $p) = @_;
  my $sth = $self->_remote_statement($p);

  $sth->execute;

  # convert only by standard type code
  my @result_conv;
  for my $i (0..$sth->sth->{NUM_OF_FIELDS}-1) {
    my $type = $sth->sth->{TYPE}->[$i];
    my $lt = $self->data_type_to_local($type) or next;
    my $sub = $lt->{conv_to_local_coderef} or next;
    my $name = $sth->sth->{NAME}->[$i];
    push @result_conv, { name=>$name, conv=>$sub };
  }

  while (my $row = $sth->fetchrow_hashref) {

    # convert resultset values by column name
    for my $c (@result_conv) {
      $c->{conv}->( $self->adapter, $row->{$c->{name}} );
    }

    # pipe to backend
    main::return_next(\%{$row});
  }
  $sth->finish;

  return undef;
};


# return number of proceeded rows
method remote_exec => named (
  query_text   => { isa=>'Str', required=>1 },
  param_values => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], },
  param_types  => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[], },
) => sub {
  my ($self, $p) = @_;
  my $sth = $self->_remote_statement($p);

  trace_msg('ERROR', "Query can not be prepared: $p->{query_text}") unless $sth; 

  my $result = $sth->execute;
  $sth->finish;

  return undef unless $result; # error
  return $result eq '0E0' ? 0 : $result; # integer row count
};


# cached wrapper over Accessor methods, return prepared statement with metadata (hash, not an object)
method 'remote_statement_prepare_cached' => named (
  accessor     => { isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1},
  action       => { isa=>'Action', required=>1 },
  where        => { isa=>'Str', required=>0, default=>'' },
) => sub {
  my ($self, $p) = @_;

  my $a = $p->{accessor};

  my $q = $a->load_query($p->{action});

  trace_msg("INFO", "Preparing $DBIx::PgLink::Types::action_name{$p->{action}}-statement for " . $a->remote_object_quoted)
    if trace_level >= 2;

  # check: is WHERE safe?
  if ($p->{where} && !$self->adapter->check_where_condition($p->{where})) {
    trace_msg('ERROR', "Invalid WHERE condition '$p->{where}' for " . $q->query);
  }
  my $query_text = $q->query_text; # copy
  $query_text =~ s/\$\{WHERE\}/$p->{where}/g  # replace ${WHERE} macro
    or $query_text .= ' ' . $p->{where};      # ... or simply append it

  # prepare parameters metadata
  my @params = map {
    my $t = $self->data_type_to_local($_->{remote_type});
    my $sub_name = $_->{conv_to_remote};
    {
      name      => $_->{column_name},
      data_type => $t->{standard_type}, # standard type code
      conv_to_remote_coderef => $self->resolve_converter_method($sub_name),
    }
  } @{$q->params};

  # prepare result conversion (by field name)
  my %result_conv = map {
    $_->{column_name} => $self->resolve_converter_method( $_->{conv_to_local} )
  } grep { $_->{conv_to_local} } $a->columns->metadata;

  return {
    sth         => $self->adapter->prepare_cached($query_text),
    params      => \@params,
    result_conv => \%result_conv,
    returns_set => ($a->can('returns_set') ? $a->returns_set : 1), # return set by default
  };
};


sub remote_statement_bind_and_execute {
  my ($self, $st, $param_values) = @_;

  # typed binding ~2x times slower than untyped
  my $typed = $self->adapter->require_parameter_type;

  my $i = 0;
  for my $v (@{$param_values}) {
    my $m = $st->{params}->[$i++];

    my $sub = $m->{conv_to_remote_coderef};
    $sub->($self->adapter, $v) if $sub; # conversion

    if ($typed) {
      my $type_code = $m->{data_type}; # SQL Standard type code
      if (defined $type_code) {
        $st->{sth}->bind_param($i, $v, {TYPE=>$type_code});
        trace_msg('INFO', "Bind[$i/$type_code]: " . (defined $v ? $v : 'NULL')) if trace_level >= 3;
      } else {
        $st->{sth}->bind_param($i, $v);
        trace_msg('INFO', "Bind[$i]: " . (defined $v ? $v : 'NULL')) if trace_level >= 3;
      }
    }
  }

  if ($typed) {
    $st->{sth}->execute;
  } else {
    $st->{sth}->execute(@{$param_values});
  }
}


# cache to the session end
memoize 'remote_statement_prepare_cached';


# store session-level filter for SELECT remote data, by object_id
has 'query_session_filter' => (is=>'ro', isa=>'HashRef', default=>sub{{}} );


method remote_accessor_query => named (
  object_id    => { isa=>'Int', required=>1 },
  where        => { isa=>'Str', required=>0, default=>'' },
  param_values => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[] },
  param_types  => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[] },
) => sub {
  my ($self, $p) = @_;

  # use session filter, if there is no user-supplied params and WHERE-clause
  unless ($p->{where} || @{$p->{param_values}}) {
    my $f = $self->query_session_filter->{$p->{object_id}};
    $p = $f if $f;
  }

  my $a = $self->load_accessor_cached($p->{object_id});

  my $st = $self->remote_statement_prepare_cached(
    accessor => $a,
    action   => 'S', 
    where    => $p->{where},
  );

  trace_msg('INFO', "QUERY to " . $a->remote_object_quoted) if trace_level >= 2;
  # -------------------------------------------------------
  if (@{$p->{param_types}}) {
    $self->_bind_user_params( $st->{sth}, $p->{param_values}, $p->{param_types} );
    $st->{sth}->execute;
  } else {
    $self->remote_statement_bind_and_execute( $st, $p->{param_values} );
  }
  # -------------------------------------------------------

  if ($st->{returns_set}) {
    # return setof record
    while (my $row = $st->{sth}->fetchrow_hashref) {
      # convert resultset values by column name
      while (my ($col, $sub) = each %{$st->{result_conv}}) {
        $sub->( $self->adapter, $row->{$col} );
      }
      # pipe row to PostgreSQL
      main::return_next(\%{$row});
    }
    $st->{sth}->finish;
    return undef;
  } else {
    # return scalar
    my $result = $st->{sth}->fetchrow_array;
    my (undef, $sub) = each %{$st->{result_conv}}; # only one
    $sub->($result) if $sub;
    $st->{sth}->finish;
    return $result;
  }
};


method set_query_session_filter => named (
  object_id    => { isa=>'Int', required=>1 },
  where        => { isa=>'Str', required=>0, default=>'' },
  param_values => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[] },
  param_types  => { isa=>'PostgreSQLArray', required=>0, coerce=>1, default=>[] },
) => sub {
  my ($self, $p) = @_;
  $self->query_session_filter->{$p->{object_id}} = $p;
};


method reset_query_session_filter => named (
  object_id    => { isa=>'Int', required=>1 },
) => sub {
  my ($self, $p) = @_;
  delete $self->query_session_filter->{$p->{object_id}};
};



# nested operation on remote table is not allowed
has 'shadow_transaction' => (is=>'rw', isa=>'Bool',default=>0);
has 'shadow_row_counter' => (is=>'rw', isa=>'Int', default=>0);


method shadow_statement_trigger => named (
  object_id    => { isa=>'Int', required=>1 },
  trigger_data => { isa => 'HashRef', required => 1 },
) => sub {
  my ($self, $p) = @_;

  trace_msg('INFO', Data::Dumper->Dump([$p->{trigger_data}], ['statement trigger'])) 
    if trace_level >= 4;

  my $a = $self->load_accessor_cached($p->{object_id})
    or confess "Could not load accessor by id $p->{object_id}";

  if ($p->{trigger_data}->{when} eq 'BEFORE') {
    # start transaction before remote DMLs

    # in statement-trigger we don't know what kind of operation performing
    trace_msg('INFO', "Modification of " . $a->remote_object_quoted) if trace_level >= 2;

    my $transaction = $self->adapter->are_transactions_supported 
                   && !$self->adapter->is_transaction_active;
    if ($transaction) {
      trace_msg('INFO', "Begin remote transaction") if trace_level >= 2;
      $self->adapter->begin_work;
    }
    # WARNING: no reliable rollback in case of local error, transaction stall until session end
    $self->shadow_transaction($transaction);
    $self->shadow_row_counter(0);

  } else { # AFTER
    #commit transaction

    $self->{shadow_row_counter} = '<unknown>' if $self->{shadow_row_counter} == -1;
    trace_msg('INFO', "$self->{shadow_row_counter} row(s) of " . $a->remote_object_quoted ." proceeded") 
      if trace_level >= 1;
    if ($self->shadow_transaction) {
      trace_msg('INFO', "Commit remote transaction") if trace_level >= 2;
      $self->adapter->commit;
    }
    $self->shadow_transaction(0);

  }
  return undef; # return value of statement-level trigger is always ignored
};


method shadow_row_trigger => named (
  object_id    => { isa=>'Int', required=>1 },
  trigger_data => { isa => 'HashRef', required => 1 },
) => sub {
  my ($self, $p) = @_;

  trace_msg('INFO', Data::Dumper->Dump([$p->{trigger_data}], ['row trigger'])) 
    if trace_level >= 4;

  my $action = $p->{trigger_data}->{new}->{action};

  my $a;

  # rollback on *every* remote error and *some* local errors
  eval {

     $a = $self->load_accessor_cached($p->{object_id})
      or confess "Could not load accessor by id $p->{object_id}";

    # get prepared statement handle and parameter list
    my $st = $self->remote_statement_prepare_cached(
      accessor => $a,
      action   => $action,
    );

    # get values inserted to shadow table
    my @param_values = map { $p->{trigger_data}->{new}->{$_->{name}} } @{$st->{params}};

    trace_msg('INFO', "EXECUTE:\n" . $st->{sth}->sth->{Statement})
      if trace_level >= 3;

    # -----------------------------------------------------------------
    my $rc = $self->remote_statement_bind_and_execute( $st, \@param_values );
    # -----------------------------------------------------------------
    if ($self->{shadow_row_counter} >= 0) {
      if ($rc == -1) {
        $self->{shadow_row_counter} = -1; # unknown
      } else {
        $self->{shadow_row_counter} += $rc
      }
    }
    $st->{sth}->finish;

  };
  if ($@) {
    if ($self->shadow_transaction) {
      trace_msg('INFO', "Rollback remote transaction") if trace_level >= 2;
      $self->adapter->rollback;
    }
    $self->shadow_transaction(0);
    trace_msg('ERROR', "Modification of remote " . $a->remote_object_type . " " . $a->remote_object_quoted . " failed: $@");
  }

  return 'SKIP';  # do nothing on shadow table
};



1;
