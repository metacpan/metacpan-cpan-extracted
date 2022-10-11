#!/usr/bin/env perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../local/lib/perl5";

use Cwd qw(abs_path);
use Daemon::Control;

my $PORT = $ENV{APP_PORT} // 3333;
my $APP  = $ENV{APP_NAME} // 'example';
my $APP_DIR = abs_path('..') . "/$APP";

# Fake the `carton exec -- ...` effect
$ENV{'PERL5LIB'} = "$APP_DIR/local/lib/perl5:$APP_DIR/lib";
chdir $APP_DIR or die "$APP_DIR: $!";

Daemon::Control->new(
    {
        name => $APP,
        path => $APP_DIR, #abs_path($0),

        program      => "$APP_DIR/local/bin/starman",
        program_args => [
            '-l', "0.0.0.0:$PORT",
            '--workers', '1',        # 1 worker for the in-memory db
            "$APP_DIR/bin/app.psgi",
        ],

        pid_file    => "$APP_DIR/$APP.pid",
        stderr_file => "$APP_DIR/$APP.err",
        stdout_file => "$APP_DIR/$APP.out",

        fork => 1,
    }
)->run;
