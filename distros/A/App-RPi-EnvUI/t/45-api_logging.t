use strict;
use warnings;

BEGIN {
    use lib 't/';
    use TestBase;
    config();
    db_create();
}

use App::RPi::EnvUI::API;
use App::RPi::EnvUI::DB;
use Data::Dumper;
use Test::More;

$| = 1; # autoflush so we can read log file while it's still open

#FIXME: add tests to test overrides for hum and temp

my $api = App::RPi::EnvUI::API->new(
    testing => 1,
    config_file => 't/envui.json'
);

is ref $api, 'App::RPi::EnvUI::API', "new() returns a proper object";
is $api->{testing}, 1, "testing param to new() ok";

{ # log level

    my $lvl = $api->log_level;
    is $lvl, -1, "default log level is -1/disabled";

    is $api->log_level(7), 7, "setting log level ok";
    is $api->log_level(-1), -1, "as is setting it back to default";

}

{ # log file

    $api->log_level( 7 );

    my $fn = $api->log_file;
    is $fn, '', "log file is not set in default config";

    $api->log_file( 't/test.log' );
    is $api->log_file, 't/test.log', "log_file() w/ param ok";

    my $log = $api->log()->child('log_test');
    is ref $log, 'Logging::Simple', "logging agent is in proper class";

    is $log->level, 7, "log level was set correctly through api to log";

    $log->_0( "test" );

    open my $fh, '<', $api->log_file or die $!;

    while (my $entry = <$fh>){
        like $entry, qr/test$/, "log file has correct entry";
        like $entry, qr/\[EnvUI.log_test\]/, "...and has proper child name";
    }

    $api->log_file('');
    is $api->log_file, '', "api log reset to no file";

    $api->log_level(-1);
    is $api->log_level, -1, "api log level reset to -1";

    is
        $log->file,
        't/test.log',
        "resetting \$api->log_file doesn't affect existing logs";

    is $log->level, 7, "\$api->log_level doesn't affect existing logs";

    unlink 't/test.log' or die $!;
}

{ # level < -1

    my $w;
    local $SIG{__WARN__} = sub { $w = shift; };
    $api->log_level(-2);
    like $w, qr/^log level has to be between/, "log_level(-2) warns";
}

{ # level > 7

    my $w;
    local $SIG{__WARN__} = sub { $w = shift; };
    $api->log_level(8);
    like $w, qr/^log level has to be between/, "log_level(8) warns";
}

unconfig();
db_remove();
done_testing();

