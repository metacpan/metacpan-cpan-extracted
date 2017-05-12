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

my %RpcArgs     = ( 1 => "b" );
my %RpcRv       = ( auto => 1, begin => 1, end => 1 );
my $EntryPoint  = 'http://localhost/rpc';
my $Prefix      = 'rpc.functions.';
my %Methods     = (
    'echo_fault'        => [ 101, 'echo_fault' ]
);

# init -- mention var twice due to warnings;
$RPC::XML::ENCODING = $RPC::XML::ENCODING = 'UTF-8';

while ( my($meth,$rv) = each %Methods ) {

    my $str = RPC::XML::request->new( 
                    $Prefix . $meth, 
                    input => \%RpcArgs 
                )->as_string;

    my $req = HTTP::Request->new( POST => $EntryPoint );
    $req->header( 'Content-Length'  => length($str) );
    $req->header( 'Content-Type'    => 'text/xml' );
    $req->content( $str );
    my $res = request( $req );

    ok( $res,                   "Got response on '$meth'" );
    ok( $res->is_success,       "   Response successfull 2XX" );
    is( $res->code, 200,        "   Reponse code 200" );

    my $data = RPC::XML::Parser->new->parse( $res->content )->value->value;
    my ($rv_code,$rv_msg) = @$rv; 
    is_deeply( $data->{faultCode}, $rv_code,     "   Return value of faultCode as expected" );
    is_deeply( $data->{faultString}, $rv_msg,     "   Return value of faultString as expected" );

    if( ref $data and ( reftype($data) eq 'HASH' ) ) {
        ok( (exists($data->{faultString})),
                                "   Faultstring present" );
        ok( (exists($data->{faultCode})),
                                "   Faultcode present" );

        diag( $data->{faultCode} . ' ' . $data->{faultString} )
            if $data->{faultString};
    }
}

