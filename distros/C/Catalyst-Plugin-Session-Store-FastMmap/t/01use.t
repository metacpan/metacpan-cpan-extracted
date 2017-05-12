use strict;
use Test::More tests => 1;

BEGIN { use_ok('Catalyst::Plugin::Session::Store::FastMmap') }

diag("testing Catalyst::Plugin::Session::Store::FastMmap version $Catalyst::Plugin::Session::Store::FastMmap::VERSION");
