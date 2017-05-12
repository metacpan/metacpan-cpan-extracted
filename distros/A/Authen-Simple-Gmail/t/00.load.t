use strict;
use warnings;

use Test::More tests => 4;
use Net::Detect;
use File::Slurp;

require_ok('Authen::Simple::Gmail');

diag("Testing Authen::Simple::Gmail $Authen::Simple::Gmail::VERSION");

my $gmail_auth = new_ok('Authen::Simple::Gmail');

SKIP: {

    # better way? patches welcome!
    my ( $username, $password ) = -e '.gmail.test.config' ? File::Slurp::read_file('.gmail.test.config') : ();
    chomp($username) if defined $username;
    chomp($password) if defined $password;
    skip 'Please specify a valid username and password (in that order on a line by itself) in .gmail.test.config', 2 unless $username && $password;

  SKIP: {
        skip 'These tests require connectivity to pop.gmail.com over port 995.', 2 unless detect_net( 'pop.gmail.com', 995 );

        ok( $gmail_auth->authenticate( $username, $password ), 'authenticate() valid credentials return true' );

        ok( !$gmail_auth->authenticate( $username, $password . $$ . time ), 'authenticate() invalid credentials return false' );
    }
}
