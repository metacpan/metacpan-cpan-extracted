use strict ;
use warnings ;
use Apache::Test () ;
use Apache::TestRequest qw(GET) ;
use Apache2::Const qw(:http) ;

# Here we simply run the Client tests after setting up the correct URL.
my $url = Apache::TestRequest::module2url('', {path => '/httunnel'}) ;

$HTTunnel::Client::Test::URL = undef ; # stupid warning
$HTTunnel::Client::Test::URL = $url ;
$HTTunnel::Client::Test::ExtraTests = undef ; # stupid warning
$HTTunnel::Client::Test::ExtraTests = 1 ;

require "Client/t/HTTunnel-Client.t" ;

# Exceptions
my $resp = GET $HTTunnel::Client::Test::URL ;
ok($resp->code(), Apache2::Const::HTTP_METHOD_NOT_ALLOWED()) ;

