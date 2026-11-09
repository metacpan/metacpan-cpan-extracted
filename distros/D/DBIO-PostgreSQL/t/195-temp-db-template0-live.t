use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k151: the temporary database of a deploy is an empty database from
# template0 with the encoding and the collation of the live database, and a
# deploy stops when it is not empty -- and the temporary database goes.
#
# WHY: a database made from template1 carries whatever template1 holds into
# the target model. Every database here is named dbio_pg_k151_*; template0 and
# template1 are never changed.

# the settings a database has, as far as this server's pg_database has them
sub settings_of {
  my ($dbh, $name) = @_;
  return $dbh->selectrow_arrayref(q{
    SELECT pg_catalog.pg_encoding_to_char(d.encoding), d.datcollate, d.datctype,
           to_jsonb(d)->>'datlocprovider', to_jsonb(d)->>'daticulocale',
           to_jsonb(d)->>'datlocale', to_jsonb(d)->>'daticurules'
      FROM pg_catalog.pg_database d WHERE d.datname = ?
  }, undef, $name);
}

my @own;
END {
  return unless @own;
  my $dbh = eval { LiveServer->dbh_or_die(attrs => { RaiseError => 0 }) } or return;
  $dbh->do('DROP DATABASE IF EXISTS ' . $dbh->quote_identifier($_) . ' WITH (FORCE)') for @own;
  $dbh->disconnect;
}

sub deploy_of {
  my ($login, $class, %o) = @_;
  my $schema = $class->connect(@$login, { PrintError => 0, PrintWarn => 0 });
  return ($schema, DBIO::PostgreSQL::Deploy->new(schema => $schema, %o));
}

{
  package T195L::Schema;
  our @ISA = ('DBIO::Schema');
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public');
}

# --- encoding and collation follow the live database ------------------------
my @sources = ([ 'the live database' => [ PrivatePgDatabase->create('pg_k151_live') ] ]);

{
  my $ctl = LiveServer->control_dbh(attrs => { PrintWarn => 0 });
  if ($ctl->{pg_server_version} >= 170000) {
    my $name = "dbio_pg_k151_builtin_$$";
    push @own, $name;
    $ctl->do("DROP DATABASE IF EXISTS $name WITH (FORCE)");
    $ctl->do(qq{CREATE DATABASE $name TEMPLATE template0 ENCODING 'UTF8'
      LC_COLLATE 'C' LC_CTYPE 'C' LOCALE_PROVIDER builtin BUILTIN_LOCALE 'C.UTF-8'});
    push @sources, [ 'a builtin-provider database' => [ LiveServer->login_for_database($name) ] ];
  }
  $ctl->disconnect;
}

for my $source (@sources) {
  my ($what, $login) = @$source;
  my ($schema, $deploy) = deploy_of($login, 'T195L::Schema');
  my $live = $schema->storage->dbh;
  my $admin = $deploy->_admin_dbh;
  my $temp = $deploy->_create_temp_db($admin);
  my $want = settings_of($admin, $live->selectrow_array('SELECT current_database()'));
  my $got  = settings_of($admin, $temp);
  is_deeply $got, $want, "$what: the temporary database has its encoding, collation and locale"
    or diag explain [ $got, $want ];

  my ($template) = $admin->selectrow_array(
    q{SELECT 1 FROM pg_database WHERE datname = ? }, undef, $temp);
  ok $template, "$what: the temporary database exists";
  ok eval { $deploy->_check_temp_db_empty($temp); 1 },
    "$what: it is empty (public and plpgsql only)" or diag $@;
  $deploy->_drop_temp_db($admin, $temp);
  $deploy->_release_admin_dbh;
  $schema->storage->disconnect;
}

# --- the emptiness check on a database that holds objects -------------------
{
  my @db = PrivatePgDatabase->create('pg_k151_full');
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do('CREATE SCHEMA foreign_s');
  $dbh->do('CREATE TABLE public.foreign_t (id int)');
  $dbh->do('CREATE FUNCTION public.foreign_f() RETURNS void LANGUAGE sql AS $$ SELECT 1 $$');
  $dbh->do(q{CREATE TYPE public.foreign_mood AS ENUM ('a')});

  my ($schema, $deploy) = deploy_of(\@db, 'T195L::Schema');
  ok !eval { $deploy->_check_database_empty($dbh); 1 }, 'a database with objects: the check dies';
  my $err = $@;
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/schema foreign_s/, 'the message names the schema';
  like "$err", qr/table public\.foreign_t/, 'the message names the table';
  like "$err", qr/function public\.foreign_f\(\)/, 'the message names the function';
  like "$err", qr/type public\.foreign_mood/, 'the message names the type';
  $dbh->disconnect;
  $schema->storage->disconnect;
}

# --- a deploy whose check dies leaves no temporary database -----------------
{
  package T195L::Deploy;
  our @ISA = ('DBIO::PostgreSQL::Deploy');
  sub _check_database_empty { die "T195 refuses: not empty\n" }
}
{
  my @db = PrivatePgDatabase->create('pg_k151_flow');
  my $prefix = "dbio_pg_k151_tmp_${$}_";
  my $schema = T195L::Schema->connect(@db, { PrintError => 0, PrintWarn => 0 });
  my $deploy = T195L::Deploy->new(schema => $schema, temp_db_prefix => $prefix);
  ok !eval { $deploy->diff; 1 }, 'the deploy dies where the check dies';
  is $@, "T195 refuses: not empty\n", 'with the error of the check';

  my $ctl = LiveServer->control_dbh;
  my $left = $ctl->selectcol_arrayref(
    q{SELECT datname FROM pg_database WHERE starts_with(datname, ?)}, undef, $prefix);
  is_deeply $left, [], 'the temporary database is dropped';
  $ctl->do('DROP DATABASE IF EXISTS ' . $ctl->quote_identifier($_) . ' WITH (FORCE)') for @$left;
  $ctl->disconnect;
  $schema->storage->disconnect;
}

done_testing;
