use strict;
use warnings;

use Test::More tests => 6;

use_ok( 'Apps::Checkbook' );
use_ok( 'Apps::Checkbook::PayeeOr' );
use_ok( 'Apps::Checkbook::Trans' );
use_ok( 'Apps::Checkbook::Trans::Action' );
use_ok( 'Apps::Checkbook::NoOp' );
use_ok( 'Apps::Checkbook::SchTbl' );
