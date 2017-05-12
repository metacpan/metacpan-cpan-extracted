# testscript for Config::General::Hierarchical module
#
# needs to be invoked using the command "make test" from
# the Config::General::Hierarchical source directory.
#
# under normal circumstances every test should succeed.

use Data::Dumper;
use Test::More tests => 20;
use Config::General::Hierarchical::ExcludeWeaken;

BEGIN { use_ok 'Config::General::Hierarchical' }
require_ok('Config::General::Hierarchical');

BEGIN { use_ok 'Config::General::Hierarchical::Test' }

ok( my $cfg = Config::General::Hierarchical->new, 'new call' );
isa_ok( $cfg, 'Config::General::Hierarchical' );

eval { Config::General::Hierarchical::new; };
like(
    $@,
qr{^Config::General::Hierarchical: wrong new call at t/01_new.t line \d+\n$},
    'wrong call'
);

eval { Config::General::Hierarchical->new( log => 1 ); };
is( $@, '', 'wrong parameter' );

ok( Config::General::Hierarchical->new( name => 'name', opt => {} ),
    'internal new call' );

$cfg = Config::General::Hierarchical->new(
    name      => 'name',
    undefined => 'undefined'
);
is( $cfg->name, 'name', 'mixed parameters opt 1' );
eval { $cfg->undefined; };
like(
    $@,
qr{^Can't call method "undefined" on an undefined value at .+/Hierarchical\.pm line \d+\.\n$},
    'mixed parameters opt 2'
);

$cfg = Config::General::Hierarchical->new( name => 'name', '-CComments' => 1 );
is( $cfg->name, 'name', 'mixed parameters general 1' );
is( $cfg->opt,  undef,  'mixed parameters general 2' );

eval { $cfg->getk; };
like(
    $@,
qr{^Config::General::Hierarchical: can't get keys before reading any file at t/01_new.t line \d+\n$},
    'keys without read'
);

$cfg = Config::General::Hierarchical->new( file => 't/empty.conf' );
is( $cfg->name,              '', 'read call (name)' );
is( scalar %{ $cfg->value }, 0,  'read call (empty value)' );

$cfg = Config::General::Hierarchical->new( file => 't/ccomments.conf' );
is( scalar keys %{ $cfg->value }, 3, 'read call (filled value)' );

$cfg = Config::General::Hierarchical->new(
    file         => 't/ccomments.conf',
    '-CComments' => 1
);
is( scalar %{ $cfg->value }, 0, 'Config::General proxy' );

is( $cfg->inherits, 'inherits', 'default inherits option' );
$cfg = Config::General::Hierarchical->new( inherits => 'other_string' );
is( $cfg->inherits, 'other_string', 'inherits option' );

$Config::General::Hierarchical::Test::count = 0;
{
    my $ref =
      Config::General::Hierarchical::Test->new(
        file => 't/dump_substitutions.conf' );
}
is( $Config::General::Hierarchical::Test::count,
    $Config::General::Hierarchical::ExcludeWeaken::exclude ? 0 : 1, 'DESTROY' );
