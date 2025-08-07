#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 4;

use Capture::Tiny ':all';

use File::Spec::Functions;

use File::Basename;


BEGIN {
    use_ok( 'App::ghmulti' ) || BAIL_OUT("Could not load module 'App::ghmulti'");
}


my $Ghmulti_Scr = catdir(dirname(__FILE__), qw(.. script ghmulti));

ok(-x $Ghmulti_Scr, "$Ghmulti_Scr is executable");

# Run it with `perl ...` so tests will work on Windows as well.
like(`perl $Ghmulti_Scr --version`,
     qr/\bghmulti:\s*\Q$App::ghmulti::VERSION\E\b/,
     'Option --version');

like(`perl $Ghmulti_Scr --help`,
     qr/\bghmulti - Helps when using multiple Github accounts with SSH keys\b/,
     'Option --help');
