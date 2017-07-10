use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Capture::Tiny 'capture_stderr';

{

    package MyApp;
    use Dancer2;
    set 'logger' => 'Console::Colored';

    get '/debug'   => sub { debug 'debug'; };
    get '/info'    => sub { info 'info'; };
    get '/warning' => sub { warning 'warning'; };
    get '/error'   => sub { error 'error'; };
}

my $app = MyApp->to_app;
isa_ok( $app, 'CODE' );

my $file     = __FILE__;
my %defaults = (
    debug   => "\e[1;94m",
    info    => "\e[1;32m",
    warning => "\e[1;33m",
    error   => "\e[1;33;41m",
);

test_psgi $app, sub {
    my $cb = shift;

    for my $level ( sort keys %defaults ) {
        my $stderr = capture_stderr { $cb->( GET "/$level" ) };

        like $stderr, qr{
            \Q$defaults{$level}\E   # color of this level, escaped
                $level              # name of the level
            \e\[0m                  # end of coloring
            \s                      # whitespace
            in                      # "in"
            \s                      # whitespace
            \e\[36m                 # cyan for the origin of the message
                \Q$file\E           # the origin of the message
            \e\[0m                  # end of coloring
            \s                      # whitespace
            l[.]                    # "l."
            \s                      # whitespace
            \e\[36m                 # cyan for the origin of the message
                \d+                 # we don't care about the line here
            \e\[0m                  # end of coloring
        }x, "$level message sent";
    }
};

done_testing;
