use strict;
use warnings;
use Test::More;

# LIVE half of karr k116 (t/143 has the offline half and the reasoning): a
# foreign key made with an explicit NO ACTION is no change to the diff.
#
# Measured 2026-10-24, MySQL 8.0.30 and MariaDB 11.8.9: the unwritten action
# is NO ACTION on MySQL and RESTRICT on MariaDB, an explicit NO ACTION stays
# NO ACTION on both. The model is read back from a temp database the DDL of
# install_ddl made, so a MariaDB saw RESTRICT there and NO ACTION on the
# live constraint, and the diff dropped and added it. Claims, on both servers:
#   1. a hand-made constraint with explicit NO ACTION (update and delete), of
#      the name and columns the model gives, is not part of the diff;
#   2. the same for the constraint install_ddl made (unset, NO ACTION);
#   3. a real difference (CASCADE in the model) is still found;
#   4. after the upgrade of that, the diff is empty.
# Works in a database of its own (see t/86).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "mysql_k116_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

my $n = 0;
sub schema_for {
  my ($attrs) = @_;
  my $ns = 'K116Live::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $m (qw/Child Parent/) {
    my $class = "${ns}::Result::$m";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table(lc $m);
    $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 },
      $m eq 'Child' ? (parent_id => { data_type => 'integer', is_nullable => 1 }) : ());
    $class->set_primary_key('id');
    $class->belongs_to(parent => "${ns}::Result::Parent", { 'foreign.id' => 'self.parent_id' }, $attrs)
      if $m eq 'Child';
    $ns->register_class($m => $class);
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}
sub fresh { drop_database(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") }
sub fk_changes {
  my ($attrs) = @_;
  my $schema = schema_for($attrs);
  my $d = DBIO::MySQL::Deploy->new(schema => $schema)->diff;
  $schema->storage->disconnect;
  return join "\n", grep { /FOREIGN KEY/ } map { $_->as_sql } @{ $d->operations };
}

# What the model's install_ddl makes, to start from tables the model knows.
sub install_model {
  my ($attrs) = @_;
  my $schema = schema_for($attrs);
  DBIO::MySQL::Deploy->new(schema => $schema)->install;
  $schema->storage->disconnect;
}

for my $name ('unset', 'NO ACTION') {
  my $attrs = $name eq 'unset' ? {} : { on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  fresh();
  install_model($attrs);
  is fk_changes($attrs), '', "$name, made by install_ddl: the diff has no foreign key in it";
}

# The same constraint with the actions written out, replacing the one install made.
fresh();
install_model({});
$raw->do('ALTER TABLE `child` DROP FOREIGN KEY `child_parent_id_fk`');
$raw->do('ALTER TABLE `child` ADD CONSTRAINT `child_parent_id_fk` FOREIGN KEY (`parent_id`) '
  . 'REFERENCES `parent` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION');
my ($rules) = $raw->selectrow_array("SELECT CONCAT(UPDATE_RULE, '/', DELETE_RULE) FROM information_schema.REFERENTIAL_CONSTRAINTS "
  . "WHERE CONSTRAINT_SCHEMA = '$DB'");
note "the server reports the hand-made constraint as $rules";
is fk_changes({}), '', 'explicit NO ACTION made by hand: the diff has no foreign key in it';
is fk_changes({ on_delete => 'NO ACTION', on_update => 'NO ACTION' }), '', '... with NO ACTION in the model as well';

like fk_changes({ on_delete => 'cascade' }), qr/ON DELETE CASCADE/, 'a real difference (CASCADE in the model) is still found';

my $schema = schema_for({ on_delete => 'cascade' });
ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->upgrade; 1 }, 'the upgrade takes it' or diag $@;
$schema->storage->disconnect;
is fk_changes({ on_delete => 'cascade' }), '', 'and the next diff has no foreign key in it';

done_testing;
