# testscript for Config::General::Hierarchical module
#
# needs to be invoked using the command "make test" from
# the Config::General::Hierarchical source directory.
#
# under normal circumstances every test should succeed.

use Config::General::Hierarchical;
use Cwd qw( abs_path );
use Test::More tests => 11;

eval { Config::General::Hierarchical->new( file => 't/e/s/t' ); };
like(
    $@,
qr{^Config::General::Hierarchical: no such directory: t/e/s/t\n  at t/02_read.t line \d+\n$},
    'bad directory'
);

eval { Config::General::Hierarchical->new( file => 't/not_exists.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: no such (directory|file): .+/t/not_exists.conf\n  at t/02_read.t line \d+\n$},
    'file doesn\'t exists'
);

eval { Config::General::Hierarchical->new( file => 't/error1.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: Config::General: Block "<node>" has no EndBlock statement \(level: 2, chunk 2\)\!\nin file: .+/t/error1.conf\n  at t/02_read.t line \d+\n$},
    'read exception'
);

eval { Config::General::Hierarchical->new( file => 't/inherits_error1.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: wrong use of inherits \('inherits'\) directive\nin file: .+/t/inherits_error1.conf\n  at t/02_read.t line \d+\n$},
    'wrong inherits'
);

my $cfg = Config::General::Hierarchical->new( file => 't/inherits1.conf' );
is( scalar @{ $cfg->opt->files }, 2, 'single inherits' );

$cfg = Config::General::Hierarchical->new( file => 't/inherits2.conf' );
is( scalar @{ $cfg->opt->files }, 3, 'double inherits' );

eval { Config::General::Hierarchical->new( file => 't/inherits_error2.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: Config::General: Block "<node>" has no EndBlock statement \(level: 2, chunk 2\)\!\nin file: .+/t/error1.conf\ninherited by: .+/t/inherits_error2.conf\n  at t/02_read.t line \d+\n$},
    'bad inherited file'
);

eval { Config::General::Hierarchical->new( file => 't/inherits_error3.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: recursive hierarchy\nin file: .+/t/inherits_error3.conf\ninherited by: .+/t/inherits_error3_.conf\ninherited by: .+/t/inherits_error3.conf\n  at t/02_read.t line \d+\n$},
    'recursive hieararchy'
);

eval { Config::General::Hierarchical->new( file => 't/inherits_error4.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: inherits \('inherits'\) directive cannot be used as node name\nin file: .+/t/inherits_error4.conf\n  at t/02_read.t line \d+\n$},
    'inherits directive as node name'
);

eval { Config::General::Hierarchical->new( file => 't/error3.conf' ); };
like(
    $@,
qr{^Config::General::Hierarchical: wrong use of undefined \('undefined'\) directive\nin file: .+/t/error3.conf\n  at t/02_read.t line \d+\n$},
    'wrong undefind'
);

if ( open FD, '>tmp_test.conf' ) {
    my $ok;
    if ( $ok = open FD2, '>tmp_test2.conf' ) {
        print FD2 "a b\n";
        close FD2;
    }

    my $tmp = abs_path('tmp_test2.conf');
    print FD "inherits $tmp\n";
    close FD;

    if ($ok) {
        $cfg = Config::General::Hierarchical->new( file => 'tmp_test.conf' );
        is( $cfg->_a, 'b', 'absolute path inherits' );
        unlink 'tmp_test2.conf';
    }
    else {
        ok( 1, 'dummy' );
    }

    unlink 'tmp_test.conf';
}
else {
    ok( 1, 'dummy' );
}
