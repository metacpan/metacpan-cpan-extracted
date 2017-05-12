use strict;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

use Devel::Cycle;

use_ok('Catalyst::Test', 'TestApp');

my $ctx;
my $response;
ok((($response, $ctx) = ctx_request("/test_render?template=specified_template.tx&param=parameterized")), 'request ok');

#this is the kind that causes a mem leak
$ctx->view('Xslate::ExposeMethods')->render( $ctx, 'header.tx', $ctx->{stash} );

my $cycle_count = 0;
my $callback = sub { $cycle_count++ };

#shut up some warnings that mean nothing
%Devel::Cycle::already_warned = (
    REGEXP => 1,
    GLOB   => 1,
);

find_cycle( $ctx, $callback );
is $cycle_count, 0, 'no reference cycles found';