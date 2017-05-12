#!perl -T

use strict;
use warnings;
use Blitz;
use JSON::XS;
use MIME::Base64;

use Test::More tests => 12;
use Test::MockObject;

my $blitz = Blitz->new({ 
    username => 'me@foo.com',
    api_key  => '12121212-aaaaaaaa-bbbbbbbb-01010101',
});

my $start_job_error = {
    error => 'login',
    reason => 'You need to be signed in!!',
};

my $start_job_success = {
    ok => 1,
    job_id => 'california:1234',
    status => 'queued',
    region => 'california',
};

my $integer_test = { 
    url => 'http://falling-moon-908.heroku.com/iterate=#{iterate}',
    variables => {
        iterate => { type => 'number', min => 2, max => 4 },
    },  
    region => 'california',
};

my $integer_test_foo = {
    url => 'http://foo.com',
    variables => {
        var1 => { type => 'number', min => 2, max => 5 },
    },
};

my $start_job_error_json = encode_json($start_job_error);
my $start_job_success_json = encode_json($start_job_success);
my $integer_test_json = encode_json($integer_test);

my $content = encode_base64('content');
my $status = {
    _id => 'a123',
    ok => 1,
    result => {
        region => 'california',
        duration => 10,
        connect => 1,
        request => {
            line => 'GET / HTTP/1.1',
            method => 'GET',
            url => 'http://localhost:9295',
            headers => {},
            content => $content,
         },
         response => {
            line => 'GET / HTTP/1.1',
            message => 'message',
            status => 200,
            headers => {},
            content => $content,
         },
     },
};
my $status_success_json = encode_json($status);
my $client = $blitz->get_client;

sub _mock_server_response {
    my $method = shift;
    my $json = shift;
    my $lwp = Test::MockObject->new();
    $lwp->fake_module( 'LWP::UserAgent'=> (
        new => sub { $lwp },
    ));
    
    $lwp->mock( $method => sub {
        my $response = HTTP::Response->new;
        $response->code(200);
        $response->content($json);
        return $response;
    });
    return $lwp;
}

# start_job success
{
    my $lwp = _mock_server_response('post', $start_job_success_json);
    
    my $response = $client->start_job({});
    ok($response->{ok}, 'execute response ok');
    ok(!$response->{error}, 'no error on success');
    is($response->{job_id}, $start_job_success->{job_id}, 'id is returned correctly');

}

# start_job error
{
    my $lwp = _mock_server_response('post', $start_job_error_json);
    
    my $response = $client->start_job({});
    ok($response->{error}, 'start_job response correctly reports error');
    ok(!$response->{ok}, 'no ok on error');
    is($response->{reason}, $start_job_error->{reason}, 'error reason returned correctly');

}

# job status success
{
    my $lwp = _mock_server_response('get', $status_success_json);
    my $job_id = $client->job_id($status->{_id});
    my $response = $client->job_status();
    
    ok(!$response->{error}, 'job_status responds without error');
    ok($response->{ok}, 'no error on success');
    is($response->{_id}, $status->{_id}, 'job id returns correctly');
    is($response->{result}{request}{content}, 'content', 'request content was base64 encoded and decoded');
    is($response->{result}{response}{content}, 'content', 'response content was base64 encoded and decoded');

}

# integer test
{
    my $lwp = _mock_server_response('post', $integer_test_json);
    
    my $response = $client->start_job($integer_test);
    is_deeply($response, $integer_test, 'response and json are identical');
}
