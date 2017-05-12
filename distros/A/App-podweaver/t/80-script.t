#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Command;

use File::Spec;

plan tests => 3;

my ( $script_dir, $perl, $script, $cmd, $tc );

$script_dir = 'script';

$script = File::Spec->catfile( $script_dir, 'podweaver' );

#  Untaint stuff so -T doesn't complain.
delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};   # Make %ENV safer

#  Ditto their perl location.
#  We run the script via the currently invoked perl, because the
#  shebang perl at the top of the script is probably the wrong version
#  under a smoke tester.
( $perl ) = $^X =~ /^(.*)$/;


#
#  1:  Script file exists.
ok( ( -e $script ), 'podweaver script found' );

#
#  2:  Script file is executable.
SKIP:
{
    skip 'Skip "is executable?" check for MSWin', 1 if $^O =~ /^MSWin/;
    ok( ( -x $script ), 'podweaver script is executable' );
}

#
#  3:  Does script compile as valid perl?
$cmd = "$perl -c $script";
#diag( "Testing script compiles with command: $cmd" );
$tc = Test::Command->new( cmd => $cmd );
$tc->stderr_like( qr/syntax OK$/, 'script compiles ok' );
