package AsposeSlidesCloud::SlidesApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeSlidesCloud::ApiClient;
use AsposeSlidesCloud::Configuration;

my $VERSION = '1.03';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeSlidesCloud::Configuration::api_client ? $AsposeSlidesCloud::Configuration::api_client  :
	AsposeSlidesCloud::ApiClient->new;
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
# PutSlidesConvert
#
# 
# 
# @param String $password  (optional)
# @param String $format  (optional)
# @param String $outPath  (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PutSlidesConvert {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutSlidesConvert");
    }
    

    # parse inputs
    my $_resource_path = '/slides/convert/?appSid={appSid}&amp;password={password}&amp;toFormat={toFormat}&amp;outPath={outPath}';
    
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
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesDocument
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return DocumentResponse
#
sub GetSlidesDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesDocument");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutNewPresentation
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PutNewPresentation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutNewPresentation");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutNewPresentation");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}/g;
	$_resource_path =~ s/\Q{path}\E/{Path}/g;
    
    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept( 'application/json');
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
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesDocument
#
# 
# 
# @param String $name  (required)
# @param String $templatePath  (required)
# @param String $templateStorage  (optional)
# @param Boolean $isImageDataEmbeeded  (optional)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PostSlidesDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesDocument");
    }
    
    # verify the required parameter 'templatePath' is set
    unless (exists $args{'templatePath'}) {
      croak("Missing the required parameter 'templatePath' when calling PostSlidesDocument");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostSlidesDocument");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/?appSid={appSid}&amp;templatePath={templatePath}&amp;templateStorage={templateStorage}&amp;isImageDataEmbeeded={isImageDataEmbeeded}&amp;password={password}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'templatePath'}) {        		
		$_resource_path =~ s/\Q{templatePath}\E/$args{'templatePath'}/g;
    }else{
		$_resource_path    =~ s/[?&]templatePath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'templateStorage'}) {        		
		$_resource_path =~ s/\Q{templateStorage}\E/$args{'templateStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]templateStorage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isImageDataEmbeeded'}) {        		
		$_resource_path =~ s/\Q{isImageDataEmbeeded}\E/$args{'isImageDataEmbeeded'}/g;
    }else{
		$_resource_path    =~ s/[?&]isImageDataEmbeeded.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutNewPresentationFromStoredTemplate
#
# 
# 
# @param String $name  (required)
# @param String $templatePath  (required)
# @param String $templateStorage  (optional)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PutNewPresentationFromStoredTemplate {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutNewPresentationFromStoredTemplate");
    }
    
    # verify the required parameter 'templatePath' is set
    unless (exists $args{'templatePath'}) {
      croak("Missing the required parameter 'templatePath' when calling PutNewPresentationFromStoredTemplate");
    }
    
    # verify the required parameter 'file' is set
    #unless (exists $args{'file'}) {
     # croak("Missing the required parameter 'file' when calling PutNewPresentationFromStoredTemplate");
    #}
    

    # parse inputs
    my $_resource_path = '/slides/{name}/?appSid={appSid}&amp;templatePath={templatePath}&amp;templateStorage={templateStorage}&amp;password={password}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'templatePath'}) {        		
		$_resource_path =~ s/\Q{templatePath}\E/$args{'templatePath'}/g;
    }else{
		$_resource_path    =~ s/[?&]templatePath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'templateStorage'}) {        		
		$_resource_path =~ s/\Q{templateStorage}\E/$args{'templateStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]templateStorage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesDocumentWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $format  (required)
# @param String $jpegQuality  (optional)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @return ResponseMessage
#
sub GetSlidesDocumentWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesDocumentWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetSlidesDocumentWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/?appSid={appSid}&amp;toFormat={toFormat}&amp;jpegQuality={jpegQuality}&amp;password={password}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    if ( exists $args{'jpegQuality'}) {        		
		$_resource_path =~ s/\Q{jpegQuality}\E/$args{'jpegQuality'}/g;
    }else{
		$_resource_path    =~ s/[?&]jpegQuality.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesDocumentProperties
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return DocumentPropertiesResponse
#
sub GetSlidesDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSetDocumentProperties
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param DocumentProperties $body  (required)
# @return DocumentPropertiesResponse
#
sub PostSlidesSetDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSetDocumentProperties");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostSlidesSetDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSlidesDocumentProperties
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return DocumentPropertiesResponse
#
sub DeleteSlidesDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSlidesDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return DocumentPropertyResponse
#
sub GetSlidesDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling GetSlidesDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSlidesSetDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param DocumentProperty $body  (required)
# @return DocumentPropertyResponse
#
sub PutSlidesSetDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSlidesSetDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling PutSlidesSetDocumentProperty");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSlidesSetDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSlidesDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return CommonResponse
#
sub DeleteSlidesDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSlidesDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling DeleteSlidesDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommonResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSlidesDocumentFromHtml
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return DocumentResponse
#
sub PutSlidesDocumentFromHtml {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSlidesDocumentFromHtml");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutSlidesDocumentFromHtml");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/fromHtml/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesImages
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ImagesResponse
#
sub GetSlidesImages {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesImages");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/images/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ImagesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutPresentationMerge
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param OrderedMergeRequest $body  (required)
# @return DocumentResponse
#
sub PutPresentationMerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutPresentationMerge");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutPresentationMerge");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/merge/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostPresentationMerge
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param PresentationsMergeRequest $body  (required)
# @return DocumentResponse
#
sub PostPresentationMerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostPresentationMerge");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostPresentationMerge");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/merge/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesPresentationReplaceText
#
# 
# 
# @param String $name  (required)
# @param String $oldValue  (required)
# @param String $newValue  (required)
# @param Boolean $ignoreCase  (optional)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return PresentationStringReplaceResponse
#
sub PostSlidesPresentationReplaceText {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesPresentationReplaceText");
    }
    
    # verify the required parameter 'oldValue' is set
    unless (exists $args{'oldValue'}) {
      croak("Missing the required parameter 'oldValue' when calling PostSlidesPresentationReplaceText");
    }
    
    # verify the required parameter 'newValue' is set
    unless (exists $args{'newValue'}) {
      croak("Missing the required parameter 'newValue' when calling PostSlidesPresentationReplaceText");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/replaceText/?oldValue={oldValue}&amp;newValue={newValue}&amp;appSid={appSid}&amp;ignoreCase={ignoreCase}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'oldValue'}) {        		
		$_resource_path =~ s/\Q{oldValue}\E/$args{'oldValue'}/g;
    }else{
		$_resource_path    =~ s/[?&]oldValue.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newValue'}) {        		
		$_resource_path =~ s/\Q{newValue}\E/$args{'newValue'}/g;
    }else{
		$_resource_path    =~ s/[?&]newValue.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'ignoreCase'}) {        		
		$_resource_path =~ s/\Q{ignoreCase}\E/$args{'ignoreCase'}/g;
    }else{
		$_resource_path    =~ s/[?&]ignoreCase.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PresentationStringReplaceResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSaveAsHtml
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @param HtmlExportOptions $body  (required)
# @return ResponseMessage
#
sub PostSlidesSaveAsHtml {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSaveAsHtml");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostSlidesSaveAsHtml");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/saveAs/html/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSaveAsPdf
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @param PdfExportOptions $body  (required)
# @return ResponseMessage
#
sub PostSlidesSaveAsPdf {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSaveAsPdf");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostSlidesSaveAsPdf");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/saveAs/pdf/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSaveAsTiff
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @param TiffExportOptions $body  (required)
# @return ResponseMessage
#
sub PostSlidesSaveAsTiff {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSaveAsTiff");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostSlidesSaveAsTiff");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/saveAs/tiff/?appSid={appSid}&amp;password={password}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlidesList
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub GetSlidesSlidesList {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlidesList");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAddEmptySlide
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostAddEmptySlide {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAddEmptySlide");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSlidesCleanSlidesList
#
# 
# 
# @param String $name  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub DeleteSlidesCleanSlidesList {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSlidesCleanSlidesList");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesReorderPosition
#
# 
# 
# @param String $name  (required)
# @param String $oldPosition  (required)
# @param String $newPosition  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostSlidesReorderPosition {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesReorderPosition");
    }
    
    # verify the required parameter 'oldPosition' is set
    unless (exists $args{'oldPosition'}) {
      croak("Missing the required parameter 'oldPosition' when calling PostSlidesReorderPosition");
    }
    
    # verify the required parameter 'newPosition' is set
    unless (exists $args{'newPosition'}) {
      croak("Missing the required parameter 'newPosition' when calling PostSlidesReorderPosition");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;oldPosition={oldPosition}&amp;newPosition={newPosition}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'oldPosition'}) {        		
		$_resource_path =~ s/\Q{oldPosition}\E/$args{'oldPosition'}/g;
    }else{
		$_resource_path    =~ s/[?&]oldPosition.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newPosition'}) {        		
		$_resource_path =~ s/\Q{newPosition}\E/$args{'newPosition'}/g;
    }else{
		$_resource_path    =~ s/[?&]newPosition.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAddEmptySlideAtPosition
#
# 
# 
# @param String $name  (required)
# @param String $position  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostAddEmptySlideAtPosition {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAddEmptySlideAtPosition");
    }
    
    # verify the required parameter 'position' is set
    unless (exists $args{'position'}) {
      croak("Missing the required parameter 'position' when calling PostAddEmptySlideAtPosition");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;position={position}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'position'}) {        		
		$_resource_path =~ s/\Q{position}\E/$args{'position'}/g;
    }else{
		$_resource_path    =~ s/[?&]position.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostClonePresentationSlide
#
# 
# 
# @param String $name  (required)
# @param String $position  (required)
# @param String $slideToClone  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostClonePresentationSlide {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostClonePresentationSlide");
    }
    
    # verify the required parameter 'position' is set
    unless (exists $args{'position'}) {
      croak("Missing the required parameter 'position' when calling PostClonePresentationSlide");
    }
    
    # verify the required parameter 'slideToClone' is set
    unless (exists $args{'slideToClone'}) {
      croak("Missing the required parameter 'slideToClone' when calling PostClonePresentationSlide");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;position={position}&amp;slideToClone={slideToClone}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'position'}) {        		
		$_resource_path =~ s/\Q{position}\E/$args{'position'}/g;
    }else{
		$_resource_path    =~ s/[?&]position.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'slideToClone'}) {        		
		$_resource_path =~ s/\Q{slideToClone}\E/$args{'slideToClone'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideToClone.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAddSlideCopy
#
# 
# 
# @param String $name  (required)
# @param String $slideToClone  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostAddSlideCopy {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAddSlideCopy");
    }
    
    # verify the required parameter 'slideToClone' is set
    unless (exists $args{'slideToClone'}) {
      croak("Missing the required parameter 'slideToClone' when calling PostAddSlideCopy");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;slideToClone={slideToClone}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideToClone'}) {        		
		$_resource_path =~ s/\Q{slideToClone}\E/$args{'slideToClone'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideToClone.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostCopySlideFromSourcePresentation
#
# 
# 
# @param String $name  (required)
# @param String $slideToCopy  (required)
# @param String $source  (required)
# @param String $position  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub PostCopySlideFromSourcePresentation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostCopySlideFromSourcePresentation");
    }
    
    # verify the required parameter 'slideToCopy' is set
    unless (exists $args{'slideToCopy'}) {
      croak("Missing the required parameter 'slideToCopy' when calling PostCopySlideFromSourcePresentation");
    }
    
    # verify the required parameter 'source' is set
    unless (exists $args{'source'}) {
      croak("Missing the required parameter 'source' when calling PostCopySlideFromSourcePresentation");
    }
    
    # verify the required parameter 'position' is set
    unless (exists $args{'position'}) {
      croak("Missing the required parameter 'position' when calling PostCopySlideFromSourcePresentation");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/?appSid={appSid}&amp;slideToCopy={slideToCopy}&amp;source={source}&amp;position={position}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideToCopy'}) {        		
		$_resource_path =~ s/\Q{slideToCopy}\E/$args{'slideToCopy'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideToCopy.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'source'}) {        		
		$_resource_path =~ s/\Q{source}\E/$args{'source'}/g;
    }else{
		$_resource_path    =~ s/[?&]source.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'position'}) {        		
		$_resource_path =~ s/\Q{position}\E/$args{'position'}/g;
    }else{
		$_resource_path    =~ s/[?&]position.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlide
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideResponse
#
sub GetSlidesSlide {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlide");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlide");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSlideByIndex
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideListResponse
#
sub DeleteSlideByIndex {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSlideByIndex");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling DeleteSlideByIndex");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideListResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlideWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $format  (required)
# @param String $width  (optional)
# @param String $height  (optional)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetSlideWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlideWithFormat");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlideWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetSlideWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/?appSid={appSid}&amp;toFormat={toFormat}&amp;width={width}&amp;height={height}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'width'}) {        		
		$_resource_path =~ s/\Q{width}\E/$args{'width'}/g;
    }else{
		$_resource_path    =~ s/[?&]width.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'height'}) {        		
		$_resource_path =~ s/\Q{height}\E/$args{'height'}/g;
    }else{
		$_resource_path    =~ s/[?&]height.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideBackground
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideBackgroundResponse
#
sub GetSlidesSlideBackground {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideBackground");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideBackground");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideBackgroundResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSlidesSlideBackground
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param  $body  (required)
# @return SlideBackgroundResponse
#
sub PutSlidesSlideBackground {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSlidesSlideBackground");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling PutSlidesSlideBackground");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSlidesSlideBackground");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideBackgroundResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteSlidesSlideBackground
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideBackgroundResponse
#
sub DeleteSlidesSlideBackground {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteSlidesSlideBackground");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling DeleteSlidesSlideBackground");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideBackgroundResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideComments
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideCommentsResponse
#
sub GetSlidesSlideComments {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideComments");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideComments");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/comments/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideCommentsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideImages
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ImagesResponse
#
sub GetSlidesSlideImages {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideImages");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideImages");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/images/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ImagesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesPlaceholders
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return PlaceholdersResponse
#
sub GetSlidesPlaceholders {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesPlaceholders");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesPlaceholders");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/placeholders/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PlaceholdersResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesPlaceholder
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $placeholderIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return PlaceholderResponse
#
sub GetSlidesPlaceholder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesPlaceholder");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesPlaceholder");
    }
    
    # verify the required parameter 'placeholderIndex' is set
    unless (exists $args{'placeholderIndex'}) {
      croak("Missing the required parameter 'placeholderIndex' when calling GetSlidesPlaceholder");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/placeholders/{placeholderIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'placeholderIndex'}) {        		
		$_resource_path =~ s/\Q{placeholderIndex}\E/$args{'placeholderIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]placeholderIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PlaceholderResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSlideReplaceText
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $oldValue  (required)
# @param String $newValue  (required)
# @param Boolean $ignoreCase  (optional)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SlideStringReplaceResponse
#
sub PostSlidesSlideReplaceText {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSlideReplaceText");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling PostSlidesSlideReplaceText");
    }
    
    # verify the required parameter 'oldValue' is set
    unless (exists $args{'oldValue'}) {
      croak("Missing the required parameter 'oldValue' when calling PostSlidesSlideReplaceText");
    }
    
    # verify the required parameter 'newValue' is set
    unless (exists $args{'newValue'}) {
      croak("Missing the required parameter 'newValue' when calling PostSlidesSlideReplaceText");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/replaceText/?oldValue={oldValue}&amp;newValue={newValue}&amp;appSid={appSid}&amp;ignoreCase={ignoreCase}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'oldValue'}) {        		
		$_resource_path =~ s/\Q{oldValue}\E/$args{'oldValue'}/g;
    }else{
		$_resource_path    =~ s/[?&]oldValue.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newValue'}) {        		
		$_resource_path =~ s/\Q{newValue}\E/$args{'newValue'}/g;
    }else{
		$_resource_path    =~ s/[?&]newValue.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'ignoreCase'}) {        		
		$_resource_path =~ s/\Q{ignoreCase}\E/$args{'ignoreCase'}/g;
    }else{
		$_resource_path    =~ s/[?&]ignoreCase.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SlideStringReplaceResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideShapes
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ShapesResponse
#
sub GetSlidesSlideShapes {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideShapes");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideShapes");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ShapesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAddNewShape
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param Shape $body  (required)
# @return ShapeResponse
#
sub PostAddNewShape {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAddNewShape");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling PostAddNewShape");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostAddNewShape");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ShapeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetShapeWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapeIndex  (required)
# @param String $format  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param String $scaleX  (optional)
# @param String $scaleY  (optional)
# @param String $bounds  (optional)
# @return ResponseMessage
#
sub GetShapeWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetShapeWithFormat");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetShapeWithFormat");
    }
    
    # verify the required parameter 'shapeIndex' is set
    unless (exists $args{'shapeIndex'}) {
      croak("Missing the required parameter 'shapeIndex' when calling GetShapeWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetShapeWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapeIndex}/?toFormat={toFormat}&amp;appSid={appSid}&amp;folder={folder}&amp;storage={storage}&amp;scaleX={scaleX}&amp;scaleY={scaleY}&amp;bounds={bounds}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapeIndex'}) {        		
		$_resource_path =~ s/\Q{shapeIndex}\E/$args{'shapeIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapeIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'scaleX'}) {        		
		$_resource_path =~ s/\Q{scaleX}\E/$args{'scaleX'}/g;
    }else{
		$_resource_path    =~ s/[?&]scaleX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'scaleY'}) {        		
		$_resource_path =~ s/\Q{scaleY}\E/$args{'scaleY'}/g;
    }else{
		$_resource_path    =~ s/[?&]scaleY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'bounds'}) {        		
		$_resource_path =~ s/\Q{bounds}\E/$args{'bounds'}/g;
    }else{
		$_resource_path    =~ s/[?&]bounds.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlideShapeParagraphs
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapeIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ShapesResponse
#
sub GetSlideShapeParagraphs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlideShapeParagraphs");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlideShapeParagraphs");
    }
    
    # verify the required parameter 'shapeIndex' is set
    unless (exists $args{'shapeIndex'}) {
      croak("Missing the required parameter 'shapeIndex' when calling GetSlideShapeParagraphs");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapeIndex}/paragraphs/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapeIndex'}) {        		
		$_resource_path =~ s/\Q{shapeIndex}\E/$args{'shapeIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapeIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ShapesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetShapeParagraph
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapeIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetShapeParagraph {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetShapeParagraph");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetShapeParagraph");
    }
    
    # verify the required parameter 'shapeIndex' is set
    unless (exists $args{'shapeIndex'}) {
      croak("Missing the required parameter 'shapeIndex' when calling GetShapeParagraph");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling GetShapeParagraph");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapeIndex}/paragraphs/{paragraphIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapeIndex'}) {        		
		$_resource_path =~ s/\Q{shapeIndex}\E/$args{'shapeIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapeIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetParagraphPortion
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapeIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $portionIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return PortionResponse
#
sub GetParagraphPortion {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetParagraphPortion");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetParagraphPortion");
    }
    
    # verify the required parameter 'shapeIndex' is set
    unless (exists $args{'shapeIndex'}) {
      croak("Missing the required parameter 'shapeIndex' when calling GetParagraphPortion");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling GetParagraphPortion");
    }
    
    # verify the required parameter 'portionIndex' is set
    unless (exists $args{'portionIndex'}) {
      croak("Missing the required parameter 'portionIndex' when calling GetParagraphPortion");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapeIndex'}) {        		
		$_resource_path =~ s/\Q{shapeIndex}\E/$args{'shapeIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapeIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'portionIndex'}) {        		
		$_resource_path =~ s/\Q{portionIndex}\E/$args{'portionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]portionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PortionResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSetParagraphPortionProperties
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapeIndex  (required)
# @param String $paragraphIndex  (required)
# @param String $portionIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param Portion $body  (required)
# @return PortionResponse
#
sub PutSetParagraphPortionProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSetParagraphPortionProperties");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling PutSetParagraphPortionProperties");
    }
    
    # verify the required parameter 'shapeIndex' is set
    unless (exists $args{'shapeIndex'}) {
      croak("Missing the required parameter 'shapeIndex' when calling PutSetParagraphPortionProperties");
    }
    
    # verify the required parameter 'paragraphIndex' is set
    unless (exists $args{'paragraphIndex'}) {
      croak("Missing the required parameter 'paragraphIndex' when calling PutSetParagraphPortionProperties");
    }
    
    # verify the required parameter 'portionIndex' is set
    unless (exists $args{'portionIndex'}) {
      croak("Missing the required parameter 'portionIndex' when calling PutSetParagraphPortionProperties");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSetParagraphPortionProperties");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapeIndex'}) {        		
		$_resource_path =~ s/\Q{shapeIndex}\E/$args{'shapeIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapeIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'paragraphIndex'}) {        		
		$_resource_path =~ s/\Q{paragraphIndex}\E/$args{'paragraphIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]paragraphIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'portionIndex'}) {        		
		$_resource_path =~ s/\Q{portionIndex}\E/$args{'portionIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]portionIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PortionResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideShapesParent
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapePath  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ShapeResponse
#
sub GetSlidesSlideShapesParent {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideShapesParent");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideShapesParent");
    }
    
    # verify the required parameter 'shapePath' is set
    unless (exists $args{'shapePath'}) {
      croak("Missing the required parameter 'shapePath' when calling GetSlidesSlideShapesParent");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapePath}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapePath'}) {        		
		$_resource_path =~ s/\Q{shapePath}\E/$args{'shapePath'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapePath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ShapeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutSlideShapeInfo
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $shapePath  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param Shape $body  (required)
# @return ShapeResponse
#
sub PutSlideShapeInfo {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutSlideShapeInfo");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling PutSlideShapeInfo");
    }
    
    # verify the required parameter 'shapePath' is set
    unless (exists $args{'shapePath'}) {
      croak("Missing the required parameter 'shapePath' when calling PutSlideShapeInfo");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSlideShapeInfo");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{shapePath}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'shapePath'}) {        		
		$_resource_path =~ s/\Q{shapePath}\E/$args{'shapePath'}/g;
    }else{
		$_resource_path    =~ s/[?&]shapePath.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ShapeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesSlideTextItems
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param Boolean $withEmpty  (optional)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return TextItemsResponse
#
sub GetSlidesSlideTextItems {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesSlideTextItems");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesSlideTextItems");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/textItems/?appSid={appSid}&amp;withEmpty={withEmpty}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'withEmpty'}) {        		
		$_resource_path =~ s/\Q{withEmpty}\E/$args{'withEmpty'}/g;
    }else{
		$_resource_path    =~ s/[?&]withEmpty.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesTheme
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ThemeResponse
#
sub GetSlidesTheme {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesTheme");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesTheme");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ThemeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesThemeColorScheme
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return ColorSchemeResponse
#
sub GetSlidesThemeColorScheme {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesThemeColorScheme");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesThemeColorScheme");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/colorScheme/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColorSchemeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesThemeFontScheme
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return FontSchemeResponse
#
sub GetSlidesThemeFontScheme {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesThemeFontScheme");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesThemeFontScheme");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/fontScheme/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FontSchemeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesThemeFormatScheme
#
# 
# 
# @param String $name  (required)
# @param String $slideIndex  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return FormatSchemeResponse
#
sub GetSlidesThemeFormatScheme {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesThemeFormatScheme");
    }
    
    # verify the required parameter 'slideIndex' is set
    unless (exists $args{'slideIndex'}) {
      croak("Missing the required parameter 'slideIndex' when calling GetSlidesThemeFormatScheme");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/formatScheme/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'slideIndex'}) {        		
		$_resource_path =~ s/\Q{slideIndex}\E/$args{'slideIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]slideIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FormatSchemeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSlidesSplit
#
# 
# 
# @param String $name  (required)
# @param String $width  (optional)
# @param String $height  (optional)
# @param String $to  (optional)
# @param String $from  (optional)
# @param String $destFolder  (optional)
# @param String $format  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SplitDocumentResponse
#
sub PostSlidesSplit {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSlidesSplit");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/split/?appSid={appSid}&amp;width={width}&amp;height={height}&amp;to={to}&amp;from={from}&amp;destFolder={destFolder}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'width'}) {        		
		$_resource_path =~ s/\Q{width}\E/$args{'width'}/g;
    }else{
		$_resource_path    =~ s/[?&]width.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'height'}) {        		
		$_resource_path =~ s/\Q{height}\E/$args{'height'}/g;
    }else{
		$_resource_path    =~ s/[?&]height.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'to'}) {        		
		$_resource_path =~ s/\Q{to}\E/$args{'to'}/g;
    }else{
		$_resource_path    =~ s/[?&]to.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'from'}) {        		
		$_resource_path =~ s/\Q{from}\E/$args{'from'}/g;
    }else{
		$_resource_path    =~ s/[?&]from.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destFolder'}) {        		
		$_resource_path =~ s/\Q{destFolder}\E/$args{'destFolder'}/g;
    }else{
		$_resource_path    =~ s/[?&]destFolder.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SplitDocumentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetSlidesPresentationTextItems
#
# 
# 
# @param String $name  (required)
# @param Boolean $withEmpty  (optional)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return TextItemsResponse
#
sub GetSlidesPresentationTextItems {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetSlidesPresentationTextItems");
    }
    

    # parse inputs
    my $_resource_path = '/slides/{name}/textItems/?appSid={appSid}&amp;withEmpty={withEmpty}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'withEmpty'}) {        		
		$_resource_path =~ s/\Q{withEmpty}\E/$args{'withEmpty'}/g;
    }else{
		$_resource_path    =~ s/[?&]withEmpty.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'folder'}) {        		
		$_resource_path =~ s/\Q{folder}\E/$args{'folder'}/g;
    }else{
		$_resource_path    =~ s/[?&]folder.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
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

	if($AsposeSlidesCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
