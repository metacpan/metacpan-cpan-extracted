package AsposeEmailCloud::EmailApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeEmailCloud::ApiClient;
use AsposeEmailCloud::Configuration;

my $VERSION = '1.01';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeEmailCloud::Configuration::api_client ? $AsposeEmailCloud::Configuration::api_client  :
	AsposeEmailCloud::ApiClient->new;
    my (%self) = (
        'api_client' => $default_api_client,
        @_
    );

    #my $self = {
    #    #api_client => $options->{api_client}
    #    api_client => $default_api_client
    #}; 

    bless \%self, $class;

}

#
# AppendMessage
#
# Append message from a storage
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $folder  (optional)
# @param String $mailPath  (optional)
# @param Boolean $markAsSent  (optional)
# @return SaaSposeResponse
#
sub AppendMessage {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/Append/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;folder={folder}&amp;mailPath={mailPath}&amp;markAsSent={markAsSent}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'mailPath'}) {        		
		$_resource_path =~ s/\Q{mailPath}\E/$args{'mailPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]mailPath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'markAsSent'}) {        		
		$_resource_path =~ s/\Q{markAsSent}\E/$args{'markAsSent'}/g;
    }else{
		$_resource_path    =~ s/[?&]markAsSent.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# AppendMimeMessage
#
# Append mime message
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $folder  (optional)
# @param Boolean $markAsSent  (optional)
# @param  $body  (required)
# @return SaaSposeResponse
#
sub AppendMimeMessage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling AppendMimeMessage");
    }
    

    # parse inputs
    my $_resource_path = '/email/client/AppendMime/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;folder={folder}&amp;markAsSent={markAsSent}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'markAsSent'}) {        		
		$_resource_path =~ s/\Q{markAsSent}\E/$args{'markAsSent'}/g;
    }else{
		$_resource_path    =~ s/[?&]markAsSent.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    # body params
    if ( exists $args{'body'}) {
        $_body_data = $args{'body'};
    }

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# CreateFolder
#
# Creates the new folder
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $parentFolder  (optional)
# @param String $name  (optional)
# @return SaaSposeResponse
#
sub CreateFolder {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/CreateFolder/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;parentFolder={parentFolder}&amp;name={name}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'parentFolder'}) {        		
		$_resource_path =~ s/\Q{parentFolder}\E/$args{'parentFolder'}/g;
    }else{
		$_resource_path    =~ s/[?&]parentFolder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteFolder
#
# Deletes the folder
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $folder  (optional)
# @param Boolean $deletePermanently  (optional)
# @return SaaSposeResponse
#
sub DeleteFolder {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/DeleteFolder/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;folder={folder}&amp;deletePermanently={deletePermanently}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'deletePermanently'}) {        		
		$_resource_path =~ s/\Q{deletePermanently}\E/$args{'deletePermanently'}/g;
    }else{
		$_resource_path    =~ s/[?&]deletePermanently.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteMessage
#
# Deletes the mail message
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $messageId  (optional)
# @param Boolean $deletePermanently  (optional)
# @return SaaSposeResponse
#
sub DeleteMessage {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/DeleteMessage/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;messageId={messageId}&amp;deletePermanently={deletePermanently}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'messageId'}) {        		
		$_resource_path =~ s/\Q{messageId}\E/$args{'messageId'}/g;
    }else{
		$_resource_path    =~ s/[?&]messageId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'deletePermanently'}) {        		
		$_resource_path =~ s/\Q{deletePermanently}\E/$args{'deletePermanently'}/g;
    }else{
		$_resource_path    =~ s/[?&]deletePermanently.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# FetchMessage
#
# Fetches the message from server
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $messageId  (optional)
# @return MimeResponse
#
sub FetchMessage {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/Fetch/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;messageId={messageId}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'messageId'}) {        		
		$_resource_path =~ s/\Q{messageId}\E/$args{'messageId'}/g;
    }else{
		$_resource_path    =~ s/[?&]messageId.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'MimeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# ListFolders
#
# Gets collection of child folders from parent
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $parentFolder  (optional)
# @return ListFoldersResponse
#
sub ListFolders {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/ListFolders/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;parentFolder={parentFolder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'parentFolder'}) {        		
		$_resource_path =~ s/\Q{parentFolder}\E/$args{'parentFolder'}/g;
    }else{
		$_resource_path    =~ s/[?&]parentFolder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ListFoldersResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# ListMessages
#
# List the messages in the specified folder.
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $folder  (optional)
# @param Boolean $recursive  (optional)
# @param String $queryString  (optional)
# @return ListResponse
#
sub ListMessages {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/ListMessages/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;folder={folder}&amp;recursive={recursive}&amp;queryString={queryString}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'recursive'}) {        		
		$_resource_path =~ s/\Q{recursive}\E/$args{'recursive'}/g;
    }else{
		$_resource_path    =~ s/[?&]recursive.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'queryString'}) {        		
		$_resource_path =~ s/\Q{queryString}\E/$args{'queryString'}/g;
    }else{
		$_resource_path    =~ s/[?&]queryString.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# SaveMailAccount
#
# Get mail common info.
# 
# @param String $storage  (required)
# @param String $accountName  (required)
# @param String $host  (required)
# @param String $port  (required)
# @param String $login  (required)
# @param String $password  (required)
# @param String $securityOptions  (required)
# @param String $protocolType  (required)
# @param String $description  (required)
# @return SaaSposeResponse
#
sub SaveMailAccount {
    my ($self, %args) = @_;

    
    # verify the required parameter 'storage' is set
    unless (exists $args{'storage'}) {
      croak("Missing the required parameter 'storage' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'accountName' is set
    unless (exists $args{'accountName'}) {
      croak("Missing the required parameter 'accountName' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'host' is set
    unless (exists $args{'host'}) {
      croak("Missing the required parameter 'host' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'port' is set
    unless (exists $args{'port'}) {
      croak("Missing the required parameter 'port' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'login' is set
    unless (exists $args{'login'}) {
      croak("Missing the required parameter 'login' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'password' is set
    unless (exists $args{'password'}) {
      croak("Missing the required parameter 'password' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'securityOptions' is set
    unless (exists $args{'securityOptions'}) {
      croak("Missing the required parameter 'securityOptions' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'protocolType' is set
    unless (exists $args{'protocolType'}) {
      croak("Missing the required parameter 'protocolType' when calling SaveMailAccount");
    }
    
    # verify the required parameter 'description' is set
    unless (exists $args{'description'}) {
      croak("Missing the required parameter 'description' when calling SaveMailAccount");
    }
    

    # parse inputs
    my $_resource_path = '/email/client/SaveMailAccount/?appSid={appSid}&amp;storage={storage}&amp;accountName={accountName}&amp;host={host}&amp;port={port}&amp;login={login}&amp;password={password}&amp;securityOptions={securityOptions}&amp;protocolType={protocolType}&amp;description={description}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName'}) {        		
		$_resource_path =~ s/\Q{accountName}\E/$args{'accountName'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'host'}) {        		
		$_resource_path =~ s/\Q{host}\E/$args{'host'}/g;
    }else{
		$_resource_path    =~ s/[?&]host.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'port'}) {        		
		$_resource_path =~ s/\Q{port}\E/$args{'port'}/g;
    }else{
		$_resource_path    =~ s/[?&]port.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'login'}) {        		
		$_resource_path =~ s/\Q{login}\E/$args{'login'}/g;
    }else{
		$_resource_path    =~ s/[?&]login.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'securityOptions'}) {        		
		$_resource_path =~ s/\Q{securityOptions}\E/$args{'securityOptions'}/g;
    }else{
		$_resource_path    =~ s/[?&]securityOptions.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'protocolType'}) {        		
		$_resource_path =~ s/\Q{protocolType}\E/$args{'protocolType'}/g;
    }else{
		$_resource_path    =~ s/[?&]protocolType.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'description'}) {        		
		$_resource_path =~ s/\Q{description}\E/$args{'description'}/g;
    }else{
		$_resource_path    =~ s/[?&]description.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# SaveMailOAuthAccount
#
# Get mail common info.
# 
# @param String $storage  (required)
# @param String $accountName  (required)
# @param String $host  (required)
# @param String $port  (required)
# @param String $login  (required)
# @param String $clientId  (required)
# @param String $clientSecret  (required)
# @param String $refreshToken  (required)
# @param String $securityOptions  (required)
# @param String $protocolType  (required)
# @param String $description  (required)
# @return SaaSposeResponse
#
sub SaveMailOAuthAccount {
    my ($self, %args) = @_;

    
    # verify the required parameter 'storage' is set
    unless (exists $args{'storage'}) {
      croak("Missing the required parameter 'storage' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'accountName' is set
    unless (exists $args{'accountName'}) {
      croak("Missing the required parameter 'accountName' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'host' is set
    unless (exists $args{'host'}) {
      croak("Missing the required parameter 'host' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'port' is set
    unless (exists $args{'port'}) {
      croak("Missing the required parameter 'port' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'login' is set
    unless (exists $args{'login'}) {
      croak("Missing the required parameter 'login' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'clientId' is set
    unless (exists $args{'clientId'}) {
      croak("Missing the required parameter 'clientId' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'clientSecret' is set
    unless (exists $args{'clientSecret'}) {
      croak("Missing the required parameter 'clientSecret' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'refreshToken' is set
    unless (exists $args{'refreshToken'}) {
      croak("Missing the required parameter 'refreshToken' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'securityOptions' is set
    unless (exists $args{'securityOptions'}) {
      croak("Missing the required parameter 'securityOptions' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'protocolType' is set
    unless (exists $args{'protocolType'}) {
      croak("Missing the required parameter 'protocolType' when calling SaveMailOAuthAccount");
    }
    
    # verify the required parameter 'description' is set
    unless (exists $args{'description'}) {
      croak("Missing the required parameter 'description' when calling SaveMailOAuthAccount");
    }
    

    # parse inputs
    my $_resource_path = '/email/client/SaveMailOAuthAccount/?appSid={appSid}&amp;storage={storage}&amp;accountName={accountName}&amp;host={host}&amp;port={port}&amp;login={login}&amp;clientId={clientId}&amp;clientSecret={clientSecret}&amp;refreshToken={refreshToken}&amp;securityOptions={securityOptions}&amp;protocolType={protocolType}&amp;description={description}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName'}) {        		
		$_resource_path =~ s/\Q{accountName}\E/$args{'accountName'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'host'}) {        		
		$_resource_path =~ s/\Q{host}\E/$args{'host'}/g;
    }else{
		$_resource_path    =~ s/[?&]host.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'port'}) {        		
		$_resource_path =~ s/\Q{port}\E/$args{'port'}/g;
    }else{
		$_resource_path    =~ s/[?&]port.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'login'}) {        		
		$_resource_path =~ s/\Q{login}\E/$args{'login'}/g;
    }else{
		$_resource_path    =~ s/[?&]login.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'clientId'}) {        		
		$_resource_path =~ s/\Q{clientId}\E/$args{'clientId'}/g;
    }else{
		$_resource_path    =~ s/[?&]clientId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'clientSecret'}) {        		
		$_resource_path =~ s/\Q{clientSecret}\E/$args{'clientSecret'}/g;
    }else{
		$_resource_path    =~ s/[?&]clientSecret.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'refreshToken'}) {        		
		$_resource_path =~ s/\Q{refreshToken}\E/$args{'refreshToken'}/g;
    }else{
		$_resource_path    =~ s/[?&]refreshToken.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'securityOptions'}) {        		
		$_resource_path =~ s/\Q{securityOptions}\E/$args{'securityOptions'}/g;
    }else{
		$_resource_path    =~ s/[?&]securityOptions.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'protocolType'}) {        		
		$_resource_path =~ s/\Q{protocolType}\E/$args{'protocolType'}/g;
    }else{
		$_resource_path    =~ s/[?&]protocolType.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'description'}) {        		
		$_resource_path =~ s/\Q{description}\E/$args{'description'}/g;
    }else{
		$_resource_path    =~ s/[?&]description.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# Send
#
# Send mail message from a storage
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $mailPath  (optional)
# @return SaaSposeResponse
#
sub Send {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/Send/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;mailPath={mailPath}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'mailPath'}) {        		
		$_resource_path =~ s/\Q{mailPath}\E/$args{'mailPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]mailPath.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# SendMime
#
# Send mail message
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param  $body  (required)
# @return SaaSposeResponse
#
sub SendMime {
    my ($self, %args) = @_;

    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling SendMime");
    }
    

    # parse inputs
    my $_resource_path = '/email/client/SendMime/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    # body params
    if ( exists $args{'body'}) {
        $_body_data = $args{'body'};
    }

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# SetReadFlag
#
# Marks the specifeid message as read.
# 
# @param String $storage  (optional)
# @param String $accountName1  (optional)
# @param String $accountName2  (optional)
# @param String $messageId  (optional)
# @param Boolean $isRead  (optional)
# @return SaaSposeResponse
#
sub SetReadFlag {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/email/client/SetReadFlag/?appSid={appSid}&amp;storage={storage}&amp;accountName1={accountName1}&amp;accountName2={accountName2}&amp;messageId={messageId}&amp;isRead={isRead}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName1'}) {        		
		$_resource_path =~ s/\Q{accountName1}\E/$args{'accountName1'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName1.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'accountName2'}) {        		
		$_resource_path =~ s/\Q{accountName2}\E/$args{'accountName2'}/g;
    }else{
		$_resource_path    =~ s/[?&]accountName2.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'messageId'}) {        		
		$_resource_path =~ s/\Q{messageId}\E/$args{'messageId'}/g;
    }else{
		$_resource_path    =~ s/[?&]messageId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isRead'}) {        		
		$_resource_path =~ s/\Q{isRead}\E/$args{'isRead'}/g;
    }else{
		$_resource_path    =~ s/[?&]isRead.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocument
#
# Get mail common info.
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocument");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'EmailPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutCreateNewEmail
#
# Add new email.
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param EmailDocument $body  (required)
# @return EmailDocumentResponse
#
sub PutCreateNewEmail {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutCreateNewEmail");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutCreateNewEmail");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    # body params
    if ( exists $args{'body'}) {
        $_body_data = $args{'body'};
    }

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'EmailDocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentWithFormat
#
# Convert mail message to target format.
# 
# @param String $name  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @return ResponseMessage
#
sub GetDocumentWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetDocumentWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetEmailAttachment
#
# Get email attachment by name.
# 
# @param String $name  (required)
# @param String $attachName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetEmailAttachment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetEmailAttachment");
    }
    
    # verify the required parameter 'attachName' is set
    unless (exists $args{'attachName'}) {
      croak("Missing the required parameter 'attachName' when calling GetEmailAttachment");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/attachments/{attachName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/octet-stream');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'attachName'}) {        		
		$_resource_path =~ s/\Q{attachName}\E/$args{'attachName'}/g;
    }else{
		$_resource_path    =~ s/[?&]attachName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAddEmailAttachment
#
# Add email attachment.
# 
# @param String $name  (required)
# @param String $attachName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return EmailDocumentResponse
#
sub PostAddEmailAttachment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAddEmailAttachment");
    }
    
    # verify the required parameter 'attachName' is set
    unless (exists $args{'attachName'}) {
      croak("Missing the required parameter 'attachName' when calling PostAddEmailAttachment");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/attachments/{attachName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'attachName'}) {        		
		$_resource_path =~ s/\Q{attachName}\E/$args{'attachName'}/g;
    }else{
		$_resource_path    =~ s/[?&]attachName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'EmailDocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetEmailProperty
#
# Read document property by name.
# 
# @param String $propertyName  (required)
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetEmailProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling GetEmailProperty");
    }
    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetEmailProperty");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/properties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'propertyName'}) {        		
		$_resource_path =~ s/\Q{propertyName}\E/$args{'propertyName'}/g;
    }else{
		$_resource_path    =~ s/[?&]propertyName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'EmailPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSetEmailProperty
#
# Set document property.
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param EmailProperty $body  (required)
# @return EmailPropertyResponse
#
sub PutSetEmailProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSetEmailProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling PutSetEmailProperty");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSetEmailProperty");
    }
    

    # parse inputs
    my $_resource_path = '/email/{name}/properties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/xml', 'application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'propertyName'}) {        		
		$_resource_path =~ s/\Q{propertyName}\E/$args{'propertyName'}/g;
    }else{
		$_resource_path    =~ s/[?&]propertyName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
    
    # body params
    if ( exists $args{'body'}) {
        $_body_data = $args{'body'};
    }

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeEmailCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'EmailPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
