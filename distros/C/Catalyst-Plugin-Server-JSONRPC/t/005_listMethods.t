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


my @result =  (
   'rpc.also',
   'rpc.functions.echo_fault',
   'rpc.settings.test',
   'rpc.errors.remoteonly',
   'rpc.only',
   'rpc.functions.echo_plain',
   'rpc.functions.echo_plain_stash',
   'rpc.functions.echo.path.stash',
   'rpc.functions.echo.path'
);

my $EntryPoint  = 'http://localhost/rpc';


use JSON::RPC::Common::Marshal::Text;
use JSON;
my $m = JSON::RPC::Common::Marshal::Text->new;
my $call = {version=>'1.0', method=>'system.listMethods', params=>[], id=>1};
my $str = JSON::to_json($m->json_to_call(JSON::to_json($call))->deflate());

my $req = HTTP::Request->new( POST => $EntryPoint );
$req->header( 'Content-Length'  => length($str) );
$req->header( 'Content-Type'    => 'application/json' );
$req->content( $str );
my $res = request( $req );

ok( $res,                   "Got response ");
ok( $res->is_success,       "   Response successfull 2XX" );
is( $res->code, 200,        "   Reponse code 200" );

my $data = JSON::from_json( $res->content );
#die Dumper($data);
ok( !$data->{error},       "   No errors" );
ok( $data->{result},       "   Got result" );
my $is_array = ref $data->{result} eq 'ARRAY';
ok( $is_array ,       "   Is array. Dump:".Dumper($data) );

if ( $is_array ) {
    my @arr = @{$data->{result}};
    ok( scalar(@result) == scalar(@arr) ,       "   medhods count" );
    for(my $i=0;$i<scalar(@result);$i++){
        ok( $result[$i] eq $arr[$i] ,       $result[$i]."  ok " );
    }
}