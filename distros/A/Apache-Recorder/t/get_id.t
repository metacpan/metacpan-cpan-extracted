BEGIN { $| = 1; print "1..3\n"; }

END {print "not ok 2\n" unless $cookie;}
END {print "not ok 1\n" unless $loaded;}

use strict;
use vars qw( $loaded $storable $cookie );

use Apache::Recorder;
$loaded = 1;
print "ok 1\n";

use CGI::Cookie;
$cookie = 1;
print "ok 2\n";

########################################################
# Test Apache::Recorder::get_id()
########################################################

use lib "t/";
use Mock::Apache::Request;
my $cookie_id = '123456';
my $mock_r = new Mock::Apache::Request( 'cookie_id' => $cookie_id );

my $id = Apache::Recorder::get_id( $mock_r );
if ( $id eq $cookie_id ) { print "ok 3\n" }
else { print "not ok 3\n" }

