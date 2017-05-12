use strict;
use warnings;

use Test::More tests => 18, import => ['!pass'];

use lib 't/lib';
use TestApp;
use Dancer;
use Dancer::Test;
  
use RPC::XML;
use Data::Dumper;

# test that the TestApp set up a route
route_exists [POST => '/xmlrpc'], '/xmlrpc route exists';
route_doesnt_exist [GET => '/xmlrpc'], 'GET /xmlrpc route does not exists' ;

# dont react to GET
response_status_is [GET => '/xmprpc'],  404,  "response for GET /xmlrpc is 404";

# do react to POST
response_status_is [POST => '/xmlrpc'],  200,  "response for POST /xmlrpc is 200";

# the response thing to use
my $resp;
my $rpcxmlresp;

my %faults = ( '' => -1, 'Bogus' => -2, '<something></something>' => -2 );

# test internal faults
foreach my $k ( keys %faults ) {
  $resp = dancer_response POST => '/xmlrpc', {body => $k};
  is ($resp->header('Content-Type'), "text/xml");
  $rpcxmlresp = RPC::XML::ParserFactory->new()->parse($resp->{content});
  ok ($rpcxmlresp->is_fault && $rpcxmlresp->value->code == $faults{$k});
}

# test generated fault
$resp = dancer_response POST => '/xmlrpc', {body => RPC::XML::request->new( 'testFault' )->as_string};
is ($resp->header('Content-Type'), "text/xml");
$rpcxmlresp = RPC::XML::ParserFactory->new()->parse($resp->{content});
ok ($rpcxmlresp->is_fault && $rpcxmlresp->value->code == 100);

# test a non-fault response
$resp = dancer_response POST => '/xmlrpc', {body => RPC::XML::request->new( 'someMethod', 'foo', 'bar' )->as_string};
is ($resp->header('Content-Type'), "text/xml");
$rpcxmlresp = RPC::XML::ParserFactory->new()->parse($resp->{content});
ok (ref $rpcxmlresp eq 'RPC::XML::response' );
ok (!$rpcxmlresp->is_fault);

my $val = $rpcxmlresp->value;
ok (ref $val eq 'RPC::XML::struct');

my $hash = $val->value;
ok ( defined( $hash->{methodWas} ) && $hash->{methodWas} eq 'someMethod' );
ok ( defined( $hash->{dataWas} ) && ref $hash->{dataWas} eq 'ARRAY' && $hash->{dataWas}[0] eq 'foo' && $hash->{dataWas}[1] eq 'bar' );
