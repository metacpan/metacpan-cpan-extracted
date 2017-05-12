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

#use HTTP::Request;
use Data::Dumper;


my %Setup       = (
        'webonly'   => {
            web => '/web/only',
            rpc => 'web.only',
            valid => [ 'web' ],
            },
        'rpconly'   => {
            web => '/rpc/only',
            rpc => 'rpc.only',
            valid => [ 'rpc' ],
            },
        'webandrpc' => {
            web => '/web/also',
            rpc => 'rpc.also',
            valid => [ 'web', 'rpc' ],
            },
        );

my %RpcArgs         = ( hello => "world" );
my $RpcEntryPoint   = 'http://localhost/rpc';
my $RpcPrefix       = '';

### Change config to show errors
TestApp->server->jsonrpc->config->show_errors(1);


### Some defaults
sub shoot {
    my ($meth, $content) = @_;
    if (!$content) {
        my $call = {version=>'1.1', method=>$RpcPrefix . $meth, params=>\%RpcArgs, id=>1};
        $content = JSON::to_json($call);
    }

    my $req = HTTP::Request->new( POST => $RpcEntryPoint );
    $req->header( 'Content-Length'  => length($content) );
    $req->header( 'Content-Type'    => 'application/json' );
    $req->content( $content );
    my $res = request( $req );
}

while ( my($action, $data) = each %Setup ) {
    ### Check RPC
    {
        my $req = shoot($data->{rpc});
        my $res = JSON::from_json( $req->content );
        if (grep(/^rpc$/, @{$data->{valid}})) {
            ok(!$res->{error},  'Got RPC response on ' . $data->{rpc});
        } else {
            is($res->{error}->{message}, 'Invalid JSONRPC request: No such method',
                                'Got invalid RPC method ' . $data->{rpc});
        }
    }

    ### Check Web
    {
        my $res = get($data->{web});
        if (grep(/^web$/, @{$data->{valid}})) {
            ok($res =~ /$action/,  'Got WEB response on ' . $data->{web});
        } else {
            ok($res !~ /$action/,
                                'Got no WEB method ' . $data->{web});
        }
    }
}

