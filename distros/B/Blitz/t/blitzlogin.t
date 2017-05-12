#!perl -T

use strict;
use warnings;
use Blitz;
use Blitz::API;
use JSON::XS;

use Test::More tests => 10;
use Test::MockObject;

my $blitz = Blitz->new({ 
    username => 'me@foo.com',
    api_key  => '12121212-aaaaaaaa-bbbbbbbb-01010101',
});

my $client = $blitz->get_client;
my $expected = {
    login => {
        success => "{\"api_key\":\"34343434-abcabcab-99999999-abacab12\",\"ok\":true}",
        fail    => "{\"reason\":\"authentication failed\",\"error\":\"login\"}",
    },
    execute => {
        success => "{\"ok\":true,\"job_id\":\"a123\"}",
        # XXX: check to see what an expected failure message really would look like
        fail    => "{\"reason\":\"timeout\",\"error\":\"server\"}",
    },
    abort => {
        success => "{}",
        fail    => "{}",
    },
};

sub _mock_server {
    my $lwp = Test::MockObject->new();
    $lwp->fake_module( 'LWP::UserAgent'=> (
        new => sub { $lwp },
    ));
    return $lwp;
}
 
# Successful login
{
    my $lwp = _mock_server();
    
    $lwp->mock( get => sub {
        # Return a hand crafted HTTP::Response object
        my $response = HTTP::Response->new;
        $response->code(200);
        $response->content($expected->{login}{success});
        return $response;
    });

    my $response = $client->login();
    my $success_hash = decode_json($expected->{login}{success});
    ok($response->{ok}, 'login response ok');
    ok(!$response->{error}, 'no error on success');
    is($response->{api_key}, $success_hash->{api_key}, 'api_key is correct');
}

# Server error
{
    my $lwp = _mock_server();
    
    $lwp->mock( get => sub {
        # Return a hand crafted HTTP::Response object
        my $response = HTTP::Response->new;
        $response->code(500);
        $response->content('');
        return $response;
    });

    my $response = $client->login();
    is($response->{error}, 'server');
    is($response->{cause}, 500);
}

# Failed login
{
    my $lwp = _mock_server();
    
    $lwp->mock( get => sub {
        # Return a hand crafted HTTP::Response object
        my $response = HTTP::Response->new;
        $response->code(200);
        $response->content($expected->{login}{fail});
        return $response;
    });

    my $response = $client->login();
    my $fail_hash = decode_json($expected->{login}{fail});
    ok($response->{reason}, 'error reason as expected');
    is($response->{error}, $fail_hash->{error}, 'error response as expected');
}

# Execute success
{
    my $lwp = _mock_server();
    
    $lwp->mock( post => sub {
        my $response = HTTP::Response->new;
        $response->code(200);
        $response->content($expected->{execute}{success});
        return $response;
    });
    
    my $response = $client->start_job( { region => 'california', url => '127.0.0.1', } );
    my $exec_hash = decode_json($expected->{execute}{success});

    ok($response->{ok}, 'execute response ok');
    ok(!$response->{error}, 'no error on success');
    is($response->{job_id}, $exec_hash->{job_id}, 'id is returned correctly');
}

