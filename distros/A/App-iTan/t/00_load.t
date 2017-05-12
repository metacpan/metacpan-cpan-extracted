# -*- perl -*-

# t/00_load.t - check module loading and create testing directory

use Test::More tests => 8;

use_ok( 'App::iTan' );
use_ok( 'App::iTan::Utils' );
use_ok( 'App::iTan::Command::Get' );
use_ok( 'App::iTan::Command::Import' );
use_ok( 'App::iTan::Command::Info' );
use_ok( 'App::iTan::Command::List' );
use_ok( 'App::iTan::Command::Reset' );
use_ok( 'App::iTan::Command::Delete' );