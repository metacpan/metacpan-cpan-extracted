#!perl

use 5.10.1;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  eval { require DBD::mysql; 1 }
    or plan skip_all => 'DBD::mysql is required for this test.';
  eval { DBD::mysql->VERSION >= 4.005 }
    or plan skip_all => 'DBD::mysql >= 4.005 required. You have only'
    . DBD::mysql->VERSION;
  use File::Basename 'dirname';
  use Cwd;
  use lib (Cwd::abs_path(dirname(__FILE__) . '/..') . '/examples/lib');
}
use Data::Dumper;
use DBIx::Simple::Class::Schema;


my $DSCS = 'DBIx::Simple::Class::Schema';
my $dbix;
eval {
  $dbix =
    DBIx::Simple->connect('dbi:mysql:database=test;host=127.0.0.1;mysql_enable_utf8=1',
    '', '');
}
  or plan skip_all => (
  $@ =~ /Can\'t connect to local/
  ? 'Start MySQL on localhost to enable this test.'
  : $@
  );

#=pod

#Suppress some warnings from DBIx::Simple::Class during tests.
local $SIG{__WARN__} = sub {
  if (
    $_[0] =~ /(Will\sdump\sschema\sat
         |exists
         |avoid\snamespace\scollisions
         |\w+\.pm|make\spath)/x
    )
  {
    my ($package, $filename, $line, $subroutine) = caller(2);
    ok($_[0], $subroutine . " warns '$1' OK");
  }
  else {
    warn $_[0];
  }
};

#=cut

isa_ok(ref($DSCS->dbix($dbix)), 'DBIx::Simple');
can_ok($DSCS, qw(load_schema dump_schema_at));


#create some tables
#=pod

$dbix->query('DROP TABLE IF EXISTS `groups`');
$dbix->query(<<'TAB');
CREATE TABLE  IF NOT EXISTS groups(
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  group_name VARCHAR(12),
  `is blocked` INT,
  data TEXT

  ) DEFAULT CHARSET=utf8 COLLATE=utf8_bin
TAB

$dbix->query('DROP TABLE IF EXISTS `users`');
$dbix->query(<<'TAB');
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL COMMENT 'Primary group for this user',
  `login_name` varchar(100) NOT NULL,
  `login_password` varchar(100) NOT NULL COMMENT 'Mojo::Util::md5_sum($login_name.$login_password)',
  `name` varchar(255) NOT NULL DEFAULT '',
  `email` varchar(255) NOT NULL DEFAULT 'email@domain.com',
  `disabled` tinyint(1) NOT NULL DEFAULT '0',
  balance DECIMAL(8,2) NOT NULL DEFAULT '0.00',
  dummy_dec DECIMAL(8,0) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `login_name` (`login_name`),
  UNIQUE KEY `email` (`email`),
  KEY `group_id` (`group_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT COMMENT='This table stores the users'

TAB
$dbix->query(<<'TAB');
--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_group_id` FOREIGN KEY (`group_id`) REFERENCES `users` (`id`)
TAB

#=cut

ok(my $code = $DSCS->load_schema(namespace => 'Test'), 'scalar context OK');
ok(my @code = $DSCS->load_schema(namespace => 'Test'), 'list context OK');

#warn Dumper($DSCS->_schemas('Test')->{tables});
#PARAMS
delete $DSCS->_schemas->{Test};
$DSCS->load_schema(namespace => 'Your::Model', table => '%user%', type => "'TABLE'")
  ;    #void context ok
isa_ok($DSCS->_schemas('Your::Model'),
  'HASH', 'load_schema creates Your::Model namespace OK');

is($DSCS->_schemas('Your::Model')->{tables}[0]->{TABLE_NAME},
  'users', 'first table is "users"');
is(scalar @{$DSCS->_schemas('Your::Model')->{tables}}, 1, 'the only table is "users"');
SKIP: {
  skip "I have only linux, see http://perldoc.perl.org/perlport.html#chmod", 1,
    if $^O !~ /linux/i;
  chmod 0444, $INC[0];
  ok(!$DSCS->dump_schema_at(lib_root => $INC[0]), 'quits OK');
  chmod 0755, $INC[0];
}
ok($DSCS->dump_schema_at(lib_root => $INC[0]), 'dumps OK');
File::Path::remove_tree($INC[0] . '/Your');
$dbix->query('DROP TABLE IF EXISTS `groups`');
$dbix->query('DROP TABLE IF EXISTS `users`');

done_testing;

