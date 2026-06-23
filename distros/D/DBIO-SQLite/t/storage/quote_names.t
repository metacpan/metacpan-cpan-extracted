use strict;
use warnings;
use Test::More;
use Data::Dumper::Concise;
use Try::Tiny;
use DBIO::SQLite::Test;

my %expected = (
  'DBIO::Storage::DBI'                    =>
      # no default quote_char
    {                             name_sep => '.' },

  'DBIO::MSSQL::Storage'                  =>
    { quote_char => [ '[', ']' ], name_sep => '.' },

  'DBIO::DB2::Storage'                    =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::Informix::Storage'               =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::Firebird::Storage::InterBase'    =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::MySQL::Storage'                  =>
    { quote_char => '`',          name_sep => '.' },

  'DBIO::PostgreSQL::Storage'             =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::Oracle::Storage'                 =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::SQLite::Storage'                 =>
    { quote_char => '"',          name_sep => '.' },

  'DBIO::Sybase::Storage::ASE'            =>
    { quote_char => [ '[', ']' ], name_sep => '.' },
);

for my $class (keys %expected) { SKIP: {
  eval "require ${class}"
    or skip "Skipping test of quotes for $class due to missing dependencies", 1;

  my $mapping = $expected{$class};
  my ($quote_char, $name_sep) = @$mapping{qw/quote_char name_sep/};
  my $instance = $class->new;

  my $quote_char_text = dumper($quote_char);

  if (exists $mapping->{quote_char}) {
    is_deeply $instance->sql_quote_char, $quote_char,
      "sql_quote_char for $class is $quote_char_text";
  }

  is $instance->sql_name_sep, $name_sep,
    "sql_name_sep for $class is '$name_sep'";
}}

# Try quote_names with available DBs.

# Env var to base class mapping, these are the DBs I actually have.
# the SQLITE is a fake memory dsn
local $ENV{DBIO_TEST_SQLITE_DSN} = 'dbi:SQLite::memory:';
my %dbs = (
  SQLITE           => 'DBIO::SQLite::Storage',
  ORA              => 'DBIO::Oracle::Storage',
  PG               => 'DBIO::PostgreSQL::Storage',
  MYSQL            => 'DBIO::MySQL::Storage',
  DB2              => 'DBIO::DB2::Storage',
  SYBASE           => 'DBIO::Sybase::Storage::ASE',
  FIREBIRD         => 'DBIO::Firebird::Storage::InterBase',
  FIREBIRD_ODBC    => 'DBIO::Firebird::Storage::InterBase',
  INFORMIX         => 'DBIO::Informix::Storage',
  MSSQL_ODBC       => 'DBIO::MSSQL::Storage',
);

# Make sure oracle is tried last - some clients (e.g. 10.2) have symbol
# clashes with libssl, and will segfault everything coming after them
for my $db (sort {
    $a eq 'ORA' ? 1
  : $b eq 'ORA' ? -1
  : $a cmp $b
} keys %dbs) {
  my ($dsn, $user, $pass) = map $ENV{"DBIO_TEST_${db}_$_"}, qw/DSN USER PASS/;

  next unless $dsn;

  my $schema;

  my $sql_maker = try {
    $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, {
      quote_names => 1
    });
    $schema->storage->ensure_connected;
    $schema->storage->sql_maker;
  } || next;

  my ($exp_quote_char, $exp_name_sep) =
    @{$expected{$dbs{$db}}}{qw/quote_char name_sep/};

  my ($quote_char_text, $name_sep_text) = map { dumper($_) }
    ($exp_quote_char, $exp_name_sep);

  is_deeply $sql_maker->quote_char,
    $exp_quote_char,
    "$db quote_char with quote_names => 1 is $quote_char_text";


  is $sql_maker->name_sep,
    $exp_name_sep,
    "$db name_sep with quote_names => 1 is $name_sep_text";

  # if something was produced - it better be quoted
  if (
    # the SQLT producer has no idea what quotes are :/
    ! grep { $db eq $_ } qw( SYBASE DB2 )
      and
    my $ddl = try { $schema->deployment_statements }
  ) {
    my $quoted_artist = $sql_maker->_quote('artist');

    like ($ddl, qr/^CREATE\s+TABLE\s+\Q$quoted_artist/msi, "$db DDL contains expected quoted table name");
  }
}

done_testing;

sub dumper {
  my $val = shift;

  my $dd = DumperObject;
  $dd->Indent(0);
  return $dd->Values([ $val ])->Dump;
}

1;
