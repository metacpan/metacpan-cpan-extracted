package Binance::API::Request;

# MIT License
#
# Copyright (c) 2017 Lari Taskula  <lari@taskula.fi>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;

use base 'LWP::UserAgent';

use Digest::SHA qw( hmac_sha256_hex );
use JSON;
use Time::HiRes;
use URI;
use URI::QueryParam;

use Binance::Constants qw( :all );

use Binance::Exception::Parameter::Required;

=head1 NAME

Binance::API::Request -- LWP::UserAgent wrapper for L<Binance::API>

=head1 DESCRIPTION

This module provides a wrapper for LWP::UserAgent. Generates required parameters
for Binance API requests.

=cut

sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new;

    $self->{apiKey}     = $params{'apiKey'};
    $self->{secretKey}  = $params{'secretKey'};
    $self->{recvWindow} = $params{'recvWindow'};
    $self->{baseUrl}    = $params{'baseUrl'};
    $self->{logger}     = $params{'logger'};

    bless $self, $class;
}

sub get {
    my ($self, $url, $params) = @_;

    my ($path, %data) = $self->_init($url, $params);
    return $self->_exec('get', $path, %data);
}

sub post {
    my ($self, $url, $params) = @_;

    my ($path, %data) = $self->_init($url, $params);
    return $self->_exec('post', $path, %data);
}

sub delete {
    my ($self, $url, $params) = @_;

    my ($path, %data) = $self->_init($url, $params);
    return $self->_exec('delete', $path, %data);
}

sub _exec {
    my ($self, $method, $url, %data) = @_;

    $self->{logger}->debug("New request: $url");
    $method = "SUPER::$method";
    my $response;
    if (keys %data > 0) {
        $response = $self->$method($url, %data);
    } else {
        $response = $self->$method($url);
    }
    if ($response->is_success) {
        $response = eval { decode_json($response->decoded_content); };
        if ($@) {
            $self->{logger}->error(
                "Error decoding response. \nStatus => " . $response->code . ",\n"
                . 'Content => ' . ($response->content ? $response->content : '')
            );
        }
    } else {
        $self->{logger}->error(
            "Unsuccessful request. \nStatus => " . $response->code . ",\n"
            . 'Content => ' . ($response->content ? $response->content : '')
        );
    }
    return $response;
}

sub _init {
    my ($self, $path, $params) = @_;

    unless ($path) {
        Binance::Exception::Parameter::Required->throw(
            error => 'Parameter "path" required',
            parameters => ['path']
        );
    }

    my $timestamp = $params->{'timestamp'};
    delete $params->{'timestamp'};
    # Delete undefined query parameters
    my $query = $params->{'query'};
    foreach my $param (keys %$query) {
        delete $query->{$param} unless defined $query->{$param};
    }

    # Delete undefined body parameters
    my $body = $params->{'body'};
    foreach my $param (keys %$body) {
        delete $body->{$param} unless defined $body->{$param};
    }

    my $recvWindow;
    if ($params->{signed}) {
        $recvWindow = $query->{'recvWindow'} // $body->{'recvWindow'} //
            defined $self->{'recvWindow'} ? $self->{'recvWindow'} : undef;
    }

    $timestamp //= int Time::HiRes::time * 1000 if $params->{'signed'};

    my $base_url = defined $self->{'baseUrl'} ? $self->{'baseUrl'} : BASE_URL;
    my $uri = URI->new( $base_url . $path );
    my $full_path = $uri->as_string;

    my %data;
    # Mixed request (both query params & body params)
    if (keys %$body && keys %$query) {
        if (!defined $body->{'recvWindow'} && defined $recvWindow) {
            $query->{'recvWindow'} = $recvWindow;
        }
        elsif (!defined $query->{'recvWindow'} && defined $recvWindow) {
            $body->{'recvWindow'} = $recvWindow;
        }

        # First, generate escaped parameter sets
        my $tmp = $uri->clone;
        $tmp->query_form($query);
        my $query_params = $tmp->query();
        $tmp->query_form($body);
        my $body_params = $tmp->query();

        # Add timestamp to the end of body
        $body_params .= "&timestamp=$timestamp" if defined $timestamp;

        # Combine query and body parameters so that we can sign it.
        # Binance documentation states that mixed content signature
        # generation should not add the '&' character between query
        # and body parameter sets.
        my $to_sign = $query_params . $body_params;

        $self->{logger}->debug("Generating signature from: '$to_sign'");

        $body_params .= '&signature='.hmac_sha256_hex(
            $to_sign, $self->{secretKey}
        ) if $params->{signed};

        $full_path .= "?$query_params";
        $data{'Content'} = $body_params;
    }
    # Query parameters only
    elsif (keys %$query || !keys %$query && !keys %$body) {
        $query->{'recvWindow'} = $recvWindow if $recvWindow;

        my $tmp = $uri->clone;
        $tmp->query_form($query);
        my $query_params = $tmp->query();

        # Add timestamp to the end of query
        $query_params .= "&timestamp=$timestamp" if defined $timestamp;

        $self->{logger}->debug("Generating signature from: '$query_params'")
            if $query_params;

        $query_params .= '&signature='.hmac_sha256_hex(
            $query_params, $self->{secretKey}
        ) if $params->{signed};

        $full_path .= "?$query_params" if $query_params;
    }
    # Body parameters only
    elsif (keys %$body) {
        $body->{'recvWindow'} = $recvWindow if $recvWindow;

        $full_path = $uri->as_string;

        my $tmp = $uri->clone;
        $tmp->query_form($body);
        my $body_params = $tmp->query();

        # Add timestamp to the end of body
        $body_params .= "&timestamp=$timestamp" if defined $timestamp;

        $self->{logger}->debug("Generating signature from: '$body_params'");

        $body_params .= '&signature='.hmac_sha256_hex(
            $body_params, $self->{secretKey}
        ) if $params->{signed};

        $data{'Content'} = $body_params;
    }

    if (defined $self->{apiKey}) {
        $data{'X_MBX_APIKEY'} = $self->{apiKey};
    }

    return ($full_path, %data);
}

1;
