package DBIx::PgLink::Adapter::SQLServer;

# common ancestor of Sybase ASE and Microsoft SQL Server

use Carp;
use Moose;
use MooseX::Method;
use Data::Dumper;
use DBIx::PgLink::Logger;

extends 'DBIx::PgLink::Adapter';

has '+are_transactions_supported' => (default=>1);
has '+are_routines_supported'     => (default=>1);
has '+include_catalog_to_qualified_name' => (default=>1);


sub current_database {
  my $self = shift;
  return $self->selectrow_array('SELECT db_name()');
}

sub current_user {
  my $self = shift;
  return $self->selectrow_array('SELECT user_name()');
}


method 'format_routine_call' => named(
  catalog      => {isa=>'StrNull',required=>0},
  schema       => {isa=>'StrNull',required=>0},
  routine      => {isa=>'Str',required=>1},
  routine_type => {isa=>'Str',required=>1},
  returns_set  => {isa=>'Str',required=>0},
  arguments    => {isa=>'ArrayRef',required=>0, default=>[]},
) => sub {
  my ($self, $p) = @_;

  if ($p->{routine_type} eq 'PROCEDURE') {
    return 'EXEC '
      . $self->quote_identifier($p->{catalog}, $p->{schema}, $p->{routine}) 
      . ' ' . join( ',', map { "$_->{arg_name}=?" } @{$p->{arguments}} );
  } else {
    return $self->SUPER::format_routine_call($p);
  }
};


around 'expand_column_info' => sub { 
  my ($next, $self, $info) = @_;
  # unnamed column in procedure resultset (not a valid identifier)
  if ($info->{COLUMN_NAME} eq '') { 
    $info->{COLUMN_NAME} = "COLUMN" . $info->{ORDINAL_POSITION};
  }
  $next->($self, $info);
};
	

around 'routine_argument_info_arrayref' => sub { 
  my ($next, $self, $routine_info) = @_;

  my @result = ();

  my $full_proc_name = $self->quote_identifier(
    $routine_info->{SPECIFIC_CATALOG},
    'dbo',
    'sp_sproc_columns'
  );
  
  my $sth = $self->prepare("EXEC $full_proc_name ?,?,?");
  $sth->execute( # name in reverse order
    $routine_info->{SPECIFIC_NAME},
    $routine_info->{SPECIFIC_SCHEMA},
    $routine_info->{SPECIFIC_CATALOG},
  );

  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_routine_argument_info($i)
    and push @result, $i;
  }
  $sth->finish;

  return \@result;

};


around 'expand_routine_argument_info' => sub {
  my ($next, $self, $arg) = @_;

  # skip procedure result
  return 0 if $arg->{ORDINAL_POSITION} <= 0;

  $next->($self, $arg);
};


around 'routine_column_info_arrayref' => sub { 
  my ($next, $self, $info) = @_;

  if ($info->{ROUTINE_TYPE} eq 'PROCEDURE') {

    my @result = ();

    # the only way to get column list of procedure resultset 
    # is procedure execution in FMTONLY mode with NULL parameters.
    # but procedure can do parameter check and return error rather than resultset
    # also, procedure can return different resultset structure for different arguments

    my $full_name= $self->quote_identifier(
      $info->{SPECIFIC_CATALOG},
      $info->{SPECIFIC_SCHEMA},
      $info->{SPECIFIC_NAME},
    );
    my $exec_proc = "EXEC $full_name " 
      . join(",", $self->dummy_procedure_call_arguments($info));
    trace_msg('INFO', $exec_proc) if trace_level >= 3;

    $self->dbh->type_info(0); # required for column_info_from_statement_arrayref()
    eval {
      $self->do('SET FMTONLY ON');
      my $sth = $self->prepare($exec_proc);
      $sth->execute;
      my $rows = $self->column_info_from_statement_arrayref(
        $info->{SPECIFIC_CATALOG},
        $info->{SPECIFIC_SCHEMA},
        $info->{SPECIFIC_NAME},
        $sth
      );
      $sth->finish;
      for my $ci (@{$rows}) {
        $self->expand_column_info($ci)
        and push @result, $ci;
      }
    };
    my $err = $@;
    $self->do('SET FMTONLY OFF');

    if ($err || !@result) {
      die "Cannot detect resultset of stored procedure $full_name: $err";
    }

    return \@result;

  } else {
    return $next->($self, $info); # generic Adapter use INFORMATION_SCHEMA.ROUTINE_COLUMNS
  }
};


sub dummy_procedure_call_arguments {
  my ($self, $info) = @_;
  # can get more reliable result if sp_sproc_columns returns parameter default, but it is not
  # THOUGHT: procedure text parsing for parameter defaults (syscomments)
  return map { 'NULL' } @{$self->routine_argument_info_arrayref($info)};
}


1;
