
use strict;
use Test::More 'no_plan';

BEGIN {
use_ok( 'Config::Context' );
}

diag( "Testing Config::Context $Config::Context::VERSION" );

my $conf;
eval {
    $conf = Config::Context->new(
        driver => 'foo',
        borgle => 1
    );
};
like($@, qr/borgle/, 'caught bad param');

eval {
    $conf = Config::Context->new(
    );
};
like($@, qr/driver/,   'driver param required (2)');
like($@, qr/required/, 'driver param required (1)');

eval {
    $conf = Config::Context->new(
        driver => 'foo',
    );
};
like($@, qr/driver/, 'caught bad driver (1)');
like($@, qr/foo/,    'caught bad driver (2)');

eval {
    $conf = Config::Context->new(
        driver => 'ConfigGeneral',
    );
};


like($@, qr/required/, 'caught missing config, string, file (1)');
like($@, qr/string/,   'caught missing config, string, file (2)');
like($@, qr/file/,     'caught missing config, string, file (3)');
like($@, qr/config/,   'caught missing config, string, file (4)');

