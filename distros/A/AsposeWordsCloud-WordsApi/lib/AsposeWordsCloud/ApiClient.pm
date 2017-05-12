package AsposeWordsCloud::ApiClient;

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
use Digest::HMAC_SHA1;
use MIME::Base64;

use AsposeWordsCloud::Configuration;

sub new
{
	
	if(not defined $AsposeWordsCloud::Configuration::app_sid or $AsposeWordsCloud::Configuration::app_sid eq ''){
		croak("Aspose Cloud App SID key is missing.");
    }
	
	if(not defined $AsposeWordsCloud::Configuration::api_key or $AsposeWordsCloud::Configuration::api_key eq ''){
		croak("Aspose Cloud API key is missing.");
    }
    
    my $class = shift;
    my (%args) = (
        'ua' => LWP::UserAgent->new,
        'base_url' => $AsposeWordsCloud::Configuration::api_server,
        @_
    );
  
    return bless \%args, $class;
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

# make the HTTP request
# @param string $resourcePath path to method endpoint
# @param string $method method to call
# @param array $queryParams parameters to be place in query URL
# @param array $postData parameters to be placed in POST body
# @param array $headerParams parameters to be place in request header
# @return mixed
sub call_api {
    my $self = shift;
    my ($resource_path, $method, $query_params, $post_params, $header_params, $body_data, $auth_settings) = @_;
  
	$resource_path =~ s/\Q{appSid}\E/$AsposeWordsCloud::Configuration::app_sid/g;
  
    my $_url = $self->{base_url} . $resource_path;
  
    # update signature
    my $signature = $self->sign($_url, $AsposeWordsCloud::Configuration::app_sid, $AsposeWordsCloud::Configuration::api_key);
	
	$_url = $_url . '&signature=' . $signature;
	
	if($AsposeWordsCloud::Configuration::debug){
		print "\nFinal URL: ".$method."::".$_url."\n";
	}
	# body data
    $body_data = to_json($body_data->to_hash) if defined $body_data && $body_data->can('to_hash'); # model to json string
    my $_body_data = keys %$post_params > 1 ? $post_params : $body_data;
   
    #my $_body_data = $body_data;
  
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
        $_request = DELETE($_url, %$headers, Content => $_body_data);
    }
    elsif ($method eq 'PATCH') { #TODO
    }
    else {
    }
   
    $self->{ua}->timeout($self->{http_timeout} || $AsposeWordsCloud::Configuration::http_timeout); 
    $self->{ua}->agent($self->{http_user_agent} || $AsposeWordsCloud::Configuration::http_user_agent);
    
    my $_response = $self->{ua}->request($_request);
  
    unless ($_response->is_success) {
        croak("API Exception(".$_response->code."): ".$_response->message);
    }
       
    return $_response;
  
}

#  Take value and turn it into a string suitable for inclusion in
#  the path, by url-encoding.
#  @param string $value a string which will be part of the path
#  @return string the serialized object
sub to_path_value {
    my ($self, $value) = @_;
    return uri_escape($self->to_string($value));
}


# Take value and turn it into a string suitable for inclusion in
# the query, by imploding comma-separated if it's an object.
# If it's a string, pass through unchanged. It will be url-encoded
# later.
# @param object $object an object to be serialized to a string
# @return string the serialized object
sub to_query_value {
      my ($self, $object) = @_;
      if (is_array($object)) {
          return implode(',', $object);
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
        my $_instance = use_module("AsposeWordsCloud::Object::$class")->new;
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

sub pre_deserialize
{
    my ($self, $data, $class, $content_type) = @_;
    $log->debugf("pre_deserialize %s for %s and content_type %s", $data, $class, $content_type);    
        if ($class eq "ResponseMessage") {        	
        	if (defined $content_type and lc $content_type ne 'application/json' ) {        		
        		my $_instance = use_module("AsposeWordsCloud::Object::$class")->new;
        		$_instance->{'Status'} = 'OK';
        		$_instance->{'Code'} = 200;
        		$_instance->{'Content'} = $data;
        		return  $_instance;
       	 	}
       }
       
       if ( (defined $content_type) && ($content_type !~ m/json/) )  {
       		croak("API Exception(406.): Invalid contentType".$content_type);
       }
        
        return $self->deserialize($class, $data);
}

# return signature for aspose cloud api
sub sign {
    my ($self, $url_to_sign, $appSid, $appKey) = @_;
  
    #return if (!defined($url_to_sign) || scalar(@$auth_settings) == 0);
        	
    my $hmac = Digest::HMAC_SHA1->new($appKey);
	$hmac->add($url_to_sign);
	my $signature = $hmac->digest;
	$signature = encode_base64($signature, '');
	$signature =~ s/=//;
	$log->debugf ("signature :: ".$signature);
	return $signature;
}

1;
