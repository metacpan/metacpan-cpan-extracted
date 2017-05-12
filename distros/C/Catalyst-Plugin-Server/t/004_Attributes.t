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
TestApp->server->xmlrpc->config->show_errors(1);

# init -- mention var twice due to warnings;
$RPC::XML::ENCODING = $RPC::XML::ENCODING = 'UTF-8';

### Some defaults
sub shoot {
    my ($meth, $content) = @_;
    if (!$content) {
        $content = RPC::XML::request->new(
                        $RpcPrefix . $meth,
                        input => \%RpcArgs
                    )->as_string;
    }

    my $req = HTTP::Request->new( POST => $RpcEntryPoint );
    $req->header( 'Content-Length'  => length($content) );
    $req->header( 'Content-Type'    => 'text/xml' );
    $req->content( $content );
    my $res = request( $req );
}

while ( my($action, $data) = each %Setup ) {
    ### Check RPC
    {
        my $req = shoot($data->{rpc});
        my $res = RPC::XML::Parser->new->parse( $req->content )->value->value;
        if (grep(/^rpc$/, @{$data->{valid}})) {
            ok(!$res->{faultString},  'Got RPC response on ' . $data->{rpc});
        } else {
            is($res->{faultString}, 'Invalid XMLRPC request: No such method',
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

