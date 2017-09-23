#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Cwd;
use File::Spec;

use Test::More;

main();

sub main {
    require_ok('bin/sshss') or BAIL_OUT();

    my $script_basedir = File::Spec->catdir( cwd(), 'bin' );

    # Remove the drive for Windows to make the test pass
    ( undef, $script_basedir, undef ) = File::Spec->splitpath( $script_basedir, 1 );
    is( App::SSH::SwitchShell::get_abs_script_basedir(), $script_basedir, 'get_abs_script_basedir() returns the correct path' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
