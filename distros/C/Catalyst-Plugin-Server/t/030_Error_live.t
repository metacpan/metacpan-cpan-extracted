#!perl

use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/lib";
    
    chdir 't' if -d 't';
    use lib qw[../lib inc];

    require 'local_request.pl';
}

use Test::More  'no_plan';
use Catalyst::Test 'TestApp';

use RPC::XML;
use HTTP::Request;
use Data::Dumper;

use Scalar::Util 'reftype';

### Change config to show errors
TestApp->server->xmlrpc->config->show_errors(1);

my %RpcArgs     = ( 1 => "b" );
#my %RpcRv       = ( auto => 1, begin => 1, end => 1, input => \%RpcArgs );
my %RpcRv       = ( auto => 1, begin => 1, end => 1 );
my $EntryPoint  = 'http://localhost/rpc';
my $Prefix      = 'rpc.errors.';
my %Methods     = (
    # method name       # rv
    'privateonly'   => {'Error' => 'Invalid XMLRPC request: No such method',
                        'stash' => 'privateonly',
                        },
    'localonly'     => {'Error' => 'Invalid XMLRPC request: No such method',
                        'stash' => 'privateonly',
                        },
    ### Check if call does not fallback on another method
    'remoteonly.ne' => {'Error' => 'Invalid XMLRPC request: No such method',
                        'stash' => 'privateonly',
                        },
);


# init -- mention var twice due to warnings;
$RPC::XML::ENCODING = $RPC::XML::ENCODING = 'UTF-8';

### Some defaults
sub shoot {
    my ($meth, $content) = @_;
    if (!$content) {
        $content = RPC::XML::request->new(
                        $Prefix . $meth,
                        input => \%RpcArgs
                    )->as_string;
    }

    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($content) );
    $req->header( 'Content-Type'    => 'text/xml' );
    $req->content( $content );
    my $res = request( $req );
}

while ( my($meth,$data) = each %Methods ) {

    my $res = shoot($meth);

    ok( $res,                   "Got response on '$meth'" );
    ok( $res->is_success,       "   Response successfull 2XX" );
    is( $res->code, 200,        "   Reponse code 200" );

    my $rv = RPC::XML::Parser->new->parse( $res->content )->value->value;
    #is_deeply( $data, $rv,     "   Return value as expected" );
    is($rv->{faultString}, 'Invalid XMLRPC request: No such method', 'Got faultString "No such method"');
}

### This content is NOT VALID xml check
{
    my $res = shoot((keys %Methods)[0], 'bLegH');
    my $data = RPC::XML::Parser->new->parse( $res->content )->value->value;

    if ((reftype($data) eq 'HASH') && $data->{faultString}) {
        like($data->{faultString}, qr/Invalid XMLRPC request.*syntax error/s,'Got faultString "syntax error"');
    }
}
