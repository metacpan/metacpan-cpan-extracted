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

    my $self = {
        apiKey     => $params{'apiKey'},
        secretKey  => $params{'secretKey'},
        recvWindow => $params{'recvWindow'},
        logger     => $params{'logger'},
    };

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
                . 'Content => ' . $response->message ? $response->message : ''
            );
        }
    } else {
        $self->{logger}->error(
            "Unsuccessful request. \nStatus => " . $response->code . ",\n"
            . 'Content => ' . $response->message ? $response->message : ''
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
        $recvWindow = defined $self->{'recvWindow'}
            ? $self->{'recvWindow'} : 5000;
    }

    my $timestamp = int Time::HiRes::time * 1000 if $params->{'signed'};
    my $uri = URI->new( BASE_URL . $path );
    my $full_path;

    my %data;
    # Mixed request (both query params & body params)
    if (keys %$body && keys %$query) {
        if (!defined $query->{'recvWindow'} && defined $recvWindow) {
            $query->{'recvWindow'} = $recvWindow;
        }
        elsif (!defined $body->{'recvWindow'} && defined $recvWindow) {
            $body->{'recvWindow'} = $recvWindow;
        }

        $uri->clone->query_form($body);
        $uri->query_form($query);
        $full_path = $uri->as_string;
        $body->{signature} = hmac_sha256_hex(
            { %$body, %$query }, $self->{secretKey}
        ) if $params->{signed};
        $data{'Content'} = $body;
    }
    # Query parameters only
    elsif (keys %$query || !keys %$query && !keys %$body) {
        $query->{'timestamp'} = $timestamp if defined $timestamp;
        if (!defined $query->{'recvWindow'} && defined $recvWindow) {
            $query->{'recvWindow'} = $recvWindow;
        }

        $uri->query_form($query);
        if ($params->{signed}) {
            $query->{signature} = hmac_sha256_hex(
                $uri->query, $self->{secretKey}
            );
            $uri->query_form($query);
        }

        $full_path = $uri->as_string;
    }
    # Body parameters only
    elsif (keys %$body) {
        $body->{'timestamp'} = $timestamp if defined $timestamp;
        if (!defined $body->{'recvWindow'} && defined $recvWindow) {
            $body->{'recvWindow'} = $recvWindow;
        }

        $full_path = $uri->as_string;
        $uri->query_form($body);
        if ($params->{signed}) {
            $body->{signature} = hmac_sha256_hex(
                $uri->query, $self->{secretKey}
            );
            $uri->query_form($body);
        }

        $data{'Content'} = $uri->query;
    }

    if (defined $self->{apiKey}) {
        $data{'X_MBX_APIKEY'} = $self->{apiKey};
    }

    return ($full_path, %data);
}

1;
