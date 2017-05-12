use strict;
use warnings;
no warnings 'redefine';

use Test::More;
use Dancer::Test;

plan tests => 3;

use Sys::Syslog;

sub Sys::Syslog::openlog {
    pass "log opened";
}

sub Sys::Syslog::syslog {
    my( $level, $message ) = @_;
    subtest syslog => sub {
        plan tests => 2;
        is $level => 'debug';
        like $message => qr'!debug!';
    }
}

{
    package MyApp;

    use Dancer;
    use Dancer::Logger::Syslog;

    set logger_format => '!%L!';
    set logger => 'syslog';

    get '/' => sub {
        debug( "debugging message" );
        'foo';
    };
}

response_status_is '/' => 200;





