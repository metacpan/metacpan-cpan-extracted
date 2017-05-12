use strict;
use warnings;
use lib 't/lib';
use Test::More;
use JSON::Any;
use HTTP::Request::Common;
use utf8;

BEGIN {
    use_ok 'Catalyst::Test', 'Simple';
}

my $param = { foo => 'áçéò' };
my ( $res, $ctx ) = ctx_request(
    '/?' . 'param='
    . JSON::Any->new->encode($param)
);
my $req = $ctx->req;
is_deeply($req->dparams, $req->decoded_parameters);
is_deeply($req->dparams, $req->decoded_params);
is_deeply($req->decoded_params->{'param'}, $param);
is_deeply($req->dquery_params->{'param'}, $param);

( $res, $ctx ) = ctx_request( POST('/', {
    param => JSON::Any->new->encode($param)
}));
$req = $ctx->req;
is_deeply($req->dparams, $req->decoded_parameters);
is_deeply($req->dparams, $req->decoded_params);
is_deeply($req->decoded_params->{'param'}, $param);
is_deeply($req->dbody_params->{'param'}, $param);

done_testing;
