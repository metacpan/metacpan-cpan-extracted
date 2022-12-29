=begin comment

Copyright (c) 2019 Aspose Pty Ltd

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=end comment

=cut

package AsposeSlidesCloud::ApiClient;

use strict;
use warnings;
use utf8;

use MIME::Base64;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request::Common qw(DELETE POST GET HEAD PUT);
use HTTP::Status;
use URI::Query;
use JSON;
use URI::Escape;
use Scalar::Util;
use Carp;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Log::Any::Adapter ('Stderr');
use AsposeSlidesCloud::ApiInfo;
use AsposeSlidesCloud::ClassRegistry;
use AsposeSlidesCloud::Configuration;

sub new {
    my $class = shift;

    my $config;

    my %params = @_;

    if (defined $params{config}) {
        $config = $params{config};
    } else {
        $config = AsposeSlidesCloud::Configuration->new(@_);
    }

    my $ua = LWP::UserAgent->new;

    if ($config->{allow_insecure_requests}) {
        $ua->ssl_opts(SSL_verify_mode => 0);
        $ua->ssl_opts(verify_hostname => 0);
    }

    if (defined $config->{http_request_timeout}) {
        $ua->{timeout} = $config->{http_request_timeout};
    }

    my (%args) = ('ua' => $ua, 'config' => $config);
  
    return bless \%args, $class;
}

# make the HTTP request
# @param string $resourcePath path to method endpoint
# @param string $method method to call
# @param array $queryParams parameters to be place in query URL
# @param array $postParams parameters to be placed in POST body
# @param array $headerParams parameters to be place in request header
# @param array $body_data data to be place in request body
# @param array $files files to be posted
# @return mixed
sub call_api {
    my $self = shift;
    my ($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $files) = @_;

    my $had_token = defined $self->{config}{access_token} && $self->{config}{access_token} ne "";
    my $response = $self->call_api_once($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $files);
    my $content = sprintf("%s", $response->content);
    if ($had_token && ($response->code eq 401 || ($response->code eq 500 && !$content))) {
        $self->{config}{access_token} = "";
        $response = $self->call_api_once($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $files);
        $content = sprintf("%s", $response->content);
    }
    unless ($response->is_success) {
        croak(sprintf "API Exception(%s): %s\n%s", $response->code, $response->message, $content);
    }
    return $content;
}

sub call_api_once {
    my $self = shift;
    my ($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $files) = @_;
  
    $self->update_headers($header_params);
  
    my $_url = $self->{config}{base_url}."/".$self->{config}{version}.$resource_path;

    # build query 
    if (%$query_params) {
        $_url = ($_url . '?' . eval { URI::Query->new($query_params)->stringify });
    }

    my $_body_data = %$post_params ? $post_params : $self->get_body_data($header_params, $body_data, $files);

    # Make the HTTP request
    my $_request;
    if ($method eq 'POST') {
        # multipart
        $header_params->{'Content-Type'} = lc $header_params->{'Content-Type'} eq 'multipart/form' ?
            'form-data' : $header_params->{'Content-Type'};
        $_request = POST($_url, %$header_params, Content => $_body_data);
  
    }
    elsif ($method eq 'PUT') {
        # multipart
        $header_params->{'Content-Type'}  = lc $header_params->{'Content-Type'} eq 'multipart/form' ? 
            'form-data' : $header_params->{'Content-Type'};
  
        $_request = PUT($_url, %$header_params, Content => $_body_data);

    }
    elsif ($method eq 'GET') {
        my $headers = HTTP::Headers->new(%$header_params);
        $_request = GET($_url, %$header_params);
    }
    elsif ($method eq 'HEAD') {
        my $headers = HTTP::Headers->new(%$header_params);
        $_request = HEAD($_url,%$header_params); 
    }
    elsif ($method eq 'DELETE') { #TODO support form data
        my $headers = HTTP::Headers->new(%$header_params);
        $_request = DELETE($_url, %$headers);
    }

    if ($self->{config}{debug}) {
        $log->info("REQUEST: %s", $_request->as_string);
    }

    my $_response = $self->{ua}->request($_request);

    if ($self->{config}{debug}) {
        $log->debugf("RESPONSE: %s", $_response->as_string);
    }
       
    return $_response;
}

# get request body
# @param array $headerParams parameters to be place in request header
# @param array $body_data data to be place in request body
# @param array $files files to be posted
# @return mixed
sub get_body_data {
    my $self = shift;
    my ($header_params, $body_data, $files) = @_;
    my $part_count = 0;
    if (defined $body_data) {
        if (!(ref $body_data eq "HASH") && $body_data->can('to_hash')) {
            $body_data = $body_data->to_hash;
        }
        if (ref $body_data eq "HASH") {
            $body_data = to_json($body_data); # model to json string
        }
    }
    if (defined $files) {
        $part_count += scalar @$files;
    }
    my $_body_data = "";
    if ($part_count > 0) {
        my $boundary = "7d70fb31-0eb9-4846-9ea8-933dfb69d8f1";
        $header_params->{'Content-Type'} = "multipart/form-data; boundary=${boundary}";
        if (defined $body_data) {
            $_body_data = $_body_data . "\r\n--${boundary}\r\n";
            $_body_data = $_body_data . "Content-Disposition: form-data; name=\"data\"\r\n";
            $_body_data = $_body_data . "Content-Type: text/json\r\n";
            $_body_data = $_body_data . "\r\n";
            $_body_data = $_body_data . $body_data;
        }
        my $fileIndex = 1;
        foreach (@$files) {
            $_body_data = $_body_data . "\r\n--${boundary}\r\n";
            $_body_data = $_body_data . "Content-Disposition: form-data; name=\"file${fileIndex}\";filename=\"file${fileIndex}\"\r\n";
            $_body_data = $_body_data . "Content-Type: application/octet-stream\r\n";
            $_body_data = $_body_data . "\r\n";
            $_body_data = $_body_data . $_;
            $fileIndex++;
        }
        $_body_data = $_body_data . "\r\n--${boundary}--\r\n";
    } elsif (defined $body_data) {
        $_body_data = $body_data;
    } elsif (defined $files) {
        $_body_data = @$files[0];
    }
    return $_body_data;
}

#  Take value and turn it into a string suitable for inclusion in
#  the path, by url-encoding.
#  @param string $value a string which will be part of the path
#  @return string the serialized object
sub to_path_value {
    my ($self, $value) = @_;
    return $self->to_string($value);
}

# Take value and turn it into a string suitable for inclusion in
# the query, by imploding comma-separated if it's an object.
# @param object $object an object to be serialized to a string
# @return string the serialized object
sub to_query_value {
      my ($self, $object) = @_;
      if (ref($object) eq 'ARRAY') {
          return join(',', @$object);
      } else {
          return $self->to_string($object);
      }
}

# Take boolean value and turn it into a string suitable for inclusion in
# the query, by imploding comma-separated if it's an object.
# @param object $object an object to be serialized to a string
# @return string the serialized object
sub to_boolean_query_value {
      my ($self, $value) = @_;
      if ($value) {
          return "true";
      } else {
          return "false";
      }
}

# Take value and turn it into a string suitable for inclusion in
# the header. If it's a string, pass through unchanged
# If it's a datetime object, format it in ISO8601
# @param string $value a string which will be part of the header
# @return string the header string
sub to_header_value {
    my ($self, $value) = @_;
    return $self->to_string($value);
}

# Take value and turn it into a string suitable for inclusion in
# the http body (form parameter). If it's a string, pass through unchanged
# If it's a datetime object, format it in ISO8601
# @param string $value the value of the form parameter
# @return string the form string
sub to_form_value {
    my ($self, $value) = @_;
    return $self->to_string($value);
}

# Take value and turn it into a string suitable for inclusion in
# the parameter. If it's a string, pass through unchanged
# If it's a datetime object, format it in ISO8601
# @param string $value the value of the parameter
# @return string the header string
sub to_string {
    my ($self, $value) = @_;
    if (ref($value) eq "DateTime") { # datetime in ISO8601 format
        return $value->datetime();
    }
    else {
        return sprintf("%s", $value);
    }
}

# Deserialize a JSON string into an object
#  
# @param string $class class name is passed as a string
# @param string $data data of the body
# @return object an instance of $class
sub deserialize
{
    my ($self, $class, $data) = @_;
  
    if (not defined $data) {
        return undef;
    } elsif ( (substr($class, 0, 5)) eq 'HASH[') { #hash
        if ($class =~ /^HASH\[(.*),(.*)\]$/) {
            my ($key_type, $type) = ($1, $2);
            my %hash;
            my $decoded_data = decode_json $data;
            foreach my $key (keys %$decoded_data) {
                if (ref $decoded_data->{$key} eq 'HASH') {
                    $hash{$key} = $self->deserialize($type, encode_json $decoded_data->{$key});
                } else {
                    $hash{$key} = $self->deserialize($type, $decoded_data->{$key});
                }
            }
            return \%hash;
        } else {
          #TODO log error
        }
    
    } elsif ( (substr($class, 0, 6)) eq 'ARRAY[' ) { # array of data
        return $data if $data eq '[]'; # return if empty array
    
        my $_sub_class = substr($class, 6, -1);
        my $_json_data = decode_json $data;
        my @_values = ();
        foreach my $_value (@$_json_data) {
            if (ref $_value eq 'ARRAY') {
                push @_values, $self->deserialize($_sub_class, encode_json $_value);
            } else {
                push @_values, $self->deserialize($_sub_class, $_value);
            }
        }
        return \@_values;
    } elsif ($class eq 'DateTime') {
        return DateTime->from_epoch(epoch => str2time($data));
    } elsif (grep /^$class$/, ('string', 'int', 'float', 'bool', 'object', 'File')) {
        return $data;
    } else { # model
        $class = AsposeSlidesCloud::ClassRegistry->get_class_name($class, $data);
        my $_instance = use_module("AsposeSlidesCloud::Object::$class")->new;
        if (ref $data eq "HASH") {
            return $_instance->from_hash($data);
        } else { # string, need to json decode first
            return $_instance->from_hash(decode_json $data);
        }
    }
}

# return 'Accept' based on an array of accept provided
# @param [Array] header_accept_array Array fo 'Accept'
# @return String Accept (e.g. application/json)
sub select_header_accept
{
    my ($self, @header) = @_;
  
    if (@header == 0 || (@header == 1 && $header[0] eq '')) {
        return undef;
    } elsif (grep(/^application\/json$/i, @header)) {
        return 'application/json';
    } else {
        return join(',', @header);
    }
  
}

# return the content type based on an array of content-type provided
# @param [Array] content_type_array Array fo content-type
# @return String Content-Type (e.g. application/json)
sub select_header_content_type
{
    my ($self, @header) = @_;
  
    if (@header == 0 || (@header == 1 && $header[0] eq '')) {
        return 'application/json'; # default to application/json
    } elsif (grep(/^application\/json$/i, @header)) {
        return 'application/json';
    } elsif ($header[0] eq 'multipart/form-data') {
        return 'application/octet-stream';
    } else {
        return $header[0]
    }
  
}

# add auth, user agent and other headers
#  
# @param array $headerParams header parameters (by ref)
sub update_headers {
    my ($self, $header_params) = @_;
    my $custom_headers = $self->{config}{custom_headers};
    foreach my $key (keys %$custom_headers) {
        $header_params->{$key} = $self->{config}{custom_headers}{$key};
    }
    $self->update_params_for_auth($header_params);
}

# update header and query param based on authentication setting
#  
# @param array $headerParams header parameters (by ref)
sub update_params_for_auth {
    my ($self, $header_params) = @_;
    if ((defined $self->{config}{app_sid} && $self->{config}{app_sid} ne "") && (!defined $self->{config}{access_token} || $self->{config}{access_token} eq "")) {
        my $_url = $self->{config}{auth_base_url} . "/connect/token";
        my $_request = POST($_url, {}, Content => 'grant_type=client_credentials&client_id='.$self->{config}{app_sid}.'&client_secret='.$self->{config}{app_key});
        my $_response = $self->{ua}->request($_request);
        unless ($_response->is_success) {
            my $content = sprintf("%s", $_response->content);
            croak(sprintf "API Exception(%s): %s\n%s", 401, $_response->message, $content);
        }
        my $decoded_data = decode_json $_response->content;
        $self->{config}{access_token} = $decoded_data->{access_token};
    }
    if (defined $self->{config}{access_token} && $self->{config}{access_token} ne "") {
        $header_params->{'Authorization'} = 'Bearer ' . $self->{config}{access_token};
    }
}

1;
