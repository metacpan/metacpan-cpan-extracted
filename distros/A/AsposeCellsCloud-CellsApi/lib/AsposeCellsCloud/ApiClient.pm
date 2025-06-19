=begin comment

Copyright (c) 2025 Aspose.Cells Cloud
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

package AsposeCellsCloud::ApiClient;

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
use Log::Any qw($log);
use Carp;
use Module::Runtime qw(use_module);

use AsposeCellsCloud::Configuration;


sub new {
    my $class = shift;

    my $config;
    my $get_access_token_time;
    if ( $_[0] && ref $_[0] && ref $_[0] eq 'AsposeCellsCloud::Configuration' ) {
        $config = $_[0];
    } else {
        $config = AsposeCellsCloud::Configuration->new(@_);
    }

    my (%args) = (
        'ua' => LWP::UserAgent->new,
        'config' => $config,
        'get_access_token_time' =>$get_access_token_time,
    );

    return bless \%args, $class;
}

sub need_auth{
    my ($self) = @_;

    if( $self->{config}->{client_id}  ||  $self->{config}->{client_secret} ) {
        return 1;
    }
    return  0;
}

# Set the user agent of the API client
#
# @param string $user_agent The user agent of the API client
#
sub set_user_agent {
    my ($self, $user_agent) = @_;
    $self->{http_user_agent}= $user_agent;
}

# Set timeout
#
# @param integer $seconds Number of seconds before timing out [set to 0 for no timeout]
# 
sub set_timeout {
    my ($self, $seconds) = @_;
    if (!looks_like_number($seconds)) {
        croak('Timeout variable must be numeric.');
    }
    $self->{http_timeout} = $seconds;
}

# @return AccessTokenResponse
#
sub o_auth_post {
    my ($self, %args) = @_;

    # verify the required parameter 'grant_type' is set
    unless (exists $args{'grant_type'}) {
      croak("Missing the required parameter 'grant_type' when calling o_auth_post");
    }

    # verify the required parameter 'client_id' is set
    unless (exists $args{'client_id'}) {
      croak("Missing the required parameter 'client_id' when calling o_auth_post");
    }

    # verify the required parameter 'client_secret' is set
    unless (exists $args{'client_secret'}) {
      croak("Missing the required parameter 'client_secret' when calling o_auth_post");
    }

    # parse inputs
    my $_resource_path = '/v3.0/cells/connect/token';
    if($self->{config}->{api_version} eq "v1.1"){
        $_resource_path = '/oauth2/token';
    }

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->select_header_content_type('application/x-www-form-urlencoded');

    # form params
    if ( exists $args{'grant_type'} ) {
                $form_params->{'grant_type'} = $self->to_form_value($args{'grant_type'});
    }

    # form params
    if ( exists $args{'client_id'} ) {
                $form_params->{'client_id'} = $self->to_form_value($args{'client_id'});
    }

    # form params
    if ( exists $args{'client_secret'} ) {
                $form_params->{'client_secret'} = $self->to_form_value($args{'client_secret'});
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings, 'get_token');
    if (!$response) {
        return;
    }
    my $_response_object = $self->deserialize('AccessTokenResponse', $response);
    $self->{get_access_token_time} = time();
    return $_response_object;
}
# check access token
sub check_access_token {
    my ($self, %args) = @_;
    if(!$self->need_auth()){
        return;
    }
    if($self->{get_access_token_time}){
        my $difference_in_seconds=time() - $self->{get_access_token_time};
        if($difference_in_seconds < 86300){
            return;
        }
    }
    my $access_token  =  $self->o_auth_post('grant_type' => "client_credentials", 'client_id' => $self->{config}->{client_id}, 'client_secret' =>$self->{config}->{client_secret})->access_token;
    $self->{config}->{access_token} = $access_token;
}

# make the HTTP request
# @param string $resourcePath path to method endpoint
# @param string $method method to call
# @param array $queryParams parameters to be place in query URL
# @param array $postData parameters to be placed in POST body
# @param array $headerParams parameters to be place in request header
# @return mixed
sub call_api {
    my $self = shift;
    my ($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $auth_settings,$get_token) = @_;

    # update parameters based on authentication settings
    $self->update_params_for_auth($header_params, $query_params, $auth_settings ); 


    my $_url = $self->{config}{base_url}."/" . $resource_path;
    if($get_token){
        $_url = $self->{config}{base_url} . $resource_path;
    }

    # build header

    $header_params->{'x-aspose-client'} = 'perl sdk';
    $header_params->{'x-aspose-client-version'} = '25.6.1';  
    # build query 
    if (%$query_params) {
        $_url = ($_url . '?' . eval { URI::Query->new($query_params)->stringify });
    }


    # body data
    $body_data = to_json($body_data->to_hash) if defined $body_data && $body_data->can('to_hash'); # model to json string
    my $_body_data = %$post_params ? $post_params : $body_data;

    # Make the HTTP request
    my $_request;
    if ($method eq 'POST') {
        # multipart
        $header_params->{'Content-Type'} = lc $header_params->{'Content-Type'} eq 'multipart/form' ? 
            'form-data' : $header_params->{'Content-Type'};

        if($_body_data){
            $_request = POST($_url, %$header_params, Content => $_body_data);
        }
        else{
            $_request = POST($_url, %$header_params);
        }  
    }
    elsif ($method eq 'PUT') {
        # multipart
        $header_params->{'Content-Type'}  = lc $header_params->{'Content-Type'} eq 'multipart/form' ? 
            'form-data' : $header_params->{'Content-Type'};

        if($_body_data){
            $_request = PUT($_url, %$header_params, Content => $_body_data);
        }
        else{
            $_request = PUT($_url, %$header_params);
        }
    }
    elsif ($method eq 'GET') {
        my $headers = HTTP::Headers->new(%$header_params);
        if($_body_data){
            $_request = GET($_url, %$header_params, Content => $_body_data);
        }
        else{
           $_request = GET($_url, %$header_params);
        }
    }
    elsif ($method eq 'HEAD') {
        my $headers = HTTP::Headers->new(%$header_params);
        $_request = HEAD($_url,%$header_params); 
    }
    elsif ($method eq 'DELETE') { #TODO support form data
        my $headers = HTTP::Headers->new(%$header_params);
        if($_body_data){
            $_request = DELETE($_url, %$header_params, Content => $_body_data);
        }
        else{
            $_request = DELETE($_url, %$header_params);
        }
    }
    elsif ($method eq 'PATCH') { #TODO
    }
    else {
    }
    #proxy####################################################################
    #$self->{ua}=LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 },);
    #$self->{ua}->proxy(['https'], "http://127.0.0.1:8888"); 
    #printf $self->{ua}->ssl_opts;############################################
    $self->{ua}->timeout($self->{http_timeout} || $self->{config}{http_timeout});
    $self->{ua}->agent($self->{http_user_agent} || $self->{config}{http_user_agent});

    $log->debugf("REQUEST: %s", $_request->as_string);
    my $_response = $self->{ua}->request($_request);
    $log->debugf("RESPONSE: %s", $_response->as_string);

    unless ($_response->is_success) {
        croak(sprintf "API Exception(%s): %s\n%s", $_response->code, $_response->message, $_response->content);
    }

    return $_response->content;

}

#  Take value and turn it into a string suitable for inclusion in
#  the path, by url-encoding.
#  @param string $value a string which will be part of the path
#  @return string the serialized object
sub to_path_value {
    my ($self, $value) = @_;
    my $newpath = uri_escape($self->to_string($value));
    my $form = "%2F";
    my $to ="/";
    $newpath =~ s/$form/$to/g;
    return  $newpath;
}


# Take value and turn it into a string suitable for inclusion in
# the query, by imploding comma-separated if it's an object.
# If it's a string, pass through unchanged. It will be url-encoded
# later.
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
        return $value;
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
    $log->debugf("deserializing %s for %s", $data, $class);

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
    } elsif (grep /^$class$/, ('string', 'int', 'float', 'bool', 'object')) {
        return $data;
    } else { # model
        my $_instance = use_module("AsposeCellsCloud::Object::$class")->new;
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
    } else {
        return join(',', @header);
    }

}

# Get API key (with prefix if set)
# @param string key name
# @return string API key with the prefix
sub get_api_key_with_prefix
{
	my ($self, $key_name) = @_;

	my $api_key = $self->{config}{api_key}{$key_name};

	return unless $api_key;

	my $prefix = $self->{config}{api_key_prefix}{$key_name};
	return $prefix ? "$prefix $api_key" : $api_key;
}	

# update header and query param based on authentication setting
#  
# @param array $headerParams header parameters (by ref)
# @param array $queryParams query parameters (by ref)
# @param array $authSettings array of authentication scheme (e.g ['api_key'])
sub update_params_for_auth {
    my ($self, $header_params, $query_params, $auth_settings) = @_;
	if(!$self->need_auth()){
        return;
    }    
    return $self->_global_auth_setup($header_params, $query_params) 
    	unless $auth_settings && @$auth_settings;

    # one endpoint can have more than 1 auth settings
    foreach my $auth (@$auth_settings) {
        # determine which one to use
        if (!defined($auth)) {
            # TODO show warning about auth setting not defined
        }
        elsif ($auth eq 'appsid') {

            my $api_key = $self->get_api_key_with_prefix('appsid');
            if ($api_key) {
                $query_params->{'appsid'} = $api_key;
            }
        }
elsif ($auth eq 'oauth') {

            if ($self->{config}{access_token}) {
                $header_params->{'Authorization'} = 'Bearer ' . $self->{config}{access_token};
            }
        }
elsif ($auth eq 'signature') {

            my $api_key = $self->get_api_key_with_prefix('signature');
            if ($api_key) {
                $query_params->{'signature'} = $api_key;
            }
        }
        else {
       	    # TODO show warning about security definition not found
        }
    }
}

# The endpoint API class has not found any settings for auth. This may be deliberate, 
# in which case update_params_for_auth() will be a no-op. But it may also be that the 
# OpenAPI Spec does not describe the intended authorization. So we check in the config for any 
# auth tokens and if we find any, we use them for all endpoints; 
sub _global_auth_setup {
	my ($self, $header_params, $query_params) = @_; 

	my $tokens = $self->{config}->get_tokens;
	return unless keys %$tokens;

	# basic
	if (my $uname = delete $tokens->{username}) {
		my $pword = delete $tokens->{password};
		$header_params->{'Authorization'} = 'Basic '.encode_base64($uname.":".$pword);
	}
	# sid key
	if (my $client_id = delete $tokens->{client_id}) {
		my $client_secret = delete $tokens->{client_secret};
		$query_params->{'client_id'} = $client_id;
        $query_params->{'client_secret'} = $client_secret;
	}

	# oauth
	if (my $access_token = delete $tokens->{access_token}) {
		$header_params->{'Authorization'} = 'Bearer ' . $access_token;
	}

	# other keys
	foreach my $token_name (keys %$tokens) {
		my $in = $tokens->{$token_name}->{in};
		my $token = $self->get_api_key_with_prefix($token_name);
		if ($in eq 'head') {
			$header_params->{$token_name} = $token;
		}
		elsif ($in eq 'query') {
			$query_params->{$token_name} = $token;
		}
		else {
			die "Don't know where to put token '$token_name' ('$in' is not 'head' or 'query')";
		}
	}
}


1;