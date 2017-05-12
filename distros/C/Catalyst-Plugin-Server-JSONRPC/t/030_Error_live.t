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

use JSON;
use HTTP::Request;
use Data::Dumper;

### Change config to show errors
TestApp->server->jsonrpc->config->show_errors(1);

my %RpcArgs     = ( 1 => "b" );
#my %RpcRv       = ( auto => 1, begin => 1, end => 1, input => \%RpcArgs );
my %RpcRv       = ( auto => 1, begin => 1, end => 1 );
my $EntryPoint  = 'http://localhost/rpc';
my $Prefix      = 'rpc.errors.';
my %Methods     = (
    # method name       # rv
    'privateonly'   => {'Error' => 'Invalid JSONRPC request: No such method',
                        'stash' => 'privateonly',
                        },
    'localonly'     => {'Error' => 'Invalid JSONRPC request: No such method',
                        'stash' => 'privateonly',
                        },
    ### Check if call does not fallback on another method
    'remoteonly.ne' => {'Error' => 'Invalid JSONRPC request: No such method',
                        'stash' => 'privateonly',
                        },
);


### Some defaults
sub shoot {
    my ($meth, $content) = @_;
    if (!$content) {
        my $call = {version=>'1.1', method=>$meth, params=>\%RpcArgs, id=>1};
        $content = JSON::to_json($call);
    }

    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($content) );
    $req->header( 'Content-Type'    => 'application/json' );
    $req->content( $content );
    my $res = request( $req );
}

while ( my($meth,$data) = each %Methods ) {

    my $res = shoot($meth);

    ok( $res,                   "Got response on '$meth'" );
    ok( $res->is_success,       "   Response successfull 2XX" );
    is( $res->code, 200,        "   Reponse code 200" );
    my $rv = JSON::from_json( $res->content );

    #is_deeply( $data, $rv,     "   Return value as expected" );
    is($rv->{error}->{message}, 'Invalid JSONRPC request: No such method', 'Got faultString "No such method"');
}

### This content is NOT VALID json check
{
    my $res = shoot((keys %Methods)[0], 'bLegH');
    my $data = JSON::from_json( $res->content );

    if (UNIVERSAL::isa($data, 'HASH') && $data->{error}) {
        like($data->{error}->{message}, qr/Invalid JSONRPC request.*malformed JSON string/s,'Got error "malformed JSON string"');
    }
}
