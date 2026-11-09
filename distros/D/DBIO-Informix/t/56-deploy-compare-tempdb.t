use strict;
use warnings;
use Test::More;

# Offline, no Informix server. The compare deploy builds the desired schema in
# a throwaway database (karr k21): this test records every statement of every
# connection the build opens and asserts that
#   - CREATE DATABASE ... WITH LOG and the drop run on a connection that is
#     connected to no database, never on the live handle,
#   - the compare DDL (table, unique index, view, bare and quoted names) is
#     sent to a connection to the throwaway database, and that DSN is not the
#     live one,
#   - the live handle receives no statement at all,
#   - the throwaway database is dropped when the deploy dies, too.

use DBI;
use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;

my %conn;        # dsn => recorder
my @order;       # dsns in connect order
my $fail_on;     # statement pattern the recorders die on

{
  package T::Rec;
  sub new { bless { sql => [], dsn => $_[1] }, $_[0] }
  sub do {
    my ($s, $sql) = @_;
    push @{ $s->{sql} }, $sql;
    die "forced failure: $sql\n" if $fail_on && $sql =~ $fail_on;
    1;
  }
  sub disconnect { 1 }
}

{
  package T::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 20, is_unique => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::Quoted;
  use base 'DBIO::Core';
  __PACKAGE__->table('order item');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer' },
    part_no    => { data_type => 'varchar', size => 20, is_unique => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::View;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('my view');
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM plain');
  __PACKAGE__->add_columns('id' => { data_type => 'integer' });

  package T::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('DBIO::Informix::Storage');
  __PACKAGE__->register_class(Plain => 'T::Plain');
  __PACKAGE__->register_class(Quoted => 'T::Quoted');
  __PACKAGE__->register_class(View => 'T::View');

  package T::Deploy;
  use base 'DBIO::Informix::Deploy';
  # the live handle: a recorder, kept in %conn under the live DSN
  sub _dbh { $conn{'dbi:Informix:livedb@srv'} }
}

no warnings qw(redefine once);
local *DBI::connect = sub {
  my ($class, $dsn) = @_;
  push @order, $dsn;
  return $conn{$dsn} = T::Rec->new($dsn);
};
local *DBIO::Informix::Introspect::new   = sub { bless {}, 'DBIO::Informix::Introspect' };
local *DBIO::Informix::Introspect::model = sub { { introspected => 1 } };

sub run_build {
  %conn = (); @order = ();
  $conn{'dbi:Informix:livedb@srv'} = T::Rec->new('dbi:Informix:livedb@srv');
  my $schema = T::Schema->connect('dbi:Informix:livedb@srv', 'u', 'p');
  my $d = T::Deploy->new(schema => $schema);
  my $model = eval { $d->_build_target_model };
  return ($model, $@);
}

my ($model, $err) = run_build();
is($err, '', 'build lives');
is_deeply($model, { introspected => 1 }, 'the introspected model of the throwaway database');

my $live = $conn{'dbi:Informix:livedb@srv'};
is_deeply($live->{sql}, [], 'the live handle receives no statement') or diag explain $live->{sql};

# Since the storage declares transactional DDL (karr k23), core's
# _execute_ddl asks whether the storage owns the handle it was given, and that
# question reaches the live storage's handle (storage->dbh), which this mock
# had never opened: a connect to the live DSN, after the other two. It carries
# no statement (asserted above); it is the live connection a real storage
# already holds.
is(scalar(grep { $_ ne 'dbi:Informix:livedb@srv' } @order), 2,
  'two connections: the admin one and the one to the throwaway database');
my ($admin_dsn, $temp_dsn) = @order;
is($admin_dsn, 'dbi:Informix:@srv', 'admin connection: the server, no database');
like($temp_dsn, qr/\Adbi:Informix:_dbio_tmp_\d+_\d+\@srv\z/, 'DDL connection: the throwaway database on the same server');
isnt($temp_dsn, 'dbi:Informix:livedb@srv', 'not the live DSN');

my @admin = @{ $conn{$admin_dsn}{sql} };
my ($name) = $temp_dsn =~ /:(_dbio_tmp_\d+_\d+)\@/;
is_deeply(\@admin, [ "CREATE DATABASE $name WITH LOG", 'CLOSE DATABASE', "DROP DATABASE $name" ],
  'admin connection: create with log, close, drop') or diag explain \@admin;

my @sql = @{ $conn{$temp_dsn}{sql} };
is(scalar @sql, 5, 'two tables, two unique indexes, one view') or diag explain \@sql;
for my $s (@sql) {
  like($s, qr/^CREATE (?:TABLE|UNIQUE INDEX|VIEW) (?:"[^"]+"|\w+)[ (]/,
    'created object has a plain name, no owner and no database: ' . substr($s, 0, 40));
  unlike($s, qr/^CREATE (?:TABLE|UNIQUE INDEX|VIEW) \S*[.:]/, 'no qualifier on the created object');
}
ok((grep { /^CREATE TABLE "order item"/ } @sql), 'quoted table');
ok((grep { /^CREATE UNIQUE INDEX "order item_part_no" ON "order item" \(part_no\)/ } @sql), 'quoted unique index');
ok((grep { /^CREATE VIEW "my view" AS SELECT id FROM plain/ } @sql), 'view, body as the user wrote it');

# the throwaway database is dropped when the deploy dies, and the error stays
$fail_on = qr/^CREATE VIEW/;
($model, $err) = run_build();
like($err, qr/forced failure: CREATE VIEW/, 'the deploy error is raised');
($admin_dsn, $temp_dsn) = @order;
is($conn{$admin_dsn}{sql}[-1] =~ /^DROP DATABASE _dbio_tmp_/ ? 1 : 0, 1, 'the throwaway database is dropped after a failed deploy')
  or diag explain $conn{$admin_dsn}{sql};
is_deeply($conn{'dbi:Informix:livedb@srv'}{sql}, [], 'still nothing on the live handle');
$fail_on = undef;

# no database to derive from
{
  my $schema = T::Schema->connect('dbi:Informix:database=x', 'u', 'p');
  my $d = T::Deploy->new(schema => $schema);
  %conn = (); @order = ();
  eval { $d->_build_target_model };
  like($@, qr/expected dbi:Informix:database\[\@server\]/, 'an unsupported DSN form is refused');
  is(scalar @order, 0, 'and nothing is connected');
}

done_testing;
