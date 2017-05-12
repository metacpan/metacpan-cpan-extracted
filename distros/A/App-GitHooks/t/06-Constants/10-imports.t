#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


note( 'Import with :HOOK_EXIT_CODES.');
use_ok( 'App::GitHooks::Constants', ':HOOK_EXIT_CODES' );

note( 'Import with :PLUGIN_RETURN_CODES.' );
use_ok( 'App::GitHooks::Constants', ':PLUGIN_RETURN_CODES' );
