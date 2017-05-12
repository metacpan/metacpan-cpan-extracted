package AsposeImagingCloud::ImagingApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeImagingCloud::ApiClient;
use AsposeImagingCloud::Configuration;

my $VERSION = '1.01';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeImagingCloud::Configuration::api_client ? $AsposeImagingCloud::Configuration::api_client  :
	AsposeImagingCloud::ApiClient->new;
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
# PostImageBmp
#
# Update parameters of bmp image.
# 
# @param String $bitsPerPixel Color depth. (required)
# @param String $horizontalResolution New horizontal resolution. (required)
# @param String $verticalResolution New vertical resolution. (required)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageBmp {
    my ($self, %args) = @_;

    
    # verify the required parameter 'bitsPerPixel' is set
    unless (exists $args{'bitsPerPixel'}) {
      croak("Missing the required parameter 'bitsPerPixel' when calling PostImageBmp");
    }
    
    # verify the required parameter 'horizontalResolution' is set
    unless (exists $args{'horizontalResolution'}) {
      croak("Missing the required parameter 'horizontalResolution' when calling PostImageBmp");
    }
    
    # verify the required parameter 'verticalResolution' is set
    unless (exists $args{'verticalResolution'}) {
      croak("Missing the required parameter 'verticalResolution' when calling PostImageBmp");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageBmp");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/bmp/?appSid={appSid}&amp;bitsPerPixel={bitsPerPixel}&amp;horizontalResolution={horizontalResolution}&amp;verticalResolution={verticalResolution}&amp;fromScratch={fromScratch}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'bitsPerPixel'}) {        		
		$_resource_path =~ s/\Q{bitsPerPixel}\E/$args{'bitsPerPixel'}/g;
    }else{
		$_resource_path    =~ s/[?&]bitsPerPixel.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'horizontalResolution'}) {        		
		$_resource_path =~ s/\Q{horizontalResolution}\E/$args{'horizontalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]horizontalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'verticalResolution'}) {        		
		$_resource_path =~ s/\Q{verticalResolution}\E/$args{'verticalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]verticalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostCropImage
#
# Crop image from body
# 
# @param String $format Output file format. Valid Formats: Bmp, png, jpg, tiff, psd, gif. (required)
# @param String $x X position of start point for cropping rectangle (required)
# @param String $y Y position of start point for cropping rectangle (required)
# @param String $width Width of cropping rectangle (required)
# @param String $height Height of cropping rectangle (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostCropImage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling PostCropImage");
    }
    
    # verify the required parameter 'x' is set
    unless (exists $args{'x'}) {
      croak("Missing the required parameter 'x' when calling PostCropImage");
    }
    
    # verify the required parameter 'y' is set
    unless (exists $args{'y'}) {
      croak("Missing the required parameter 'y' when calling PostCropImage");
    }
    
    # verify the required parameter 'width' is set
    unless (exists $args{'width'}) {
      croak("Missing the required parameter 'width' when calling PostCropImage");
    }
    
    # verify the required parameter 'height' is set
    unless (exists $args{'height'}) {
      croak("Missing the required parameter 'height' when calling PostCropImage");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostCropImage");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/crop/?appSid={appSid}&amp;toFormat={toFormat}&amp;x={x}&amp;y={y}&amp;width={width}&amp;height={height}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'x'}) {        		
		$_resource_path =~ s/\Q{x}\E/$args{'x'}/g;
    }else{
		$_resource_path    =~ s/[?&]x.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'y'}) {        		
		$_resource_path =~ s/\Q{y}\E/$args{'y'}/g;
    }else{
		$_resource_path    =~ s/[?&]y.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImageGif
#
# Update parameters of gif image.
# 
# @param String $backgroundColorIndex Index of the background color. (optional)
# @param array $colorResolution Color resolution. (optional)
# @param array $hasTrailer Specifies if image has trailer. (optional)
# @param Integer $interlaced Specifies if image is interlaced. (optional)
# @param Boolean $isPaletteSorted Specifies if palette is sorted. (optional)
# @param String $pixelAspectRatio Pixel aspect ratio. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageGif {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageBmp");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/gif/?appSid={appSid}&amp;backgroundColorIndex={backgroundColorIndex}&amp;colorResolution={colorResolution}&amp;hasTrailer={hasTrailer}&amp;interlaced={interlaced}&amp;isPaletteSorted={isPaletteSorted}&amp;pixelAspectRatio={pixelAspectRatio}&amp;fromScratch={fromScratch}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'backgroundColorIndex'}) {        		
		$_resource_path =~ s/\Q{backgroundColorIndex}\E/$args{'backgroundColorIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]backgroundColorIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'colorResolution'}) {        		
		$_resource_path =~ s/\Q{colorResolution}\E/$args{'colorResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]colorResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'hasTrailer'}) {        		
		$_resource_path =~ s/\Q{hasTrailer}\E/$args{'hasTrailer'}/g;
    }else{
		$_resource_path    =~ s/[?&]hasTrailer.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'interlaced'}) {        		
		$_resource_path =~ s/\Q{interlaced}\E/$args{'interlaced'}/g;
    }else{
		$_resource_path    =~ s/[?&]interlaced.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isPaletteSorted'}) {        		
		$_resource_path =~ s/\Q{isPaletteSorted}\E/$args{'isPaletteSorted'}/g;
    }else{
		$_resource_path    =~ s/[?&]isPaletteSorted.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pixelAspectRatio'}) {        		
		$_resource_path =~ s/\Q{pixelAspectRatio}\E/$args{'pixelAspectRatio'}/g;
    }else{
		$_resource_path    =~ s/[?&]pixelAspectRatio.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImageJpg
#
# Update parameters of jpg image.
# 
# @param String $quality Quality of image. From 0 to 100. Default is 75 (optional)
# @param String $compressionType Compression type. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageJpg {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageJpg");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/jpg/?appSid={appSid}&amp;quality={quality}&amp;compressionType={compressionType}&amp;fromScratch={fromScratch}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'quality'}) {        		
		$_resource_path =~ s/\Q{quality}\E/$args{'quality'}/g;
    }else{
		$_resource_path    =~ s/[?&]quality.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'compressionType'}) {        		
		$_resource_path =~ s/\Q{compressionType}\E/$args{'compressionType'}/g;
    }else{
		$_resource_path    =~ s/[?&]compressionType.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImagePng
#
# Update parameters of png image.
# 
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImagePng {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImagePng");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/png/?appSid={appSid}&amp;fromScratch={fromScratch}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImagePsd
#
# Update parameters of psd image.
# 
# @param Integer $channelsCount Count of channels. (optional)
# @param String $compressionMethod Compression method. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImagePsd {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImagePsd");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/psd/?appSid={appSid}&amp;channelsCount={channelsCount}&amp;compressionMethod={compressionMethod}&amp;fromScratch={fromScratch}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'channelsCount'}) {        		
		$_resource_path =~ s/\Q{channelsCount}\E/$args{'channelsCount'}/g;
    }else{
		$_resource_path    =~ s/[?&]channelsCount.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'compressionMethod'}) {        		
		$_resource_path =~ s/\Q{compressionMethod}\E/$args{'compressionMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]compressionMethod.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostChangeImageScale
#
# Change scale of an image from body
# 
# @param String $format Output file format. Valid Formats: Bmp, png, jpg, tiff, psd, gif. (required)
# @param String $newWidth New width of the scaled image. (required)
# @param String $newHeight New height of the scaled image. (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostChangeImageScale {
    my ($self, %args) = @_;

    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling PostChangeImageScale");
    }
    
    # verify the required parameter 'newWidth' is set
    unless (exists $args{'newWidth'}) {
      croak("Missing the required parameter 'newWidth' when calling PostChangeImageScale");
    }
    
    # verify the required parameter 'newHeight' is set
    unless (exists $args{'newHeight'}) {
      croak("Missing the required parameter 'newHeight' when calling PostChangeImageScale");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostChangeImageScale");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/resize/?appSid={appSid}&amp;toFormat={toFormat}&amp;newWidth={newWidth}&amp;newHeight={newHeight}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newWidth'}) {        		
		$_resource_path =~ s/\Q{newWidth}\E/$args{'newWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]newWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newHeight'}) {        		
		$_resource_path =~ s/\Q{newHeight}\E/$args{'newHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]newHeight.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImageRotateFlip
#
# Rotate and flip existing image and get it from response.
# 
# @param String $format Number of frame. (Bmp, png, jpg, tiff, psd, gif.) (required)
# @param String $method New width of the scaled image. (Rotate180FlipNone,  Rotate180FlipX, Rotate180FlipXY, Rotate180FlipY, Rotate270FlipNone, Rotate270FlipX, Rotate270FlipXY, Rotate270FlipY, Rotate90FlipNone, Rotate90FlipX, Rotate90FlipXY, Rotate90FlipY, RotateNoneFlipNone, RotateNoneFlipX, RotateNoneFlipXY, RotateNoneFlipY) (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageRotateFlip {
    my ($self, %args) = @_;

    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling PostImageRotateFlip");
    }
    
    # verify the required parameter 'method' is set
    unless (exists $args{'method'}) {
      croak("Missing the required parameter 'method' when calling PostImageRotateFlip");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageRotateFlip");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/rotateflip/?toFormat={toFormat}&amp;appSid={appSid}&amp;method={method}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'method'}) {        		
		$_resource_path =~ s/\Q{method}\E/$args{'method'}/g;
    }else{
		$_resource_path    =~ s/[?&]method.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImageSaveAs
#
# Export existing image to another format. Image is passed as request body.
# 
# @param String $format Output file format. (Bmp, png, jpg, tiff, psd, gif.) (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageSaveAs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageSaveAs");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/saveAs/?appSid={appSid}&amp;toFormat={toFormat}&amp;outPath={outPath}';
    
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostProcessTiff
#
# Update tiff image.
# 
# @param String $compression New compression. (optional)
# @param String $resolutionUnit New resolution unit. (optional)
# @param String $bitDepth New bit depth. (optional)
# @param Boolean $fromScratch  (optional)
# @param String $horizontalResolution New horizontal resolution. (optional)
# @param String $verticalResolution New verstical resolution. (optional)
# @param String $outPath Path to save result (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostProcessTiff {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostProcessTiff");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/tiff/?appSid={appSid}&amp;compression={compression}&amp;resolutionUnit={resolutionUnit}&amp;bitDepth={bitDepth}&amp;fromScratch={fromScratch}&amp;horizontalResolution={horizontalResolution}&amp;verticalResolution={verticalResolution}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'compression'}) {        		
		$_resource_path =~ s/\Q{compression}\E/$args{'compression'}/g;
    }else{
		$_resource_path    =~ s/[?&]compression.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'resolutionUnit'}) {        		
		$_resource_path =~ s/\Q{resolutionUnit}\E/$args{'resolutionUnit'}/g;
    }else{
		$_resource_path    =~ s/[?&]resolutionUnit.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'bitDepth'}) {        		
		$_resource_path =~ s/\Q{bitDepth}\E/$args{'bitDepth'}/g;
    }else{
		$_resource_path    =~ s/[?&]bitDepth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'horizontalResolution'}) {        		
		$_resource_path =~ s/\Q{horizontalResolution}\E/$args{'horizontalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]horizontalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'verticalResolution'}) {        		
		$_resource_path =~ s/\Q{verticalResolution}\E/$args{'verticalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]verticalResolution.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostTiffAppend
#
# Append tiff image.
# 
# @param String $name Original image name. (required)
# @param String $appendFile Second image file name. (optional)
# @param String $storage The images storage. (optional)
# @param String $folder The images folder. (optional)
# @return SaaSposeResponse
#
sub PostTiffAppend {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostTiffAppend");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/tiff/{name}/appendTiff/?appSid={appSid}&amp;appendFile={appendFile}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'appendFile'}) {        		
		$_resource_path =~ s/\Q{appendFile}\E/$args{'appendFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]appendFile.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetTiffToFax
#
# Get tiff image for fax.
# 
# @param String $name The image file name. (required)
# @param String $storage The image file storage. (optional)
# @param String $folder The image file folder. (optional)
# @param String $outPath Path to save result (optional)
# @return ResponseMessage
#
sub GetTiffToFax {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetTiffToFax");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/tiff/{name}/toFax/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImageOperationsSaveAs
#
# Perform scaling, cropping and flipping of an image in single request. Image is passed as request body.
# 
# @param String $format Save image in another format. By default format remains the same (required)
# @param String $newWidth New Width of the scaled image. (required)
# @param String $newHeight New height of the scaled image. (required)
# @param String $x X position of start point for cropping rectangle (required)
# @param String $y Y position of start point for cropping rectangle (required)
# @param String $rectWidth Width of cropping rectangle (required)
# @param String $rectHeight Height of cropping rectangle (required)
# @param String $rotateFlipMethod RotateFlip method. Default is RotateNoneFlipNone. (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostImageOperationsSaveAs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'newWidth' is set
    unless (exists $args{'newWidth'}) {
      croak("Missing the required parameter 'newWidth' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'newHeight' is set
    unless (exists $args{'newHeight'}) {
      croak("Missing the required parameter 'newHeight' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'x' is set
    unless (exists $args{'x'}) {
      croak("Missing the required parameter 'x' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'y' is set
    unless (exists $args{'y'}) {
      croak("Missing the required parameter 'y' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'rectWidth' is set
    unless (exists $args{'rectWidth'}) {
      croak("Missing the required parameter 'rectWidth' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'rectHeight' is set
    unless (exists $args{'rectHeight'}) {
      croak("Missing the required parameter 'rectHeight' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'rotateFlipMethod' is set
    unless (exists $args{'rotateFlipMethod'}) {
      croak("Missing the required parameter 'rotateFlipMethod' when calling PostImageSaveAs");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostImageSaveAs");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/updateImage/?appSid={appSid}&amp;toFormat={toFormat}&amp;newWidth={newWidth}&amp;newHeight={newHeight}&amp;x={x}&amp;y={y}&amp;rectWidth={rectWidth}&amp;rectHeight={rectHeight}&amp;rotateFlipMethod={rotateFlipMethod}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newWidth'}) {        		
		$_resource_path =~ s/\Q{newWidth}\E/$args{'newWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]newWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newHeight'}) {        		
		$_resource_path =~ s/\Q{newHeight}\E/$args{'newHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]newHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'x'}) {        		
		$_resource_path =~ s/\Q{x}\E/$args{'x'}/g;
    }else{
		$_resource_path    =~ s/[?&]x.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'y'}) {        		
		$_resource_path =~ s/\Q{y}\E/$args{'y'}/g;
    }else{
		$_resource_path    =~ s/[?&]y.*?(?=&|\?|$)//g;
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
    if ( exists $args{'rotateFlipMethod'}) {        		
		$_resource_path =~ s/\Q{rotateFlipMethod}\E/$args{'rotateFlipMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotateFlipMethod.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageBmp
#
# Update parameters of bmp image.
# 
# @param String $name Filename of image. (required)
# @param String $bitsPerPixel Color depth. (required)
# @param String $horizontalResolution New horizontal resolution. (required)
# @param String $verticalResolution New vertical resolution. (required)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageBmp {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageBmp");
    }
    
    # verify the required parameter 'bitsPerPixel' is set
    unless (exists $args{'bitsPerPixel'}) {
      croak("Missing the required parameter 'bitsPerPixel' when calling GetImageBmp");
    }
    
    # verify the required parameter 'horizontalResolution' is set
    unless (exists $args{'horizontalResolution'}) {
      croak("Missing the required parameter 'horizontalResolution' when calling GetImageBmp");
    }
    
    # verify the required parameter 'verticalResolution' is set
    unless (exists $args{'verticalResolution'}) {
      croak("Missing the required parameter 'verticalResolution' when calling GetImageBmp");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/bmp/?appSid={appSid}&amp;bitsPerPixel={bitsPerPixel}&amp;horizontalResolution={horizontalResolution}&amp;verticalResolution={verticalResolution}&amp;fromScratch={fromScratch}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'bitsPerPixel'}) {        		
		$_resource_path =~ s/\Q{bitsPerPixel}\E/$args{'bitsPerPixel'}/g;
    }else{
		$_resource_path    =~ s/[?&]bitsPerPixel.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'horizontalResolution'}) {        		
		$_resource_path =~ s/\Q{horizontalResolution}\E/$args{'horizontalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]horizontalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'verticalResolution'}) {        		
		$_resource_path =~ s/\Q{verticalResolution}\E/$args{'verticalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]verticalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetCropImage
#
# Crop existing image
# 
# @param String $name The image name. (required)
# @param String $format Output file format. Valid Formats: Bmp, png, jpg, tiff, psd, gif. (required)
# @param String $x X position of start point for cropping rectangle (required)
# @param String $y Y position of start point for cropping rectangle (required)
# @param String $width Width of cropping rectangle (required)
# @param String $height Height of cropping rectangle (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetCropImage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetCropImage");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetCropImage");
    }
    
    # verify the required parameter 'x' is set
    unless (exists $args{'x'}) {
      croak("Missing the required parameter 'x' when calling GetCropImage");
    }
    
    # verify the required parameter 'y' is set
    unless (exists $args{'y'}) {
      croak("Missing the required parameter 'y' when calling GetCropImage");
    }
    
    # verify the required parameter 'width' is set
    unless (exists $args{'width'}) {
      croak("Missing the required parameter 'width' when calling GetCropImage");
    }
    
    # verify the required parameter 'height' is set
    unless (exists $args{'height'}) {
      croak("Missing the required parameter 'height' when calling GetCropImage");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/crop/?appSid={appSid}&amp;toFormat={toFormat}&amp;x={x}&amp;y={y}&amp;width={width}&amp;height={height}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'x'}) {        		
		$_resource_path =~ s/\Q{x}\E/$args{'x'}/g;
    }else{
		$_resource_path    =~ s/[?&]x.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'y'}) {        		
		$_resource_path =~ s/\Q{y}\E/$args{'y'}/g;
    }else{
		$_resource_path    =~ s/[?&]y.*?(?=&|\?|$)//g;
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
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageFrame
#
# Get separate frame of tiff image
# 
# @param String $name Filename of image. (required)
# @param String $frameId Number of frame. (required)
# @param String $newWidth New width of the scaled image. (optional)
# @param String $newHeight New height of the scaled image. (optional)
# @param String $x X position of start point for cropping rectangle (optional)
# @param String $y Y position of start point for cropping rectangle (optional)
# @param String $rectWidth Width of cropping rectangle (optional)
# @param String $rectHeight Height of cropping rectangle (optional)
# @param String $rotateFlipMethod RotateFlip method.(Rotate180FlipNone, Rotate180FlipX, Rotate180FlipXY, Rotate180FlipY,             Rotate270FlipNone, Rotate270FlipX, Rotate270FlipXY, Rotate270FlipY, Rotate90FlipNone, Rotate90FlipX, Rotate90FlipXY,             Rotate90FlipY, RotateNoneFlipNone, RotateNoneFlipX, RotateNoneFlipXY, RotateNoneFlipY.             Default is RotateNoneFlipNone.) (optional)
# @param Boolean $saveOtherFrames Include all other frames or just specified frame in response. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageFrame {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageFrame");
    }
    
    # verify the required parameter 'frameId' is set
    unless (exists $args{'frameId'}) {
      croak("Missing the required parameter 'frameId' when calling GetImageFrame");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/frames/{frameId}/?appSid={appSid}&amp;newWidth={newWidth}&amp;newHeight={newHeight}&amp;x={x}&amp;y={y}&amp;rectWidth={rectWidth}&amp;rectHeight={rectHeight}&amp;rotateFlipMethod={rotateFlipMethod}&amp;saveOtherFrames={saveOtherFrames}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'frameId'}) {        		
		$_resource_path =~ s/\Q{frameId}\E/$args{'frameId'}/g;
    }else{
		$_resource_path    =~ s/[?&]frameId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newWidth'}) {        		
		$_resource_path =~ s/\Q{newWidth}\E/$args{'newWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]newWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newHeight'}) {        		
		$_resource_path =~ s/\Q{newHeight}\E/$args{'newHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]newHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'x'}) {        		
		$_resource_path =~ s/\Q{x}\E/$args{'x'}/g;
    }else{
		$_resource_path    =~ s/[?&]x.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'y'}) {        		
		$_resource_path =~ s/\Q{y}\E/$args{'y'}/g;
    }else{
		$_resource_path    =~ s/[?&]y.*?(?=&|\?|$)//g;
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
    if ( exists $args{'rotateFlipMethod'}) {        		
		$_resource_path =~ s/\Q{rotateFlipMethod}\E/$args{'rotateFlipMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotateFlipMethod.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'saveOtherFrames'}) {        		
		$_resource_path =~ s/\Q{saveOtherFrames}\E/$args{'saveOtherFrames'}/g;
    }else{
		$_resource_path    =~ s/[?&]saveOtherFrames.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageFrameProperties
#
# Get properties of a tiff frame.
# 
# @param String $name Filename with image. (required)
# @param String $frameId Number of frame. (required)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ImagingResponse
#
sub GetImageFrameProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageFrameProperties");
    }
    
    # verify the required parameter 'frameId' is set
    unless (exists $args{'frameId'}) {
      croak("Missing the required parameter 'frameId' when calling GetImageFrameProperties");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/frames/{frameId}/properties/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'frameId'}) {        		
		$_resource_path =~ s/\Q{frameId}\E/$args{'frameId'}/g;
    }else{
		$_resource_path    =~ s/[?&]frameId.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ImagingResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageGif
#
# Update parameters of bmp image.
# 
# @param String $name Filename of image. (required)
# @param String $backgroundColorIndex Index of the background color. (optional)
# @param String $colorResolution Color resolution. (optional)
# @param Boolean $hasTrailer Specifies if image has trailer. (optional)
# @param Boolean $interlaced Specifies if image is interlaced. (optional)
# @param Boolean $isPaletteSorted Specifies if palette is sorted. (optional)
# @param String $pixelAspectRatio Pixel aspect ratio. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageGif {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageGif");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/gif/?appSid={appSid}&amp;backgroundColorIndex={backgroundColorIndex}&amp;colorResolution={colorResolution}&amp;hasTrailer={hasTrailer}&amp;interlaced={interlaced}&amp;isPaletteSorted={isPaletteSorted}&amp;pixelAspectRatio={pixelAspectRatio}&amp;fromScratch={fromScratch}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'backgroundColorIndex'}) {        		
		$_resource_path =~ s/\Q{backgroundColorIndex}\E/$args{'backgroundColorIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]backgroundColorIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'colorResolution'}) {        		
		$_resource_path =~ s/\Q{colorResolution}\E/$args{'colorResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]colorResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'hasTrailer'}) {        		
		$_resource_path =~ s/\Q{hasTrailer}\E/$args{'hasTrailer'}/g;
    }else{
		$_resource_path    =~ s/[?&]hasTrailer.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'interlaced'}) {        		
		$_resource_path =~ s/\Q{interlaced}\E/$args{'interlaced'}/g;
    }else{
		$_resource_path    =~ s/[?&]interlaced.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isPaletteSorted'}) {        		
		$_resource_path =~ s/\Q{isPaletteSorted}\E/$args{'isPaletteSorted'}/g;
    }else{
		$_resource_path    =~ s/[?&]isPaletteSorted.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pixelAspectRatio'}) {        		
		$_resource_path =~ s/\Q{pixelAspectRatio}\E/$args{'pixelAspectRatio'}/g;
    }else{
		$_resource_path    =~ s/[?&]pixelAspectRatio.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageJpg
#
# Update parameters of jpg image.
# 
# @param String $name Filename of image. (required)
# @param String $quality Quality of image. From 0 to 100. Default is 75 (optional)
# @param String $compressionType Compression type. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageJpg {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageJpg");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/jpg/?appSid={appSid}&amp;quality={quality}&amp;compressionType={compressionType}&amp;fromScratch={fromScratch}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'quality'}) {        		
		$_resource_path =~ s/\Q{quality}\E/$args{'quality'}/g;
    }else{
		$_resource_path    =~ s/[?&]quality.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'compressionType'}) {        		
		$_resource_path =~ s/\Q{compressionType}\E/$args{'compressionType'}/g;
    }else{
		$_resource_path    =~ s/[?&]compressionType.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImagePng
#
# Update parameters of png image.
# 
# @param String $name Filename of image. (required)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImagePng {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImagePng");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/png/?appSid={appSid}&amp;fromScratch={fromScratch}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageProperties
#
# Get properties of an image.
# 
# @param String $name The image name. (required)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ImagingResponse
#
sub GetImageProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageProperties");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/properties/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ImagingResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImagePsd
#
# Update parameters of psd image.
# 
# @param String $name Filename of image. (required)
# @param Integer $channelsCount Count of channels. (optional)
# @param String $compressionMethod Compression method. (optional)
# @param Boolean $fromScratch Specifies where additional parameters we do not support should be taken from. If this is true â€“ they will be taken from default values for standard image, if it is false â€“ they will be saved from current image. Default is false. (optional)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImagePsd {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImagePsd");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/psd/?appSid={appSid}&amp;channelsCount={channelsCount}&amp;compressionMethod={compressionMethod}&amp;fromScratch={fromScratch}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'channelsCount'}) {        		
		$_resource_path =~ s/\Q{channelsCount}\E/$args{'channelsCount'}/g;
    }else{
		$_resource_path    =~ s/[?&]channelsCount.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'compressionMethod'}) {        		
		$_resource_path =~ s/\Q{compressionMethod}\E/$args{'compressionMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]compressionMethod.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'fromScratch'}) {        		
		$_resource_path =~ s/\Q{fromScratch}\E/$args{'fromScratch'}/g;
    }else{
		$_resource_path    =~ s/[?&]fromScratch.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetChangeImageScale
#
# Change scale of an existing image
# 
# @param String $name The image name. (required)
# @param String $format Output file format. Valid Formats: Bmp, png, jpg, tiff, psd, gif. (required)
# @param String $newWidth New width of the scaled image. (required)
# @param String $newHeight New height of the scaled image. (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetChangeImageScale {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetChangeImageScale");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetChangeImageScale");
    }
    
    # verify the required parameter 'newWidth' is set
    unless (exists $args{'newWidth'}) {
      croak("Missing the required parameter 'newWidth' when calling GetChangeImageScale");
    }
    
    # verify the required parameter 'newHeight' is set
    unless (exists $args{'newHeight'}) {
      croak("Missing the required parameter 'newHeight' when calling GetChangeImageScale");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/resize/?appSid={appSid}&amp;toFormat={toFormat}&amp;newWidth={newWidth}&amp;newHeight={newHeight}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'newWidth'}) {        		
		$_resource_path =~ s/\Q{newWidth}\E/$args{'newWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]newWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newHeight'}) {        		
		$_resource_path =~ s/\Q{newHeight}\E/$args{'newHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]newHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageRotateFlip
#
# Rotate and flip existing image
# 
# @param String $name Filename of image. (required)
# @param String $format Number of frame. (Bmp, png, jpg, tiff, psd, gif.) (required)
# @param String $method New width of the scaled image. (Rotate180FlipNone,  Rotate180FlipX, Rotate180FlipXY, Rotate180FlipY, Rotate270FlipNone, Rotate270FlipX, Rotate270FlipXY, Rotate270FlipY, Rotate90FlipNone, Rotate90FlipX, Rotate90FlipXY, Rotate90FlipY, RotateNoneFlipNone, RotateNoneFlipX, RotateNoneFlipXY, RotateNoneFlipY) (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageRotateFlip {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageRotateFlip");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetImageRotateFlip");
    }
    
    # verify the required parameter 'method' is set
    unless (exists $args{'method'}) {
      croak("Missing the required parameter 'method' when calling GetImageRotateFlip");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/rotateflip/?toFormat={toFormat}&amp;appSid={appSid}&amp;method={method}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'method'}) {        		
		$_resource_path =~ s/\Q{method}\E/$args{'method'}/g;
    }else{
		$_resource_path    =~ s/[?&]method.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetImageSaveAs
#
# Export existing image to another format
# 
# @param String $name Filename of image. (required)
# @param String $format Output file format. (Bmp, png, jpg, tiff, psd, gif.) (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetImageSaveAs {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetImageSaveAs");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetImageSaveAs");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/saveAs/?appSid={appSid}&amp;toFormat={toFormat}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetUpdatedImage
#
# Perform scaling, cropping and flipping of an image in single request.
# 
# @param String $name Filename of image. (required)
# @param String $format Save image in another format. By default format remains the same (required)
# @param String $newWidth New Width of the scaled image. (required)
# @param String $newHeight New height of the scaled image. (required)
# @param String $x X position of start point for cropping rectangle (required)
# @param String $y Y position of start point for cropping rectangle (required)
# @param String $rectWidth Width of cropping rectangle (required)
# @param String $rectHeight Height of cropping rectangle (required)
# @param String $rotateFlipMethod RotateFlip method. Default is RotateNoneFlipNone. (required)
# @param String $outPath Path to updated file, if this is empty, response contains streamed image. (optional)
# @param String $folder Folder with image to process. (optional)
# @param String $storage  (optional)
# @return ResponseMessage
#
sub GetUpdatedImage {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'newWidth' is set
    unless (exists $args{'newWidth'}) {
      croak("Missing the required parameter 'newWidth' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'newHeight' is set
    unless (exists $args{'newHeight'}) {
      croak("Missing the required parameter 'newHeight' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'x' is set
    unless (exists $args{'x'}) {
      croak("Missing the required parameter 'x' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'y' is set
    unless (exists $args{'y'}) {
      croak("Missing the required parameter 'y' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'rectWidth' is set
    unless (exists $args{'rectWidth'}) {
      croak("Missing the required parameter 'rectWidth' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'rectHeight' is set
    unless (exists $args{'rectHeight'}) {
      croak("Missing the required parameter 'rectHeight' when calling GetUpdatedImage");
    }
    
    # verify the required parameter 'rotateFlipMethod' is set
    unless (exists $args{'rotateFlipMethod'}) {
      croak("Missing the required parameter 'rotateFlipMethod' when calling GetUpdatedImage");
    }
    

    # parse inputs
    my $_resource_path = '/imaging/{name}/updateImage/?appSid={appSid}&amp;toFormat={toFormat}&amp;newWidth={newWidth}&amp;newHeight={newHeight}&amp;x={x}&amp;y={y}&amp;rectWidth={rectWidth}&amp;rectHeight={rectHeight}&amp;rotateFlipMethod={rotateFlipMethod}&amp;outPath={outPath}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'newWidth'}) {        		
		$_resource_path =~ s/\Q{newWidth}\E/$args{'newWidth'}/g;
    }else{
		$_resource_path    =~ s/[?&]newWidth.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newHeight'}) {        		
		$_resource_path =~ s/\Q{newHeight}\E/$args{'newHeight'}/g;
    }else{
		$_resource_path    =~ s/[?&]newHeight.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'x'}) {        		
		$_resource_path =~ s/\Q{x}\E/$args{'x'}/g;
    }else{
		$_resource_path    =~ s/[?&]x.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'y'}) {        		
		$_resource_path =~ s/\Q{y}\E/$args{'y'}/g;
    }else{
		$_resource_path    =~ s/[?&]y.*?(?=&|\?|$)//g;
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
    if ( exists $args{'rotateFlipMethod'}) {        		
		$_resource_path =~ s/\Q{rotateFlipMethod}\E/$args{'rotateFlipMethod'}/g;
    }else{
		$_resource_path    =~ s/[?&]rotateFlipMethod.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'outPath'}) {        		
		$_resource_path =~ s/\Q{outPath}\E/$args{'outPath'}/g;
    }else{
		$_resource_path    =~ s/[?&]outPath.*?(?=&|\?|$)//g;
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

	if($AsposeImagingCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}


1;
