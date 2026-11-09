package DBIO::ClickHouse::Test;
# ABSTRACT: ClickHouse-specific test utilities for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::ClickHouse::Test::Schema;
use DBIO::ClickHouse::Deploy;
use DBIO::ClickHouse::DDL::Emit qw(create_database drop_database);
use DBI;
use Carp;
use DBIO::Util qw(mask_connect_secrets);

# Test databases created by init_schema, dropped in END.
our @CLEANUP;


sub import {
  my $self = shift;
  if (@_) {
    my $caller = caller;
    for my $exp (@_) {
      if ($exp eq ':DiffSQL') {
        require DBIO::SQLMaker;
        require SQL::Abstract::Test;
        for (qw(is_same_sql_bind is_same_sql is_same_bind)) {
          no strict 'refs';
          *{"${caller}::$_"} = \&{"SQL::Abstract::Test::$_"};
        }
      }
      elsif ($exp eq ':GlobalLock') {
        # no-op, parallel to DBIO::SQLite::Test / DBIO::DuckDB::Test
      }
      else {
        croak "Unknown export $exp requested from $self";
      }
    }
  }
}

# The keys init_schema understands itself. They must not leak into the DBI
# connect attributes: DBD::MariaDB rejects an attribute name it does not know,
# so a stray no_populate => 1 would fail the connection rather than the deploy.
my %CONTROL_ARG = map { $_ => 1 } qw(
  no_deploy no_populate schema_class
);


sub _database {
  my $self = shift;
  my %args = @_;

  delete @args{ grep { $CONTROL_ARG{$_} } keys %args };

  my $dsn = $ENV{DBIO_TEST_CLICKHOUSE_DSN}
    or croak
      'DBIO::ClickHouse::Test requires DBIO_TEST_CLICKHOUSE_DSN: '
    . 'ClickHouse has no embedded/in-memory mode, so a running ClickHouse '
    . 'server (MySQL wire protocol, port 9004) is needed. Set '
    . 'DBIO_TEST_CLICKHOUSE_DSN (plus optional _DBUSER / _DBPASS), e.g. '
    . q{dbi:MariaDB:database=default;host=127.0.0.1;port=9004};

  my %opts = ( AutoCommit => 1, RaiseError => 1, PrintError => 0, %args );

  # DBD::mysql hands back character data as bytes unless the connection asks it
  # to decode (DBD::MariaDB decodes unconditionally), and the fixture and its
  # assertions assume decoded Unicode -- the same contract both transports are
  # documented with. mysql_enable_utf8mb4 is a mysql-only attribute; it must
  # not leak into a MariaDB connection, which rejects attributes it does not
  # know. See docs/adr/0001-mysql-wire-protocol-transport.md.
  $opts{mysql_enable_utf8mb4} = 1 if $dsn =~ /^dbi:mysql:/i;

  return (
    $dsn,
    (map { $ENV{"DBIO_TEST_CLICKHOUSE_${_}"} // '' } qw/DBUSER DBPASS/),
    \%opts,
  );
}


sub test_database { 'dbio_ch_test_' . $$ }


sub test_connect_info {
  my $self = shift;
  my ($dsn, $user, $pass, $opts) = $self->_database(@_);
  return ($self->_dsn_for_database($dsn, $self->test_database), $user, $pass, $opts);
}


sub init_schema {
  my $self = shift;
  my %args = @_;

  my ($admin_dsn, $user, $pass) = $self->_database(%args);
  my ($dsn, undef, undef, $opts) = $self->test_connect_info(%args);

  my $database = $self->test_database;
  my $admin    = $self->_admin_dbh($admin_dsn, $user, $pass);

  # Drop first: a same-PID leftover from an aborted run would otherwise turn
  # every CREATE TABLE below into "table already exists".
  $admin->do(drop_database(name => $database, if_exists => 1));
  $admin->do(create_database(name => $database));

  # Registered on the statement after the CREATE, not after the connect: from
  # here on there is a database that has to be dropped no matter what fails.
  my $cleanup = _register_cleanup($admin, $database);

  my $schema_class = $args{schema_class} // 'DBIO::ClickHouse::Test::Schema';
  my $schema       = $schema_class->clone;
  $schema->storage_type('+DBIO::ClickHouse::Storage');
  $schema = $schema->connect($dsn, $user, $pass, $opts);

  # So the END block can close the connection before dropping what it points at.
  $cleanup->{schema} = $schema;

  unless ($args{no_deploy}) {
    DBIO::ClickHouse::Deploy->new(schema => $schema)->install;
    $self->populate_schema($schema)
      unless $args{no_populate} || $args{schema_class};
  }

  return $schema;
}


sub populate_schema {
  my ($self, $schema) = @_;

  $schema->resultset('Snapshot')->populate([
    { id => 1, label => 'alpha', version => 1 },
    { id => 2, label => 'beta',  version => 1 },
    { id => 3, label => 'gamma', version => 1 }
  ]);

  $schema->resultset('Hit')->populate([
    { url => '/a', hits => 1,   snapshot => 1, ts => '2024-01-01 00:00:00.000' },
    { url => '/b', hits => 10,  snapshot => 1, ts => '2024-01-02 00:00:00.000' },
    { url => '/c', hits => 100, snapshot => 2, ts => '2024-02-01 00:00:00.000' },
    { url => '/d', hits => 150, snapshot => 2, ts => '2024-02-02 00:00:00.000' },
    { url => '/e', hits => 200, snapshot => 3, ts => '2024-03-01 00:00:00.000' },
    { url => '/f', hits => 250, snapshot => 3, ts => undef }
  ]);

  $schema->resultset('Reading')->populate([
    { sensor => 'a', ts => '2024-01-01 06:00:00.000', day => '2024-01-01', value => 1.5 },
    { sensor => 'a', ts => '2024-02-01 06:00:00.000', day => '2024-02-01', value => 2.5 },
    { sensor => 'b', ts => '2024-01-01 06:00:00.000', day => '2024-01-01', value => 3.5 },
    { sensor => 'b', ts => '2024-02-01 06:00:00.000', day => '2024-02-01', value => 4.5 }
  ]);

  $schema->resultset('Unsorted')->populate([
    { foo => 1, bar => 'one' },
    { foo => 2, bar => 'two' }
  ]);

  $schema->resultset('Probe')->populate([ $self->probe_row ]);
}


sub probe_row {
  return {
    id  => 1,
    i8  => -128,
    i16 => -32768,
    i64 => '-9223372036854775808',
    u32 => 4294967295,
    u64 => '18446744073709551615',

    f32    => 1.5,
    f64    => 2.25,
    dec    => '12345678.90',
    amount => '999999999999999.1234',

    s_var  => 'varchar value',
    s_text => 'text value',
    s_blob => 'blob value',
    s_json => '{"a":1}',

    s_fixed    => 'ab',
    s_low      => 'low',
    s_low_null => undef,

    flag => 1,
    guid => '11111111-2222-4333-8444-555555555555',
    ip   => '10.0.0.1',

    d_wide   => '1900-01-01',
    d_narrow => '2024-05-06',
    ts_ms    => '2024-05-06 07:08:09.123',
    ts_sec   => '2024-05-06 07:08:09',
    ts_utc   => '2024-05-06 07:08:09.456',
    t_str    => '07:08:09',

    state => q{it's},

    tags => \q{['x', 'y']},
    nums => \q{[1, 2, 3]},

    note    => undef,
    title   => 'given',
    counter => 7
  };
}

# --- cleanup -----------------------------------------------------------------

# The admin handle is a SECOND connection, to the database named in the DSN,
# and it is kept alive on purpose: the END block needs a handle that is not
# pointed at the database it is about to drop, and reconnecting at END time
# (during interpreter shutdown, possibly after a die) is exactly where a
# cleanup silently fails to happen.
sub _admin_dbh {
  my ($self, $dsn, $user, $pass) = @_;
  # DBI's own connect error carries the DSN (which may hold a password=) and
  # the driver's text may repeat the password: nothing leaves unmasked (k39).
  my $dbh = eval {
    DBI->connect($dsn, $user, $pass,
      { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  };
  unless ($dbh) {
    my $error = $@ || "Cannot connect to $dsn: " . ( $DBI::errstr // '' );
    croak mask_connect_secrets("$error", [ $dsn, $user, $pass ]);
  }
  return $dbh;
}

sub _dsn_for_database {
  my ($self, $dsn, $database) = @_;

  return "$dsn;database=$database" unless $dsn =~ /(?:database|dbname)=/i;

  $dsn =~ s/(database|dbname)=[^;]*/$1=$database/i;
  return $dsn;
}

sub _register_cleanup {
  my ($dbh, $database) = @_;
  my $job = {
    dbh => $dbh,
    sql => drop_database(name => $database, if_exists => 1)
  };
  push @CLEANUP, $job;
  return $job;
}

# Loud on failure, per the family rule: a cleanup that quietly did not happen
# leaves a database on a shared server and makes the NEXT run's failure look
# like a code bug.
END {
  for my $job (reverse @CLEANUP) {
    if (my $schema = $job->{schema}) {
      eval { $schema->storage->disconnect; 1 };
    }
    next if eval { $job->{dbh}->do($job->{sql}); 1 };
    warn "DBIO::ClickHouse::Test cleanup failed: $job->{sql}: $@";
  }
  @CLEANUP = ();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Test - ClickHouse-specific test utilities for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::ClickHouse::Test;

  # In a live test file:
  plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live tests'
    unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

  my $schema = DBIO::ClickHouse::Test->init_schema;
  my $rs = $schema->resultset('Hit');

=head1 DESCRIPTION

Test helpers for the L<DBIO::ClickHouse> driver distribution: driver tests call
C<< DBIO::ClickHouse::Test->init_schema >> and get a connected, deployed schema
backed by a live ClickHouse server.

Unlike embedded drivers, B<ClickHouse has no in-memory / C<:memory:> mode>, so
there is no zero-config default. Everything here is gated on
C<DBIO_TEST_CLICKHOUSE_DSN> (plus optional C<DBIO_TEST_CLICKHOUSE_DBUSER> /
C<DBIO_TEST_CLICKHOUSE_DBPASS>) and dies cleanly when it is unset. Live tests
should C<plan skip_all> on that env var themselves; the die is the backstop.

=head1 METHODS

=head2 _database

Returns C<($dsn, $user, $pass, \%opts)> for C<< $schema->connect() >>.
Requires C<DBIO_TEST_CLICKHOUSE_DSN>; ClickHouse has no embedded mode, so there
is no fallback DSN. C<DBIO_TEST_CLICKHOUSE_DBUSER> / C<DBIO_TEST_CLICKHOUSE_DBPASS>
default to the empty string. Croaks with a clear message when the DSN is unset.

Any extra arguments are merged into the connect attributes, minus the
L</init_schema> control keys.

When the DSN is a C<dbi:mysql:...> one, C<mysql_enable_utf8mb4 =E<gt> 1> is added
to the connect attributes, so the suite asserts against decoded Unicode on both
transports -- the contract L<DBD::mysql> is documented with and the one
L<DBD::MariaDB> enforces unconditionally. See C<docs/adr/0001>.

=head2 test_database

    my $name = DBIO::ClickHouse::Test->test_database;

The name of this process's test database, C<dbio_ch_test_E<lt>pidE<gt>>. See
L</EVERY TEST PROCESS GETS ITS OWN DATABASE>.

=head2 test_connect_info

    my ($dsn, $user, $pass, $opts) = DBIO::ClickHouse::Test->test_connect_info;
    my ($dsn, $user, $pass, $opts)
      = DBIO::ClickHouse::Test->test_connect_info(mutations_sync => 0);

L</_database>, with the DSN pointed at L</test_database> instead of at the
database the environment names. This is what a live test needs in order to open
a B<second> connection to the same schema -- a different C<mutations_sync>, a
different session setting -- without landing in a different database than
L</init_schema> deployed into.

=head2 init_schema

  my $schema = DBIO::ClickHouse::Test->init_schema(%opts);

Creates this process's test database, connects
L<DBIO::ClickHouse::Test::Schema> to it with C<+DBIO::ClickHouse::Storage>
pinned, deploys the schema and populates the fixture. Returns the connected
schema.

Options:

=over 4

=item * C<no_deploy> -- connect only; do not create any table.

=item * C<no_populate> -- deploy, but insert no fixture rows.

=item * C<schema_class> -- deploy a different schema class instead of
L<DBIO::ClickHouse::Test::Schema>, which is how a live file that needs one
table of its own shape still gets the per-process database and its cleanup.
Implies C<no_populate>: L</populate_schema> writes the standard fixture and has
no idea what another schema's sources are called.

=back

Anything else is passed through to C<< DBI->connect >> as a connect attribute,
which is how a test reaches connect-time driver options such as
C<< mutations_sync => 0 >>.

=head2 populate_schema

    DBIO::ClickHouse::Test->populate_schema($schema);

Writes the fixture L<DBIO::ClickHouse::Test::Schema> is designed around. Every
source is filled with one void-context C<populate>, i.e. one multi-row
C<INSERT> statement -- both because that is the only insert shape ClickHouse
actually wants (L<DBIO::ClickHouse::Storage/INSERTS AND BATCHING>) and because
it means the fixture itself exercises
L<DBIO::ClickHouse::SQLMaker/insert_multi> over every column type in the
schema.

C<Hit> rows deliberately omit the C<id> column, so the server-side
C<DEFAULT generateUUIDv4()> fills it -- the one path on which this driver lets
the database generate a key.

=head2 probe_row

    my $row = DBIO::ClickHouse::Test->probe_row;

The single fixture row for L<DBIO::ClickHouse::Test::Schema::Probe>, as a
hashref ready for C<populate>. It is a method rather than a literal in
L</populate_schema> so that C<t/18-types-live.t> can assert against the same
values without repeating them, which is the whole point: the assertions there
are about what the B<server> gave back, not about what the test typed twice.

Two cells are literal SQL. C<Array(T)> has no bind type on any MySQL-wire DBD
-- L<DBIO::ClickHouse::SQLMaker/insert_multi> throws on a bare arrayref rather
than guessing -- so an array value has to be written as ClickHouse array
syntax.

Values are chosen to be significant, not merely valid: C<d_wide> is before
1970 (the range C<Date32> exists for and C<Date> cannot hold), C<ts_ms> carries
milliseconds (the precision C<DateTime64(3)> exists for), and C<state> is the
enum member whose apostrophe has to survive the wire.

=head1 EVERY TEST PROCESS GETS ITS OWN DATABASE

L</init_schema> does B<not> deploy into the database named in the DSN. It
creates C<dbio_ch_test_E<lt>pidE<gt>>, connects the schema there, deploys into
it, and drops it again in an C<END> block. The DSN's own database is only ever
used to issue the C<CREATE> / C<DROP DATABASE> pair.

That is not tidiness, it is what makes two of the live assertions possible at
all:

=over 4

=item * B<The deploy round trip is a whole-database comparison.>
C<< $deploy->diff >> introspects C<currentDatabase()> and compares it against a
scratch database holding nothing but the schema. Any other table in the
database -- a leftover from an aborted run, an unrelated table someone created
on the shared server -- shows up as a C<DROP TABLE> the diff wants to perform,
and C<t/30-deploy.t>'s central assertion ("a freshly deployed schema has no
diff against itself") fails for a reason that has nothing to do with the code
under test.

=item * B<The suite has to survive being re-run.> A live file that dies
half-way leaves its tables behind. Scoping to a per-process database, and
dropping and recreating it at the start of each C<init_schema>, means the next
run starts from a known state instead of inheriting the previous failure.

=back

The cost is that the connecting user needs C<CREATE DATABASE> and
C<DROP DATABASE>. L<DBIO::ClickHouse::Deploy> already requires both for its
scratch database, so the live suite could not run without them anyway.

It also means a live file that creates a raw table of its own needs B<no>
cleanup of its own: the table is inside the per-process database and goes with
it. Do not write a C<DROP TABLE> on the last line of the file and call that
cleanup -- the last line is precisely what a failed assertion never reaches.

A database left behind by a process that was killed outright (C<kill -9>, an
OOM) is named C<dbio_ch_test_*> and is safe to drop by hand; the k8s workflow
in the C<dbio-clickhouse-database> skill deletes the whole pod at the end,
which takes them all with it.

=head2 Why this does not call DBIO::Test->init_schema

L<DBIO::Test/init_schema> is hardcoded to L<DBIO::Test::Schema> -- both the
class it clones and the fixture C<populate_schema> writes -- and that schema
cannot be deployed against ClickHouse in any useful sense. The reasons are
recorded in L<DBIO::ClickHouse::Test::Schema/WHY NOT DBIO::Test::Schema>; the
short version is that its integer C<is_auto_increment> primary keys are
precisely the identity model L<DBIO::ClickHouse::Storage/last_insert_id> exists
to refuse.

Deployment goes through L<DBIO::ClickHouse::Deploy/install> rather than
C<< $schema->deploy >> on purpose. C<DBIO::Storage::DBI::deploy> B<carps> on a
statement that fails and carries on, so a schema that only half deployed would
be reported as deployed and the failure would surface as a mystified assertion
three files later. C<install> runs the statements with C<RaiseError>, so a
rejected C<CREATE TABLE> stops the file where it happened.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Test::Schema> - the schema deployed here, and why it is not L<DBIO::Test::Schema>

=item * L<DBIO::ClickHouse::Deploy> - the deploy path used by L</init_schema>

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
