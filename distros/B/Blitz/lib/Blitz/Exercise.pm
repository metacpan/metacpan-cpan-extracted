package Blitz::Exercise;

use strict;
use warnings;

use Blitz;
use Blitz::API;
use Blitz::Validate;
use MIME::Base64;
use JSON::XS;
use LWP;
use Storable qw(dclone);

=head1 NAME

Blitz::Exercise - Superclass for Sprint and Rush modules

=head1 SUBROUTINES/METHODS


=head2 new

Create a blitz exercise object for executing sprints or rushes

Required parameters are a set of options to run the test, and a callback 
closure to execute after each communication with the blitz.io servers

=cut

sub new {
    my ($name, $blitzObj, $options, $callback) = @_;
    # convenience vars
    my $self = {
        blitzObj    => $blitzObj,
        options     => $options,
        callback    => $callback,
        job_id      => 0,
    };

    bless $self;
    return $self;
}

=head2 blitzObj

Returns the blitzObj for a given exercise

=cut

sub blitzObj {
    my $self = shift;
    return $self->{blitzObj};
}

=head2 execute

Executes an exercise (a sprint or a rush)

=cut

sub execute {
    my $self = shift;
    my $blitz = $self->blitzObj();
    my $client = Blitz::get_client($self->blitzObj());
    
    my $clone = dclone($self->{options});
    my ($valid, $result) = Blitz::Validate::validate($clone, $self->{test_type});
    
    if (!$valid) {
        &{$self->{callback}}($result, $result->{error});
    }
    else {
        # send execute request to host

        my $response = $client->start_job($self->{options}, $self->{callback});

        if ($response->{job_id}) {
            my $job_id = $client->job_id($response->{job_id});
            my $status = $client->status;
            # wait 2 secs, then get status
            until ($status eq 'completed' or 
                    $status eq 'fail') {
                sleep 2;
                $response = $client->job_status;
                $status = $client->status;

                my $error = 0;
                if ($response->{error}) {
                    $error = $response->{error};
                }
                elsif (         
                    $response->{result} && 
                    $response->{result}{error}
                ) {
                    $error = $response->{result}{error};
                }
                if ($error) {
                    $status = 'fail';
                    &{$self->{callback}}($response, $error);
                }
                else {
                    $status = $response->{status};
                    &{$self->{callback}}($response, $error);
                }
                $client->status($status);
            }
        }
        else {
            # no id means failure
            &{$self->{callback}}($response, 'No job id returned');
        }
    }
    return $self;
}


return 1;
