#!perl
use 5.10.1;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
  eval { DBD::SQLite->VERSION >= 1 }
    or plan skip_all => 'DBD::SQLite >= 1.00 required';
  use File::Basename 'dirname';
  use Cwd;
  use lib (Cwd::abs_path(dirname(__FILE__) . '/..') . '/examples/lib');
}


use DBI::Const::GetInfoType;
use Data::Dumper;

#Suppress some warnings from DBIx::Simple::Class during tests.
local $SIG{__WARN__} = sub {
  if (
    $_[0] =~ /(Will\sdump\sschema\sat
         |exists
         |avoid\snamespace\scollisions
         |\w+\.pm|make\spath
         |Overwriting)/x
    )
  {
    my ($package, $filename, $line, $subroutine) = caller(2);
    ok($_[0], ($subroutine || '') . " warns '$1' OK");
  }
  else {
    warn $_[0];
  }
};

use DBIx::Simple::Class::Schema;

my $DSCS = 'DBIx::Simple::Class::Schema';
my $dbix = DBIx::Simple->connect('dbi:SQLite:dbname=:memory:', {sqlite_unicode => 1});
$dbix->dbh->do('PRAGMA foreign_keys = ON');
isa_ok(ref($DSCS->dbix($dbix)), 'DBIx::Simple');
can_ok($DSCS, qw(load_schema dump_schema_at));


$dbix->query(<<'TAB');
CREATE TABLE groups(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_name VARCHAR(12),
  "is blocked" INT,
  data TEXT
  )
TAB

#=pod
#create some tables
$dbix->query(<<'TAB');
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id int(11) NOT NULL, -- COMMENT 'Primary group for this user'
  login_name varchar(100) NOT NULL,
  login_password varchar(100) NOT NULL, -- COMMENT 'Mojo::Util::md5_sum($login_name.$login_password)'
  name varchar(255) NOT NULL DEFAULT '',
  email varchar(255) NOT NULL DEFAULT 'email@domain.com',
  disabled tinyint(1) NOT NULL DEFAULT '0',
  balance DECIMAL(8,2) NOT NULL DEFAULT '0.00',
  dummy_dec DECIMAL(8,0) NOT NULL DEFAULT '0',
  nullable_column TEXT DEFAULT NULL,
  UNIQUE(login_name) ON CONFLICT ROLLBACK,
  UNIQUE(email) ON CONFLICT ROLLBACK,
  FOREIGN KEY(group_id) REFERENCES groups(id)

)
TAB

#=cut

#BARE DEFAULTS
like(
  (eval { $DSCS->dump_schema_at() }, $@),
  qr/Please first call/,
  'dump_schema_at() croaks OK'
);
require File::Path;
File::Path::remove_tree($INC[0] . '/DSCS/Memory');
unlink($INC[0] . '/DSCS/Memory.pm');
File::Path::remove_tree($INC[0] . '/Your');

ok(my $code = $DSCS->load_schema(), 'scalar context OK');
ok(my @code = $DSCS->load_schema(), 'list context OK');

my $tables = $DSCS->_schemas('DSCS::Memory')->{tables};

#warn Dumper($tables);

ok((grep { $_->{TABLE_NAME} eq 'users' || $_->{TABLE_NAME} eq 'groups' } @$tables),
  '_get_table_info works');
my @column_infos;
foreach (@$tables) {
  push @column_infos, @{$_->{column_info}};
}

#we have two columns named "id" - one per table.
is((grep { $_->{COLUMN_NAME} eq 'id' } @column_infos), 2, '_get_column_info works');
my %alaiases =
  (%{$tables->[0]->{ALIASES}}, %{$tables->[1]->{ALIASES}}, %{$tables->[2]->{ALIASES}});
is((grep { $_ eq 'is_blocked' || $_ eq 'column_data' } values %alaiases),
  2, '_generate_ALIASES works');

my %checks =
  (%{$tables->[0]->{CHECKS}}, %{$tables->[1]->{CHECKS}}, %{$tables->[2]->{CHECKS}});
ok($checks{group_name}{allow}('alaba_anica2'),   'checks VARCHAR(12) works fine');
ok(!$checks{group_name}{allow}('alaba_anica13'), 'checks VARCHAR(12) works fine');
like('1',  qr/$checks{id}->{allow}/, 'checks INT works fine');
like('11', qr/$checks{id}->{allow}/, 'checks INT works fine');
unlike('a', qr/$checks{id}->{allow}/, 'checks INT works fine');
ok($checks{data}{allow}('1'),          'checks TEXT works fine');
ok($checks{data}{allow}('11sd,asd,a'), 'checks TEXT works fine');
unlike('', qr/$checks{'is blocked'}{allow}/, 'checks INT works fine');
like('1', qr/$checks{disabled}->{allow}/, 'checks TINYINT(1) works fine');
unlike('11', qr/$checks{disabled}->{allow}/, 'checks TINYINT(1) works fine');
unlike('a',  qr/$checks{disabled}->{allow}/, 'checks TINYINT(1) works fine');
like('1',         qr/$checks{balance}->{allow}/, 'checks DECIMAL(8,2) works fine');
like('11.2',      $checks{balance}->{allow},     'checks DECIMAL(8,2) works fine');
like('123456.20', $checks{balance}->{allow},     'checks DECIMAL(8,2) works fine');
unlike('1234567.2', $checks{balance}->{allow},     'checks DECIMAL(8,2) works fine');
unlike('a',         qr/$checks{balance}->{allow}/, 'checks DECIMAL(8,2) works fine');
like('11', $checks{dummy_dec}->{allow}, 'checks DECIMAL(8,0) works fine');
unlike('11.2', $checks{dummy_dec}->{allow}, 'checks DECIMAL(8,0) works fine');

my $nc = 'nullable_column';
is(
  undef,
  Params::Check::check({$nc => $checks{$nc}}, {$nc => undef})->{$nc},
  'checks TEXT DEFAULT NULL works fine'
);

ok((eval {$code}), 'code generated ok') or diag($@);
ok($DSCS->dump_schema_at(), 'dump_schema_at dumps code to files OK');
use_ok('DSCS::Memory::Groups');
use_ok('DSCS::Memory::Users');

#END BARE DEFAULTS
#Now we should have some files to remove
ok($DSCS->dump_schema_at(), 'does not quit OK');
unlink($INC[0] . '/DSCS/Memory.pm');

ok($DSCS->dump_schema_at(), 'does not quit OK');
$DSCS->DEBUG(1);
unlink($INC[0] . '/DSCS/Memory.pm');
unlink($INC[0] . '/DSCS/Memory/SqliteSequence.pm');
ok($DSCS->dump_schema_at(overwrite => 1), 'overwrites OK');
$DSCS->DEBUG(0);
SKIP: {
  skip "I have only linux and mac, see http://perldoc.perl.org/perlport.html#chmod", 1,
    if $^O !~ /linux|darwin/i;
  chmod 0444, $INC[0] . '/DSCS/Memory/Users.pm';
  ok(!$DSCS->dump_schema_at(overwrite => 1), 'quits OK');
  chmod 0644, $INC[0] . '/DSCS/Memory/Users.pm';
}
File::Path::remove_tree($INC[0] . '/DSCS/Memory');
unlink($INC[0] . '/DSCS/Memory.pm');

#PARAMS
delete $DSCS->_schemas->{Memory};
$DSCS->load_schema(namespace => 'Your::Model', table => 'user%', type => "'TABLE'")
  ;    #void context ok
isa_ok($DSCS->_schemas('Your::Model'),
  'HASH', 'load_schema creates Your::Model namespace OK');
is(scalar @{$DSCS->_schemas('Your::Model')->{code}}, 1, 'only one piece of code - ok');

is($DSCS->_schemas('Your::Model')->{tables}[0]->{TABLE_NAME},
  'users', 'first table is "users"');
is(scalar @{$DSCS->_schemas('Your::Model')->{tables}}, 1, 'the only table is "users"');

my $class_to_file = "$INC[0]/Your/Model.pm";
ok(!-f $class_to_file, 'schema class is NOT generated - OK');
my $class_code =
  $DSCS->load_schema(namespace => 'Your::Model', table => 'users', type => "'TABLE'");
unlike($class_code, qr/package\s+Your\:\:Model\;/x, 'No schema class generated - ok2');

SKIP: {
  skip "I have only linux and mac, see http://perldoc.perl.org/perlport.html#chmod", 1,
    if $^O !~ /linux|darwin/i;
  chmod 0444, $INC[0];
  ok(!$DSCS->dump_schema_at(lib_root => $INC[0]), 'quits OK');
  chmod 0755, $INC[0];
}
ok($DSCS->dump_schema_at(lib_root => $INC[0]), 'dumps OK');
File::Path::remove_tree($INC[0] . '/Your');


done_testing;
