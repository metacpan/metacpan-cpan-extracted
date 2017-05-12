package AsposeOcrCloud::OcrApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeOcrCloud::ApiClient;
use AsposeOcrCloud::Configuration;

my $VERSION = '1.01';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeOcrCloud::Configuration::api_client ? $AsposeOcrCloud::Configuration::api_client  :
	AsposeOcrCloud::ApiClient->new;
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
# PostOcrFromUrlOrContent
#
# Recognize image text from some url if provided or from the request body content, language can be selected, default dictionaries can be used for correction.
# 
# @param String $url The image file url. (optional)
# @param String $language Language of the document. (optional)
# @param Boolean $useDefaultDictionaries Use default dictionaries for result correction. (optional)
# @param File $file  (required)
# @return OCRResponse
#
sub PostOcrFromUrlOrContent {
    my ($self, %args) = @_;

    
    # parse inputs
    my $_resource_path = '/ocr/recognize/?appSid={appSid}&amp;url={url}&amp;language={language}&amp;useDefaultDictionaries={useDefaultDictionaries}';
    
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
    if ( exists $args{'url'}) {        		
		$_resource_path =~ s/\Q{url}\E/$args{'url'}/g;
    }else{
		$_resource_path    =~ s/[?&]url.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'language'}) {        		
		$_resource_path =~ s/\Q{language}\E/$args{'language'}/g;
    }else{
		$_resource_path    =~ s/[?&]language.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useDefaultDictionaries'}) {        		
		$_resource_path =~ s/\Q{useDefaultDictionaries}\E/$args{'useDefaultDictionaries'}/g;
    }else{
		$_resource_path    =~ s/[?&]useDefaultDictionaries.*?(?=&|\?|$)//g;
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

	if($AsposeOcrCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'OCRResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetRecognizeDocument
#
# Recognize image text, language and text region can be selected, default dictionaries can be used for correction.
# 
# @param String $name Name of the file to recognize. (required)
# @param String $language Language of the document. (optional)
# @param String $rectX Top left point X coordinate of  to recognize text inside. (optional)
# @param String $rectY Top left point Y coordinate of  to recognize text inside. (optional)
# @param String $rectWidth Width of  to recognize text inside. (optional)
# @param String $rectHeight Height of  to recognize text inside. (optional)
# @param Boolean $useDefaultDictionaries Use default dictionaries for result correction. (optional)
# @param String $storage Image&#39;s storage. (optional)
# @param String $folder Image&#39;s folder. (optional)
# @return OCRResponse
#
sub GetRecognizeDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetRecognizeDocument");
    }
    

    # parse inputs
    my $_resource_path = '/ocr/{name}/recognize/?appSid={appSid}&amp;language={language}&amp;rectX={rectX}&amp;rectY={rectY}&amp;rectWidth={rectWidth}&amp;rectHeight={rectHeight}&amp;useDefaultDictionaries={useDefaultDictionaries}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'language'}) {        		
		$_resource_path =~ s/\Q{language}\E/$args{'language'}/g;
    }else{
		$_resource_path    =~ s/[?&]language.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rectX'}) {        		
		$_resource_path =~ s/\Q{rectX}\E/$args{'rectX'}/g;
    }else{
		$_resource_path    =~ s/[?&]rectX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rectY'}) {        		
		$_resource_path =~ s/\Q{rectY}\E/$args{'rectY'}/g;
    }else{
		$_resource_path    =~ s/[?&]rectY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rectWidth'}) {        		
		$_resource_path =~ s/\Q{rectWidth}\E/$args{'rectWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]rectWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rectHeight'}) {        		
		$_resource_path =~ s/\Q{rectHeight}\E/$args{'rectHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]rectHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useDefaultDictionaries'}) {        		
		$_resource_path =~ s/\Q{useDefaultDictionaries}\E/$args{'useDefaultDictionaries'}/g;
    }else{
		$_resource_path    =~ s/[?&]useDefaultDictionaries.*?(?=&|\?|$)//g;
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

	if($AsposeOcrCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'OCRResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
