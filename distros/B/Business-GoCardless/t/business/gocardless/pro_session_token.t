#!perl

use strict;
use warnings;

use Test::Most;
use HTTP::Response;

use Business::GoCardless::Pro;

my $GoCardless = Business::GoCardless::Pro->new( token => 'foo' );

my @requests;
my ( $mandate,$served );

no warnings 'redefine';
*LWP::UserAgent::request = sub {
    my ( $ua,$req ) = @_;
    push( @requests,$req->method . ' ' . $req->uri->path );
    my $res = HTTP::Response->new( 200 );
    $res->content(
        $req->uri->path eq '/payments'
            ? '{"payments":{"id":"PM123","links":{"mandate":"MD123"}}}'
            : '{"redirect_flows":{"id":"RE123",'
                . ( defined $served ? qq{"session_token":"$served",} : '' )
                . '"links":{' . ( $mandate ? '"mandate":"MD123"' : '' ) . '}}}'
    );
    return $res;
};

foreach my $case (
    [ 0,'SESS_1','SESS_2' ], # incomplete flow, another session's token
    [ 1,'SESS_1','SESS_2' ], # flow with a mandate, another session's token
    [ 1,undef,'' ],          # flow without a token, empty token
) {
    ( $mandate,$served,my $token ) = @{ $case };
    @requests = ();

    throws_ok(
        sub {
            $GoCardless->confirm_resource(
                redirect_flow_id => 'RE123',
                session_token    => $token,
                type             => 'payment',
                amount           => 100,
                currency         => 'GBP',
            );
        },
        'Business::GoCardless::Exception',
        "->confirm_resource checks session_token ('$token')",
    );

    like( $@->message,qr/session_token does not match/,' ... and throws expected error' );
    is_deeply( \@requests,[ 'GET /redirect_flows/RE123' ],' ... and creates nothing' );
}

done_testing();
