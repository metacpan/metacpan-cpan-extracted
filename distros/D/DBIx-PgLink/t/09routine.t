use strict;
use Test::More tests=>11;
use Test::Deep;
use Data::Dumper;

use lib 't';
use PgLinkTestUtil;

use DBIx::PgLink::Adapter;
use DBIx::PgLink::Adapter::Pg;

{
  # generic implementation
  my $db = DBIx::PgLink::Adapter->new();

  $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {});

  my $sth = $db->routine_info('%', 'source', '%');

  ok($sth, 'routine_info');

  diag Dumper($sth->fetchall_arrayref({})) if $Trace_level>=2;
}


{
  # PostgreSQL
  my $db = DBIx::PgLink::Adapter::Pg->new();

  $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {});

  my $sth = $db->routine_info('%', 'source', '%', 'FUNCTION');

  ok($sth, 'routine_info');

  my $functions = $sth->fetchall_arrayref({});

  for my $f (@{$functions}) {
    diag "Routine: " . Dumper($f) if $Trace_level>=2;
    
    my $arg = $db->routine_argument_info_arrayref($f);
    diag "Arguments: " . Dumper($arg) if $Trace_level>=2;
    my $res = $db->routine_column_info_arrayref($f);
    diag "Result: " . Dumper($res) if $Trace_level>=2;

    if ($f->{SPECIFIC_NAME} eq 'get_scalar()') {  # no arguments, scalar result
      cmp_deeply($arg, [],  'arguments of get_scalar()');
      cmp_deeply($res, [
        {
          COLUMN_NAME      => 'RESULT',
          ORDINAL_POSITION => 1,
          TYPE_NAME        => 'integer',
          NULLABLE         => 'YES',
          base_type_name   => 'integer',
          native_type_name => 'integer',
          pg_type_id       => ignore(),
        }
      ], 'result of get_scalar()');

    } elsif ($f->{SPECIFIC_NAME} eq 'get_scalar(a integer, b text)') {  # 1 argument, scalar result
      cmp_deeply($arg, [
        {
         COLUMN_NAME      => 'a', 
         ORDINAL_POSITION => 1, 
         native_type_name => 'integer', 
         base_type_name   => 'integer', 
         pg_type_id       => ignore(),
        },
        {
         COLUMN_NAME      => 'b', 
         ORDINAL_POSITION =>2, 
         native_type_name =>'text', 
         base_type_name   =>'text', 
         pg_type_id       =>ignore(),
        },
      ],  'arguments of get_scalar(a integer, b text)');
      cmp_deeply($res, [
        {
          COLUMN_NAME      => 'RESULT',
          ORDINAL_POSITION => 1,
          TYPE_NAME        => 'integer',
          NULLABLE         => 'YES',
          base_type_name   => 'integer',
          native_type_name => 'integer',
          pg_type_id       => ignore(),
        }
      ], 'result of get_scalar(a integer, b text)');

    } elsif ($f->{SPECIFIC_NAME} eq 'get_row1(a source.domain2, b text)') {  # 2 arguments, 1 composite row result
      cmp_deeply($arg, [
        {
         COLUMN_NAME      => 'a', 
         ORDINAL_POSITION => 1, 
         native_type_name => 'source.domain2', 
         base_type_name   => 'integer', 
         pg_type_id       => ignore(),
        },
        {
         COLUMN_NAME      => 'b', 
         ORDINAL_POSITION =>2, 
         native_type_name =>'text', 
         base_type_name   =>'text', 
         pg_type_id       =>ignore(),
        },
      ],  'arguments of get_row1(a source.domain2, b text)');
      is(scalar(@$res), 3);
      { 
        my @r = @{$res->[0]}{qw/COLUMN_NAME TYPE_NAME native_type_name base_type_name/};
        is_deeply(\@r, [qw/id integer integer integer/]);
      }
      { 
        my @r = @{$res->[1]}{qw/COLUMN_NAME TYPE_NAME native_type_name base_type_name/};
        is_deeply(\@r, [qw/i integer integer integer/]);
      }
      { 
        my @r = @{$res->[2]}{qw/COLUMN_NAME TYPE_NAME native_type_name base_type_name/};
        is_deeply(\@r, [qw/t text text text/]);
      }
    }
  }
}

