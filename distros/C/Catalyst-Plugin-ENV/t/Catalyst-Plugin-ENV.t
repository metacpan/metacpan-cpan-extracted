package main;
use Test::More qw/no_plan/;
use FindBin qw($Bin);
use lib $Bin.'/../lib';
BEGIN { use_ok('Catalyst::Plugin::ENV') };

