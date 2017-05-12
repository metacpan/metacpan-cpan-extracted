package Blitz::API;

use strict;
use warnings;

use LWP;
use Blitz;
use JSON;
use MIME::Base64;

=head1 NAME

Blitz::API - Perl module for API access to Blitz

=cut

=head1 SUBROUTINES/METHODS

=head2 client

Create a blitz client object for executing sprints or rushes

Required parameters are credentials (email address and api-key)

See http://blitz.io for information regarding the api key.

=cut

sub client {
    my $this = shift;
    my $creds = shift;
    my $self = {
        credentials => $creds,
        job_id => undef,
        job_status => 'idle',
    };
    bless $self;
    return $self;
}

=head2 status

status is a get/set method for the current status of a running exercise

=cut

sub status {
    my $self = shift;
    my $status = shift;
    if ($status) {
        $self->{job_status} = $status;
    }
    
    return $self->{job_status};
}

sub _make_url {
    my $self = shift;
    my $path = shift;
    my $url = "http://" . $self->{credentials}{host}; # fix for https later?
    $url .= ":$self->{credentials}{port}" if $self->{credentials}{port} != 80;
    $url .= $path if $path;
    return $url;
}

sub _http_get {
    my $self = shift;
    my $path = shift;

    my $browser = LWP::UserAgent->new;
    my $url = _make_url($self, $path);
    my $response = $browser->get($url,
        'X-API-User'   => $self->{credentials}{username},
        'X-API-Key'    => $self->{credentials}{api_key},
        'X-API-Client' => 'Perl',
    );
    
    return $response;
}

=head2 _decode_response

Decodes the JSON result object from Blitz
Decodes base64 response in content areas of request and response

=cut

sub _decode_response {
    my $self = shift;
    my $response = shift;
    my $return = {};
    if ( $response->{_rc} != 200 ) {
        $return->{error} = 'server';
        $return->{cause} = $response->code();
    }
    else {
        $return = decode_json($response->{_content});
        for my $key ('request', 'response') {
            if ($return->{result}) {
                if ($return->{result}{$key} && $return->{result}{$key}{content}) {
                    $return->{result}{$key}{content} = decode_base64($return->{result}{$key}{content});    
                }    
            }
        }
    }

    return $return;
}

=head2 login

Sends the RESTful login request to blitz.io servers
When correctly executed, response contains a second api key that maintains
authentication permission for running tests.

=cut

sub login {
    my $self = shift;
    my $closure = shift;

    my $response = _http_get($self, '/login/api');
    my $result = _decode_response($self, $response);

    if ($closure) {
        &$closure($self, $result);
    }
    return $result;
}

=head2 job_id

Get/set method for the job_id attached to a given client object

=cut

sub job_id {
    my $self = shift;
    my $job_id = shift;
    $self->{job_id} = $job_id if $job_id;
    return $self->{job_id};
}

=head2 job_status

Sends RESTful request for job status of a given (known) job_id
Sets status of the job in the client object after response is returned

=cut

sub job_status {

    my $self = shift;
    my $job_id = $self->job_id;
    my $closure = $self->{callback};

    my $request = '/api/1/jobs/' . $job_id . '/status';
    my $response = _http_get($self, $request);
    
    my $result = _decode_response($self, $response);

    $self->status($result->{status});
    
    if ($closure) {
        &$closure($self, $result);
    }

    return $result;
}

=head2 start_job

Executes an exercise (sprint or rush) on blitz.io

When this method runs successfully, job_id is returned and
the progress of the job can be queried with job_status()

=cut

sub start_job {
    my $self = shift;
    my $data = shift;
    my $closure = $self->{callback};
    
    my $json = encode_json($data);
        
    my $browser = LWP::UserAgent->new;
    my $url = _make_url($self, '/api/1/curl/execute');

    my $response = $browser->post($url,
        'X-API-User'     => $self->{credentials}{username},
        'X-API-Key'      => $self->{credentials}{api_key},
        'X-API-Client'   => 'Perl',
        'content-length' => length($json),
        Content          => $json,
    );
    my $result = _decode_response($self, $response);
    
    if ($closure) {
        &$closure($self, $result);
    }
    return $result;
}


return 1;
