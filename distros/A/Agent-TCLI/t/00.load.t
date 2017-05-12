use Test::More tests => 18;

# $Id: 00.load.t 49 2007-04-25 10:32:36Z hacker $

BEGIN {
use_ok( 'Agent::TCLI' );
}

diag( "Testing Agent::TCLI::Base $Agent::TCLI::VERSION" );

use_ok( 'Agent::TCLI::Base' );
use_ok( 'Agent::TCLI::Command' );
use_ok( 'Agent::TCLI::Control' );
use_ok( 'Agent::TCLI::Parameter' );
use_ok( 'Agent::TCLI::Request' );
use_ok( 'Agent::TCLI::Response' );
use_ok( 'Agent::TCLI::User' );
use_ok( 'Agent::TCLI::Transport::Base' );
use_ok( 'Agent::TCLI::Transport::Test' );
use_ok( 'Agent::TCLI::Testee' );
use_ok( 'Agent::TCLI::Transport::XMPP' );
use_ok( 'Agent::TCLI::Package::Base' );
use_ok( 'Agent::TCLI::Package::UnixBase' );
use_ok( 'Agent::TCLI::Package::Tail' );
use_ok( 'Agent::TCLI::Package::XMPP' );
use_ok( 'Agent::TCLI::Package::Tail::Test' );
use_ok( 'Agent::TCLI::Package::Tail::Line' );


