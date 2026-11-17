use strict;
use warnings;
use Test::More;

# LIVE. Numbers make the round trip with their decimals in every NLS
# territory.
#
# CLAIM: a number goes to the server as text and comes back as text, both read
# and written with the NLS_NUMERIC_CHARACTERS of the session. Under a
# territory with a decimal comma (NLS_LANG=GERMAN_GERMANY.AL32UTF8) a bound
# 1.5 was refused with ORA-01722 (and a read value would have been "1,5").
# After: the connection sets '.,' for its session, so NUMBER, BINARY_DOUBLE and
# BINARY_FLOAT are bound and read with a point whatever the client says. A
# setting of the application (on_connect_do) runs after and wins.
#
# The client environment is read once when the OCI library starts, so the
# German and the comma-decimal rounds run in a child perl of their own with
# NLS_LANG / NLS_NUMERIC_CHARACTERS set; the parent checks the child passed.
# The table is T102_<pid>_<n>, made here and dropped at the end.

plan skip_all => 'DBIO_TEST_ORA_DSN not set (no Oracle to run against)'
  unless length($ENV{DBIO_TEST_ORA_DSN} // '') and eval { require DBD::Oracle; 1 };

my @connect = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
my @VALUES  = (1.5, 0.25, -12.375, 1234.5);
my @TABLES;
END {
  local $@;
  my $dbh = eval { DBI->connect(@connect, { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) } or return;
  eval { $dbh->do(qq{DROP TABLE "$_" PURGE}) } for @TABLES;
}

sub run_checks {
  my $table = shift;
  require DBI;
  my $dbh = DBI->connect(@connect, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $dbh->do(qq{CREATE TABLE "$table" ("id" NUMBER(10) NOT NULL PRIMARY KEY,
    "n" NUMBER(12,4), "d" BINARY_DOUBLE, "f" BINARY_FLOAT)});
  push @TABLES, $table;

  {
    package T102::Result;
    use base 'DBIO::Core';
  }
  {
    package T102::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Oracle');
  }
  T102::Result->table($table);
  T102::Result->add_columns(
    id => { data_type => 'integer' },
    n  => { data_type => 'numeric', size => [12, 4], is_nullable => 1 },
    d  => { data_type => 'double', is_nullable => 1 },
    f  => { data_type => 'float', is_nullable => 1 },
  );
  T102::Result->set_primary_key('id');
  T102::Schema->register_class(N => 'T102::Result');

  my $schema = T102::Schema->connect(@connect, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
  my $rs = $schema->resultset('N');

  my ($chars) = $schema->storage->dbh->selectrow_array(
    q{SELECT value FROM nls_session_parameters WHERE parameter = 'NLS_NUMERIC_CHARACTERS'});
  is $chars, '.,', 'the session has a decimal point and a group comma';

  my $id = 0;
  for my $v (@VALUES) {
    $id++;
    my $row = eval { $rs->create({ id => $id, n => $v, d => $v, f => $v }) };
    ok $row, "$v: bound into NUMBER, BINARY_DOUBLE and BINARY_FLOAT" or diag $@;
    my $got = $rs->find($id);
    cmp_ok $got->get_column($_) + 0, '==', $v, "$v: $_ read back" for qw(n d f);
    my ($raw) = $schema->storage->dbh->selectrow_array(
      qq{SELECT "n" FROM "$table" WHERE "id" = ?}, undef, $id);
    cmp_ok $raw + 0, '==', $v, "$v: NUMBER read as text numifies to the value";
    is scalar($rs->search({ n => $v })->count), 1, "$v: bound as a search condition";
  }

  my $own = T102::Schema->connect(@connect, { AutoCommit => 1, RaiseError => 1, PrintError => 0 },
    { on_connect_do => q{alter session set nls_numeric_characters = ',.'} });
  my ($mine) = $own->storage->dbh->selectrow_array(
    q{SELECT value FROM nls_session_parameters WHERE parameter = 'NLS_NUMERIC_CHARACTERS'});
  is $mine, ',.', 'an on_connect_do of the application wins over the default';
  $own->storage->disconnect;
  $schema->storage->disconnect;
  $dbh->disconnect;
}

if ($ENV{T102_CHILD}) {
  run_checks($ENV{T102_CHILD});
  done_testing;
  exit( Test::More->builder->is_passing ? 0 : 1 );
}

my $n = 0;
run_checks("T102_${$}_" . ++$n);

my @ROUNDS = (
  [ 'a German client (NLS_LANG)'                  => { NLS_LANG => 'GERMAN_GERMANY.AL32UTF8' } ],
  [ 'a client naming the decimal comma itself'    => { NLS_LANG => 'GERMAN_GERMANY.AL32UTF8', NLS_NUMERIC_CHARACTERS => ',.' } ],
  [ 'the decimal comma without a German NLS_LANG' => { NLS_NUMERIC_CHARACTERS => ',.' } ],
);
for my $r (@ROUNDS) {
  my ($name, $env) = @$r;
  my $table = "T102_${$}_" . ++$n;
  my $out = do {
    local @ENV{keys %$env} = values %$env;
    local $ENV{T102_CHILD} = $table;
    open my $fh, '-|', $^X, (map "-I$_", @INC), $0 or die "cannot run child: $!";
    local $/; <$fh>;
  };
  my $status = $?;
  my $planned = () = $out =~ /^(?:not )?ok /mg;
  ok $status == 0 && $planned && $out !~ /^not ok /m, "$name: every check passes"
    or diag $out;
}

done_testing;
