#!perl

use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/dispatch/lib";
    
    chdir 't' if -d 't';
    use lib qw[../lib inc];

    require 'local_request.pl';
}

use Test::More  'no_plan';
use Catalyst::Test 'TestApp';

use JSON;
use HTTP::Request;
use Data::Dumper;

my $EntryPoint  = 'http://localhost/rpc';
my @Methods     = qw[a 1];
    

# init -- mention var twice due to warnings;
for my $meth ( @Methods ) {

    my $call = {version=>'1.1', method=>$meth, params=>[], id=>1};
    my $str = JSON::to_json($call);


    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($str) );
    $req->header( 'Content-Type'    => 'application/json' );
    $req->content( $str );
    my $res = request( $req );
    
    ok( $res,                   "Got response on '$meth'" );
    ok( $res->is_success,       "   Response successfull 2XX" );
    is( $res->code, 200,        "   Reponse code 200" );
    
    my $data = JSON::from_json( $res->content )->{result};
    is_deeply( $data, $meth,    "   Return value as expected" );

    if( ref $data and UNIVERSAL::isa( $data, 'HASH' ) ) {
        ok( not(exists($data->{error})),
                                "   No faultstring" );
        ok( not(exists($data->{error})),
                                "   No faultcode" );
        
        diag( $data->{error} . ' ' . $data->{error}->{message} )
            if $data->{error};
    }
}
