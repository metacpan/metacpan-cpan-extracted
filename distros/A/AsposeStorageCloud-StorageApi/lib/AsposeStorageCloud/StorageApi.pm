package AsposeStorageCloud::StorageApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use File::Slurp;

use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;

my $VERSION = '1.02';

sub new {
    my $class   = shift;
    my $default_api_client = $AsposeStorageCloud::Configuration::api_client ? $AsposeStorageCloud::Configuration::api_client  :
	AsposeStorageCloud::ApiClient->new;
    my (%self) = (
        'api_client' => $default_api_client,
        @_
    );

    bless \%self, $class;

}

#
# GetDiscUsage
#
# Check the disk usage of the current account. Parameters: storage - user's storage name.
# 
# @param string $storage  (optional)
# @return DiscUsageResponse
#
sub GetDiscUsage {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/storage/disc/?appSid={appSid}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'DiscUsageResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetIsExist
#
# Check if a specific file or folder exists. Parameters: path - file or folder path e.g. /file.ext or /Folder1, versionID - file's version, storage - user's storage name.
# 
# @param string $Path  (required)
# @param string $versionId  (optional)
# @param string $storage  (optional)
# @return FileExistResponse
#
sub GetIsExist {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling GetIsExist");
    }
    

    # parse inputs
    my $_resource_path = '/storage/exist/{path}/?appSid={appSid}&amp;versionId={versionId}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FileExistResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutCopy
#
# Copy a specific file. Parameters: path - source file path e.g. /file.ext, versionID - source file's version, storage - user's source storage name, newdest - destination file path, destStorage - user's destination storage name.
# 
# @param string $Path  (required)
# @param string $newdest  (required)
# @param file $file  (required)
# @param string $versionId  (optional)
# @param string $storage  (optional)
# @param string $destStorage  (optional)
# @return ResponseMessage
#
sub PutCopy {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling PutCopy");
    }
    
    # verify the required parameter 'newdest' is set
    unless (exists $args{'newdest'}) {
      croak("Missing the required parameter 'newdest' when calling PutCopy");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutCopy");
    }
    

    # parse inputs
    my $_resource_path = '/storage/file/{path}/?appSid={appSid}&amp;newdest={newdest}&amp;versionId={versionId}&amp;storage={storage}&amp;destStorage={destStorage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newdest'}) {        		
		$_resource_path =~ s/\Q{newdest}\E/$args{'newdest'}/g;
    }else{
		$_resource_path    =~ s/[?&]newdest.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destStorage'}) {        		
		$_resource_path =~ s/\Q{destStorage}\E/$args{'destStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]destStorage.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetDownload
#
# Download a specific file. Parameters: path - file path e.g. /file.ext, versionID - file's version, storage - user's storage name.
# 
# @param string $Path  (required)
# @param string $versionId  (optional)
# @param string $storage  (optional)
# @return ResponseMessage
#
sub GetDownload {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling GetDownload");
    }
    

    # parse inputs
    my $_resource_path = '/storage/file/{path}/?appSid={appSid}&amp;versionId={versionId}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutCreate
#
# Upload a specific file. Parameters: path - source file path e.g. /file.ext, versionID - source file's version, storage - user's source storage name, newdest - destination file path, destStorage - user's destination storage name.
# 
# @param string $Path  (required)
# @param file $file  (required)
# @param string $versionId  (optional)
# @param string $storage  (optional)
# @return ResponseMessage
#
sub PutCreate {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling PutCreate");
    }
    
    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling PutCreate");
    }
    

    # parse inputs
    my $_resource_path = '/storage/file/{path}/?appSid={appSid}&amp;versionId={versionId}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteFile
#
# Remove a specific file. Parameters: path - file path e.g. /file.ext, versionID - file's version, storage - user's storage name.
# 
# @param string $Path  (required)
# @param string $versionId  (optional)
# @param string $storage  (optional)
# @return RemoveFileResponse
#
sub DeleteFile {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling DeleteFile");
    }
    

    # parse inputs
    my $_resource_path = '/storage/file/{path}/?appSid={appSid}&amp;versionId={versionId}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RemoveFileResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostMoveFile
#
# Move a specific file.
# 
# @param string $src source file path e.g. /file.ext (required)
# @param string $dest  (required)
# @param string $versionId source file&#39;s version, (optional)
# @param string $storage user&#39;s source storage name (optional)
# @param string $destStorage user&#39;s destination storage name (optional)
# @return MoveFileResponse
#
sub PostMoveFile {
    my ($self, %args) = @_;

    
    # verify the required parameter 'src' is set
    unless (exists $args{'src'}) {
      croak("Missing the required parameter 'src' when calling PostMoveFile");
    }
    
    # verify the required parameter 'dest' is set
    unless (exists $args{'dest'}) {
      croak("Missing the required parameter 'dest' when calling PostMoveFile");
    }
    

    # parse inputs
    my $_resource_path = '/storage/file/{src}/?dest={dest}&amp;appSid={appSid}&amp;versionId={versionId}&amp;storage={storage}&amp;destStorage={destStorage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'src'}) {        		
		$_resource_path =~ s/\Q{src}\E/$args{'src'}/g;
    }else{
		$_resource_path    =~ s/[?&]src.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dest'}) {        		
		$_resource_path =~ s/\Q{dest}\E/$args{'dest'}/g;
    }else{
		$_resource_path    =~ s/[?&]dest.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'versionId'}) {        		
		$_resource_path =~ s/\Q{versionId}\E/$args{'versionId'}/g;
    }else{
		$_resource_path    =~ s/[?&]versionId.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destStorage'}) {        		
		$_resource_path =~ s/\Q{destStorage}\E/$args{'destStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]destStorage.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'MoveFileResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutCopyFolder
#
# Copy a folder. Parameters: path - source folder path e.g. /Folder1, storage - user's source storage name, newdest - destination folder path e.g. /Folder2, destStorage - user's destination storage name.
# 
# @param string $Path  (required)
# @param string $newdest  (required)
# @param string $storage  (optional)
# @param string $destStorage  (optional)
# @return ResponseMessage
#
sub PutCopyFolder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling PutCopyFolder");
    }
    
    # verify the required parameter 'newdest' is set
    unless (exists $args{'newdest'}) {
      croak("Missing the required parameter 'newdest' when calling PutCopyFolder");
    }
    

    # parse inputs
    my $_resource_path = '/storage/folder/{path}/?appSid={appSid}&amp;newdest={newdest}&amp;storage={storage}&amp;destStorage={destStorage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'newdest'}) {        		
		$_resource_path =~ s/\Q{newdest}\E/$args{'newdest'}/g;
    }else{
		$_resource_path    =~ s/[?&]newdest.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destStorage'}) {        		
		$_resource_path =~ s/\Q{destStorage}\E/$args{'destStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]destStorage.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetListFiles
#
# Get the file listing of a specific folder. Parametres: path - start with name of storage e.g. root folder '/'or some folder '/folder1/..', storage - user's storage name.
# 
# @param string $Path  (optional)
# @param string $storage  (optional)
# @return ResponseMessage
#
sub GetListFiles {
    my ($self, %args) = @_;

    

    # parse inputs
    my $_resource_path = '/storage/folder/{path}/?appSid={appSid}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# PutCreateFolder
#
# Create the folder. Parameters: path - source folder path e.g. /Folder1, storage - user's source storage name, newdest - destination folder path e.g. /Folder2, destStorage - user's destination storage name.
# 
# @param string $Path  (required)
# @param string $storage  (optional)
# @param string $destStorage  (optional)
# @return ResponseMessage
#
sub PutCreateFolder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling PutCreateFolder");
    }
    

    # parse inputs
    my $_resource_path = '/storage/folder/{path}/?appSid={appSid}&amp;storage={storage}&amp;destStorage={destStorage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destStorage'}) {        		
		$_resource_path =~ s/\Q{destStorage}\E/$args{'destStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]destStorage.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'ResponseMessage', $response->header('content-type'));
    return $_response_object;
    
}
#
# DeleteFolder
#
# Remove a specific folder. Parameters: path - folder path e.g. /Folder1, storage - user's storage name, recursive - is subfolders and files must be deleted for specified path.
# 
# @param string $Path  (required)
# @param string $storage  (optional)
# @param boolean $recursive  (optional)
# @return RemoveFolderResponse
#
sub DeleteFolder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling DeleteFolder");
    }
    

    # parse inputs
    my $_resource_path = '/storage/folder/{path}/?appSid={appSid}&amp;storage={storage}&amp;recursive={recursive}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'recursive'}) {        		
		$_resource_path =~ s/\Q{recursive}\E/$args{'recursive'}/g;
    }else{
		$_resource_path    =~ s/[?&]recursive.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'RemoveFolderResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# PostMoveFolder
#
# Move a specific folder. Parameters: src - source folder path e.g. /Folder1, storage - user's source storage name, dest - destination folder path e.g. /Folder2, destStorage - user's destination storage name.
# 
# @param string $src  (required)
# @param string $dest  (required)
# @param string $storage  (optional)
# @param string $destStorage  (optional)
# @return MoveFolderResponse
#
sub PostMoveFolder {
    my ($self, %args) = @_;

    
    # verify the required parameter 'src' is set
    unless (exists $args{'src'}) {
      croak("Missing the required parameter 'src' when calling PostMoveFolder");
    }
    
    # verify the required parameter 'dest' is set
    unless (exists $args{'dest'}) {
      croak("Missing the required parameter 'dest' when calling PostMoveFolder");
    }
    

    # parse inputs
    my $_resource_path = '/storage/folder/{src}/?dest={dest}&amp;appSid={appSid}&amp;storage={storage}&amp;destStorage={destStorage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'src'}) {        		
		$_resource_path =~ s/\Q{src}\E/$args{'src'}/g;
    }else{
		$_resource_path    =~ s/[?&]src.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'dest'}) {        		
		$_resource_path =~ s/\Q{dest}\E/$args{'dest'}/g;
    }else{
		$_resource_path    =~ s/[?&]dest.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'storage'}) {        		
		$_resource_path =~ s/\Q{storage}\E/$args{'storage'}/g;
    }else{
		$_resource_path    =~ s/[?&]storage.*?(?=&|\?|$)//g;
	}# query params
    if ( exists $args{'destStorage'}) {        		
		$_resource_path =~ s/\Q{destStorage}\E/$args{'destStorage'}/g;
    }else{
		$_resource_path    =~ s/[?&]destStorage.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'MoveFolderResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetListFileVersions
#
# Get the file's versions list. Parameters: path - file path e.g. /file.ext or /Folder1/file.ext, storage - user's storage name.
# 
# @param string $Path  (required)
# @param string $storage  (optional)
# @return FileVersionsResponse
#
sub GetListFileVersions {
    my ($self, %args) = @_;

    
    # verify the required parameter 'Path' is set
    unless (exists $args{'Path'}) {
      croak("Missing the required parameter 'Path' when calling GetListFileVersions");
    }
    

    # parse inputs
    my $_resource_path = '/storage/version/{path}/?appSid={appSid}&amp;storage={storage}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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
    if ( exists $args{'Path'}) {        		
		$_resource_path =~ s/\Q{Path}\E/$args{'Path'}/g;
    }else{
		$_resource_path    =~ s/[?&]Path.*?(?=&|\?|$)//g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'FileVersionsResponse', $response->header('content-type'));
    return $_response_object;
    
}
#
# GetIsStorageExist
#
# Check if a specific storage exists.
# 
# @param string $name Storage name (required)
# @return StorageExistResponse
#
sub GetIsStorageExist {
    my ($self, %args) = @_;

    
    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling GetIsStorageExist");
    }
    

    # parse inputs
    my $_resource_path = '/storage/{name}/exist/?appSid={appSid}';
    
	$_resource_path =~ s/\Q&amp;\E/&/g;
    $_resource_path =~ s/\Q\/?\E/?/g;
    $_resource_path =~ s/\QtoFormat={toFormat}\E/format={format}"/g;
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

	if($AsposeStorageCloud::Configuration::debug){
		print "\nResponse Content: ".$response->content;
	}    
	
	my $_response_object = $self->{api_client}->pre_deserialize($response->content, 'StorageExistResponse', $response->header('content-type'));
    return $_response_object;
    
}


1;
