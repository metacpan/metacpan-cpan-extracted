package AsposeBarCodeCloud::BarcodeApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;
use URI::Escape;

use AsposeBarCodeCloud::ApiClient;
use AsposeBarCodeCloud::Configuration;

# my $VERSION = '1.0.3';
our $VERSION = '1.0.3';
sub new {
    my $class   = shift;
    my $default_api_client = $AsposeBarCodeCloud::Configuration::api_client ? $AsposeBarCodeCloud::Configuration::api_client  :
	AsposeBarCodeCloud::ApiClient->new;
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
# GetBarcodeGenerate
#
# Generate barcode.
# 
# @param String $text The code text. (optional)
# @param String $type Barcode type. (optional)
# @param String $format Result format. (optional)
# @param String $resolutionX Horizontal resolution. (optional)
# @param String $resolutionY Vertical resolution. (optional)
# @param String $dimensionX Smallest width of barcode unit (bar or space). (optional)
# @param String $dimensionY Smallest height of barcode unit (for 2D barcodes). (optional)
# @param String $enableChecksum Sets if checksum will be generated. (optional)
# @return ResponseMessage
#
sub GetBarcodeGenerate {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/barcode/generate/?appSid={appSid}&amp;text={text}&amp;type={type}&amp;toFormat={toFormat}&amp;resolutionX={resolutionX}&amp;resolutionY={resolutionY}&amp;dimensionX={dimensionX}&amp;dimensionY={dimensionY}&amp;enableChecksum={enableChecksum}';
    
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
    if ( exists $args{'text'}) {       
    	my $escapedText = uri_escape( $args{'text'} );        		
		$_resource_path =~ s/\Q{text}\E/$escapedText/g;
    }else{
		$_resource_path    =~ s/[?&]text.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolutionX'}) {        		
		$_resource_path =~ s/\Q{resolutionX}\E/$args{'resolutionX'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolutionX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolutionY'}) {        		
		$_resource_path =~ s/\Q{resolutionY}\E/$args{'resolutionY'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolutionY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dimensionX'}) {        		
		$_resource_path =~ s/\Q{dimensionX}\E/$args{'dimensionX'}/g;
    }else{
		$_resource_path    =~ s/[?&]dimensionX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dimensionY'}) {        		
		$_resource_path =~ s/\Q{dimensionY}\E/$args{'dimensionY'}/g;
    }else{
		$_resource_path    =~ s/[?&]dimensionY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'enableChecksum'}) {        		
		$_resource_path =~ s/\Q{enableChecksum}\E/$args{'enableChecksum'}/g;
    }else{
		$_resource_path    =~ s/[?&]enableChecksum.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostGenerateMultiple
#
# Generate multiple barcodes and return in response stream
# 
# @param String $format Format to return stream in (optional)
# @param BarcodeBuildersList $body  (required)
# @return ResponseMessage
#
sub PostGenerateMultiple {
    my ($self, %args) = @_;

    
   # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutSlidesSetDocumentProperty");
    }
    
    # parse inputs
    my $_resource_path = '/barcode/generateMultiple/?appSid={appSid}&amp;toFormat={toFormat}';
    
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
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostBarcodeRecognizeFromUrlorContent
#
# Recognize barcode from an url.
# 
# @param String $type Barcode type. (optional)
# @param String $checksumValidation Checksum validation parameter. (optional)
# @param Boolean $stripFnc Allows to strip FNC symbol in recognition results. (optional)
# @param String $rotationAngle Recognition of rotated barcode. Possible angles are 90, 180, 270, default is 0 (optional)
# @param String $url The image file url. (optional)
# @param File $file  (required)
# @return BarcodeResponseList
#
sub PostBarcodeRecognizeFromUrlorContent {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    #unless (exists $args{'file'}) {
     # croak("Missing the required parameter 'file' when calling PostBarcodeRecognizeFromUrlorContent");
    #}
    

    # parse inputs
    my $_resource_path = '/barcode/recognize/?appSid={appSid}&amp;type={type}&amp;checksumValidation={checksumValidation}&amp;stripFnc={stripFnc}&amp;rotationAngle={rotationAngle}&amp;url={url}';
    
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
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'checksumValidation'}) {        		
		$_resource_path =~ s/\Q{checksumValidation}\E/$args{'checksumValidation'}/g;
    }else{
		$_resource_path    =~ s/[?&]checksumValidation.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'stripFnc'}) {        		
		$_resource_path =~ s/\Q{stripFnc}\E/$args{'stripFnc'}/g;
    }else{
		$_resource_path    =~ s/[?&]stripFnc.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'url'}) {        		
		$_resource_path =~ s/\Q{url}\E/$args{'url'}/g;
    }else{
		$_resource_path    =~ s/[?&]url.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BarcodeResponseList', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostBarcodeRecognizeFromRequestBody
#
# Recognize barcode from request body.
# 
# @param String $type Barcode type (required). 
# @param String $checksumValidation Checksum validation parameter. (optional)
# @param Boolean $stripFnc Allows to strip FNC symbol in recognition results. (optional)
# @param String $rotationAngle Recognition of rotated barcode. Possible angles are 90, 180, 270, default is 0 (optional)
# @param String $body (required)
# @return BarcodeResponseList
#
sub PostBarcodeRecognizeFromRequestBody{
    my ($self, %args) = @_;

    
    # verify the required parameter 'type' is set
    unless (exists $args{'type'}) {
      croak("Missing the required parameter 'type' when calling PostBarcodeRecognizeFromRequestBody");
    }

   unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostBarcodeRecognizeFromRequestBody");
    }
    

    # parse inputs
    my $_resource_path = '/barcode/recognize/?appSid={appSid}&amp;type={type}&amp;checksumValidation={checksumValidation}&amp;stripFnc={stripFnc}&amp;rotationAngle={rotationAngle}';
    
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
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'checksumValidation'}) {        		
		$_resource_path =~ s/\Q{checksumValidation}\E/$args{'checksumValidation'}/g;
    }else{
		$_resource_path    =~ s/[?&]checksumValidation.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'stripFnc'}) {        		
		$_resource_path =~ s/\Q{stripFnc}\E/$args{'stripFnc'}/g;
    }else{
		$_resource_path    =~ s/[?&]stripFnc.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BarcodeResponseList', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutBarcodeGenerateFile
#
# Generate barcode and save on server.
# 
# @param String $name The image name. (required)
# @param String $text Barcode&#39;s text. (optional)
# @param String $type The barcode type. (optional)
# @param String $format The image format. (optional)
# @param String $resolutionX Horizontal resolution. (optional)
# @param String $resolutionY Vertical resolution. (optional)
# @param String $dimensionX Smallest width of barcode unit (bar or space). (optional)
# @param String $dimensionY Smallest height of barcode unit (for 2D barcodes). (optional)
# @param String $codeLocation property of the barcode. (optional)
# @param String $grUnit Measurement of barcode properties. (optional)
# @param String $autoSize Sets if barcode size will be updated automatically. (optional)
# @param String $barHeight Height of the bar. (optional)
# @param String $imageHeight Height of the image. (optional)
# @param String $imageWidth Width of the image. (optional)
# @param String $imageQuality Detepmines  of the barcode image. (optional)
# @param String $rotAngle Angle of barcode orientation. (optional)
# @param String $topMargin Top margin. (optional)
# @param String $bottomMargin Bottom margin. (optional)
# @param String $leftMargin Left margin. (optional)
# @param String $rightMargin Right margin. (optional)
# @param String $enableChecksum Sets if checksum will be generated. (optional)
# @param String $storage Image&#39;s storage. (optional)
# @param String $folder Image&#39;s folder. (optional)
# @param File $file  (required)
# @return SaaSposeResponse
#
sub PutBarcodeGenerateFile {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutBarcodeGenerateFile");
    }
    
    # verify the required parameter 'file' is set
    #unless (exists $args{'file'}) {
     # croak("Missing the required parameter 'file' when calling PutBarcodeGenerateFile");
    #}
    

    # parse inputs
    my $_resource_path = '/barcode/{name}/generate/?appSid={appSid}&amp;text={text}&amp;type={type}&amp;toFormat={toFormat}&amp;resolutionX={resolutionX}&amp;resolutionY={resolutionY}&amp;dimensionX={dimensionX}&amp;dimensionY={dimensionY}&amp;codeLocation={codeLocation}&amp;grUnit={grUnit}&amp;autoSize={autoSize}&amp;barHeight={barHeight}&amp;imageHeight={imageHeight}&amp;imageWidth={imageWidth}&amp;imageQuality={imageQuality}&amp;rotAngle={rotAngle}&amp;topMargin={topMargin}&amp;bottomMargin={bottomMargin}&amp;leftMargin={leftMargin}&amp;rightMargin={rightMargin}&amp;enableChecksum={enableChecksum}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'text'}) {
    	my $escapedText = uri_escape( $args{'text'} );        		
		$_resource_path =~ s/\Q{text}\E/$escapedText/g;
    }else{
		$_resource_path    =~ s/[?&]text.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolutionX'}) {        		
		$_resource_path =~ s/\Q{resolutionX}\E/$args{'resolutionX'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolutionX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolutionY'}) {        		
		$_resource_path =~ s/\Q{resolutionY}\E/$args{'resolutionY'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolutionY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dimensionX'}) {        		
		$_resource_path =~ s/\Q{dimensionX}\E/$args{'dimensionX'}/g;
    }else{
		$_resource_path    =~ s/[?&]dimensionX.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dimensionY'}) {        		
		$_resource_path =~ s/\Q{dimensionY}\E/$args{'dimensionY'}/g;
    }else{
		$_resource_path    =~ s/[?&]dimensionY.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'codeLocation'}) {        		
		$_resource_path =~ s/\Q{codeLocation}\E/$args{'codeLocation'}/g;
    }else{
		$_resource_path    =~ s/[?&]codeLocation.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'grUnit'}) {        		
		$_resource_path =~ s/\Q{grUnit}\E/$args{'grUnit'}/g;
    }else{
		$_resource_path    =~ s/[?&]grUnit.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'autoSize'}) {        		
		$_resource_path =~ s/\Q{autoSize}\E/$args{'autoSize'}/g;
    }else{
		$_resource_path    =~ s/[?&]autoSize.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'barHeight'}) {        		
		$_resource_path =~ s/\Q{barHeight}\E/$args{'barHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]barHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageHeight'}) {        		
		$_resource_path =~ s/\Q{imageHeight}\E/$args{'imageHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageWidth'}) {        		
		$_resource_path =~ s/\Q{imageWidth}\E/$args{'imageWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageQuality'}) {        		
		$_resource_path =~ s/\Q{imageQuality}\E/$args{'imageQuality'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageQuality.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotAngle'}) {        		
		$_resource_path =~ s/\Q{rotAngle}\E/$args{'rotAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'topMargin'}) {        		
		$_resource_path =~ s/\Q{topMargin}\E/$args{'topMargin'}/g;
    }else{
		$_resource_path    =~ s/[?&]topMargin.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'bottomMargin'}) {        		
		$_resource_path =~ s/\Q{bottomMargin}\E/$args{'bottomMargin'}/g;
    }else{
		$_resource_path    =~ s/[?&]bottomMargin.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'leftMargin'}) {        		
		$_resource_path =~ s/\Q{leftMargin}\E/$args{'leftMargin'}/g;
    }else{
		$_resource_path    =~ s/[?&]leftMargin.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rightMargin'}) {        		
		$_resource_path =~ s/\Q{rightMargin}\E/$args{'rightMargin'}/g;
    }else{
		$_resource_path    =~ s/[?&]rightMargin.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'enableChecksum'}) {        		
		$_resource_path =~ s/\Q{enableChecksum}\E/$args{'enableChecksum'}/g;
    }else{
		$_resource_path    =~ s/[?&]enableChecksum.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutGenerateMultiple
#
# Generate image with multiple barcodes and put new file on server
# 
# @param String $name New filename (required)
# @param String $format Format of file (optional)
# @param String $folder Folder to place file to (optional)
# @param File $file  (required)
# @return SaaSposeResponse
#
sub PutGenerateMultiple {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutGenerateMultiple");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutGenerateMultiple");
    }
    

    # parse inputs
    my $_resource_path = '/barcode/{name}/generateMultiple/?appSid={appSid}&amp;toFormat={toFormat}&amp;folder={folder}';
    
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
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetBarcodeRecognize
#
# Recognize barcode from a file on server.
# 
# @param String $name The image name. (required)
# @param String $type The barcode type. (optional)
# @param String $checksumValidation Checksum validation parameter. (optional)
# @param Boolean $stripFnc Allows to strip FNC symbol in recognition results. (optional)
# @param String $rotationAngle Allows to correct angle of barcode. (optional)
# @param String $barcodesCount Count of barcodes to recognize. (optional)
# @param String $rectX Top left point X coordinate of  to recognize barcode inside. (optional)
# @param String $rectY Top left point Y coordinate of  to recognize barcode inside. (optional)
# @param String $rectWidth Width of  to recognize barcode inside. (optional)
# @param String $rectHeight Height of  to recognize barcode inside. (optional)
# @param String $storage The image storage. (optional)
# @param String $folder The image folder. (optional)
# @return BarcodeResponseList
#
sub GetBarcodeRecognize {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetBarcodeRecognize");
    }
    

    # parse inputs
    my $_resource_path = '/barcode/{name}/recognize/?appSid={appSid}&amp;type={type}&amp;checksumValidation={checksumValidation}&amp;stripFnc={stripFnc}&amp;rotationAngle={rotationAngle}&amp;barcodesCount={barcodesCount}&amp;rectX={rectX}&amp;rectY={rectY}&amp;rectWidth={rectWidth}&amp;rectHeight={rectHeight}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'checksumValidation'}) {        		
		$_resource_path =~ s/\Q{checksumValidation}\E/$args{'checksumValidation'}/g;
    }else{
		$_resource_path    =~ s/[?&]checksumValidation.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'stripFnc'}) {        		
		$_resource_path =~ s/\Q{stripFnc}\E/$args{'stripFnc'}/g;
    }else{
		$_resource_path    =~ s/[?&]stripFnc.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rotationAngle'}) {        		
		$_resource_path =~ s/\Q{rotationAngle}\E/$args{'rotationAngle'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotationAngle.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'barcodesCount'}) {        		
		$_resource_path =~ s/\Q{barcodesCount}\E/$args{'barcodesCount'}/g;
    }else{
		$_resource_path    =~ s/[?&]barcodesCount.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BarcodeResponseList', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutBarcodeRecognizeFromBody
#
# Recognition of a barcode from file on server with parameters in body.
# 
# @param String $name The image name. (required)
# @param String $type The barcode type. (optional)
# @param String $folder The image folder. (optional)
# @param BarcodeReader $body BarcodeReader object with parameters. (required)
# @return BarcodeResponseList
#
sub PutBarcodeRecognizeFromBody {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutBarcodeRecognizeFromBody");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutBarcodeRecognizeFromBody");
    }
    

    # parse inputs
    my $_resource_path = '/barcode/{name}/recognize/?appSid={appSid}&amp;type={type}&amp;folder={folder}';
    
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
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
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

	if($AsposeBarCodeCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BarcodeResponseList', $response->header('content-type'));
    return $_response_object;
    
}


1;
