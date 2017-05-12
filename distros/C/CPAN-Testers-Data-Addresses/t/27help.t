#!/usr/bin/perl -w
use strict;

use Test::More;

#----------------------------------------------------------------------------#
# SKIP OPTIONAL TEST

# Code below shamelessly stolen from XIONG/Error-Base-v1.0.2 :)

my $module_loaded;

# Load non-core modules conditionally
BEGIN{
    my $diag   = 'load-test-trap';
    eval{
        require Test::Trap;                     # Block eval on steroids
        Test::Trap->import (qw/ :default /);
    };
    $module_loaded    = !$@;                    # loaded if no error
                                                # must be package variable
                                                # to escape BEGIN block
    if ( $module_loaded ) {
        note($diag);
    } else {
        diag('Test::Trap required to execute this test script; skipping.');
        pass();
        done_testing(1);
        exit 0;
    };
}; ## BEGIN

#----------------------------------------------------------------------------#

plan tests => 10;

SKIP: {
    skip 'Test::Trap required for testing help features; skipping.', 10 unless($module_loaded);
    
    use CPAN::Testers::Data::Addresses;

    my $VERSION = '0.17';

    my $obj;
    my $stdout;
    my $config = 't/20attributes.ini';

    {
        trap { $obj = CPAN::Testers::Data::Addresses->new() };

        like($trap->stdout,qr/Must specify the configuration file/,'.. no file name');
        like($trap->stdout,qr/Usage:.*--config|c=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::Data::Addresses->new( config => 'bogus.file' ) };

        like($trap->stdout,qr/Configuration file .*? not found/,'.. no file found');
        like($trap->stdout,qr/Usage:.*--config|c=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::Data::Addresses->new( config =>  $config, help => 1 ) };

        like($trap->stdout,qr/Usage:.*--config|c=<file>/,'.. got help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

    {
        trap { $obj = CPAN::Testers::Data::Addresses->new( config => $config, version => 1 ) };

        unlike($trap->stdout,qr/Usage:.*--config|c=<file>/,'.. no help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

    {
        unshift @ARGV, '--help';
        trap { $obj = CPAN::Testers::Data::Addresses->new( config =>  $config ) };

        like($trap->stdout,qr/Usage:.*--config|c=<file>/,'.. got help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }
}
