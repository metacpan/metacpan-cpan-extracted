use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL;

# karr k71 (review remainder).
#
# 1. A PRIMARY KEY is CLUSTERED in SQL Server unless written NONCLUSTERED, and
#    a table has one clustered index (Msg 1902). A declared clustered index on
#    a table with a primary key is refused before the server; on a table
#    without a primary key it stays valid. The refusal changes nothing for a
#    declaration the server accepted.
# 2. A string default on a numeric or bit type is refused (a literal where an
#    expression was meant, e.g. 'GETDATE()' -- fails only at the first INSERT).
# 3. Same for date/time types: measured live in t/99, the server takes any
#    string at CREATE TABLE there too and fails at the INSERT (Msg 22007/22018),
#    so a string that does not look like a date/time literal is refused.

my $n = 0;
sub ddl_of {
  my (%o) = @_;
  my $schema = 'K71Cl::S' . ++$n;
  my $cols = $o{columns} // q{id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }};
  my $pk = $o{pk} ? q{__PACKAGE__->set_primary_key('id');} : '';
  eval qq{
    package $schema; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
    package ${schema}::Result::T; use DBIO 'Core';
    __PACKAGE__->table('t');
    __PACKAGE__->add_columns($cols);
    $pk
    1;
  } or die $@;
  my $src = "${schema}::Result::T"->result_source_instance;
  $src->add_index_declaration($_) for @{ $o{idx} // [] };
  $schema->register_class(T => "${schema}::Result::T");
  my $ddl = eval { DBIO::MSSQL::DDL->install_ddl($schema) };
  return ($ddl, $@);
}

my $clust  = { name => 'c1', columns => ['name'], driver => { mssql => { kind => 'clustered' } } };
my $clust2 = { name => 'c2', columns => ['id'],   driver => { mssql => { kind => 'clustered' } } };
my $nonc   = { name => 'n1', columns => ['name'], driver => { mssql => { kind => 'nonclustered' } } };

{
  my ($ddl, $err) = ddl_of(pk => 1, idx => [$clust]);
  like $err, qr/refus/, 'clustered index + primary key: refused';
  like $err, qr/'c1'/, '... naming the index';
  like $err, qr/table 't'/, '... and the table';
  like $err, qr/1902/, '... with the server error it prevents';
  ok !defined $ddl, '... and no DDL is returned';
}
{
  my ($ddl, $err) = ddl_of(pk => 0, idx => [$clust]);
  is $err, '', 'clustered index on a table without primary key: valid';
  like $ddl, qr/CREATE CLUSTERED INDEX c1 ON t \(name\);/, '... written';
}
{
  my ($ddl, $err) = ddl_of(pk => 1, idx => [$nonc]);
  is $err, '', 'primary key + nonclustered index: valid';
  like $ddl, qr/CREATE NONCLUSTERED INDEX n1/, '... written';
  like $ddl, qr/PRIMARY KEY \(id\)/, '... key unchanged (still the default CLUSTERED, not rewritten)';
  unlike $ddl, qr/PRIMARY KEY NONCLUSTERED/, '... never rewritten into NONCLUSTERED';
}
{
  my ($ddl, $err) = ddl_of(pk => 0, idx => [$clust, $clust2]);
  like $err, qr/refus.*'c2'.*t|refus.*second clustered/s, 'two clustered indexes on one table: refused';
}

# string defaults
my $numcols = sub {
  my ($type, $dv) = @_;
  return qq{id => { data_type => 'integer' }, v => { data_type => '$type', default_value => $dv }};
};
for my $type (qw(integer int bigint smallint tinyint numeric decimal float real money smallmoney boolean bit)) {
  my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->($type, q{'abc'}));
  like $err, qr/column 'v' of table 't' is refused/, "string default 'abc' on $type: refused, naming column and table"
    or diag $ddl;
  like $err, qr/\\'expr'|scalar reference/, '... and the way out' if $type eq 'integer';
}
{
  my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('integer', q{'GETDATE()'}));
  like $err, qr/GETDATE/, "'GETDATE()' on an int is refused";
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('integer', q{\\'7 + 1'}));
  is $err, '', 'a scalar reference on an int stays an expression';
  like $ddl, qr/DEFAULT 7 \+ 1/, '... written as it is';
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('integer', 5));
  is $err, '', 'a number on an int is valid';
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('numeric', q{'-1.50'}));
  is $err, '', 'a numeric string on a numeric type is valid';
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('bit', q{'1'}));
  is $err, '', "'1' on a bit is valid";
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('varchar', q{'abc'}));
  is $err, '', 'a string on a varchar is valid';
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('datetime', q{'2020-01-01'}));
  is $err, '', 'a date string on datetime is not refused';
  like $ddl, qr/DEFAULT '2020-01-01'/, '... written as a literal';
}

# date/time types (t/99: the server fails only at the INSERT)
for my $type (qw(datetime timestamp datetime2 smalldatetime date time datetimeoffset timestamptz)) {
  for my $dv (q{'abc'}, q{'GETDATE()'}, q{'CURRENT_TIMESTAMP'}) {
    my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->($type, $dv));
    ok ref $err ? 1 : length $err, "$dv on $type: refused" or diag $ddl;
    like "$err", qr/column 'v' of table 't' is refused/, '... naming column and table';
    isa_ok $err, 'DBIO::Exception';
    like "$err", qr/scalar reference/, '... and the way out';
  }
  my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->($type, q{\\'GETDATE()'}));
  is "$err", '', "a scalar reference on $type stays an expression";
  like $ddl, qr/DEFAULT GETDATE\(\)/, '... written as it is';
}
for my $c ([datetime => '2020-01-01'], [datetime => '2020-01-01 12:30:00.123'],
           [datetime2 => '2020-01-01T12:30:00'], [date => '2020-01-01'],
           [time => '12:30'], [time => '12:30:15.5'],
           [datetime => '12:30'], [datetimeoffset => '2020-01-01 12:00:00 +02:00']) {
  my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->($c->[0], "'$c->[1]'"));
  is "$err", '', "'$c->[1]' on $c->[0]: valid";
  like $ddl, qr/DEFAULT '\Q$c->[1]\E'/, '... written as a literal';
}
{
  my ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('date', q{'12:30'}));
  like "$err", qr/refus/, 'a time on a date: refused';
  ($ddl, $err) = ddl_of(pk => 1, columns => $numcols->('time', q{'2020-01-01'}));
  like "$err", qr/refus/, 'a date on a time: refused';
}

done_testing;
