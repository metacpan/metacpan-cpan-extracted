#!perl
BEGIN {
    chdir 't' if -d 't';
    use lib qw[../lib/ lib/];
}

use Test::More 'no_plan';
use Catalyst::Test 'TestApp';
use Data::Dumper;

{
    my %tests = (
            noregister => {
                    method      => 'noregister',
                    response    => 'noregister',
                },
            register => {
                    method      => 'register',
                    response    => 'register',
                },
            novalidate => {
                    method      => 'novalidate',
                    response    => 'novalidate',
                },
            validate => {
                    method      => 'validate',
                    response    => 'validate',
                    get         => 'test=ja',
                },
            describe => {
                    method      => 'describe',
                    response     => 'describe',
                },
            checkparams_empty => {
                    method      => 'checkparams',
                    response    => 'invalid_params',
                },
            checkparams_unknown => {
                    method      => 'checkparams',
                    noresponse  => 'vier',
                    get         => 'een=uno&twee=2&drie=1',
                },
            checkparams_allowunknown => {
                    method      => 'checkparamsunkn',
                    response    => 'vier',
                    get         => 'een=uno&twee=2&drie=1&vier=a',
                },
            checkparams_required => {
                    method      => 'checkparams',
                    response    => 'validated_params',
                    get         => 'een=uno&twee=2',
                },
            checkparamspc_unknown => {
                    method      => 'checkparamspc',
                    noresponse  => 'vier',
                    get         => 'een=uno&twee=2&drie=1',
                },
            checkparamspc_allowunknown => {
                    method      => 'checkparamsunknpc',
                    response    => 'vier',
                    get         => 'een=uno&twee=2&drie=1&vier=a',
                },
            checkparamspc_required => {
                    method      => 'checkparamspc',
                    response    => 'validated_params',
                    get         => 'een=uno&twee=2',
                },
            checkparamspc_empty => {
                    method      => 'checkparamspc',
                    response    => 'invalid_params',
                },
        );
    my $reqtest = 0;

    foreach my $test (keys %tests) {
        my $response;
        my $url = '/functions/' . $tests{$test}->{method};
        $url .= '/?' . $tests{$test}->{get} if $tests{$test}->{get};
        if (!$reqtest) {
            $response = request($url);
        } else {
            ok($response = request($url), 'Request OK');
        }
        if ($tests{$test}->{response}) {
            like( $response->content, qr/$tests{$test}->{response}/,  $test . ' profile check');
        } elsif ($tests{$test}->{noresponse}) {
            unlike( $response->content, qr/$tests{$test}->{noresponse}/,  $test . ' profile check');
        }
    }
}


1;
