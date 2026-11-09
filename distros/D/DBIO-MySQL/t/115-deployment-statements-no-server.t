use strict;
use warnings;
use Test::More;

# OFFLINE test (karr k96 point 5): deployment_statements is core's reader of a
# DDL file on this storage. It asks no server and leaves the caller's
# \%sqlt_args alone.
#
# WHY: the override this storage used to carry read the server's version and
# wrote it into the caller's \%sqlt_args as producer_args.mysql_version -- an
# argument of the SQL::Translator producer core no longer has. Nothing read it,
# yet returning a DDL file from disk needed a connection for it: with the
# server out of reach the call died with "DBI Connection failed" where the
# file, or core's "requires a pre-existing DDL file", was due. The claims:
#   1. with a DDL file in $dir the call returns its contents;
#   2. without one it throws core's reason, not a failed connect;
#   3. neither opens a connection, and the \%sqlt_args passed is unchanged.
#
# THE SUBSTITUTION: DBI->connect counts its calls and dies.

use File::Temp ();
use DBI;
use DBIO::MySQL::Storage;

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
  package NoServer::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
NoServer::Schema->register_class(Widget => 'NoServer::Result::Widget');

my $connects = 0;
{
  no warnings 'redefine';
  *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };
}

my $FILE_DDL = "CREATE TABLE from_the_ddl_file (id int);\n";

sub ddl_dir {
  my ($schema, $with_file) = @_;
  my $dir = File::Temp::tempdir(CLEANUP => 1) . '/';
  if ($with_file) {
    my $file = $schema->ddl_filename('MySQL', '1.x', $dir);
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

for my $way (@WAYS) {
  my ($name, $call) = @$way;

  {
    my $schema   = NoServer::Schema->connect('dbi:mysql:database=appdb;host=db.example', 'app', 's3cret');
    my $dir      = ddl_dir($schema, 1);
    my %sqltargs = (add_drop_table => 1);
    $connects = 0;

    is scalar eval { $call->($schema, undef, undef, $dir, \%sqltargs) }, $FILE_DDL,
      "$name, a DDL file in \$dir: its contents"
      or diag $@;
    is $connects, 0, '... without a connection';
    is_deeply \%sqltargs, { add_drop_table => 1 }, '... and the \%sqlt_args passed is as it was';
  }

  {
    my $schema   = NoServer::Schema->connect('dbi:mysql:database=appdb;host=db.example', 'app', 's3cret');
    my $dir      = ddl_dir($schema, 0);
    my %sqltargs = (add_drop_table => 1);
    $connects = 0;

    my $ok  = eval { $call->($schema, undef, undef, $dir, \%sqltargs); 1 };
    my $err = $@;
    ok !$ok, "$name, no DDL file: throws";
    like $err, qr/requires a pre-existing DDL file/, q{... core's reason, not a failed connect};
    is $connects, 0, '... without a connection';
    is_deeply \%sqltargs, { add_drop_table => 1 }, '... and the \%sqlt_args passed is as it was';
  }
}

done_testing;
