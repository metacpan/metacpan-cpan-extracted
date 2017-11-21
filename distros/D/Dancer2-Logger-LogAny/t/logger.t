use strict; use warnings;
use Test::More;

use Dancer2 qw/ !log !pass /;
use Plack::Test;
use HTTP::Request::Common;

use Log::Any::Test;
use Log::Any qw/ $log /;

my @levels = ( qw/ debug info warning error / );

{
    package TestApp;

    use Dancer2;

    get '/debug'   => sub { debug 'debug-msg'; return 'debug-msg' };
    get '/info'    => sub { info 'info-msg'; return 'info-msg' };
    get '/warning' => sub { warning 'warning-msg'; return 'warning-msg' };
    get '/error'   => sub { error 'error-msg'; return 'error-msg' };

    1;
}

my $testapp = TestApp->to_app;

my $app_config = config;

my $test_config = {
    engines => {
        logger => {
            LogAny => {
                category => 'Testeroo',
                logger   => ['Stderr'],
            },
        },
    },
    logger => 'LogAny',
};

is_deeply( $app_config->{'engines'}, $test_config->{'engines'}, 'config `engines` section is as expected.' );
is( $app_config->{'logger'}, $test_config->{'logger'},          'Dancer2 logger is set to LogAny' );

test_psgi $testapp, sub {
    my $cb = shift;

    for my $level ( @levels ) {
        my $url = '/' . $level;
        my $message = $level . '-msg';
        my $res  = $cb->( GET $url );
        ok( $res->is_success,                                   "request to $url was successful" );
        is( $res->content, $message,                            '... page content is as expected' );

        my $messages = $log->msgs;

        pop @{ $messages }; # hook core.app.after_request 
        is_deeply(
            pop @{ $messages },
            {
                category => 'Testeroo',
                level    => ( $level eq 'core' ? 'info' : $level ),
                message  => "$message"
            },                                                  '... log content is as expected',
        );

        $log->clear;
    }
};

done_testing;

__END__
