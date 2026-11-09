use strict;
use warnings;
use Test::More;

# OFFLINE test: deployment_statements is the reader of a DDL file for every
# schema on this storage, asks no server and leaves the caller's arguments
# alone (karr k104, core ADR 0064).
#
# WHY: deployment_statements promises the contents of a DDL file in $dir and
# throws when there is none (core ADR 0006). Core ADR 0064, point 3, holds
# that for every driver, with or without a native deploy class -- so on this
# storage the answer does not depend on whether the schema loads the
# DBIO::PostgreSQL component. A caller who keeps .sql files gets his file
# either way, and install DDL has one name of its own, pg_install_ddl
# (DBIO::PostgreSQL::DDL->install_ddl).
#
# What the call costs was measured on this storage (karr k104): on the way to
# the file it read the server's version and wrote it into the caller's
# \%sqlt_args as producer_args.postgres_version, an argument of the
# SQL::Translator producer core does not have. Nothing read it, and
#   * reading a file from disk needed a connection: with the server out of
#     reach the DDL file was not returned, the call died with "DBI Connection
#     failed", and the same error stood in the place of core's "requires a
#     pre-existing DDL file" when there was none;
#   * the hash the caller passed came back with a producer_args key it had not
#     put there.
#
# What this file claims, for a schema WITHOUT the component and for one WITH
# it alike, of $schema->deployment_statements and
# $storage->deployment_statements:
#   1. with a DDL file in $dir they return its contents -- the file named for
#      the engine this storage is, PostgreSQL, where no $type is given;
#   2. without one, they throw core's reason, naming the DDL file;
#   3. neither opens a connection, and the \%sqlt_args passed is unchanged.
# And for the schema WITH the component:
#   4. its install DDL is what pg_install_ddl returns, the DDL of
#      DBIO::PostgreSQL::DDL->install_ddl, without a connection -- and that is
#      not what deployment_statements answers, DDL file or none.
#
# NOT CLAIMED: what $schema->deploy and $storage->deploy install. They go to
# the class dbio_deploy_class names and read no DDL file
# (t/128-storage-deploy-class.t, t/128-storage-deploy-class-live.t).
#
# THE SUBSTITUTION: DBI->connect counts its calls and dies. Everything else is
# core's and this dist's own code.

use File::Temp ();
use DBI;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::DDL;

{
  package NoServer::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # Does NOT load the PostgreSQL component: the shortcut declares the driver
  # and nothing else (a schema always has one, core ADR 0067).
  package NoServer::Plain;
  use DBIO 'Schema', -pg;
}
NoServer::Plain->register_class(Widget => 'NoServer::Result::Widget');
{
  package NoServer::Comp;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
NoServer::Comp->register_class(Widget => 'NoServer::Result::Widget');

my $connects = 0;
{
  no warnings 'redefine';
  *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };
}

my $FILE_DDL = "CREATE TABLE from_the_ddl_file (id integer);\n";

# A directory for the DDL file, with or without the file core looks for.
sub ddl_dir {
  my ($schema, $with_file) = @_;
  my $dir = File::Temp::tempdir(CLEANUP => 1) . '/';
  if ($with_file) {
    my $file = $schema->ddl_filename('PostgreSQL', '1.x', $dir);
    open my $fh, '>', $file or die "cannot write $file: $!";
    print {$fh} $FILE_DDL;
    close $fh;
  }
  return $dir;
}

my @WAYS = (
  [ '$schema->deployment_statements',
    sub { my ($schema, @args) = @_; $schema->deployment_statements(@args) } ],
  [ '$storage->deployment_statements',
    sub { my ($schema, @args) = @_; $schema->storage->deployment_statements($schema, @args) } ],
);

sub connected_schema {
  my ($class) = @_;
  return $class->connect('dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret');
}

# ---------------------------------------------------------------------------
# 1.-3. The reader of a DDL file, without the component and with it.
# ---------------------------------------------------------------------------

for my $case (
  [ 'NoServer::Plain', 'no component' ],
  [ 'NoServer::Comp',  'with the component' ],
) {
  my ($class, $label) = @$case;

  for my $way (@WAYS) {
    my ($name, $call) = @$way;

    {
      my $schema   = connected_schema($class);
      my $dir      = ddl_dir($schema, 1);
      my %sqltargs = (add_drop_table => 1);
      $connects = 0;

      is scalar eval { $call->($schema, undef, undef, $dir, \%sqltargs) }, $FILE_DDL,
        "$name, $label, a DDL file in \$dir: its contents"
        or diag $@;
      is $connects, 0, '... without a connection';
      is_deeply \%sqltargs, { add_drop_table => 1 }, '... and the \%sqlt_args passed is as it was';
      isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage', '... asked of the PostgreSQL storage: it';
    }

    {
      my $schema   = connected_schema($class);
      my $dir      = ddl_dir($schema, 0);
      my %sqltargs = (add_drop_table => 1);
      $connects = 0;

      my $ok  = eval { $call->($schema, undef, undef, $dir, \%sqltargs); 1 };
      my $err = $@;
      ok !$ok, "$name, $label, no DDL file: throws";
      like $err, qr/requires a pre-existing DDL file/, q{... core's reason, not a failed connect};
      is $connects, 0, '... without a connection';
      is_deeply \%sqltargs, { add_drop_table => 1 }, '... and the \%sqlt_args passed is as it was';
    }
  }
}

# ---------------------------------------------------------------------------
# 4. With the component: the install DDL is pg_install_ddl's.
# ---------------------------------------------------------------------------

{
  my $NATIVE = DBIO::PostgreSQL::DDL->install_ddl('NoServer::Comp');
  like $NATIVE, qr/^CREATE TABLE widget \(/m, 'the install DDL of the schema creates its table';
  isnt $NATIVE, $FILE_DDL, '... which the DDL file does not';

  my $schema = connected_schema('NoServer::Comp');
  $connects = 0;
  is scalar eval { $schema->pg_install_ddl }, $NATIVE,
    '$schema->pg_install_ddl, with the component: the install DDL'
    or diag $@;
  is $connects, 0, '... without a connection';
}

done_testing;
