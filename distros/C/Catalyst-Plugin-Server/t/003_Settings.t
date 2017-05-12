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

# init -- mention var twice due to warnings;
$RPC::XML::ENCODING = $RPC::XML::ENCODING = 'UTF-8';

my $EntryPoint  = 'http://localhost/rpc';
my $Method      = 'rpc.settings.test';


run_test( { input => { 1 => "b" } } );  # a single hashref
run_test( 1..9 );                       # a list of args

sub run_test {
    my @args = @_;

    my $str = RPC::XML::request->new( $Method, @args )->as_string;
    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($str) );
    $req->header( 'Content-Type'    => 'text/xml' );
    $req->content( $str );
    my $res = request( $req );
    
    ok( $res,                       "Got response on '$Method'" );
    ok( $res->is_success,           "   Response successfull 2XX" );
    is( $res->code, 200,            "   Reponse code 200" );
    
    my $data = RPC::XML::Parser->new->parse( $res->content )->value->value;

    ### general settings
    {   is( $data->{method}, $Method,
                                    "   Method name matches" );
    
        is( $data->{body}, $str,    "   Body as expected" );
        ok( $data->{is_xmlrpc},     "   Request got flagged as xmlrpc req" );                                
    }    
    
    ### ->param
    {   for my $key ( qw[xmlrpc_params catalyst_params] ) {
    
            ### different structure based on whether we sent a single
            ### hashref or somethign else
            is_deeply( $data->{$key}, ( @args == 1 ? @args : {} ),
                                    "   '$key' returned correctly" );
        }
        
        ok( $data->{'params_same'}, "       Params are identical" );
    }
    
    ### ->args
    {   for my $key ( qw[xmlrpc_args catalyst_args sub_args] ) {
    
            is_deeply( $data->{$key}, \@args,
                                    "   '$key' returned correctly" ); 
        }
        
        #ok( $data->{'args_same'},   "       Args are identical" );    
    }
}
