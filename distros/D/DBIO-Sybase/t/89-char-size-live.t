use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Introspect;

# LIVE (karr k70, k52). The counterpart of the offline claims of
# t/45-ddl-util.t, asked of the server:
#
#   1. A column declared `character`, size 10, is char(10) in the catalog
#      (it was char(1): CHARACTER passed through without its size), and a
#      10-character value goes in and comes back whole. `char varying`,
#      size 20, is varchar(20).
#   2. `mediumtext` installs, as a text column.
#   3. A default of \'current_timestamp' installs (Msg 128 before) and the
#      default fills a row that leaves the column out.
#
# Runs in a database it creates and drops itself; needs a login allowed to
# CREATE DATABASE.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

{
  package T::K70::Result::Sensor;
  use base 'DBIO::Core';
  __PACKAGE__->table('k70_sensor');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    sensors => { data_type => 'character', size => 10 },
    label   => { data_type => 'char varying', size => 20, is_nullable => 1 },
    memo    => { data_type => 'mediumtext', is_nullable => 1 },
    stamp   => { data_type => 'timestamp', default_value => \'current_timestamp' },
  );
  __PACKAGE__->set_primary_key('id');

  package T::K70::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Sensor => 'T::K70::Result::Sensor');
}

my %attr = ( RaiseError => 1, PrintError => 0, AutoCommit => 1 );
my $db   = "dbio_k70_${$}";

my $admin = DBI->connect($dsn, $user, $pass, \%attr);
$admin->do('use master');

my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ( $dsn =~ /:$/ ? '' : ';' ) . "database=$db";

$admin->do("create database $db");
{
  local $admin->{syb_err_handler} = sub { $_[1] > 10 ? 1 : 0 };
  my $sth = $admin->prepare("exec sp_dboption '$db', 'abort tran on log full', true");
  $sth->execute;
  do { 1 while $sth->fetchrow_arrayref } while $sth->{syb_more_results};
}

my $schema = T::K70::Schema->connect($db_dsn, $user, $pass, {
  on_connect_do => [ 'set lock wait 10' ],
});

my $lived = eval {
  ok eval { DBIO::Sybase::Deploy->new(schema => $schema)->install; 1 },
    'character, char varying, mediumtext and a current_timestamp default install'
    or diag $@;

  my $cols = DBIO::Sybase::Introspect->new(dbh => $schema->storage->dbh)->model->{columns}{k70_sensor};
  my %col  = map { $_->{column_name} => $_ } @{ $cols // [] };

  is $col{sensors}{data_type}, 'char',    'sensors reads back as char';
  is $col{sensors}{size},      10,        '... of length 10, not 1';
  is $col{label}{data_type},   'varchar', 'label (char varying) reads back as varchar';
  is $col{label}{size},        20,        '... of length 20';
  is $col{memo}{data_type},    'text',    'mediumtext reads back as text';

  my $row = $schema->resultset('Sensor')->create({ sensors => '0123456789', label => 'x' });
  my ($got) = $schema->storage->dbh->selectrow_array(
    'select sensors from k70_sensor where id = ?', undef, $row->id);
  is $got, '0123456789', 'a 10-character value is stored whole';

  my ($stamp) = $schema->storage->dbh->selectrow_array(
    'select stamp from k70_sensor where id = ?', undef, $row->id);
  ok defined $stamp, 'the getdate() default filled the column';
  1;
};
my $error = $@;
fail('the live section ran through'), diag $error unless $lived;

$schema->storage->disconnect;
my $kept = AseDatabase::drop($admin, $db);
is $kept, '', 'the database of this test is dropped' or diag "  $kept";

done_testing;
