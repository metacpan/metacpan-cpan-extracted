# testscript for Config::General::Hierarchical module
#
# needs to be invoked using the command "make test" from
# the Config::General::Hierarchical source directory.
#
# under normal circumstances every test should succeed.

use Config::General::Hierarchical;
use Test::More tests => 35;
use Test::Differences;

my $cfg = Config::General::Hierarchical->new( file => 't/get.conf' );
is( $cfg->get('a'), 'b', 'get call' );
is( $cfg->_a,       'b', 'AUTOLOAD call' );
isa_ok( $cfg->_e, 'Config::General::Hierarchical', 'AUTOLOAD call (no cache)' );

eval { $cfg->unknown };
like(
    $@,
qr{Can't locate object method "unknown" via package "Config::General::Hierarchical" at t/03_get.t line \d+.\n},
    'AUTOLOAD error'
);

eval { $cfg->get( 'd', 'a' ) };
like(
    $@,
qr{Config::General::Hierarchical: can't get subkey 'a' value for not node variable 'd' at t/03_get.t line \d+.\n},
    'wrong get params'
);

$cfg->_d;
eval { $cfg->get( 'd', 'a' ) };
like(
    $@,
qr{Config::General::Hierarchical: can't get subkey 'a' value for not node variable 'd' at t/03_get.t line \d+.\n},
    'wrong cached get params'
);

is( $cfg->get( 'b', 'a' ), 'c', 'get params (2)' );
isa_ok( $cfg->get('b'), 'Config::General::Hierarchical', 'get node (2)' );
is( $cfg->get('b')->get('a'), 'c', 'get subcall (2)' );

is( $cfg->get( 'c', 'b', 'a' ), 'd', 'get params (3)' );
isa_ok(
    my $node = $cfg->get( 'c', 'b' ),
    'Config::General::Hierarchical',
    'get node (3)'
);
is( $cfg->_c->_b->_a, 'd', 'get subcall (3)' );

is( $cfg->_c->_b,  $node, 'get cache' );
is( $cfg->_c('b'), $node, 'get params cache' );

eval { $cfg->_c->_b->_a('e') };
like(
    $@,
qr{Config::General::Hierarchical: can't get subkey 'e' value for not node variable 'c->b->a' at t/03_get.t line \d+.\n},
    'cached names'
);

is( $cfg->_f, 'b', 'inherits order' );

eval { $cfg->_error };
like(
    $@,
qr{Config::General::Hierarchical: systax error in inline variable substitution for value 'ab\$\{ab' for variable 'error' at t/03_get.t line \d+.\n},
    'inline error'
);

eval { $cfg->_unfind };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'ab'\nin file: .+/t/get.conf at t/03_get.t line \d+\n during inline variable sostitution for variable 'unfind' at t/03_get.t line \d+.\n},
    'inline undef'
);

eval { $node->_unfind };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'b->c'\nin file: .+/t/get.conf at t/03_get.t line \d+\n during inline variable sostitution for variable 'c->b->unfind' at t/03_get.t line \d+.\n},
    'inline undef not root'
);

eval { $cfg->_type };
like(
    $@,
qr{Config::General::Hierarchical: can't get subkey 'b' value for not node variable 'a' at t/03_get.t line \d+\n during inline variable sostitution for variable 'type' at t/03_get.t line \d+.\n},
    'inline type error'
);

eval { $cfg->_innode };
like(
    $@,
qr{Config::General::Hierarchical: can't use node or array variable in inline variable sostitution for variable 'innode' at t/03_get.t line \d+.\n},
    'inline type error'
);

is( $cfg->_sub, '$abcd', 'inline substitution' );

SKIP: {
    skip 'excluded waken', 1
      if $Config::General::Hierarchical::ExcludeWeaken::exclude;
    $node = Config::General::Hierarchical->new( file => 't/get3.conf' )->_node;
    eval { $node->_key; };
    like(
        $@,
qr{Config::General::Hierarchical: can't do inline variable substitution for variable 'node->key' when reference to root node was lost at t/03_get.t line \d+.\n},
        'inline when lost root'
    );
}

$node = Config::General::Hierarchical->new( file => 't/get3.conf', check => 1 )
  ->_node;
is( $node->_key, 'abc', 'inline when lost root - check' );

eval { Config::General::Hierarchical->new( file => 't/get.conf', check => 1 ); };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'b->c'\nin file: .+/t/get.conf at t/03_get.t line \d+\n during inline variable sostitution for variable 'c->b->unfind' at t/03_get.t line \d+.\n},
    'read - check error'
);

eq_or_diff( [ $node->getk ], ['key'], 'getk' );

$cfg = Config::General::Hierarchical->new( file => 't/get4.conf' );

is( $cfg->_f->_g->_h, 'i', 'wild key 1' );
is( $cfg->_f->_g->_a, 'j', 'wild key 2' );
is( $cfg->_f->_g->_c, 'd', 'wild key 3' );
is( $cfg->_f->_b->_a, 'e', 'wild key 4' );
is( $cfg->_f->_b->_c, 'd', 'wild key 5' );
is( $cfg->_f->_a,     'b', 'wild key 6' );
is( $cfg->_a->_a,     'b', 'wild key 7' );
is( $cfg->_a->_b->_a, 'e', 'wild key 8' );
is( $cfg->_a->_b->_c, 'd', 'wild key 9' );
