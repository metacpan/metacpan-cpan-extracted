package AsposeWordsCloud::WordsApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeWordsCloud::ApiClient;
use AsposeWordsCloud::Configuration;

my $VERSION = '1.0.1';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeWordsCloud::Configuration::api_client ? $AsposeWordsCloud::Configuration::api_client  :
	AsposeWordsCloud::ApiClient->new;
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
# PutConvertDocument
#
# 
# 
# @param String $format  (optional)
# @param String $outPath  (optional)
# @param String $replaceResourcesHostTo  (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PutConvertDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutConvertDocument");
    }
    

    # parse inputs
    my $_resource_path = '/words/convert/?appSid={appSid}&amp;toFormat={toFormat}&amp;outPath={outPath}&amp;replaceResourcesHostTo={replaceResourcesHostTo}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'replaceResourcesHostTo'}) {        		
		$_resource_path =~ s/\Q{replaceResourcesHostTo}\E/$args{'replaceResourcesHostTo'}/g;
    }else{
		$_resource_path    =~ s/[?&]replaceResourcesHostTo.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	# form params
    if ( exists $args{'file'} ) {
        
		$_body_data = read_file( $args{'file'} , binmode => ':raw' );
        
        
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutExecuteMailMergeOnline
#
# 
# 
# @param Boolean $withRegions  (required)
# @param String $cleanup  (optional)
# @param File $file  (required)
# @param File $data  (required)
# @return ResponseMessage
#
sub PutExecuteMailMergeOnline {
    my ($self, %args) = @_;

    
    # verify the required parameter 'withRegions' is set
    unless (exists $args{'withRegions'}) {
      croak("Missing the required parameter 'withRegions' when calling PutExecuteMailMergeOnline");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutExecuteMailMergeOnline");
    }
    
    # verify the required parameter 'data' is set
    unless (exists $args{'data'}) {
      croak("Missing the required parameter 'data' when calling PutExecuteMailMergeOnline");
    }

    # parse inputs
    my $_resource_path = '/words/executeMailMerge/?withRegions={withRegions}&amp;appSid={appSid}&amp;cleanup={cleanup}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'withRegions'}) {        		
		$_resource_path =~ s/\Q{withRegions}\E/$args{'withRegions'}/g;
    }else{
		$_resource_path    =~ s/[?&]withRegions.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cleanup'}) {        		
		$_resource_path =~ s/\Q{cleanup}\E/$args{'cleanup'}/g;
    }else{
		$_resource_path    =~ s/[?&]cleanup.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	
   # form params
   if ( exists $args{'file'} and  exists $args{'data'}) {
        $form_params->{'file'} = [] unless defined $form_params->{'file'};
        $form_params->{'data'} = [] unless defined $form_params->{'data'};
        
        push @{$form_params->{'file'}}, ($args{'file'}, 'file', ('Content-Type' => 'application/octet-stream')) ;
        push @{$form_params->{'data'}}, ($args{'data'}, 'data', ('Content-Type' => 'application/xml')) ;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutExecuteTemplateOnline
#
# 
# 
# @param String $cleanup  (optional)
# @param Boolean $useWholeParagraphAsRegion  (optional)
# @param Boolean $withRegions  (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PutExecuteTemplateOnline {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutExecuteTemplateOnline");
    }
    
    # verify the required parameter 'data' is set
    unless (exists $args{'data'}) {
      croak("Missing the required parameter 'data' when calling PutExecuteTemplateOnline");
    }

    # parse inputs
    my $_resource_path = '/words/executeTemplate/?appSid={appSid}&amp;cleanup={cleanup}&amp;useWholeParagraphAsRegion={useWholeParagraphAsRegion}&amp;withRegions={withRegions}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'cleanup'}) {        		
		$_resource_path =~ s/\Q{cleanup}\E/$args{'cleanup'}/g;
    }else{
		$_resource_path    =~ s/[?&]cleanup.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useWholeParagraphAsRegion'}) {        		
		$_resource_path =~ s/\Q{useWholeParagraphAsRegion}\E/$args{'useWholeParagraphAsRegion'}/g;
    }else{
		$_resource_path    =~ s/[?&]useWholeParagraphAsRegion.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'withRegions'}) {        		
		$_resource_path =~ s/\Q{withRegions}\E/$args{'withRegions'}/g;
    }else{
		$_resource_path    =~ s/[?&]withRegions.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	# form params
    if ( exists $args{'file'} and  exists $args{'data'}) {
        $form_params->{'file'} = [] unless defined $form_params->{'file'};
        $form_params->{'data'} = [] unless defined $form_params->{'data'};
        
        push @{$form_params->{'file'}}, ($args{'file'}, 'file', ('Content-Type' => 'application/octet-stream')) ;
        push @{$form_params->{'data'}}, ($args{'data'}, 'data', ('Content-Type' => 'application/xml') ) ;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostLoadWebDocument
#
# 
# 
# @return SaveResponse
#
sub PostLoadWebDocument {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/words/loadWebDocument/?appSid={appSid}';
    
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaveResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutDocumentFieldNames
#
# 
# 
# @param Boolean $useNonMergeFields  (optional)
# @return FieldNamesResponse
#
sub PutDocumentFieldNames {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/words/mailMergeFieldNames/?appSid={appSid}&amp;useNonMergeFields={useNonMergeFields}';
    
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
    if ( exists $args{'useNonMergeFields'}) {        		
		$_resource_path =~ s/\Q{useNonMergeFields}\E/$args{'useNonMergeFields'}/g;
    }else{
		$_resource_path    =~ s/[?&]useNonMergeFields.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FieldNamesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostRunTask
#
# 
# 
# @return ResponseMessage
#
sub PostRunTask {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/words/tasks/?appSid={appSid}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    
    
    
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocument
#
# 
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
    my $_resource_path = '/words/{name}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentWithFormat
#
# 
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
    my $_resource_path = '/words/{name}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostDocumentSaveAs
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param SaveOptionsData $body  (required)
# @return SaveResponse
#
sub PostDocumentSaveAs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostDocumentSaveAs");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostDocumentSaveAs");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/SaveAs/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaveResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutDocumentSaveAsTiff
#
# 
# 
# @param String $name  (required)
# @param String $resultFile  (optional)
# @param Boolean $useAntiAliasing  (optional)
# @param Boolean $useHighQualityRendering  (optional)
# @param String $imageBrightness  (optional)
# @param String $imageColorMode  (optional)
# @param String $imageContrast  (optional)
# @param String $numeralFormat  (optional)
# @param String $pageCount  (optional)
# @param String $pageIndex  (optional)
# @param String $paperColor  (optional)
# @param String $pixelFormat  (optional)
# @param String $resolution  (optional)
# @param String $scale  (optional)
# @param String $tiffCompression  (optional)
# @param String $dmlRenderingMode  (optional)
# @param String $dmlEffectsRenderingMode  (optional)
# @param String $tiffBinarizationMethod  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Boolean $zipOutput  (optional)
# @param TiffSaveOptionsData $body  (required)
# @return SaveResponse
#
sub PutDocumentSaveAsTiff {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutDocumentSaveAsTiff");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutDocumentSaveAsTiff");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/SaveAs/tiff/?appSid={appSid}&amp;resultFile={resultFile}&amp;useAntiAliasing={useAntiAliasing}&amp;useHighQualityRendering={useHighQualityRendering}&amp;imageBrightness={imageBrightness}&amp;imageColorMode={imageColorMode}&amp;imageContrast={imageContrast}&amp;numeralFormat={numeralFormat}&amp;pageCount={pageCount}&amp;pageIndex={pageIndex}&amp;paperColor={paperColor}&amp;pixelFormat={pixelFormat}&amp;resolution={resolution}&amp;scale={scale}&amp;tiffCompression={tiffCompression}&amp;dmlRenderingMode={dmlRenderingMode}&amp;dmlEffectsRenderingMode={dmlEffectsRenderingMode}&amp;tiffBinarizationMethod={tiffBinarizationMethod}&amp;storage={storage}&amp;folder={folder}&amp;zipOutput={zipOutput}';
    
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
    if ( exists $args{'resultFile'}) {        		
		$_resource_path =~ s/\Q{resultFile}\E/$args{'resultFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]resultFile.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useAntiAliasing'}) {        		
		$_resource_path =~ s/\Q{useAntiAliasing}\E/$args{'useAntiAliasing'}/g;
    }else{
		$_resource_path    =~ s/[?&]useAntiAliasing.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useHighQualityRendering'}) {        		
		$_resource_path =~ s/\Q{useHighQualityRendering}\E/$args{'useHighQualityRendering'}/g;
    }else{
		$_resource_path    =~ s/[?&]useHighQualityRendering.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageBrightness'}) {        		
		$_resource_path =~ s/\Q{imageBrightness}\E/$args{'imageBrightness'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageBrightness.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageColorMode'}) {        		
		$_resource_path =~ s/\Q{imageColorMode}\E/$args{'imageColorMode'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageColorMode.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageContrast'}) {        		
		$_resource_path =~ s/\Q{imageContrast}\E/$args{'imageContrast'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageContrast.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'numeralFormat'}) {        		
		$_resource_path =~ s/\Q{numeralFormat}\E/$args{'numeralFormat'}/g;
    }else{
		$_resource_path    =~ s/[?&]numeralFormat.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pageCount'}) {        		
		$_resource_path =~ s/\Q{pageCount}\E/$args{'pageCount'}/g;
    }else{
		$_resource_path    =~ s/[?&]pageCount.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pageIndex'}) {        		
		$_resource_path =~ s/\Q{pageIndex}\E/$args{'pageIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pageIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paperColor'}) {        		
		$_resource_path =~ s/\Q{paperColor}\E/$args{'paperColor'}/g;
    }else{
		$_resource_path    =~ s/[?&]paperColor.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pixelFormat'}) {        		
		$_resource_path =~ s/\Q{pixelFormat}\E/$args{'pixelFormat'}/g;
    }else{
		$_resource_path    =~ s/[?&]pixelFormat.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolution'}) {        		
		$_resource_path =~ s/\Q{resolution}\E/$args{'resolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'scale'}) {        		
		$_resource_path =~ s/\Q{scale}\E/$args{'scale'}/g;
    }else{
		$_resource_path    =~ s/[?&]scale.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'tiffCompression'}) {        		
		$_resource_path =~ s/\Q{tiffCompression}\E/$args{'tiffCompression'}/g;
    }else{
		$_resource_path    =~ s/[?&]tiffCompression.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dmlRenderingMode'}) {        		
		$_resource_path =~ s/\Q{dmlRenderingMode}\E/$args{'dmlRenderingMode'}/g;
    }else{
		$_resource_path    =~ s/[?&]dmlRenderingMode.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dmlEffectsRenderingMode'}) {        		
		$_resource_path =~ s/\Q{dmlEffectsRenderingMode}\E/$args{'dmlEffectsRenderingMode'}/g;
    }else{
		$_resource_path    =~ s/[?&]dmlEffectsRenderingMode.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'tiffBinarizationMethod'}) {        		
		$_resource_path =~ s/\Q{tiffBinarizationMethod}\E/$args{'tiffBinarizationMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]tiffBinarizationMethod.*?(?=&|\?|$)//g;
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
    if ( exists $args{'zipOutput'}) {        		
		$_resource_path =~ s/\Q{zipOutput}\E/$args{'zipOutput'}/g;
    }else{
		$_resource_path    =~ s/[?&]zipOutput.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaveResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAppendDocument
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param DocumentEntryList $body  (required)
# @return DocumentResponse
#
sub PostAppendDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAppendDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostAppendDocument");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/appendDocument/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'POST';
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentBookmarks
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return BookmarksResponse
#
sub GetDocumentBookmarks {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentBookmarks");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/bookmarks/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BookmarksResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateDocumentBookmark
#
# 
# 
# @param String $name  (required)
# @param String $bookmarkName  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param BookmarkData $body  (required)
# @return BookmarkResponse
#
sub PostUpdateDocumentBookmark {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateDocumentBookmark");
    }
    
    # verify the required parameter 'bookmarkName' is set
    unless (exists $args{'bookmarkName'}) {
      croak("Missing the required parameter 'bookmarkName' when calling PostUpdateDocumentBookmark");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostUpdateDocumentBookmark");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/bookmarks/{bookmarkName}/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'bookmarkName'}) {        		
		$_resource_path =~ s/\Q{bookmarkName}\E/$args{'bookmarkName'}/g;
    }else{
		$_resource_path    =~ s/[?&]bookmarkName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BookmarkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentBookmarkByName
#
# 
# 
# @param String $name  (required)
# @param String $bookmarkName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return BookmarkResponse
#
sub GetDocumentBookmarkByName {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentBookmarkByName");
    }
    
    # verify the required parameter 'bookmarkName' is set
    unless (exists $args{'bookmarkName'}) {
      croak("Missing the required parameter 'bookmarkName' when calling GetDocumentBookmarkByName");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/bookmarks/{bookmarkName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'bookmarkName'}) {        		
		$_resource_path =~ s/\Q{bookmarkName}\E/$args{'bookmarkName'}/g;
    }else{
		$_resource_path    =~ s/[?&]bookmarkName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BookmarkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutComment
#
# 
# 
# @param String $name  (required)
# @param String $fileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param CommentDto $body  (required)
# @return CommentResponse
#
sub PutComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutComment");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutComment");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/comments/?appSid={appSid}&amp;fileName={fileName}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'fileName'}) {        		
		$_resource_path =~ s/\Q{fileName}\E/$args{'fileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]fileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetComments
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CommentsResponse
#
sub GetComments {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetComments");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/comments/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostComment
#
# 
# 
# @param String $name  (required)
# @param String $commentIndex  (required)
# @param String $fileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param CommentDto $body  (required)
# @return CommentResponse
#
sub PostComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostComment");
    }
    
    # verify the required parameter 'commentIndex' is set
    unless (exists $args{'commentIndex'}) {
      croak("Missing the required parameter 'commentIndex' when calling PostComment");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostComment");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/comments/{commentIndex}/?appSid={appSid}&amp;fileName={fileName}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'commentIndex'}) {        		
		$_resource_path =~ s/\Q{commentIndex}\E/$args{'commentIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]commentIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fileName'}) {        		
		$_resource_path =~ s/\Q{fileName}\E/$args{'fileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]fileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetComment
#
# 
# 
# @param String $name  (required)
# @param String $commentIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CommentResponse
#
sub GetComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetComment");
    }
    
    # verify the required parameter 'commentIndex' is set
    unless (exists $args{'commentIndex'}) {
      croak("Missing the required parameter 'commentIndex' when calling GetComment");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/comments/{commentIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'commentIndex'}) {        		
		$_resource_path =~ s/\Q{commentIndex}\E/$args{'commentIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]commentIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteComment
#
# 
# 
# @param String $name  (required)
# @param String $commentIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $fileName  (optional)
# @return SaaSposeResponse
#
sub DeleteComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteComment");
    }
    
    # verify the required parameter 'commentIndex' is set
    unless (exists $args{'commentIndex'}) {
      croak("Missing the required parameter 'commentIndex' when calling DeleteComment");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/comments/{commentIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}&amp;fileName={fileName}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'commentIndex'}) {        		
		$_resource_path =~ s/\Q{commentIndex}\E/$args{'commentIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]commentIndex.*?(?=&|\?|$)//g;
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
    if ( exists $args{'fileName'}) {        		
		$_resource_path =~ s/\Q{fileName}\E/$args{'fileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]fileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentProperties
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DocumentPropertiesResponse
#
sub GetDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/documentProperties/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutUpdateDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param DocumentProperty $body  (required)
# @return DocumentPropertyResponse
#
sub PutUpdateDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutUpdateDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling PutUpdateDocumentProperty");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutUpdateDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/documentProperties/{propertyName}/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling DeleteDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/documentProperties/{propertyName}/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DocumentPropertyResponse
#
sub GetDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling GetDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/documentProperties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentDrawingObjects
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DrawingObjectsResponse
#
sub GetDocumentDrawingObjects {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentDrawingObjects");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/drawingObjects/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DrawingObjectsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentDrawingObjectByIndex
#
# 
# 
# @param String $name  (required)
# @param String $objectIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetDocumentDrawingObjectByIndex {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentDrawingObjectByIndex");
    }
    
    # verify the required parameter 'objectIndex' is set
    unless (exists $args{'objectIndex'}) {
      croak("Missing the required parameter 'objectIndex' when calling GetDocumentDrawingObjectByIndex");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/drawingObjects/{objectIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'objectIndex'}) {        		
		$_resource_path =~ s/\Q{objectIndex}\E/$args{'objectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentDrawingObjectByIndexWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $objectIndex  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetDocumentDrawingObjectByIndexWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentDrawingObjectByIndexWithFormat");
    }
    
    # verify the required parameter 'objectIndex' is set
    unless (exists $args{'objectIndex'}) {
      croak("Missing the required parameter 'objectIndex' when calling GetDocumentDrawingObjectByIndexWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetDocumentDrawingObjectByIndexWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/drawingObjects/{objectIndex}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'objectIndex'}) {        		
		$_resource_path =~ s/\Q{objectIndex}\E/$args{'objectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentDrawingObjectImageData
#
# 
# 
# @param String $name  (required)
# @param String $objectIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetDocumentDrawingObjectImageData {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentDrawingObjectImageData");
    }
    
    # verify the required parameter 'objectIndex' is set
    unless (exists $args{'objectIndex'}) {
      croak("Missing the required parameter 'objectIndex' when calling GetDocumentDrawingObjectImageData");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/drawingObjects/{objectIndex}/imageData/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'objectIndex'}) {        		
		$_resource_path =~ s/\Q{objectIndex}\E/$args{'objectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentDrawingObjectOleData
#
# 
# 
# @param String $name  (required)
# @param String $objectIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetDocumentDrawingObjectOleData {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentDrawingObjectOleData");
    }
    
    # verify the required parameter 'objectIndex' is set
    unless (exists $args{'objectIndex'}) {
      croak("Missing the required parameter 'objectIndex' when calling GetDocumentDrawingObjectOleData");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/drawingObjects/{objectIndex}/oleData/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'objectIndex'}) {        		
		$_resource_path =~ s/\Q{objectIndex}\E/$args{'objectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostDocumentExecuteMailMerge
#
# 
# 
# @param String $name  (required)
# @param Boolean $withRegions  (required)
# @param String $mailMergeDataFile  (optional)
# @param String $cleanup  (optional)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Boolean $useWholeParagraphAsRegion  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PostDocumentExecuteMailMerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostDocumentExecuteMailMerge");
    }
    
    # verify the required parameter 'withRegions' is set
    unless (exists $args{'withRegions'}) {
      croak("Missing the required parameter 'withRegions' when calling PostDocumentExecuteMailMerge");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostDocumentExecuteMailMerge");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/executeMailMerge/{withRegions}/?appSid={appSid}&amp;mailMergeDataFile={mailMergeDataFile}&amp;cleanup={cleanup}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}&amp;useWholeParagraphAsRegion={useWholeParagraphAsRegion}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'withRegions'}) {        		
		$_resource_path =~ s/\Q{withRegions}\E/$args{'withRegions'}/g;
    }else{
		$_resource_path    =~ s/[?&]withRegions.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'mailMergeDataFile'}) {        		
		$_resource_path =~ s/\Q{mailMergeDataFile}\E/$args{'mailMergeDataFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]mailMergeDataFile.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cleanup'}) {        		
		$_resource_path =~ s/\Q{cleanup}\E/$args{'cleanup'}/g;
    }else{
		$_resource_path    =~ s/[?&]cleanup.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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
    if ( exists $args{'useWholeParagraphAsRegion'}) {        		
		$_resource_path =~ s/\Q{useWholeParagraphAsRegion}\E/$args{'useWholeParagraphAsRegion'}/g;
    }else{
		$_resource_path    =~ s/[?&]useWholeParagraphAsRegion.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	# form params
    if ( exists $args{'file'} ) {
        
		$_body_data = read_file( $args{'file'} , binmode => ':raw' );
        
        
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostExecuteTemplate
#
# 
# 
# @param String $name  (required)
# @param String $cleanup  (optional)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Boolean $useWholeParagraphAsRegion  (optional)
# @param Boolean $withRegions  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PostExecuteTemplate {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostExecuteTemplate");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostExecuteTemplate");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/executeTemplate/?appSid={appSid}&amp;cleanup={cleanup}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}&amp;useWholeParagraphAsRegion={useWholeParagraphAsRegion}&amp;withRegions={withRegions}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cleanup'}) {        		
		$_resource_path =~ s/\Q{cleanup}\E/$args{'cleanup'}/g;
    }else{
		$_resource_path    =~ s/[?&]cleanup.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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
    if ( exists $args{'useWholeParagraphAsRegion'}) {        		
		$_resource_path =~ s/\Q{useWholeParagraphAsRegion}\E/$args{'useWholeParagraphAsRegion'}/g;
    }else{
		$_resource_path    =~ s/[?&]useWholeParagraphAsRegion.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'withRegions'}) {        		
		$_resource_path =~ s/\Q{withRegions}\E/$args{'withRegions'}/g;
    }else{
		$_resource_path    =~ s/[?&]withRegions.*?(?=&|\?|$)//g;
	}
    
    
    my $_body_data;
	# form params
    if ( exists $args{'file'} ) {
        
		$_body_data = read_file( $args{'file'} , binmode => ':raw' );
        
        
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentFields
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteDocumentFields {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentFields");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/fields/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteHeadersFooters
#
# 
# 
# @param String $name  (required)
# @param String $headersFootersTypes  (optional)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteHeadersFooters {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteHeadersFooters");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/headersfooters/?appSid={appSid}&amp;headersFootersTypes={headersFootersTypes}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'headersFootersTypes'}) {        		
		$_resource_path =~ s/\Q{headersFootersTypes}\E/$args{'headersFootersTypes'}/g;
    }else{
		$_resource_path    =~ s/[?&]headersFootersTypes.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentHyperlinks
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return HyperlinksResponse
#
sub GetDocumentHyperlinks {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentHyperlinks");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/hyperlinks/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinksResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentHyperlinkByIndex
#
# 
# 
# @param String $name  (required)
# @param String $hyperlinkIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return HyperlinkResponse
#
sub GetDocumentHyperlinkByIndex {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentHyperlinkByIndex");
    }
    
    # verify the required parameter 'hyperlinkIndex' is set
    unless (exists $args{'hyperlinkIndex'}) {
      croak("Missing the required parameter 'hyperlinkIndex' when calling GetDocumentHyperlinkByIndex");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/hyperlinks/{hyperlinkIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'hyperlinkIndex'}) {        		
		$_resource_path =~ s/\Q{hyperlinkIndex}\E/$args{'hyperlinkIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]hyperlinkIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostInsertPageNumbers
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param PageNumber $body  (required)
# @return DocumentResponse
#
sub PostInsertPageNumbers {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostInsertPageNumbers");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostInsertPageNumbers");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/insertPageNumbers/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostInsertWatermarkImage
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $rotationAngle  (optional)
# @param String $image  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PostInsertWatermarkImage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostInsertWatermarkImage");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostInsertWatermarkImage");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/insertWatermarkImage/?appSid={appSid}&amp;filename={filename}&amp;rotationAngle={rotationAngle}&amp;image={image}&amp;storage={storage}&amp;folder={folder}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'image'}) {        		
		$_resource_path =~ s/\Q{image}\E/$args{'image'}/g;
    }else{
		$_resource_path    =~ s/[?&]image.*?(?=&|\?|$)//g;
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
	# form params
    if ( exists $args{'file'} ) {
        
		$_body_data = read_file( $args{'file'} , binmode => ':raw' );
        
        
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostInsertWatermarkText
#
# 
# 
# @param String $name  (required)
# @param String $text  (optional)
# @param String $rotationAngle  (optional)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WatermarkText $body  (required)
# @return DocumentResponse
#
sub PostInsertWatermarkText {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostInsertWatermarkText");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostInsertWatermarkText");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/insertWatermarkText/?appSid={appSid}&amp;text={text}&amp;rotationAngle={rotationAngle}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'text'}) {        		
		$_resource_path =~ s/\Q{text}\E/$args{'text'}/g;
    }else{
		$_resource_path    =~ s/[?&]text.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentMacros
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteDocumentMacros {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentMacros");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/macros/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentFieldNames
#
# 
# 
# @param String $name  (required)
# @param Boolean $useNonMergeFields  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return FieldNamesResponse
#
sub GetDocumentFieldNames {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentFieldNames");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/mailMergeFieldNames/?appSid={appSid}&amp;useNonMergeFields={useNonMergeFields}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'useNonMergeFields'}) {        		
		$_resource_path =~ s/\Q{useNonMergeFields}\E/$args{'useNonMergeFields'}/g;
    }else{
		$_resource_path    =~ s/[?&]useNonMergeFields.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FieldNamesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentParagraphs
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ParagraphLinkCollectionResponse
#
sub GetDocumentParagraphs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentParagraphs");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ParagraphLinkCollectionResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentParagraph
#
# 
# 
# @param String $name  (required)
# @param String $index  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ParagraphResponse
#
sub GetDocumentParagraph {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentParagraph");
    }
    
    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling GetDocumentParagraph");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/{index}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'index'}) {        		
		$_resource_path =~ s/\Q{index}\E/$args{'index'}/g;
    }else{
		$_resource_path    =~ s/[?&]index.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ParagraphResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteParagraphFields
#
# 
# 
# @param String $name  (required)
# @param String $index  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteParagraphFields {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteParagraphFields");
    }
    
    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling DeleteParagraphFields");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/{index}/fields/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'index'}) {        		
		$_resource_path =~ s/\Q{index}\E/$args{'index'}/g;
    }else{
		$_resource_path    =~ s/[?&]index.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentParagraphRun
#
# 
# 
# @param String $name  (required)
# @param String $index  (required)
# @param String $runIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RunResponse
#
sub GetDocumentParagraphRun {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentParagraphRun");
    }
    
    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling GetDocumentParagraphRun");
    }
    
    # verify the required parameter 'runIndex' is set
    unless (exists $args{'runIndex'}) {
      croak("Missing the required parameter 'runIndex' when calling GetDocumentParagraphRun");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/{index}/runs/{runIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'index'}) {        		
		$_resource_path =~ s/\Q{index}\E/$args{'index'}/g;
    }else{
		$_resource_path    =~ s/[?&]index.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'runIndex'}) {        		
		$_resource_path =~ s/\Q{runIndex}\E/$args{'runIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]runIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RunResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentParagraphRunFont
#
# 
# 
# @param String $name  (required)
# @param String $index  (required)
# @param String $runIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return FontResponse
#
sub GetDocumentParagraphRunFont {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentParagraphRunFont");
    }
    
    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling GetDocumentParagraphRunFont");
    }
    
    # verify the required parameter 'runIndex' is set
    unless (exists $args{'runIndex'}) {
      croak("Missing the required parameter 'runIndex' when calling GetDocumentParagraphRunFont");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/{index}/runs/{runIndex}/font/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'index'}) {        		
		$_resource_path =~ s/\Q{index}\E/$args{'index'}/g;
    }else{
		$_resource_path    =~ s/[?&]index.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'runIndex'}) {        		
		$_resource_path =~ s/\Q{runIndex}\E/$args{'runIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]runIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FontResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostDocumentParagraphRunFont
#
# 
# 
# @param String $name  (required)
# @param String $index  (required)
# @param String $runIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $filename  (optional)
# @param Font $body  (required)
# @return FontResponse
#
sub PostDocumentParagraphRunFont {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostDocumentParagraphRunFont");
    }
    
    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling PostDocumentParagraphRunFont");
    }
    
    # verify the required parameter 'runIndex' is set
    unless (exists $args{'runIndex'}) {
      croak("Missing the required parameter 'runIndex' when calling PostDocumentParagraphRunFont");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostDocumentParagraphRunFont");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/paragraphs/{index}/runs/{runIndex}/font/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}&amp;filename={filename}';
    
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
    if ( exists $args{'index'}) {        		
		$_resource_path =~ s/\Q{index}\E/$args{'index'}/g;
    }else{
		$_resource_path    =~ s/[?&]index.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'runIndex'}) {        		
		$_resource_path =~ s/\Q{runIndex}\E/$args{'runIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]runIndex.*?(?=&|\?|$)//g;
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FontResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutProtectDocument
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ProtectionRequest $body  (required)
# @return ProtectionDataResponse
#
sub PutProtectDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutProtectDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutProtectDocument");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/protection/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ProtectionDataResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostChangeDocumentProtection
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ProtectionRequest $body  (required)
# @return ProtectionDataResponse
#
sub PostChangeDocumentProtection {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostChangeDocumentProtection");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostChangeDocumentProtection");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/protection/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ProtectionDataResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteUnprotectDocument
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ProtectionRequest $body  (required)
# @return ProtectionDataResponse
#
sub DeleteUnprotectDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteUnprotectDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling DeleteUnprotectDocument");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/protection/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ProtectionDataResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentProtection
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ProtectionDataResponse
#
sub GetDocumentProtection {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentProtection");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/protection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ProtectionDataResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostReplaceText
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ReplaceTextRequest $body  (required)
# @return ReplaceTextResponse
#
sub PostReplaceText {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostReplaceText");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostReplaceText");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/replaceText/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ReplaceTextResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# AcceptAllRevisions
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RevisionsModificationResponse
#
sub AcceptAllRevisions {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling AcceptAllRevisions");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/revisions/acceptAll/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RevisionsModificationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# RejectAllRevisions
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RevisionsModificationResponse
#
sub RejectAllRevisions {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling RejectAllRevisions");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/revisions/rejectAll/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RevisionsModificationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# Search
#
# 
# 
# @param String $name  (required)
# @param String $pattern  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SearchResponse
#
sub Search {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling Search");
    }
    
    # verify the required parameter 'pattern' is set
    unless (exists $args{'pattern'}) {
      croak("Missing the required parameter 'pattern' when calling Search");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/search/?appSid={appSid}&amp;pattern={pattern}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'pattern'}) {        		
		$_resource_path =~ s/\Q{pattern}\E/$args{'pattern'}/g;
    }else{
		$_resource_path    =~ s/[?&]pattern.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SearchResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSections
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SectionLinkCollectionResponse
#
sub GetSections {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSections");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SectionLinkCollectionResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSection
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SectionResponse
#
sub GetSection {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSection");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling GetSection");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SectionResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSectionFields
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteSectionFields {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSectionFields");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling DeleteSectionFields");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/fields/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSectionPageSetup
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SectionPageSetupResponse
#
sub GetSectionPageSetup {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSectionPageSetup");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling GetSectionPageSetup");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/pageSetup/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SectionPageSetupResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# UpdateSectionPageSetup
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $filename  (optional)
# @param PageSetup $body  (required)
# @return SectionPageSetupResponse
#
sub UpdateSectionPageSetup {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling UpdateSectionPageSetup");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling UpdateSectionPageSetup");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling UpdateSectionPageSetup");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/pageSetup/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}&amp;filename={filename}';
    
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SectionPageSetupResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $insertBeforeNode  (optional)
# @param String $destFileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param FieldDto $body  (required)
# @return FieldResponse
#
sub PutField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling PutField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling PutField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/fields/?appSid={appSid}&amp;insertBeforeNode={insertBeforeNode}&amp;destFileName={destFileName}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'insertBeforeNode'}) {        		
		$_resource_path =~ s/\Q{insertBeforeNode}\E/$args{'insertBeforeNode'}/g;
    }else{
		$_resource_path    =~ s/[?&]insertBeforeNode.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFileName'}) {        		
		$_resource_path =~ s/\Q{destFileName}\E/$args{'destFileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSectionParagraphFields
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteSectionParagraphFields {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSectionParagraphFields");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling DeleteSectionParagraphFields");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling DeleteSectionParagraphFields");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/fields/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $fieldIndex  (required)
# @param String $destFileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param FieldDto $body  (required)
# @return FieldResponse
#
sub PostField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling PostField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling PostField");
    }
    
    # verify the required parameter 'fieldIndex' is set
    unless (exists $args{'fieldIndex'}) {
      croak("Missing the required parameter 'fieldIndex' when calling PostField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/fields/{fieldIndex}/?appSid={appSid}&amp;destFileName={destFileName}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fieldIndex'}) {        		
		$_resource_path =~ s/\Q{fieldIndex}\E/$args{'fieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]fieldIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFileName'}) {        		
		$_resource_path =~ s/\Q{destFileName}\E/$args{'destFileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $fieldIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return FieldResponse
#
sub GetField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling GetField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling GetField");
    }
    
    # verify the required parameter 'fieldIndex' is set
    unless (exists $args{'fieldIndex'}) {
      croak("Missing the required parameter 'fieldIndex' when calling GetField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/fields/{fieldIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fieldIndex'}) {        		
		$_resource_path =~ s/\Q{fieldIndex}\E/$args{'fieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]fieldIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutFormField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $insertBeforeNode  (optional)
# @param String $destFileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param FormField $body  (required)
# @return FormFieldResponse
#
sub PutFormField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutFormField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling PutFormField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling PutFormField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutFormField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/formfields/?appSid={appSid}&amp;insertBeforeNode={insertBeforeNode}&amp;destFileName={destFileName}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/xml');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'insertBeforeNode'}) {        		
		$_resource_path =~ s/\Q{insertBeforeNode}\E/$args{'insertBeforeNode'}/g;
    }else{
		$_resource_path    =~ s/[?&]insertBeforeNode.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFileName'}) {        		
		$_resource_path =~ s/\Q{destFileName}\E/$args{'destFileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FormFieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostFormField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $formfieldIndex  (required)
# @param String $destFileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param FormField $body  (required)
# @return FormFieldResponse
#
sub PostFormField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostFormField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling PostFormField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling PostFormField");
    }
    
    # verify the required parameter 'formfieldIndex' is set
    unless (exists $args{'formfieldIndex'}) {
      croak("Missing the required parameter 'formfieldIndex' when calling PostFormField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostFormField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/formfields/{formfieldIndex}/?appSid={appSid}&amp;destFileName={destFileName}&amp;storage={storage}&amp;folder={folder}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/xml');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'formfieldIndex'}) {        		
		$_resource_path =~ s/\Q{formfieldIndex}\E/$args{'formfieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]formfieldIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFileName'}) {        		
		$_resource_path =~ s/\Q{destFileName}\E/$args{'destFileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FormFieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteFormField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $formfieldIndex  (required)
# @param String $destFileName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteFormField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteFormField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling DeleteFormField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling DeleteFormField");
    }
    
    # verify the required parameter 'formfieldIndex' is set
    unless (exists $args{'formfieldIndex'}) {
      croak("Missing the required parameter 'formfieldIndex' when calling DeleteFormField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/formfields/{formfieldIndex}/?appSid={appSid}&amp;destFileName={destFileName}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'formfieldIndex'}) {        		
		$_resource_path =~ s/\Q{formfieldIndex}\E/$args{'formfieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]formfieldIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFileName'}) {        		
		$_resource_path =~ s/\Q{destFileName}\E/$args{'destFileName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFileName.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetFormField
#
# 
# 
# @param String $name  (required)
# @param String $sectionIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $formfieldIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return FormFieldResponse
#
sub GetFormField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetFormField");
    }
    
    # verify the required parameter 'sectionIndex' is set
    unless (exists $args{'sectionIndex'}) {
      croak("Missing the required parameter 'sectionIndex' when calling GetFormField");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling GetFormField");
    }
    
    # verify the required parameter 'formfieldIndex' is set
    unless (exists $args{'formfieldIndex'}) {
      croak("Missing the required parameter 'formfieldIndex' when calling GetFormField");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/sections/{sectionIndex}/paragraphs/{paragraphIndex}/formfields/{formfieldIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'sectionIndex'}) {        		
		$_resource_path =~ s/\Q{sectionIndex}\E/$args{'sectionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sectionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'formfieldIndex'}) {        		
		$_resource_path =~ s/\Q{formfieldIndex}\E/$args{'formfieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]formfieldIndex.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FormFieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSplitDocument
#
# 
# 
# @param String $name  (required)
# @param String $format  (optional)
# @param String $from  (optional)
# @param String $to  (optional)
# @param Boolean $zipOutput  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SplitDocumentResponse
#
sub PostSplitDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSplitDocument");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/split/?appSid={appSid}&amp;toFormat={toFormat}&amp;from={from}&amp;to={to}&amp;zipOutput={zipOutput}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'from'}) {        		
		$_resource_path =~ s/\Q{from}\E/$args{'from'}/g;
    }else{
		$_resource_path    =~ s/[?&]from.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'to'}) {        		
		$_resource_path =~ s/\Q{to}\E/$args{'to'}/g;
    }else{
		$_resource_path    =~ s/[?&]to.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'zipOutput'}) {        		
		$_resource_path =~ s/\Q{zipOutput}\E/$args{'zipOutput'}/g;
    }else{
		$_resource_path    =~ s/[?&]zipOutput.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SplitDocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentStatistics
#
# 
# 
# @param String $name  (required)
# @param Boolean $includeComments  (optional)
# @param Boolean $includeFootnotes  (optional)
# @param Boolean $includeTextInShapes  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return StatDataResponse
#
sub GetDocumentStatistics {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentStatistics");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/statistics/?appSid={appSid}&amp;includeComments={includeComments}&amp;includeFootnotes={includeFootnotes}&amp;includeTextInShapes={includeTextInShapes}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
    if ( exists $args{'includeComments'}) {        		
		$_resource_path =~ s/\Q{includeComments}\E/$args{'includeComments'}/g;
    }else{
		$_resource_path    =~ s/[?&]includeComments.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'includeFootnotes'}) {        		
		$_resource_path =~ s/\Q{includeFootnotes}\E/$args{'includeFootnotes'}/g;
    }else{
		$_resource_path    =~ s/[?&]includeFootnotes.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'includeTextInShapes'}) {        		
		$_resource_path =~ s/\Q{includeTextInShapes}\E/$args{'includeTextInShapes'}/g;
    }else{
		$_resource_path    =~ s/[?&]includeTextInShapes.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'StatDataResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDocumentTextItems
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return TextItemsResponse
#
sub GetDocumentTextItems {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentTextItems");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/textItems/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'GET';
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateDocumentFields
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DocumentResponse
#
sub PostUpdateDocumentFields {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateDocumentFields");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/updateFields/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentWatermark
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DocumentResponse
#
sub DeleteDocumentWatermark {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentWatermark");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/watermark/?appSid={appSid}&amp;filename={filename}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'DELETE';
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostInsertDocumentWatermarkImage
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $rotationAngle  (optional)
# @param String $image  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PostInsertDocumentWatermarkImage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostInsertDocumentWatermarkImage");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostInsertDocumentWatermarkImage");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/watermark/insertImage/?appSid={appSid}&amp;filename={filename}&amp;rotationAngle={rotationAngle}&amp;image={image}&amp;storage={storage}&amp;folder={folder}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'image'}) {        		
		$_resource_path =~ s/\Q{image}\E/$args{'image'}/g;
    }else{
		$_resource_path    =~ s/[?&]image.*?(?=&|\?|$)//g;
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
	# form params
    if ( exists $args{'file'} ) {
        
		$_body_data = read_file( $args{'file'} , binmode => ':raw' );
        
        
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostInsertDocumentWatermarkText
#
# 
# 
# @param String $name  (required)
# @param String $filename  (optional)
# @param String $text  (optional)
# @param String $rotationAngle  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WatermarkText $body  (required)
# @return DocumentResponse
#
sub PostInsertDocumentWatermarkText {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostInsertDocumentWatermarkText");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostInsertDocumentWatermarkText");
    }
    

    # parse inputs
    my $_resource_path = '/words/{name}/watermark/insertText/?appSid={appSid}&amp;filename={filename}&amp;text={text}&amp;rotationAngle={rotationAngle}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'filename'}) {        		
		$_resource_path =~ s/\Q{filename}\E/$args{'filename'}/g;
    }else{
		$_resource_path    =~ s/[?&]filename.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'text'}) {        		
		$_resource_path =~ s/\Q{text}\E/$args{'text'}/g;
    }else{
		$_resource_path    =~ s/[?&]text.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
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

	if($AsposeWordsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
