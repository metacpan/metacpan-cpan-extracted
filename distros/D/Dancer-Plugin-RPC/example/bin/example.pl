#!/usr/bin/perl -w
use strict;

use Cwd qw(abs_path);
use Daemon::Control;

my $PORT = $ENV{APP_PORT} // 3000;
my $APP  = $ENV{APP_NAME} // 'example';
my $APP_DIR = abs_path('..') . "/$APP";

# Fake the `carton exec -- ...` effect
$ENV{'PERL5LIB'} = "$APP_DIR/local/lib/perl5";
chdir $APP_DIR or die $!;

Daemon::Control->new(
    {
        name => $APP,
        path => abs_path($0),

        program      => "$APP_DIR/local/bin/starman",
        program_args => [
            '-l', "0.0.0.0:$PORT",
            '--workers', '2',
            'bin/app.psgi'
        ],

        pid_file    => "$APP_DIR/$APP.pid",
        stderr_file => "$APP_DIR/$APP.err",
        stdout_file => "$APP_DIR/$APP.out",

        fork => 1,
    }
)->run;
