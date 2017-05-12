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

my %RpcArgs     = ( 1 => "b" );
my %RpcRv       = ( auto => 1, begin => 1, end => 1 );
my $EntryPoint  = 'http://localhost/rpc';
my $Prefix      = 'rpc.functions.';
my %Methods     = (
    'echo_fault'        => [ 101, 'echo_fault' ]
);

while ( my($meth,$rv) = each %Methods ) {

    my $call = {version=>'1.1', method=>$Prefix . $meth, params=>\%RpcArgs, id=>1};
    my $str = JSON::to_json($call);

    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($str) );
    $req->header( 'Content-Type'    => 'application/json' );
    $req->content( $str );
    my $res = request( $req );

    ok( $res,                   "Got response on '$meth'" );
    ok( $res->is_success,       "   Response successfull 2XX" );
    is( $res->code, 200,        "   Reponse code 200" );

    my $data = JSON::from_json( $res->content )->{error};
    my ($rv_code,$rv_msg) = @$rv; 
    is_deeply( $data->{code}, $rv_code,     "   Return value of faultCode as expected" );
    is_deeply( $data->{message}, $rv_msg,     "   Return value of faultString as expected" );

    if( ref $data and UNIVERSAL::isa( $data, 'HASH' ) ) {
        ok( (exists($data->{message})),
                                "   Faultstring present" );
        ok( (exists($data->{code})),
                                "   Faultcode present" );

        diag( $data->{code} . ' ' . $data->{message} )
            if $data->{message};
    }
}

