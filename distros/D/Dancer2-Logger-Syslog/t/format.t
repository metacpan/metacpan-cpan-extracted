use strict;
use warnings;
no warnings 'redefine';

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

plan tests => 3;

use Sys::Syslog;

sub Sys::Syslog::openlog {
    pass "log opened";
}

sub Sys::Syslog::syslog {
    my( $level, $message ) = @_;
    subtest syslog => sub {
        plan tests    => 2;
        is $level     => 'debug';
        like $message => qr'\sdebug\s';
    }
}

{
    package MyApp;

    use Dancer2 0.151;
    use Dancer2::Logger::Syslog;

    set logger_format => '!%L!';
    set logger => 'syslog';

    get '/' => sub {
        debug( "debugging message" );
        'foo';
    };
}

my $app = MyApp->to_app;
my $test = Plack::Test->create($app);
my $res = $test->request( GET '/' );
is( $res->code, 200, '[GET /] Request successful' );

done_testing;
