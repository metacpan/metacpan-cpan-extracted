
package AsposeCellsCloud::CellsApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeCellsCloud::ApiClient;
use AsposeCellsCloud::Configuration;

my $VERSION = '1.01';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeCellsCloud::Configuration::api_client ? $AsposeCellsCloud::Configuration::api_client  :
	AsposeCellsCloud::ApiClient->new;
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
# PutConvertWorkBook
#
# 
# 
# @param String $format  (optional)
# @param String $password  (optional)
# @param String $outPath  (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PutConvertWorkBook {
    my ($self, %args) = @_;

    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutConvertWorkBook");
    }
    

    # parse inputs
    my $_resource_path = '/cells/convert/?appSid={appSid}&amp;toFormat={toFormat}&amp;password={password}&amp;outPath={outPath}';
    
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
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBook
#
# 
# 
# @param String $name  (required)
# @param String $password  (optional)
# @param Boolean $isAutoFit  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorkBook {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBook");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/?appSid={appSid}&amp;password={password}&amp;isAutoFit={isAutoFit}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'isAutoFit'}) {        		
		$_resource_path =~ s/\Q{isAutoFit}\E/$args{'isAutoFit'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAutoFit.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorkbookResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorkbookCreate
#
# 
# 
# @param String $name  (required)
# @param String $templateFile  (optional)
# @param String $dataFile  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (optional)
# @return WorkbookResponse
#
sub PutWorkbookCreate {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorkbookCreate");
    }
    
    # parse inputs
    my $_resource_path = '/cells/{name}/?appSid={appSid}&amp;templateFile={templateFile}&amp;dataFile={dataFile}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'templateFile'}) {        		
		$_resource_path =~ s/\Q{templateFile}\E/$args{'templateFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]templateFile.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dataFile'}) {        		
		$_resource_path =~ s/\Q{dataFile}\E/$args{'dataFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]dataFile.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorkbookResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBookWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $format  (required)
# @param String $password  (optional)
# @param Boolean $isAutoFit  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @return ResponseMessage
#
sub GetWorkBookWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBookWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorkBookWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/?appSid={appSid}&amp;toFormat={toFormat}&amp;password={password}&amp;isAutoFit={isAutoFit}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    if ( exists $args{'password'}) {        		
		$_resource_path =~ s/\Q{password}\E/$args{'password'}/g;
    }else{
		$_resource_path    =~ s/[?&]password.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isAutoFit'}) {        		
		$_resource_path =~ s/\Q{isAutoFit}\E/$args{'isAutoFit'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAutoFit.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
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
# @param String $newfilename  (optional)
# @param Boolean $isAutoFitRows  (optional)
# @param Boolean $isAutoFitColumns  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param SaveOptions $body  (required)
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
    my $_resource_path = '/cells/{name}/SaveAs/?appSid={appSid}&amp;newfilename={newfilename}&amp;isAutoFitRows={isAutoFitRows}&amp;isAutoFitColumns={isAutoFitColumns}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'newfilename'}) {        		
		$_resource_path =~ s/\Q{newfilename}\E/$args{'newfilename'}/g;
    }else{
		$_resource_path    =~ s/[?&]newfilename.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isAutoFitRows'}) {        		
		$_resource_path =~ s/\Q{isAutoFitRows}\E/$args{'isAutoFitRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAutoFitRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isAutoFitColumns'}) {        		
		$_resource_path =~ s/\Q{isAutoFitColumns}\E/$args{'isAutoFitColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAutoFitColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaveResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAutofitWorkbookRows
#
# 
# 
# @param String $name  (required)
# @param String $startRow  (optional)
# @param String $endRow  (optional)
# @param Boolean $onlyAuto  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param AutoFitterOptions $body  (required)
# @return SaaSposeResponse
#
sub PostAutofitWorkbookRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAutofitWorkbookRows");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostAutofitWorkbookRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/autofitrows/?appSid={appSid}&amp;startRow={startRow}&amp;endRow={endRow}&amp;onlyAuto={onlyAuto}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endRow'}) {        		
		$_resource_path =~ s/\Q{endRow}\E/$args{'endRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]endRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'onlyAuto'}) {        		
		$_resource_path =~ s/\Q{onlyAuto}\E/$args{'onlyAuto'}/g;
    }else{
		$_resource_path    =~ s/[?&]onlyAuto.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbookCalculateFormula
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostWorkbookCalculateFormula {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbookCalculateFormula");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/calculateformula/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
	
    
    

    # authentication setting, if any
    my $auth_settings = [];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBookDefaultStyle
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return StyleResponse
#
sub GetWorkBookDefaultStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBookDefaultStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/defaultstyle/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'StyleResponse', $response->header('content-type'));
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
# @return CellsDocumentPropertiesResponse
#
sub GetDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/documentproperties/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsDocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentProperties
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CellsDocumentPropertiesResponse
#
sub DeleteDocumentProperties {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentProperties");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/documentproperties/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsDocumentPropertiesResponse', $response->header('content-type'));
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
# @return CellsDocumentPropertyResponse
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
    my $_resource_path = '/cells/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsDocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param CellsDocumentProperty $body  (required)
# @return CellsDocumentPropertyResponse
#
sub PutDocumentProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutDocumentProperty");
    }
    
    # verify the required parameter 'propertyName' is set
    unless (exists $args{'propertyName'}) {
      croak("Missing the required parameter 'propertyName' when calling PutDocumentProperty");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutDocumentProperty");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsDocumentPropertyResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentProperty
#
# 
# 
# @param String $name  (required)
# @param String $propertyName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CellsDocumentPropertiesResponse
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
    my $_resource_path = '/cells/{name}/documentproperties/{propertyName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsDocumentPropertiesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostEncryptDocument
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorkbookEncryptionRequest $body  (required)
# @return SaaSposeResponse
#
sub PostEncryptDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostEncryptDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostEncryptDocument");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/encryption/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDecryptDocument
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorkbookEncryptionRequest $body  (required)
# @return SaaSposeResponse
#
sub DeleteDecryptDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDecryptDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling DeleteDecryptDocument");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/encryption/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbooksTextSearch
#
# 
# 
# @param String $name  (required)
# @param String $text  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return TextItemsResponse
#
sub PostWorkbooksTextSearch {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbooksTextSearch");
    }
    
    # verify the required parameter 'text' is set
    unless (exists $args{'text'}) {
      croak("Missing the required parameter 'text' when calling PostWorkbooksTextSearch");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/findText/?text={text}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostImportData
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ImportOption $body  (required)
# @return SaaSposeResponse
#
sub PostImportData {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostImportData");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostImportData");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/importdata/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbooksMerge
#
# 
# 
# @param String $name  (required)
# @param String $mergeWith  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorkbookResponse
#
sub PostWorkbooksMerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbooksMerge");
    }
    
    # verify the required parameter 'mergeWith' is set
    unless (exists $args{'mergeWith'}) {
      croak("Missing the required parameter 'mergeWith' when calling PostWorkbooksMerge");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/merge/?mergeWith={mergeWith}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'mergeWith'}) {        		
		$_resource_path =~ s/\Q{mergeWith}\E/$args{'mergeWith'}/g;
    }else{
		$_resource_path    =~ s/[?&]mergeWith.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorkbookResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBookNames
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return NamesResponse
#
sub GetWorkBookNames {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBookNames");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/names/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'NamesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBookName
#
# 
# 
# @param String $name  (required)
# @param String $nameName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return NameResponse
#
sub GetWorkBookName {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBookName");
    }
    
    # verify the required parameter 'nameName' is set
    unless (exists $args{'nameName'}) {
      croak("Missing the required parameter 'nameName' when calling GetWorkBookName");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/names/{nameName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'nameName'}) {        		
		$_resource_path =~ s/\Q{nameName}\E/$args{'nameName'}/g;
    }else{
		$_resource_path    =~ s/[?&]nameName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'NameResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostProtectDocument
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorkbookProtectionRequest $body  (required)
# @return SaaSposeResponse
#
sub PostProtectDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostProtectDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostProtectDocument");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/protection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteUnProtectDocument
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorkbookProtectionRequest $body  (required)
# @return SaaSposeResponse
#
sub DeleteUnProtectDocument {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteUnProtectDocument");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling DeleteUnProtectDocument");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/protection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbooksTextReplace
#
# 
# 
# @param String $name  (required)
# @param String $oldValue  (required)
# @param String $newValue  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorkbookReplaceResponse
#
sub PostWorkbooksTextReplace {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbooksTextReplace");
    }
    
    # verify the required parameter 'oldValue' is set
    unless (exists $args{'oldValue'}) {
      croak("Missing the required parameter 'oldValue' when calling PostWorkbooksTextReplace");
    }
    
    # verify the required parameter 'newValue' is set
    unless (exists $args{'newValue'}) {
      croak("Missing the required parameter 'newValue' when calling PostWorkbooksTextReplace");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/replaceText/?oldValue={oldValue}&amp;newValue={newValue}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorkbookReplaceResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkbookSettings
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorkbookSettingsResponse
#
sub GetWorkbookSettings {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkbookSettings");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/settings/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorkbookSettingsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbookSettings
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorkbookSettings $body  (required)
# @return SaaSposeResponse
#
sub PostWorkbookSettings {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbookSettings");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorkbookSettings");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/settings/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbookGetSmartMarkerResult
#
# 
# 
# @param String $name  (required)
# @param String $xmlFile  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $outPath  (optional)
# @param File $file  (required)
# @return ResponseMessage
#
sub PostWorkbookGetSmartMarkerResult {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbookGetSmartMarkerResult");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostWorkbookGetSmartMarkerResult");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/smartmarker/?appSid={appSid}&amp;xmlFile={xmlFile}&amp;storage={storage}&amp;folder={folder}&amp;outPath={outPath}';
    
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
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'name'}) {        		
		$_resource_path =~ s/\Q{name}\E/$args{'name'}/g;
    }else{
		$_resource_path    =~ s/[?&]name.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'xmlFile'}) {        		
		$_resource_path =~ s/\Q{xmlFile}\E/$args{'xmlFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]xmlFile.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ContentMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkbookSplit
#
# 
# 
# @param String $name  (required)
# @param String $format  (optional)
# @param String $from  (optional)
# @param String $to  (optional)
# @param String $horizontalResolution  (optional)
# @param String $verticalResolution  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SplitResultResponse
#
sub PostWorkbookSplit {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkbookSplit");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/split/?appSid={appSid}&amp;toFormat={toFormat}&amp;from={from}&amp;to={to}&amp;horizontalResolution={horizontalResolution}&amp;verticalResolution={verticalResolution}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SplitResultResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkBookTextItems
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return TextItemsResponse
#
sub GetWorkBookTextItems {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkBookTextItems");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/textItems/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheets
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorksheetsResponse
#
sub GetWorkSheets {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheets");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateWorksheetProperty
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param Worksheet $body  (required)
# @return WorksheetResponse
#
sub PostUpdateWorksheetProperty {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateWorksheetProperty");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUpdateWorksheetProperty");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostUpdateWorksheetProperty");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutAddNewWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorksheetsResponse
#
sub PutAddNewWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutAddNewWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutAddNewWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorksheetsResponse
#
sub DeleteWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $format  (required)
# @param String $verticalResolution  (optional)
# @param String $horizontalResolution  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorkSheetWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetWithFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorkSheetWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/?appSid={appSid}&amp;toFormat={toFormat}&amp;verticalResolution={verticalResolution}&amp;horizontalResolution={horizontalResolution}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'format'}) {        		
		$_resource_path =~ s/\Q{format}\E/$args{'format'}/g;
    }else{
		$_resource_path    =~ s/[?&]format.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'verticalResolution'}) {        		
		$_resource_path =~ s/\Q{verticalResolution}\E/$args{'verticalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]verticalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'horizontalResolution'}) {        		
		$_resource_path =~ s/\Q{horizontalResolution}\E/$args{'horizontalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]horizontalResolution.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $verticalResolution  (optional)
# @param String $horizontalResolution  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorkSheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/?appSid={appSid}&amp;verticalResolution={verticalResolution}&amp;horizontalResolution={horizontalResolution}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'verticalResolution'}) {        		
		$_resource_path =~ s/\Q{verticalResolution}\E/$args{'verticalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]verticalResolution.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'horizontalResolution'}) {        		
		$_resource_path =~ s/\Q{horizontalResolution}\E/$args{'horizontalResolution'}/g;
    }else{
		$_resource_path    =~ s/[?&]horizontalResolution.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostAutofitWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startRow  (optional)
# @param String $endRow  (optional)
# @param Boolean $onlyAuto  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param AutoFitterOptions $body  (required)
# @return SaaSposeResponse
#
sub PostAutofitWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostAutofitWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostAutofitWorksheetRows");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostAutofitWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/autofitrows/?appSid={appSid}&amp;startRow={startRow}&amp;endRow={endRow}&amp;onlyAuto={onlyAuto}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endRow'}) {        		
		$_resource_path =~ s/\Q{endRow}\E/$args{'endRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]endRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'onlyAuto'}) {        		
		$_resource_path =~ s/\Q{onlyAuto}\E/$args{'onlyAuto'}/g;
    }else{
		$_resource_path    =~ s/[?&]onlyAuto.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetAutoshapes
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return AutoShapesResponse
#
sub GetWorksheetAutoshapes {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetAutoshapes");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetAutoshapes");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/autoshapes/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'AutoShapesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetAutoshape
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $autoshapeNumber  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetAutoshape {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetAutoshape");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetAutoshape");
    }
    
    # verify the required parameter 'autoshapeNumber' is set
    unless (exists $args{'autoshapeNumber'}) {
      croak("Missing the required parameter 'autoshapeNumber' when calling GetWorksheetAutoshape");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/autoshapes/{autoshapeNumber}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'autoshapeNumber'}) {        		
		$_resource_path =~ s/\Q{autoshapeNumber}\E/$args{'autoshapeNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]autoshapeNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'AutoShapeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetAutoshapeWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $autoshapeNumber  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetAutoshapeWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetAutoshapeWithFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetAutoshapeWithFormat");
    }
    
    # verify the required parameter 'autoshapeNumber' is set
    unless (exists $args{'autoshapeNumber'}) {
      croak("Missing the required parameter 'autoshapeNumber' when calling GetWorksheetAutoshapeWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorksheetAutoshapeWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/autoshapes/{autoshapeNumber}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'autoshapeNumber'}) {        		
		$_resource_path =~ s/\Q{autoshapeNumber}\E/$args{'autoshapeNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]autoshapeNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorkSheetBackground
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @param File $file  (required)
# @return SaaSposeResponse
#
sub PutWorkSheetBackground {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorkSheetBackground");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorkSheetBackground");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutWorkSheetBackground");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/background/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetBackground
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SaaSposeResponse
#
sub DeleteWorkSheetBackground {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetBackground");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetBackground");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/background/?appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetCells
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $offest  (optional)
# @param String $count  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CellsResponse
#
sub GetWorksheetCells {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetCells");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetCells");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/?appSid={appSid}&amp;offest={offest}&amp;count={count}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'offest'}) {        		
		$_resource_path =~ s/\Q{offest}\E/$args{'offest'}/g;
    }else{
		$_resource_path    =~ s/[?&]offest.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'count'}) {        		
		$_resource_path =~ s/\Q{count}\E/$args{'count'}/g;
    }else{
		$_resource_path    =~ s/[?&]count.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSetCellRangeValue
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellarea  (required)
# @param String $value  (required)
# @param String $type  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostSetCellRangeValue {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSetCellRangeValue");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostSetCellRangeValue");
    }
    
    # verify the required parameter 'cellarea' is set
    unless (exists $args{'cellarea'}) {
      croak("Missing the required parameter 'cellarea' when calling PostSetCellRangeValue");
    }
    
    # verify the required parameter 'value' is set
    unless (exists $args{'value'}) {
      croak("Missing the required parameter 'value' when calling PostSetCellRangeValue");
    }
    
    # verify the required parameter 'type' is set
    unless (exists $args{'type'}) {
      croak("Missing the required parameter 'type' when calling PostSetCellRangeValue");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/?cellarea={cellarea}&amp;value={value}&amp;type={type}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellarea'}) {        		
		$_resource_path =~ s/\Q{cellarea}\E/$args{'cellarea'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellarea.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'value'}) {        		
		$_resource_path =~ s/\Q{value}\E/$args{'value'}/g;
    }else{
		$_resource_path    =~ s/[?&]value.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostClearContents
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $range  (optional)
# @param String $startRow  (optional)
# @param String $startColumn  (optional)
# @param String $endRow  (optional)
# @param String $endColumn  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostClearContents {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostClearContents");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostClearContents");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/clearcontents/?appSid={appSid}&amp;range={range}&amp;startRow={startRow}&amp;startColumn={startColumn}&amp;endRow={endRow}&amp;endColumn={endColumn}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'range'}) {        		
		$_resource_path =~ s/\Q{range}\E/$args{'range'}/g;
    }else{
		$_resource_path    =~ s/[?&]range.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startColumn'}) {        		
		$_resource_path =~ s/\Q{startColumn}\E/$args{'startColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endRow'}) {        		
		$_resource_path =~ s/\Q{endRow}\E/$args{'endRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]endRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endColumn'}) {        		
		$_resource_path =~ s/\Q{endColumn}\E/$args{'endColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]endColumn.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostClearFormats
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $range  (optional)
# @param String $startRow  (optional)
# @param String $startColumn  (optional)
# @param String $endRow  (optional)
# @param String $endColumn  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostClearFormats {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostClearFormats");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostClearFormats");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/clearformats/?appSid={appSid}&amp;range={range}&amp;startRow={startRow}&amp;startColumn={startColumn}&amp;endRow={endRow}&amp;endColumn={endColumn}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'range'}) {        		
		$_resource_path =~ s/\Q{range}\E/$args{'range'}/g;
    }else{
		$_resource_path    =~ s/[?&]range.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startColumn'}) {        		
		$_resource_path =~ s/\Q{startColumn}\E/$args{'startColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endRow'}) {        		
		$_resource_path =~ s/\Q{endRow}\E/$args{'endRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]endRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'endColumn'}) {        		
		$_resource_path =~ s/\Q{endColumn}\E/$args{'endColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]endColumn.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetColumns
#
# 
# 
# @param String $name  (optional)
# @param String $sheetName  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ColumnsResponse
#
sub GetWorksheetColumns {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColumnsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostCopyWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $sourceColumnIndex  (required)
# @param String $destinationColumnIndex  (required)
# @param String $columnNumber  (required)
# @param String $worksheet  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostCopyWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostCopyWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostCopyWorksheetColumns");
    }
    
    # verify the required parameter 'sourceColumnIndex' is set
    unless (exists $args{'sourceColumnIndex'}) {
      croak("Missing the required parameter 'sourceColumnIndex' when calling PostCopyWorksheetColumns");
    }
    
    # verify the required parameter 'destinationColumnIndex' is set
    unless (exists $args{'destinationColumnIndex'}) {
      croak("Missing the required parameter 'destinationColumnIndex' when calling PostCopyWorksheetColumns");
    }
    
    # verify the required parameter 'columnNumber' is set
    unless (exists $args{'columnNumber'}) {
      croak("Missing the required parameter 'columnNumber' when calling PostCopyWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/copy/?sourceColumnIndex={sourceColumnIndex}&amp;destinationColumnIndex={destinationColumnIndex}&amp;columnNumber={columnNumber}&amp;appSid={appSid}&amp;worksheet={worksheet}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sourceColumnIndex'}) {        		
		$_resource_path =~ s/\Q{sourceColumnIndex}\E/$args{'sourceColumnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sourceColumnIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destinationColumnIndex'}) {        		
		$_resource_path =~ s/\Q{destinationColumnIndex}\E/$args{'destinationColumnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]destinationColumnIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnNumber'}) {        		
		$_resource_path =~ s/\Q{columnNumber}\E/$args{'columnNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnNumber.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'worksheet'}) {        		
		$_resource_path =~ s/\Q{worksheet}\E/$args{'worksheet'}/g;
    }else{
		$_resource_path    =~ s/[?&]worksheet.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostGroupWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $firstIndex  (required)
# @param String $lastIndex  (required)
# @param Boolean $hide  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostGroupWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostGroupWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostGroupWorksheetColumns");
    }
    
    # verify the required parameter 'firstIndex' is set
    unless (exists $args{'firstIndex'}) {
      croak("Missing the required parameter 'firstIndex' when calling PostGroupWorksheetColumns");
    }
    
    # verify the required parameter 'lastIndex' is set
    unless (exists $args{'lastIndex'}) {
      croak("Missing the required parameter 'lastIndex' when calling PostGroupWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/group/?firstIndex={firstIndex}&amp;lastIndex={lastIndex}&amp;appSid={appSid}&amp;hide={hide}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstIndex'}) {        		
		$_resource_path =~ s/\Q{firstIndex}\E/$args{'firstIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lastIndex'}) {        		
		$_resource_path =~ s/\Q{lastIndex}\E/$args{'lastIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]lastIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'hide'}) {        		
		$_resource_path =~ s/\Q{hide}\E/$args{'hide'}/g;
    }else{
		$_resource_path    =~ s/[?&]hide.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostHideWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startColumn  (required)
# @param String $totalColumns  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostHideWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostHideWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostHideWorksheetColumns");
    }
    
    # verify the required parameter 'startColumn' is set
    unless (exists $args{'startColumn'}) {
      croak("Missing the required parameter 'startColumn' when calling PostHideWorksheetColumns");
    }
    
    # verify the required parameter 'totalColumns' is set
    unless (exists $args{'totalColumns'}) {
      croak("Missing the required parameter 'totalColumns' when calling PostHideWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/hide/?startColumn={startColumn}&amp;totalColumns={totalColumns}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startColumn'}) {        		
		$_resource_path =~ s/\Q{startColumn}\E/$args{'startColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalColumns'}) {        		
		$_resource_path =~ s/\Q{totalColumns}\E/$args{'totalColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUngroupWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $firstIndex  (required)
# @param String $lastIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostUngroupWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUngroupWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUngroupWorksheetColumns");
    }
    
    # verify the required parameter 'firstIndex' is set
    unless (exists $args{'firstIndex'}) {
      croak("Missing the required parameter 'firstIndex' when calling PostUngroupWorksheetColumns");
    }
    
    # verify the required parameter 'lastIndex' is set
    unless (exists $args{'lastIndex'}) {
      croak("Missing the required parameter 'lastIndex' when calling PostUngroupWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/ungroup/?firstIndex={firstIndex}&amp;lastIndex={lastIndex}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstIndex'}) {        		
		$_resource_path =~ s/\Q{firstIndex}\E/$args{'firstIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lastIndex'}) {        		
		$_resource_path =~ s/\Q{lastIndex}\E/$args{'lastIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]lastIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUnhideWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startcolumn  (required)
# @param String $totalColumns  (required)
# @param String $width  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostUnhideWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUnhideWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUnhideWorksheetColumns");
    }
    
    # verify the required parameter 'startcolumn' is set
    unless (exists $args{'startcolumn'}) {
      croak("Missing the required parameter 'startcolumn' when calling PostUnhideWorksheetColumns");
    }
    
    # verify the required parameter 'totalColumns' is set
    unless (exists $args{'totalColumns'}) {
      croak("Missing the required parameter 'totalColumns' when calling PostUnhideWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/unhide/?startcolumn={startcolumn}&amp;totalColumns={totalColumns}&amp;appSid={appSid}&amp;width={width}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startcolumn'}) {        		
		$_resource_path =~ s/\Q{startcolumn}\E/$args{'startcolumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startcolumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalColumns'}) {        		
		$_resource_path =~ s/\Q{totalColumns}\E/$args{'totalColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalColumns.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'width'}) {        		
		$_resource_path =~ s/\Q{width}\E/$args{'width'}/g;
    }else{
		$_resource_path    =~ s/[?&]width.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetColumn
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $columnIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ColumnResponse
#
sub GetWorksheetColumn {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetColumn");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetColumn");
    }
    
    # verify the required parameter 'columnIndex' is set
    unless (exists $args{'columnIndex'}) {
      croak("Missing the required parameter 'columnIndex' when calling GetWorksheetColumn");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnIndex'}) {        		
		$_resource_path =~ s/\Q{columnIndex}\E/$args{'columnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColumnResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutInsertWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $columnIndex  (required)
# @param String $columns  (required)
# @param Boolean $updateReference  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ColumnsResponse
#
sub PutInsertWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutInsertWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutInsertWorksheetColumns");
    }
    
    # verify the required parameter 'columnIndex' is set
    unless (exists $args{'columnIndex'}) {
      croak("Missing the required parameter 'columnIndex' when calling PutInsertWorksheetColumns");
    }
    
    # verify the required parameter 'columns' is set
    unless (exists $args{'columns'}) {
      croak("Missing the required parameter 'columns' when calling PutInsertWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/?columns={columns}&amp;appSid={appSid}&amp;updateReference={updateReference}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnIndex'}) {        		
		$_resource_path =~ s/\Q{columnIndex}\E/$args{'columnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columns'}) {        		
		$_resource_path =~ s/\Q{columns}\E/$args{'columns'}/g;
    }else{
		$_resource_path    =~ s/[?&]columns.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'updateReference'}) {        		
		$_resource_path =~ s/\Q{updateReference}\E/$args{'updateReference'}/g;
    }else{
		$_resource_path    =~ s/[?&]updateReference.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColumnsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetColumns
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $columnIndex  (required)
# @param String $columns  (required)
# @param Boolean $updateReference  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ColumnsResponse
#
sub DeleteWorksheetColumns {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetColumns");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetColumns");
    }
    
    # verify the required parameter 'columnIndex' is set
    unless (exists $args{'columnIndex'}) {
      croak("Missing the required parameter 'columnIndex' when calling DeleteWorksheetColumns");
    }
    
    # verify the required parameter 'columns' is set
    unless (exists $args{'columns'}) {
      croak("Missing the required parameter 'columns' when calling DeleteWorksheetColumns");
    }
    
    # verify the required parameter 'updateReference' is set
    unless (exists $args{'updateReference'}) {
      croak("Missing the required parameter 'updateReference' when calling DeleteWorksheetColumns");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/?columns={columns}&amp;updateReference={updateReference}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnIndex'}) {        		
		$_resource_path =~ s/\Q{columnIndex}\E/$args{'columnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columns'}) {        		
		$_resource_path =~ s/\Q{columns}\E/$args{'columns'}/g;
    }else{
		$_resource_path    =~ s/[?&]columns.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'updateReference'}) {        		
		$_resource_path =~ s/\Q{updateReference}\E/$args{'updateReference'}/g;
    }else{
		$_resource_path    =~ s/[?&]updateReference.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColumnsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSetWorksheetColumnWidth
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $columnIndex  (required)
# @param String $width  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ColumnResponse
#
sub PostSetWorksheetColumnWidth {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSetWorksheetColumnWidth");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostSetWorksheetColumnWidth");
    }
    
    # verify the required parameter 'columnIndex' is set
    unless (exists $args{'columnIndex'}) {
      croak("Missing the required parameter 'columnIndex' when calling PostSetWorksheetColumnWidth");
    }
    
    # verify the required parameter 'width' is set
    unless (exists $args{'width'}) {
      croak("Missing the required parameter 'width' when calling PostSetWorksheetColumnWidth");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/?width={width}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnIndex'}) {        		
		$_resource_path =~ s/\Q{columnIndex}\E/$args{'columnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'width'}) {        		
		$_resource_path =~ s/\Q{width}\E/$args{'width'}/g;
    }else{
		$_resource_path    =~ s/[?&]width.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ColumnResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostColumnStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $columnIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return SaaSposeResponse
#
sub PostColumnStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostColumnStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostColumnStyle");
    }
    
    # verify the required parameter 'columnIndex' is set
    unless (exists $args{'columnIndex'}) {
      croak("Missing the required parameter 'columnIndex' when calling PostColumnStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostColumnStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/style/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'columnIndex'}) {        		
		$_resource_path =~ s/\Q{columnIndex}\E/$args{'columnIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]columnIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetMerge
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startRow  (required)
# @param String $startColumn  (required)
# @param String $totalRows  (required)
# @param String $totalColumns  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostWorksheetMerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetMerge");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetMerge");
    }
    
    # verify the required parameter 'startRow' is set
    unless (exists $args{'startRow'}) {
      croak("Missing the required parameter 'startRow' when calling PostWorksheetMerge");
    }
    
    # verify the required parameter 'startColumn' is set
    unless (exists $args{'startColumn'}) {
      croak("Missing the required parameter 'startColumn' when calling PostWorksheetMerge");
    }
    
    # verify the required parameter 'totalRows' is set
    unless (exists $args{'totalRows'}) {
      croak("Missing the required parameter 'totalRows' when calling PostWorksheetMerge");
    }
    
    # verify the required parameter 'totalColumns' is set
    unless (exists $args{'totalColumns'}) {
      croak("Missing the required parameter 'totalColumns' when calling PostWorksheetMerge");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/merge/?startRow={startRow}&amp;startColumn={startColumn}&amp;totalRows={totalRows}&amp;totalColumns={totalColumns}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startColumn'}) {        		
		$_resource_path =~ s/\Q{startColumn}\E/$args{'startColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalColumns'}) {        		
		$_resource_path =~ s/\Q{totalColumns}\E/$args{'totalColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RowsResponse
#
sub GetWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RowsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutInsertWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startrow  (required)
# @param String $totalRows  (optional)
# @param Boolean $updateReference  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PutInsertWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutInsertWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutInsertWorksheetRows");
    }
    
    # verify the required parameter 'startrow' is set
    unless (exists $args{'startrow'}) {
      croak("Missing the required parameter 'startrow' when calling PutInsertWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/?startrow={startrow}&amp;appSid={appSid}&amp;totalRows={totalRows}&amp;updateReference={updateReference}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startrow'}) {        		
		$_resource_path =~ s/\Q{startrow}\E/$args{'startrow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startrow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'updateReference'}) {        		
		$_resource_path =~ s/\Q{updateReference}\E/$args{'updateReference'}/g;
    }else{
		$_resource_path    =~ s/[?&]updateReference.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startrow  (required)
# @param String $totalRows  (optional)
# @param Boolean $updateReference  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetRows");
    }
    
    # verify the required parameter 'startrow' is set
    unless (exists $args{'startrow'}) {
      croak("Missing the required parameter 'startrow' when calling DeleteWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/?startrow={startrow}&amp;appSid={appSid}&amp;totalRows={totalRows}&amp;updateReference={updateReference}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startrow'}) {        		
		$_resource_path =~ s/\Q{startrow}\E/$args{'startrow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startrow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'updateReference'}) {        		
		$_resource_path =~ s/\Q{updateReference}\E/$args{'updateReference'}/g;
    }else{
		$_resource_path    =~ s/[?&]updateReference.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostCopyWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $sourceRowIndex  (required)
# @param String $destinationRowIndex  (required)
# @param String $rowNumber  (required)
# @param String $worksheet  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostCopyWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostCopyWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostCopyWorksheetRows");
    }
    
    # verify the required parameter 'sourceRowIndex' is set
    unless (exists $args{'sourceRowIndex'}) {
      croak("Missing the required parameter 'sourceRowIndex' when calling PostCopyWorksheetRows");
    }
    
    # verify the required parameter 'destinationRowIndex' is set
    unless (exists $args{'destinationRowIndex'}) {
      croak("Missing the required parameter 'destinationRowIndex' when calling PostCopyWorksheetRows");
    }
    
    # verify the required parameter 'rowNumber' is set
    unless (exists $args{'rowNumber'}) {
      croak("Missing the required parameter 'rowNumber' when calling PostCopyWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/copy/?sourceRowIndex={sourceRowIndex}&amp;destinationRowIndex={destinationRowIndex}&amp;rowNumber={rowNumber}&amp;appSid={appSid}&amp;worksheet={worksheet}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sourceRowIndex'}) {        		
		$_resource_path =~ s/\Q{sourceRowIndex}\E/$args{'sourceRowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]sourceRowIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destinationRowIndex'}) {        		
		$_resource_path =~ s/\Q{destinationRowIndex}\E/$args{'destinationRowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]destinationRowIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowNumber'}) {        		
		$_resource_path =~ s/\Q{rowNumber}\E/$args{'rowNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowNumber.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'worksheet'}) {        		
		$_resource_path =~ s/\Q{worksheet}\E/$args{'worksheet'}/g;
    }else{
		$_resource_path    =~ s/[?&]worksheet.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostGroupWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $firstIndex  (required)
# @param String $lastIndex  (required)
# @param Boolean $hide  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostGroupWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostGroupWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostGroupWorksheetRows");
    }
    
    # verify the required parameter 'firstIndex' is set
    unless (exists $args{'firstIndex'}) {
      croak("Missing the required parameter 'firstIndex' when calling PostGroupWorksheetRows");
    }
    
    # verify the required parameter 'lastIndex' is set
    unless (exists $args{'lastIndex'}) {
      croak("Missing the required parameter 'lastIndex' when calling PostGroupWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/group/?firstIndex={firstIndex}&amp;lastIndex={lastIndex}&amp;appSid={appSid}&amp;hide={hide}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstIndex'}) {        		
		$_resource_path =~ s/\Q{firstIndex}\E/$args{'firstIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lastIndex'}) {        		
		$_resource_path =~ s/\Q{lastIndex}\E/$args{'lastIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]lastIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'hide'}) {        		
		$_resource_path =~ s/\Q{hide}\E/$args{'hide'}/g;
    }else{
		$_resource_path    =~ s/[?&]hide.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostHideWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startrow  (required)
# @param String $totalRows  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostHideWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostHideWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostHideWorksheetRows");
    }
    
    # verify the required parameter 'startrow' is set
    unless (exists $args{'startrow'}) {
      croak("Missing the required parameter 'startrow' when calling PostHideWorksheetRows");
    }
    
    # verify the required parameter 'totalRows' is set
    unless (exists $args{'totalRows'}) {
      croak("Missing the required parameter 'totalRows' when calling PostHideWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/hide/?startrow={startrow}&amp;totalRows={totalRows}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startrow'}) {        		
		$_resource_path =~ s/\Q{startrow}\E/$args{'startrow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startrow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUngroupWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $firstIndex  (required)
# @param String $lastIndex  (required)
# @param Boolean $isAll  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostUngroupWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUngroupWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUngroupWorksheetRows");
    }
    
    # verify the required parameter 'firstIndex' is set
    unless (exists $args{'firstIndex'}) {
      croak("Missing the required parameter 'firstIndex' when calling PostUngroupWorksheetRows");
    }
    
    # verify the required parameter 'lastIndex' is set
    unless (exists $args{'lastIndex'}) {
      croak("Missing the required parameter 'lastIndex' when calling PostUngroupWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/ungroup/?firstIndex={firstIndex}&amp;lastIndex={lastIndex}&amp;appSid={appSid}&amp;isAll={isAll}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstIndex'}) {        		
		$_resource_path =~ s/\Q{firstIndex}\E/$args{'firstIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lastIndex'}) {        		
		$_resource_path =~ s/\Q{lastIndex}\E/$args{'lastIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]lastIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isAll'}) {        		
		$_resource_path =~ s/\Q{isAll}\E/$args{'isAll'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAll.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUnhideWorksheetRows
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startrow  (required)
# @param String $totalRows  (required)
# @param String $height  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostUnhideWorksheetRows {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUnhideWorksheetRows");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUnhideWorksheetRows");
    }
    
    # verify the required parameter 'startrow' is set
    unless (exists $args{'startrow'}) {
      croak("Missing the required parameter 'startrow' when calling PostUnhideWorksheetRows");
    }
    
    # verify the required parameter 'totalRows' is set
    unless (exists $args{'totalRows'}) {
      croak("Missing the required parameter 'totalRows' when calling PostUnhideWorksheetRows");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/unhide/?startrow={startrow}&amp;totalRows={totalRows}&amp;appSid={appSid}&amp;height={height}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startrow'}) {        		
		$_resource_path =~ s/\Q{startrow}\E/$args{'startrow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startrow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'height'}) {        		
		$_resource_path =~ s/\Q{height}\E/$args{'height'}/g;
    }else{
		$_resource_path    =~ s/[?&]height.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateWorksheetRow
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $rowIndex  (required)
# @param String $height  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RowResponse
#
sub PostUpdateWorksheetRow {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateWorksheetRow");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUpdateWorksheetRow");
    }
    
    # verify the required parameter 'rowIndex' is set
    unless (exists $args{'rowIndex'}) {
      croak("Missing the required parameter 'rowIndex' when calling PostUpdateWorksheetRow");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/?appSid={appSid}&amp;height={height}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowIndex'}) {        		
		$_resource_path =~ s/\Q{rowIndex}\E/$args{'rowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'height'}) {        		
		$_resource_path =~ s/\Q{height}\E/$args{'height'}/g;
    }else{
		$_resource_path    =~ s/[?&]height.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RowResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetRow
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $rowIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RowResponse
#
sub GetWorksheetRow {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetRow");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetRow");
    }
    
    # verify the required parameter 'rowIndex' is set
    unless (exists $args{'rowIndex'}) {
      croak("Missing the required parameter 'rowIndex' when calling GetWorksheetRow");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowIndex'}) {        		
		$_resource_path =~ s/\Q{rowIndex}\E/$args{'rowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RowResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutInsertWorksheetRow
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $rowIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return RowResponse
#
sub PutInsertWorksheetRow {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutInsertWorksheetRow");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutInsertWorksheetRow");
    }
    
    # verify the required parameter 'rowIndex' is set
    unless (exists $args{'rowIndex'}) {
      croak("Missing the required parameter 'rowIndex' when calling PutInsertWorksheetRow");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowIndex'}) {        		
		$_resource_path =~ s/\Q{rowIndex}\E/$args{'rowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RowResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetRow
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $rowIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetRow {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetRow");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetRow");
    }
    
    # verify the required parameter 'rowIndex' is set
    unless (exists $args{'rowIndex'}) {
      croak("Missing the required parameter 'rowIndex' when calling DeleteWorksheetRow");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowIndex'}) {        		
		$_resource_path =~ s/\Q{rowIndex}\E/$args{'rowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostRowStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $rowIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return SaaSposeResponse
#
sub PostRowStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostRowStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostRowStyle");
    }
    
    # verify the required parameter 'rowIndex' is set
    unless (exists $args{'rowIndex'}) {
      croak("Missing the required parameter 'rowIndex' when calling PostRowStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostRowStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/style/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'rowIndex'}) {        		
		$_resource_path =~ s/\Q{rowIndex}\E/$args{'rowIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]rowIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateWorksheetRangeStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $range  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return SaaSposeResponse
#
sub PostUpdateWorksheetRangeStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateWorksheetRangeStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUpdateWorksheetRangeStyle");
    }
    
    # verify the required parameter 'range' is set
    unless (exists $args{'range'}) {
      croak("Missing the required parameter 'range' when calling PostUpdateWorksheetRangeStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostUpdateWorksheetRangeStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/style/?range={range}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'range'}) {        		
		$_resource_path =~ s/\Q{range}\E/$args{'range'}/g;
    }else{
		$_resource_path    =~ s/[?&]range.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetUnmerge
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $startRow  (required)
# @param String $startColumn  (required)
# @param String $totalRows  (required)
# @param String $totalColumns  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostWorksheetUnmerge {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetUnmerge");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetUnmerge");
    }
    
    # verify the required parameter 'startRow' is set
    unless (exists $args{'startRow'}) {
      croak("Missing the required parameter 'startRow' when calling PostWorksheetUnmerge");
    }
    
    # verify the required parameter 'startColumn' is set
    unless (exists $args{'startColumn'}) {
      croak("Missing the required parameter 'startColumn' when calling PostWorksheetUnmerge");
    }
    
    # verify the required parameter 'totalRows' is set
    unless (exists $args{'totalRows'}) {
      croak("Missing the required parameter 'totalRows' when calling PostWorksheetUnmerge");
    }
    
    # verify the required parameter 'totalColumns' is set
    unless (exists $args{'totalColumns'}) {
      croak("Missing the required parameter 'totalColumns' when calling PostWorksheetUnmerge");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/unmerge/?startRow={startRow}&amp;startColumn={startColumn}&amp;totalRows={totalRows}&amp;totalColumns={totalColumns}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startRow'}) {        		
		$_resource_path =~ s/\Q{startRow}\E/$args{'startRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]startRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'startColumn'}) {        		
		$_resource_path =~ s/\Q{startColumn}\E/$args{'startColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]startColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalColumns'}) {        		
		$_resource_path =~ s/\Q{totalColumns}\E/$args{'totalColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetCellSetValue
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $value  (optional)
# @param String $type  (optional)
# @param String $formula  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CellResponse
#
sub PostWorksheetCellSetValue {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetCellSetValue");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetCellSetValue");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling PostWorksheetCellSetValue");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellName}/?appSid={appSid}&amp;value={value}&amp;type={type}&amp;formula={formula}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'value'}) {        		
		$_resource_path =~ s/\Q{value}\E/$args{'value'}/g;
    }else{
		$_resource_path    =~ s/[?&]value.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'type'}) {        		
		$_resource_path =~ s/\Q{type}\E/$args{'type'}/g;
    }else{
		$_resource_path    =~ s/[?&]type.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'formula'}) {        		
		$_resource_path =~ s/\Q{formula}\E/$args{'formula'}/g;
    }else{
		$_resource_path    =~ s/[?&]formula.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostSetCellHtmlString
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return CellResponse
#
sub PostSetCellHtmlString {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostSetCellHtmlString");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostSetCellHtmlString");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling PostSetCellHtmlString");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostSetCellHtmlString");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellName}/htmlstring/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetCellStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return StyleResponse
#
sub GetWorksheetCellStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetCellStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetCellStyle");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling GetWorksheetCellStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellName}/style/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'StyleResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateWorksheetCellStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return StyleResponse
#
sub PostUpdateWorksheetCellStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateWorksheetCellStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUpdateWorksheetCellStyle");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling PostUpdateWorksheetCellStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostUpdateWorksheetCellStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellName}/style/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'StyleResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetCell
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellOrMethodName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetCell {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetCell");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetCell");
    }
    
    # verify the required parameter 'cellOrMethodName' is set
    unless (exists $args{'cellOrMethodName'}) {
      croak("Missing the required parameter 'cellOrMethodName' when calling GetWorksheetCell");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellOrMethodName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellOrMethodName'}) {        		
		$_resource_path =~ s/\Q{cellOrMethodName}\E/$args{'cellOrMethodName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellOrMethodName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CellResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetCell2
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellOrMethodName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetCell2 {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetCell");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetCell");
    }
    
    # verify the required parameter 'cellOrMethodName' is set
    unless (exists $args{'cellOrMethodName'}) {
      croak("Missing the required parameter 'cellOrMethodName' when calling GetWorksheetCell");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{cellOrMethodName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellOrMethodName'}) {        		
		$_resource_path =~ s/\Q{cellOrMethodName}\E/$args{'cellOrMethodName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellOrMethodName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	return  $response;
    
}
#
# PostCopyCellIntoCell
#
# 
# 
# @param String $name  (required)
# @param String $destCellName  (required)
# @param String $sheetName  (required)
# @param String $worksheet  (required)
# @param String $cellname  (optional)
# @param String $row  (optional)
# @param String $column  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostCopyCellIntoCell {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostCopyCellIntoCell");
    }
    
    # verify the required parameter 'destCellName' is set
    unless (exists $args{'destCellName'}) {
      croak("Missing the required parameter 'destCellName' when calling PostCopyCellIntoCell");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostCopyCellIntoCell");
    }
    
    # verify the required parameter 'worksheet' is set
    unless (exists $args{'worksheet'}) {
      croak("Missing the required parameter 'worksheet' when calling PostCopyCellIntoCell");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/cells/{destCellName}/copy/?worksheet={worksheet}&amp;appSid={appSid}&amp;cellname={cellname}&amp;row={row}&amp;column={column}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'destCellName'}) {        		
		$_resource_path =~ s/\Q{destCellName}\E/$args{'destCellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destCellName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'worksheet'}) {        		
		$_resource_path =~ s/\Q{worksheet}\E/$args{'worksheet'}/g;
    }else{
		$_resource_path    =~ s/[?&]worksheet.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellname'}) {        		
		$_resource_path =~ s/\Q{cellname}\E/$args{'cellname'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellname.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'row'}) {        		
		$_resource_path =~ s/\Q{row}\E/$args{'row'}/g;
    }else{
		$_resource_path    =~ s/[?&]row.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'column'}) {        		
		$_resource_path =~ s/\Q{column}\E/$args{'column'}/g;
    }else{
		$_resource_path    =~ s/[?&]column.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetCharts
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ChartsResponse
#
sub GetWorksheetCharts {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetCharts");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetCharts");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ChartsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetClearCharts
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetClearCharts {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetClearCharts");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetClearCharts");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetAddChart
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartType  (required)
# @param String $upperLeftRow  (optional)
# @param String $upperLeftColumn  (optional)
# @param String $lowerRightRow  (optional)
# @param String $lowerRightColumn  (optional)
# @param String $area  (optional)
# @param Boolean $isVertical  (optional)
# @param String $categoryData  (optional)
# @param Boolean $isAutoGetSerialName  (optional)
# @param String $title  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ChartsResponse
#
sub PutWorksheetAddChart {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetAddChart");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetAddChart");
    }
    
    # verify the required parameter 'chartType' is set
    unless (exists $args{'chartType'}) {
      croak("Missing the required parameter 'chartType' when calling PutWorksheetAddChart");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/?chartType={chartType}&amp;appSid={appSid}&amp;upperLeftRow={upperLeftRow}&amp;upperLeftColumn={upperLeftColumn}&amp;lowerRightRow={lowerRightRow}&amp;lowerRightColumn={lowerRightColumn}&amp;area={area}&amp;isVertical={isVertical}&amp;categoryData={categoryData}&amp;isAutoGetSerialName={isAutoGetSerialName}&amp;title={title}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartType'}) {        		
		$_resource_path =~ s/\Q{chartType}\E/$args{'chartType'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartType.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftRow'}) {        		
		$_resource_path =~ s/\Q{upperLeftRow}\E/$args{'upperLeftRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftColumn'}) {        		
		$_resource_path =~ s/\Q{upperLeftColumn}\E/$args{'upperLeftColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lowerRightRow'}) {        		
		$_resource_path =~ s/\Q{lowerRightRow}\E/$args{'lowerRightRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]lowerRightRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lowerRightColumn'}) {        		
		$_resource_path =~ s/\Q{lowerRightColumn}\E/$args{'lowerRightColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]lowerRightColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'area'}) {        		
		$_resource_path =~ s/\Q{area}\E/$args{'area'}/g;
    }else{
		$_resource_path    =~ s/[?&]area.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isVertical'}) {        		
		$_resource_path =~ s/\Q{isVertical}\E/$args{'isVertical'}/g;
    }else{
		$_resource_path    =~ s/[?&]isVertical.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'categoryData'}) {        		
		$_resource_path =~ s/\Q{categoryData}\E/$args{'categoryData'}/g;
    }else{
		$_resource_path    =~ s/[?&]categoryData.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isAutoGetSerialName'}) {        		
		$_resource_path =~ s/\Q{isAutoGetSerialName}\E/$args{'isAutoGetSerialName'}/g;
    }else{
		$_resource_path    =~ s/[?&]isAutoGetSerialName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'title'}) {        		
		$_resource_path =~ s/\Q{title}\E/$args{'title'}/g;
    }else{
		$_resource_path    =~ s/[?&]title.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ChartsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetDeleteChart
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ChartsResponse
#
sub DeleteWorksheetDeleteChart {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetDeleteChart");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetDeleteChart");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling DeleteWorksheetDeleteChart");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ChartsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetChartArea
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ChartAreaResponse
#
sub GetChartArea {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetChartArea");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetChartArea");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling GetChartArea");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ChartAreaResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetChartAreaBorder
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return LineResponse
#
sub GetChartAreaBorder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetChartAreaBorder");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetChartAreaBorder");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling GetChartAreaBorder");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/border/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'LineResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetChartAreaFillFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return FillFormatResponse
#
sub GetChartAreaFillFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetChartAreaFillFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetChartAreaFillFormat");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling GetChartAreaFillFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/fillFormat/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FillFormatResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetChartLegend
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return LegendResponse
#
sub GetWorksheetChartLegend {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetChartLegend");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetChartLegend");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling GetWorksheetChartLegend");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'LegendResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetChartLegend
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PutWorksheetChartLegend {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetChartLegend");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetChartLegend");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling PutWorksheetChartLegend");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetChartLegend
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Legend $body  (required)
# @return LegendResponse
#
sub PostWorksheetChartLegend {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetChartLegend");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetChartLegend");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling PostWorksheetChartLegend");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorksheetChartLegend");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'LegendResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetChartLegend
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetChartLegend {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetChartLegend");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetChartLegend");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling DeleteWorksheetChartLegend");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetChartTitle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Title $body  (required)
# @return TitleResponse
#
sub PutWorksheetChartTitle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetChartTitle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetChartTitle");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling PutWorksheetChartTitle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutWorksheetChartTitle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TitleResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetChartTitle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Title $body  (required)
# @return TitleResponse
#
sub PostWorksheetChartTitle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetChartTitle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetChartTitle");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling PostWorksheetChartTitle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorksheetChartTitle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TitleResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetChartTitle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetChartTitle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetChartTitle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetChartTitle");
    }
    
    # verify the required parameter 'chartIndex' is set
    unless (exists $args{'chartIndex'}) {
      croak("Missing the required parameter 'chartIndex' when calling DeleteWorksheetChartTitle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartIndex'}) {        		
		$_resource_path =~ s/\Q{chartIndex}\E/$args{'chartIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetChart
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartNumber  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetChart {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetChart");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetChart");
    }
    
    # verify the required parameter 'chartNumber' is set
    unless (exists $args{'chartNumber'}) {
      croak("Missing the required parameter 'chartNumber' when calling GetWorksheetChart");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartNumber}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartNumber'}) {        		
		$_resource_path =~ s/\Q{chartNumber}\E/$args{'chartNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ChartResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetChartWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $chartNumber  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetChartWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetChartWithFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetChartWithFormat");
    }
    
    # verify the required parameter 'chartNumber' is set
    unless (exists $args{'chartNumber'}) {
      croak("Missing the required parameter 'chartNumber' when calling GetWorksheetChartWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorksheetChartWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/charts/{chartNumber}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'chartNumber'}) {        		
		$_resource_path =~ s/\Q{chartNumber}\E/$args{'chartNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]chartNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetComments
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CommentsResponse
#
sub GetWorkSheetComments {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetComments");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetComments");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/comments/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetComment
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return CommentResponse
#
sub GetWorkSheetComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetComment");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetComment");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling GetWorkSheetComment");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/comments/{cellName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorkSheetComment
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Comment $body  (required)
# @return CommentResponse
#
sub PutWorkSheetComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorkSheetComment");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorkSheetComment");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling PutWorkSheetComment");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutWorkSheetComment");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/comments/{cellName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'CommentResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkSheetComment
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Comment $body  (required)
# @return SaaSposeResponse
#
sub PostWorkSheetComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkSheetComment");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorkSheetComment");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling PostWorkSheetComment");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorkSheetComment");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/comments/{cellName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetComment
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorkSheetComment {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetComment");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetComment");
    }
    
    # verify the required parameter 'cellName' is set
    unless (exists $args{'cellName'}) {
      croak("Missing the required parameter 'cellName' when calling DeleteWorkSheetComment");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/comments/{cellName}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellName'}) {        		
		$_resource_path =~ s/\Q{cellName}\E/$args{'cellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostCopyWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $sourceSheet  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SaaSposeResponse
#
sub PostCopyWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostCopyWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostCopyWorksheet");
    }
    
    # verify the required parameter 'sourceSheet' is set
    unless (exists $args{'sourceSheet'}) {
      croak("Missing the required parameter 'sourceSheet' when calling PostCopyWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/copy/?sourceSheet={sourceSheet}&amp;appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'sourceSheet'}) {        		
		$_resource_path =~ s/\Q{sourceSheet}\E/$args{'sourceSheet'}/g;
    }else{
		$_resource_path    =~ s/[?&]sourceSheet.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkSheetTextSearch
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $text  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return TextItemsResponse
#
sub PostWorkSheetTextSearch {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkSheetTextSearch");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorkSheetTextSearch");
    }
    
    # verify the required parameter 'text' is set
    unless (exists $args{'text'}) {
      croak("Missing the required parameter 'text' when calling PostWorkSheetTextSearch");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/findText/?text={text}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'text'}) {        		
		$_resource_path =~ s/\Q{text}\E/$args{'text'}/g;
    }else{
		$_resource_path    =~ s/[?&]text.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetCalculateFormula
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $formula  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SingleValueResponse
#
sub GetWorkSheetCalculateFormula {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetCalculateFormula");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetCalculateFormula");
    }
    
    # verify the required parameter 'formula' is set
    unless (exists $args{'formula'}) {
      croak("Missing the required parameter 'formula' when calling GetWorkSheetCalculateFormula");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/formulaResult/?formula={formula}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'formula'}) {        		
		$_resource_path =~ s/\Q{formula}\E/$args{'formula'}/g;
    }else{
		$_resource_path    =~ s/[?&]formula.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SingleValueResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetFreezePanes
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $row  (required)
# @param String $column  (required)
# @param String $freezedRows  (required)
# @param String $freezedColumns  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SaaSposeResponse
#
sub PutWorksheetFreezePanes {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetFreezePanes");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetFreezePanes");
    }
    
    # verify the required parameter 'row' is set
    unless (exists $args{'row'}) {
      croak("Missing the required parameter 'row' when calling PutWorksheetFreezePanes");
    }
    
    # verify the required parameter 'column' is set
    unless (exists $args{'column'}) {
      croak("Missing the required parameter 'column' when calling PutWorksheetFreezePanes");
    }
    
    # verify the required parameter 'freezedRows' is set
    unless (exists $args{'freezedRows'}) {
      croak("Missing the required parameter 'freezedRows' when calling PutWorksheetFreezePanes");
    }
    
    # verify the required parameter 'freezedColumns' is set
    unless (exists $args{'freezedColumns'}) {
      croak("Missing the required parameter 'freezedColumns' when calling PutWorksheetFreezePanes");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/freezepanes/?appSid={appSid}&amp;row={row}&amp;column={column}&amp;freezedRows={freezedRows}&amp;freezedColumns={freezedColumns}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'row'}) {        		
		$_resource_path =~ s/\Q{row}\E/$args{'row'}/g;
    }else{
		$_resource_path    =~ s/[?&]row.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'column'}) {        		
		$_resource_path =~ s/\Q{column}\E/$args{'column'}/g;
    }else{
		$_resource_path    =~ s/[?&]column.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'freezedRows'}) {        		
		$_resource_path =~ s/\Q{freezedRows}\E/$args{'freezedRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]freezedRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'freezedColumns'}) {        		
		$_resource_path =~ s/\Q{freezedColumns}\E/$args{'freezedColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]freezedColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetFreezePanes
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $row  (required)
# @param String $column  (required)
# @param String $freezedRows  (required)
# @param String $freezedColumns  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetFreezePanes {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetFreezePanes");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetFreezePanes");
    }
    
    # verify the required parameter 'row' is set
    unless (exists $args{'row'}) {
      croak("Missing the required parameter 'row' when calling DeleteWorksheetFreezePanes");
    }
    
    # verify the required parameter 'column' is set
    unless (exists $args{'column'}) {
      croak("Missing the required parameter 'column' when calling DeleteWorksheetFreezePanes");
    }
    
    # verify the required parameter 'freezedRows' is set
    unless (exists $args{'freezedRows'}) {
      croak("Missing the required parameter 'freezedRows' when calling DeleteWorksheetFreezePanes");
    }
    
    # verify the required parameter 'freezedColumns' is set
    unless (exists $args{'freezedColumns'}) {
      croak("Missing the required parameter 'freezedColumns' when calling DeleteWorksheetFreezePanes");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/freezepanes/?appSid={appSid}&amp;row={row}&amp;column={column}&amp;freezedRows={freezedRows}&amp;freezedColumns={freezedColumns}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'row'}) {        		
		$_resource_path =~ s/\Q{row}\E/$args{'row'}/g;
    }else{
		$_resource_path    =~ s/[?&]row.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'column'}) {        		
		$_resource_path =~ s/\Q{column}\E/$args{'column'}/g;
    }else{
		$_resource_path    =~ s/[?&]column.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'freezedRows'}) {        		
		$_resource_path =~ s/\Q{freezedRows}\E/$args{'freezedRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]freezedRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'freezedColumns'}) {        		
		$_resource_path =~ s/\Q{freezedColumns}\E/$args{'freezedColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]freezedColumns.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorkSheetHyperlink
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $firstRow  (required)
# @param String $firstColumn  (required)
# @param String $totalRows  (required)
# @param String $totalColumns  (required)
# @param String $address  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return HyperlinkResponse
#
sub PutWorkSheetHyperlink {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'firstRow' is set
    unless (exists $args{'firstRow'}) {
      croak("Missing the required parameter 'firstRow' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'firstColumn' is set
    unless (exists $args{'firstColumn'}) {
      croak("Missing the required parameter 'firstColumn' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'totalRows' is set
    unless (exists $args{'totalRows'}) {
      croak("Missing the required parameter 'totalRows' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'totalColumns' is set
    unless (exists $args{'totalColumns'}) {
      croak("Missing the required parameter 'totalColumns' when calling PutWorkSheetHyperlink");
    }
    
    # verify the required parameter 'address' is set
    unless (exists $args{'address'}) {
      croak("Missing the required parameter 'address' when calling PutWorkSheetHyperlink");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/?appSid={appSid}&amp;firstRow={firstRow}&amp;firstColumn={firstColumn}&amp;totalRows={totalRows}&amp;totalColumns={totalColumns}&amp;address={address}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstRow'}) {        		
		$_resource_path =~ s/\Q{firstRow}\E/$args{'firstRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'firstColumn'}) {        		
		$_resource_path =~ s/\Q{firstColumn}\E/$args{'firstColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]firstColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalRows'}) {        		
		$_resource_path =~ s/\Q{totalRows}\E/$args{'totalRows'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalRows.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'totalColumns'}) {        		
		$_resource_path =~ s/\Q{totalColumns}\E/$args{'totalColumns'}/g;
    }else{
		$_resource_path    =~ s/[?&]totalColumns.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'address'}) {        		
		$_resource_path =~ s/\Q{address}\E/$args{'address'}/g;
    }else{
		$_resource_path    =~ s/[?&]address.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetHyperlinks
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return HyperlinksResponse
#
sub GetWorkSheetHyperlinks {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetHyperlinks");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetHyperlinks");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinksResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetHyperlinks
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorkSheetHyperlinks {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetHyperlinks");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetHyperlinks");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetHyperlink
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $hyperlinkIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return HyperlinkResponse
#
sub GetWorkSheetHyperlink {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetHyperlink");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetHyperlink");
    }
    
    # verify the required parameter 'hyperlinkIndex' is set
    unless (exists $args{'hyperlinkIndex'}) {
      croak("Missing the required parameter 'hyperlinkIndex' when calling GetWorkSheetHyperlink");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkSheetHyperlink
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $hyperlinkIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Hyperlink $body  (required)
# @return HyperlinkResponse
#
sub PostWorkSheetHyperlink {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkSheetHyperlink");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorkSheetHyperlink");
    }
    
    # verify the required parameter 'hyperlinkIndex' is set
    unless (exists $args{'hyperlinkIndex'}) {
      croak("Missing the required parameter 'hyperlinkIndex' when calling PostWorkSheetHyperlink");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorkSheetHyperlink");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'HyperlinkResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetHyperlink
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $hyperlinkIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorkSheetHyperlink {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetHyperlink");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetHyperlink");
    }
    
    # verify the required parameter 'hyperlinkIndex' is set
    unless (exists $args{'hyperlinkIndex'}) {
      croak("Missing the required parameter 'hyperlinkIndex' when calling DeleteWorkSheetHyperlink");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetMergedCells
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return MergedCellsResponse
#
sub GetWorkSheetMergedCells {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetMergedCells");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetMergedCells");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/mergedCells/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'MergedCellsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetMergedCell
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $mergedCellIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return MergedCellResponse
#
sub GetWorkSheetMergedCell {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetMergedCell");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetMergedCell");
    }
    
    # verify the required parameter 'mergedCellIndex' is set
    unless (exists $args{'mergedCellIndex'}) {
      croak("Missing the required parameter 'mergedCellIndex' when calling GetWorkSheetMergedCell");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/mergedCells/{mergedCellIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'mergedCellIndex'}) {        		
		$_resource_path =~ s/\Q{mergedCellIndex}\E/$args{'mergedCellIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]mergedCellIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'MergedCellResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetOleObjects
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return OleObjectsResponse
#
sub GetWorksheetOleObjects {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetOleObjects");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetOleObjects");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'OleObjectsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetOleObjects
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetOleObjects {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetOleObjects");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetOleObjects");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetOleObject
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $upperLeftRow  (optional)
# @param String $upperLeftColumn  (optional)
# @param String $height  (optional)
# @param String $width  (optional)
# @param String $oleFile  (optional)
# @param String $imageFile  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param OleObject $body  (required)
# @return OleObjectResponse
#
sub PutWorksheetOleObject {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetOleObject");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetOleObject");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutWorksheetOleObject");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/?appSid={appSid}&amp;upperLeftRow={upperLeftRow}&amp;upperLeftColumn={upperLeftColumn}&amp;height={height}&amp;width={width}&amp;oleFile={oleFile}&amp;imageFile={imageFile}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftRow'}) {        		
		$_resource_path =~ s/\Q{upperLeftRow}\E/$args{'upperLeftRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftColumn'}) {        		
		$_resource_path =~ s/\Q{upperLeftColumn}\E/$args{'upperLeftColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'height'}) {        		
		$_resource_path =~ s/\Q{height}\E/$args{'height'}/g;
    }else{
		$_resource_path    =~ s/[?&]height.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'width'}) {        		
		$_resource_path =~ s/\Q{width}\E/$args{'width'}/g;
    }else{
		$_resource_path    =~ s/[?&]width.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'oleFile'}) {        		
		$_resource_path =~ s/\Q{oleFile}\E/$args{'oleFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]oleFile.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'imageFile'}) {        		
		$_resource_path =~ s/\Q{imageFile}\E/$args{'imageFile'}/g;
    }else{
		$_resource_path    =~ s/[?&]imageFile.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'OleObjectResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetOleObject
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $objectNumber  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetOleObject {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetOleObject");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetOleObject");
    }
    
    # verify the required parameter 'objectNumber' is set
    unless (exists $args{'objectNumber'}) {
      croak("Missing the required parameter 'objectNumber' when calling GetWorksheetOleObject");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/{objectNumber}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'objectNumber'}) {        		
		$_resource_path =~ s/\Q{objectNumber}\E/$args{'objectNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'OleObjectResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetOleObjectWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $objectNumber  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetOleObjectWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetOleObjectWithFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetOleObjectWithFormat");
    }
    
    # verify the required parameter 'objectNumber' is set
    unless (exists $args{'objectNumber'}) {
      croak("Missing the required parameter 'objectNumber' when calling GetWorksheetOleObjectWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorksheetOleObjectWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/{objectNumber}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'objectNumber'}) {        		
		$_resource_path =~ s/\Q{objectNumber}\E/$args{'objectNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]objectNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostUpdateWorksheetOleObject
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $oleObjectIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param OleObject $body  (required)
# @return SaaSposeResponse
#
sub PostUpdateWorksheetOleObject {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostUpdateWorksheetOleObject");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostUpdateWorksheetOleObject");
    }
    
    # verify the required parameter 'oleObjectIndex' is set
    unless (exists $args{'oleObjectIndex'}) {
      croak("Missing the required parameter 'oleObjectIndex' when calling PostUpdateWorksheetOleObject");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostUpdateWorksheetOleObject");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/{oleObjectIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'oleObjectIndex'}) {        		
		$_resource_path =~ s/\Q{oleObjectIndex}\E/$args{'oleObjectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]oleObjectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetOleObject
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $oleObjectIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetOleObject {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetOleObject");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetOleObject");
    }
    
    # verify the required parameter 'oleObjectIndex' is set
    unless (exists $args{'oleObjectIndex'}) {
      croak("Missing the required parameter 'oleObjectIndex' when calling DeleteWorksheetOleObject");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/oleobjects/{oleObjectIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'oleObjectIndex'}) {        		
		$_resource_path =~ s/\Q{oleObjectIndex}\E/$args{'oleObjectIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]oleObjectIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetPictures
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return PicturesResponse
#
sub GetWorksheetPictures {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetPictures");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetPictures");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PicturesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetPictures
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorkSheetPictures {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetPictures");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetPictures");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetAddPicture
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $upperLeftRow  (optional)
# @param String $upperLeftColumn  (optional)
# @param String $lowerRightRow  (optional)
# @param String $lowerRightColumn  (optional)
# @param String $picturePath  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return PicturesResponse
#
sub PutWorksheetAddPicture {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetAddPicture");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetAddPicture");
    }
    
    # verify the required parameter 'file' is set
    #unless (exists $args{'file'}) {
     # croak("Missing the required parameter 'file' when calling PutWorksheetAddPicture");
    #}
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/?appSid={appSid}&amp;upperLeftRow={upperLeftRow}&amp;upperLeftColumn={upperLeftColumn}&amp;lowerRightRow={lowerRightRow}&amp;lowerRightColumn={lowerRightColumn}&amp;picturePath={picturePath}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftRow'}) {        		
		$_resource_path =~ s/\Q{upperLeftRow}\E/$args{'upperLeftRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'upperLeftColumn'}) {        		
		$_resource_path =~ s/\Q{upperLeftColumn}\E/$args{'upperLeftColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]upperLeftColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lowerRightRow'}) {        		
		$_resource_path =~ s/\Q{lowerRightRow}\E/$args{'lowerRightRow'}/g;
    }else{
		$_resource_path    =~ s/[?&]lowerRightRow.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'lowerRightColumn'}) {        		
		$_resource_path =~ s/\Q{lowerRightColumn}\E/$args{'lowerRightColumn'}/g;
    }else{
		$_resource_path    =~ s/[?&]lowerRightColumn.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'picturePath'}) {        		
		$_resource_path =~ s/\Q{picturePath}\E/$args{'picturePath'}/g;
    }else{
		$_resource_path    =~ s/[?&]picturePath.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PicturesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkSheetPicture
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pictureIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Picture $body  (required)
# @return PictureResponse
#
sub PostWorkSheetPicture {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkSheetPicture");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorkSheetPicture");
    }
    
    # verify the required parameter 'pictureIndex' is set
    unless (exists $args{'pictureIndex'}) {
      croak("Missing the required parameter 'pictureIndex' when calling PostWorkSheetPicture");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorkSheetPicture");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/{pictureIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pictureIndex'}) {        		
		$_resource_path =~ s/\Q{pictureIndex}\E/$args{'pictureIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pictureIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PictureResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetPicture
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pictureIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetPicture {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetPicture");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetPicture");
    }
    
    # verify the required parameter 'pictureIndex' is set
    unless (exists $args{'pictureIndex'}) {
      croak("Missing the required parameter 'pictureIndex' when calling DeleteWorksheetPicture");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/{pictureIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pictureIndex'}) {        		
		$_resource_path =~ s/\Q{pictureIndex}\E/$args{'pictureIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pictureIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetPicture
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pictureNumber  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetPicture {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetPicture");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetPicture");
    }
    
    # verify the required parameter 'pictureNumber' is set
    unless (exists $args{'pictureNumber'}) {
      croak("Missing the required parameter 'pictureNumber' when calling GetWorksheetPicture");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/{pictureNumber}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pictureNumber'}) {        		
		$_resource_path =~ s/\Q{pictureNumber}\E/$args{'pictureNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]pictureNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PictureResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetPictureWithFormat
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pictureNumber  (required)
# @param String $format  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ResponseMessage
#
sub GetWorksheetPictureWithFormat {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetPictureWithFormat");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetPictureWithFormat");
    }
    
    # verify the required parameter 'pictureNumber' is set
    unless (exists $args{'pictureNumber'}) {
      croak("Missing the required parameter 'pictureNumber' when calling GetWorksheetPictureWithFormat");
    }
    
    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling GetWorksheetPictureWithFormat");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/{pictureNumber}/?appSid={appSid}&amp;toFormat={toFormat}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pictureNumber'}) {        		
		$_resource_path =~ s/\Q{pictureNumber}\E/$args{'pictureNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]pictureNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetExtractBarcodes
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pictureNumber  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return BarcodeResponseList
#
sub GetExtractBarcodes {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetExtractBarcodes");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetExtractBarcodes");
    }
    
    # verify the required parameter 'pictureNumber' is set
    unless (exists $args{'pictureNumber'}) {
      croak("Missing the required parameter 'pictureNumber' when calling GetExtractBarcodes");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pictures/{pictureNumber}/recognize/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pictureNumber'}) {        		
		$_resource_path =~ s/\Q{pictureNumber}\E/$args{'pictureNumber'}/g;
    }else{
		$_resource_path    =~ s/[?&]pictureNumber.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'BarcodeResponseList', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetPivotTables
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return PivotTablesResponse
#
sub GetWorksheetPivotTables {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetPivotTables");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetPivotTables");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PivotTablesResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetPivotTables
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetPivotTables {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetPivotTables");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetPivotTables");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorksheetPivotTable
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param String $sourceData  (optional)
# @param String $destCellName  (optional)
# @param String $tableName  (optional)
# @param Boolean $useSameSource  (optional)
# @param CreatePivotTableRequest $body  (required)
# @return PivotTableResponse
#
sub PutWorksheetPivotTable {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorksheetPivotTable");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorksheetPivotTable");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutWorksheetPivotTable");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}&amp;sourceData={sourceData}&amp;destCellName={destCellName}&amp;tableName={tableName}&amp;useSameSource={useSameSource}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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
    if ( exists $args{'sourceData'}) {        		
		$_resource_path =~ s/\Q{sourceData}\E/$args{'sourceData'}/g;
    }else{
		$_resource_path    =~ s/[?&]sourceData.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destCellName'}) {        		
		$_resource_path =~ s/\Q{destCellName}\E/$args{'destCellName'}/g;
    }else{
		$_resource_path    =~ s/[?&]destCellName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'tableName'}) {        		
		$_resource_path =~ s/\Q{tableName}\E/$args{'tableName'}/g;
    }else{
		$_resource_path    =~ s/[?&]tableName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'useSameSource'}) {        		
		$_resource_path =~ s/\Q{useSameSource}\E/$args{'useSameSource'}/g;
    }else{
		$_resource_path    =~ s/[?&]useSameSource.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PivotTableResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorksheetPivotTable
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteWorksheetPivotTable {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorksheetPivotTable");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorksheetPivotTable");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling DeleteWorksheetPivotTable");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetPivotTableCalculate
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub PostWorksheetPivotTableCalculate {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetPivotTableCalculate");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetPivotTableCalculate");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling PostWorksheetPivotTableCalculate");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/Calculate/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostPivotTableCellStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $column  (required)
# @param String $row  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return SaaSposeResponse
#
sub PostPivotTableCellStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostPivotTableCellStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostPivotTableCellStyle");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling PostPivotTableCellStyle");
    }
    
    # verify the required parameter 'column' is set
    unless (exists $args{'column'}) {
      croak("Missing the required parameter 'column' when calling PostPivotTableCellStyle");
    }
    
    # verify the required parameter 'row' is set
    unless (exists $args{'row'}) {
      croak("Missing the required parameter 'row' when calling PostPivotTableCellStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostPivotTableCellStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/Format/?column={column}&amp;row={row}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'column'}) {        		
		$_resource_path =~ s/\Q{column}\E/$args{'column'}/g;
    }else{
		$_resource_path    =~ s/[?&]column.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'row'}) {        		
		$_resource_path =~ s/\Q{row}\E/$args{'row'}/g;
    }else{
		$_resource_path    =~ s/[?&]row.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostPivotTableStyle
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param Style $body  (required)
# @return SaaSposeResponse
#
sub PostPivotTableStyle {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostPivotTableStyle");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostPivotTableStyle");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling PostPivotTableStyle");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostPivotTableStyle");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/FormatAll/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetPivotTableField
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $pivotFieldIndex  (required)
# @param String $pivotFieldType  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return PivotFieldResponse
#
sub GetPivotTableField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetPivotTableField");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetPivotTableField");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling GetPivotTableField");
    }
    
    # verify the required parameter 'pivotFieldIndex' is set
    unless (exists $args{'pivotFieldIndex'}) {
      croak("Missing the required parameter 'pivotFieldIndex' when calling GetPivotTableField");
    }
    
    # verify the required parameter 'pivotFieldType' is set
    unless (exists $args{'pivotFieldType'}) {
      croak("Missing the required parameter 'pivotFieldType' when calling GetPivotTableField");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/?pivotFieldIndex={pivotFieldIndex}&amp;pivotFieldType={pivotFieldType}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotFieldIndex'}) {        		
		$_resource_path =~ s/\Q{pivotFieldIndex}\E/$args{'pivotFieldIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotFieldIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotFieldType'}) {        		
		$_resource_path =~ s/\Q{pivotFieldType}\E/$args{'pivotFieldType'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotFieldType.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PivotFieldResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutPivotTableField
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $pivotFieldType  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param PivotTableFieldRequest $body  (required)
# @return SaaSposeResponse
#
sub PutPivotTableField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutPivotTableField");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutPivotTableField");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling PutPivotTableField");
    }
    
    # verify the required parameter 'pivotFieldType' is set
    unless (exists $args{'pivotFieldType'}) {
      croak("Missing the required parameter 'pivotFieldType' when calling PutPivotTableField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutPivotTableField");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/?pivotFieldType={pivotFieldType}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotFieldType'}) {        		
		$_resource_path =~ s/\Q{pivotFieldType}\E/$args{'pivotFieldType'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotFieldType.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeletePivotTableField
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivotTableIndex  (required)
# @param String $pivotFieldType  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param PivotTableFieldRequest $body  (required)
# @return SaaSposeResponse
#
sub DeletePivotTableField {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeletePivotTableField");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeletePivotTableField");
    }
    
    # verify the required parameter 'pivotTableIndex' is set
    unless (exists $args{'pivotTableIndex'}) {
      croak("Missing the required parameter 'pivotTableIndex' when calling DeletePivotTableField");
    }
    
    # verify the required parameter 'pivotFieldType' is set
    unless (exists $args{'pivotFieldType'}) {
      croak("Missing the required parameter 'pivotFieldType' when calling DeletePivotTableField");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling DeletePivotTableField");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/?pivotFieldType={pivotFieldType}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotTableIndex'}) {        		
		$_resource_path =~ s/\Q{pivotTableIndex}\E/$args{'pivotTableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotTableIndex.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivotFieldType'}) {        		
		$_resource_path =~ s/\Q{pivotFieldType}\E/$args{'pivotFieldType'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivotFieldType.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorksheetPivotTable
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $pivottableIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return PivotTableResponse
#
sub GetWorksheetPivotTable {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorksheetPivotTable");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorksheetPivotTable");
    }
    
    # verify the required parameter 'pivottableIndex' is set
    unless (exists $args{'pivottableIndex'}) {
      croak("Missing the required parameter 'pivottableIndex' when calling GetWorksheetPivotTable");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/pivottables/{pivottableIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'pivottableIndex'}) {        		
		$_resource_path =~ s/\Q{pivottableIndex}\E/$args{'pivottableIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]pivottableIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'PivotTableResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostMoveWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param WorksheetMovingRequest $body  (required)
# @return WorksheetsResponse
#
sub PostMoveWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostMoveWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostMoveWorksheet");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostMoveWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/position/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutProtectWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ProtectSheetParameter $body  (required)
# @return WorksheetResponse
#
sub PutProtectWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutProtectWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutProtectWorksheet");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutProtectWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/protection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteUnprotectWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param ProtectSheetParameter $body  (required)
# @return WorksheetResponse
#
sub DeleteUnprotectWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteUnprotectWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteUnprotectWorksheet");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling DeleteUnprotectWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/protection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostRenameWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $newname  (required)
# @param String $folder  (optional)
# @param String $storage  (optional)
# @return SaaSposeResponse
#
sub PostRenameWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostRenameWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostRenameWorksheet");
    }
    
    # verify the required parameter 'newname' is set
    unless (exists $args{'newname'}) {
      croak("Missing the required parameter 'newname' when calling PostRenameWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/rename/?newname={newname}&amp;appSid={appSid}&amp;folder={folder}&amp;storage={storage}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newname'}) {        		
		$_resource_path =~ s/\Q{newname}\E/$args{'newname'}/g;
    }else{
		$_resource_path    =~ s/[?&]newname.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorsheetTextReplace
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $oldValue  (required)
# @param String $newValue  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorksheetReplaceResponse
#
sub PostWorsheetTextReplace {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorsheetTextReplace");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorsheetTextReplace");
    }
    
    # verify the required parameter 'oldValue' is set
    unless (exists $args{'oldValue'}) {
      croak("Missing the required parameter 'oldValue' when calling PostWorsheetTextReplace");
    }
    
    # verify the required parameter 'newValue' is set
    unless (exists $args{'newValue'}) {
      croak("Missing the required parameter 'newValue' when calling PostWorsheetTextReplace");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/replaceText/?oldValue={oldValue}&amp;newValue={newValue}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetReplaceResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorksheetRangeSort
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $cellArea  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param DataSorter $body  (required)
# @return SaaSposeResponse
#
sub PostWorksheetRangeSort {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorksheetRangeSort");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorksheetRangeSort");
    }
    
    # verify the required parameter 'cellArea' is set
    unless (exists $args{'cellArea'}) {
      croak("Missing the required parameter 'cellArea' when calling PostWorksheetRangeSort");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PostWorksheetRangeSort");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/sort/?cellArea={cellArea}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'cellArea'}) {        		
		$_resource_path =~ s/\Q{cellArea}\E/$args{'cellArea'}/g;
    }else{
		$_resource_path    =~ s/[?&]cellArea.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetTextItems
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return TextItemsResponse
#
sub GetWorkSheetTextItems {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetTextItems");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetTextItems");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/textItems/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'TextItemsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutWorkSheetValidation
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $range  (optional)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return ValidationResponse
#
sub PutWorkSheetValidation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutWorkSheetValidation");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutWorkSheetValidation");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutWorkSheetValidation");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/validations/?appSid={appSid}&amp;range={range}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'range'}) {        		
		$_resource_path =~ s/\Q{range}\E/$args{'range'}/g;
    }else{
		$_resource_path    =~ s/[?&]range.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ValidationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetValidations
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ValidationsResponse
#
sub GetWorkSheetValidations {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetValidations");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetValidations");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/validations/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ValidationsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetWorkSheetValidation
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $validationIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ValidationResponse
#
sub GetWorkSheetValidation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetWorkSheetValidation");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling GetWorkSheetValidation");
    }
    
    # verify the required parameter 'validationIndex' is set
    unless (exists $args{'validationIndex'}) {
      croak("Missing the required parameter 'validationIndex' when calling GetWorkSheetValidation");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/validations/{validationIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'validationIndex'}) {        		
		$_resource_path =~ s/\Q{validationIndex}\E/$args{'validationIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]validationIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ValidationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostWorkSheetValidation
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $validationIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param File $file  (required)
# @return ValidationResponse
#
sub PostWorkSheetValidation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PostWorkSheetValidation");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PostWorkSheetValidation");
    }
    
    # verify the required parameter 'validationIndex' is set
    unless (exists $args{'validationIndex'}) {
      croak("Missing the required parameter 'validationIndex' when calling PostWorkSheetValidation");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PostWorkSheetValidation");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/validations/{validationIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'validationIndex'}) {        		
		$_resource_path =~ s/\Q{validationIndex}\E/$args{'validationIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]validationIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ValidationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteWorkSheetValidation
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param String $validationIndex  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return ValidationResponse
#
sub DeleteWorkSheetValidation {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteWorkSheetValidation");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling DeleteWorkSheetValidation");
    }
    
    # verify the required parameter 'validationIndex' is set
    unless (exists $args{'validationIndex'}) {
      croak("Missing the required parameter 'validationIndex' when calling DeleteWorkSheetValidation");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/validations/{validationIndex}/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'validationIndex'}) {        		
		$_resource_path =~ s/\Q{validationIndex}\E/$args{'validationIndex'}/g;
    }else{
		$_resource_path    =~ s/[?&]validationIndex.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ValidationResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutChangeVisibilityWorksheet
#
# 
# 
# @param String $name  (required)
# @param String $sheetName  (required)
# @param Boolean $isVisible  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return WorksheetResponse
#
sub PutChangeVisibilityWorksheet {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutChangeVisibilityWorksheet");
    }
    
    # verify the required parameter 'sheetName' is set
    unless (exists $args{'sheetName'}) {
      croak("Missing the required parameter 'sheetName' when calling PutChangeVisibilityWorksheet");
    }
    
    # verify the required parameter 'isVisible' is set
    unless (exists $args{'isVisible'}) {
      croak("Missing the required parameter 'isVisible' when calling PutChangeVisibilityWorksheet");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/worksheets/{sheetName}/visible/?isVisible={isVisible}&amp;appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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
    if ( exists $args{'sheetName'}) {        		
		$_resource_path =~ s/\Q{sheetName}\E/$args{'sheetName'}/g;
    }else{
		$_resource_path    =~ s/[?&]sheetName.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'isVisible'}) {        		
		$_resource_path =~ s/\Q{isVisible}\E/$args{'isVisible'}/g;
    }else{
		$_resource_path    =~ s/[?&]isVisible.*?(?=&|\?|$)//g;
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'WorksheetResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutDocumentProtectFromChanges
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @param PasswordRequest $body  (required)
# @return SaaSposeResponse
#
sub PutDocumentProtectFromChanges {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling PutDocumentProtectFromChanges");
    }
    
    # verify the required parameter 'body' is set
    unless (exists $args{'body'}) {
      croak("Missing the required parameter 'body' when calling PutDocumentProtectFromChanges");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/writeProtection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteDocumentUnProtectFromChanges
#
# 
# 
# @param String $name  (required)
# @param String $storage  (optional)
# @param String $folder  (optional)
# @return SaaSposeResponse
#
sub DeleteDocumentUnProtectFromChanges {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling DeleteDocumentUnProtectFromChanges");
    }
    

    # parse inputs
    my $_resource_path = '/cells/{name}/writeProtection/?appSid={appSid}&amp;storage={storage}&amp;folder={folder}';
    
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

	if($AsposeCellsCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'SaaSposeResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
