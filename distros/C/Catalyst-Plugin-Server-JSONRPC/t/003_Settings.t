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

use HTTP::Request;
use Data::Dumper;


my $EntryPoint  = 'http://localhost/rpc';
my $Method      = 'rpc.settings.test';


run_test( '1.1', { input => { 1 => "b" } } );  # a single hashref
run_test( '1.0', [1..9] );                       # a list of args

sub run_test {
    my ($ver, $arg) = @_;

    use JSON::RPC::Common::Marshal::Text;
    use JSON;
    my $m = JSON::RPC::Common::Marshal::Text->new;
    my $call = {version=>$ver, method=>$Method, params=>$arg, id=>1};
    my $str = JSON::to_json($m->json_to_call(JSON::to_json($call))->deflate());

    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($str) );
    $req->header( 'Content-Type'    => 'application/json' );
    $req->content( $str );
    my $res = request( $req );
    
    ok( $res,                       "Got response on '$Method'" );
    ok( $res->is_success,           "   Response successfull 2XX" );
    is( $res->code, 200,            "   Reponse code 200" );
    
    my $data = JSON::from_json( $res->content )->{result};

    #warn Dumper($data);
    
    ### general settings
    {   is( $data->{method}, $Method,
                                    "   Method name matches" );
    
        is( $data->{body}, $str,    "   Body as expected" );
        ok( $data->{is_jsonrpc},     "   Request got flagged as jsonrpc req" );                                
    }    
    
    ### ->param (skip for JSON::RPC 1.0)
    if ($ver ne '1.0')
    {   for my $key ( qw[jsonrpc_params catalyst_params] ) {
    
            ### different structure based on whether we sent a single
            ### hashref or somethign else
            is_deeply( $data->{$key}, $arg ,
                                    "   '$key' returned correctly" );
        }
        
        ok( $data->{'params_same'}, "       Params are identical" );
    }
    
    ### ->args
    {   for my $key ( qw[jsonrpc_args catalyst_args sub_args] ) {
    
            is_deeply( $data->{$key}, (ref $arg eq 'HASH'? [%$arg]: $arg),
                                    "   '$key' returned correctly" ); 
        }
        
        #ok( $data->{'args_same'},   "       Args are identical" );    
    }
}
