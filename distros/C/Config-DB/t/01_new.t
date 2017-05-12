use Test::More tests => 13;

my $cfg;

BEGIN { use_ok 'Config::DB' }
require_ok('Config::DB');

eval { Config::DB::new; };
like(
    $@,
    qr{^Config::DB::new: wrong call at t/01_new.t line \d+\n$},
    'wrong new call - no parameters'
);

eval { Config::DB::new( '' ); };
like(
    $@,
    qr{^Config::DB::new: wrong call at t/01_new.t line \d+\n$},
    'wrong new call - hack try 1'
);

eval { NoOk->new; };
like(
    $@,
    qr{^Config::DB::new: 'NoOk' does not hinerit 'Config::DB' at t/01_new.t line \d+\n$},
    'wrong new call - hack try 2'
);

eval { Config::DB::new('Wrong::Class'); };
like(
    $@,
qr{^Config::DB::new: 'Wrong::Class' does not hinerit 'Config::DB' at t/01_new.t line \d+\n$},
    'wrong new call - wrong class'
);

eval { Config::DB->new; };
like(
    $@,
qr{^Config::DB::new: missing 'connect' paramenter at t/01_new.t line \d+\n$},
    'wrong new call - missing connect paramenter'
);

eval { Config::DB->new( connect => 'scalar' ); };
like(
    $@,
qr{^Config::DB::new: 'connect' paramenter is not a reference to ARRAY at t/01_new.t line \d+\n$},
    'wrong new call - connect paramenter not array ref'
);

eval { Config::DB->new( connect => [] ); };
like(
    $@,
    qr{^Config::DB::new: missing 'tables' paramenter at t/01_new.t line \d+\n$},
    'wrong new call - missing tables paramenter'
);

eval { Config::DB->new( connect => [], tables => 'scalar' ); };
like(
    $@,
qr{^Config::DB::new: 'tables' paramenter is not a reference to HASH at t/01_new.t line \d+\n$},
    'wrong new call - tables paramenter not array ref'
);

eval { Config::DB->new( connect => [], tables => {} ); };
like(
    $@,
    qr{^Config::DB::new: no tables defined at t/01_new.t line \d+\n$},
    'wrong new call - missing tables'
);

eval { $cfg = Config::DB->new( connect => [], tables => { one => 'two' } ); };
is( $@, '', 'right new call' );
isa_ok( $cfg, 'Config::DB', 'right class' );

package NoOk;

use base 'Config::DB';

sub check_Config_DB_hineritance {
    return 'NoOk';
}
