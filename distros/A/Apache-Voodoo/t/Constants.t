use strict;
use warnings;

use lib('t');

use Test::More tests => 18;

use_ok('Apache::Voodoo::Constants') || 
	BAIL_OUT("Can't load constants, all other test will fail");

eval { Apache::Voodoo::Constants->new('nosuch::config') };
ok($@ =~ /Can't find nosuch::config/, "no such config file");

eval { Apache::Voodoo::Constants->new('test_data::BrokenConfig') };
ok($@ =~ /There was an error loading/, "broken config");

my $c  = Apache::Voodoo::Constants->new('test_data::MyConfig');
my $c2 = Apache::Voodoo::Constants->new('test_data::MyConfig');
is("$c","$c2","is a singleton");

foreach (
	['apache_gid',    80],
	['apache_uid',    81],
	['code_path',     'code'],
	['conf_file',     'etc/voodoo.conf'],
	['conf_path',     'etc'],
	['install_path',  '/data/apache/sites'],
	['prefix',        '/data/apache'],
	['session_path',  '/data/apache/session'],
	['tmpl_path',     'html'],
	['updates_path',  'etc/updates'],
	['debug_dbd', [
		'dbi:SQLite:dbname=/tmp/apachevoodoo.db',
		'username',
		'password'
  		]
	],
	['debug_path',    '/debug'],
	['use_log4perl',  1],
	['log4perl_conf', '/etc/log4perl.conf'],
) {
	my ($method,$value) = @{$_};
	is_deeply($c->$method,$value,$method);
}
