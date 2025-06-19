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


package AsposeCellsCloud::CellsApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use AsposeCellsCloud::ApiClient;

use base "Class::Data::Inheritable";

__PACKAGE__->mk_classdata('method_documentation' => {});

sub new {
    my $class = shift;
    my $api_client;

    if ($_[0] && ref $_[0] && ref $_[0] eq 'AsposeCellsCloud::ApiClient' ) {
        $api_client = $_[0];
    } else {
        $api_client = AsposeCellsCloud::ApiClient->new(@_);
    }

    if($api_client->need_auth()){
        my $access_token  =  $api_client->o_auth_post('grant_type' => "client_credentials", 'client_id' => $api_client->{config}->{client_id}, 'client_secret' =>$api_client->{config}->{client_secret})->access_token;
        $api_client->{config}->{access_token} = $access_token;
    }

    bless { api_client => $api_client }, $class;

}

#
# PostAccessTokenRequest
#
# Get Access Token Result: The Cells Cloud Get Token API acts as a proxy service,forwarding user requests to the Aspose Cloud authentication server and returning the resulting access token to the client.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAccessTokenRequest',
            description => 'PostAccessToken Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_access_token' } = { 
    	summary => 'Get Access Token Result: The Cells Cloud Get Token API acts as a proxy service,forwarding user requests to the Aspose Cloud authentication server and returning the resulting access token to the client.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_access_token{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# GetAsposeCellsCloudStatusRequest
#
# Check the Health Status of Aspose.Cells Cloud Service.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'GetAsposeCellsCloudStatusRequest',
            description => 'GetAsposeCellsCloudStatus Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_aspose_cells_cloud_status' } = { 
    	summary => 'Check the Health Status of Aspose.Cells Cloud Service.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_aspose_cells_cloud_status{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# CheckCloudServiceHealthRequest
#
# Check the Health Status of Aspose.Cells Cloud Service.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'CheckCloudServiceHealthRequest',
            description => 'CheckCloudServiceHealth Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'check_cloud_service_health' } = { 
    	summary => 'Check the Health Status of Aspose.Cells Cloud Service.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub check_cloud_service_health{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ExportSpreadsheetAsFormatRequest
#
# Converts a spreadsheet in cloud storage to the specified format.
# 
# @name  string (required)  (Required) The name of the workbook file to be retrieved.  
# @format  string (required)  (Required) The desired output format (e.g., "Xlsx", "Pdf", "Csv").  
# @folder  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ExportSpreadsheetAsFormatRequest',
            description => 'ExportSpreadsheetAsFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'export_spreadsheet_as_format' } = { 
    	summary => 'Converts a spreadsheet in cloud storage to the specified format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub export_spreadsheet_as_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ExportChartAsFormatRequest
#
# Converts a chart of spreadsheet in cloud storage to the specified format.
# 
# @name  string (required)  (Required) The name of the workbook file to be retrieved.  
# @worksheet  string (required)    
# @chartIndex  int (required)    
# @format  string (required)  (Required) The desired pdf or image format  (e.g., "png", "Pdf", "svg").  
# @folder  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ExportChartAsFormatRequest',
            description => 'ExportChartAsFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'export_chart_as_format' } = { 
    	summary => 'Converts a chart of spreadsheet in cloud storage to the specified format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub export_chart_as_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ConvertSpreadsheetRequest
#
# Converts a spreadsheet on a local drive to the specified format.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @format  string (required)  (Required) The desired output format (e.g., "Xlsx", "Pdf", "Csv").  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ConvertSpreadsheetRequest',
            description => 'ConvertSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'convert_spreadsheet' } = { 
    	summary => 'Converts a spreadsheet on a local drive to the specified format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub convert_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ConvertChartToImageRequest
#
# Converts a chart of spreadsheet on a local drive to image.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @worksheet  string (required)    
# @chartIndex  int (required)    
# @format  string (required)  (Required) The desired image type (e.g., svg, png, jpg).  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ConvertChartToImageRequest',
            description => 'ConvertChartToImage Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'convert_chart_to_image' } = { 
    	summary => 'Converts a chart of spreadsheet on a local drive to image.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub convert_chart_to_image{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ConvertChartToPdfRequest
#
# Converts a chart of spreadsheet on a local drive to pdf.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @worksheet  string (required)    
# @chartIndex  int (required)    
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ConvertChartToPdfRequest',
            description => 'ConvertChartToPdf Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'convert_chart_to_pdf' } = { 
    	summary => 'Converts a chart of spreadsheet on a local drive to pdf.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub convert_chart_to_pdf{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# SaveSpreadsheetAsRequest
#
# Converts a spreadsheet in cloud storage to the specified format.
# 
# @name  string (required)  (Required) The name of the workbook file to be converted.  
# @format  string (required)  (Required) The desired output format (e.g., "Xlsx", "Pdf", "Csv").  
# @saveOptionsData  SaveOptionsData   (Optional) Save options data. The default is null.  
# @folder  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SaveSpreadsheetAsRequest',
            description => 'SaveSpreadsheetAs Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'save_spreadsheet_as' } = { 
    	summary => 'Converts a spreadsheet in cloud storage to the specified format.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub save_spreadsheet_as{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# MergeSpreadsheetsRequest
#
# Merge local spreadsheet files into a specified format file.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @outFormat  string   The out file format.  
# @mergeInOneSheet  boolean   Whether to combine all data into a single worksheet.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'MergeSpreadsheetsRequest',
            description => 'MergeSpreadsheets Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'merge_spreadsheets' } = { 
    	summary => 'Merge local spreadsheet files into a specified format file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub merge_spreadsheets{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# MergeSpreadsheetsInRemoteFolderRequest
#
# Merge spreadsheet files in folder of cloud storage into a specified format file.
# 
# @folder  string (required)  The folder used to store the merged files.  
# @fileMatchExpression  string     
# @outFormat  string   The out file format.  
# @mergeInOneSheet  boolean   Whether to combine all data into a single worksheet.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'MergeSpreadsheetsInRemoteFolderRequest',
            description => 'MergeSpreadsheetsInRemoteFolder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'merge_spreadsheets_in_remote_folder' } = { 
    	summary => 'Merge spreadsheet files in folder of cloud storage into a specified format file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub merge_spreadsheets_in_remote_folder{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# MergeRemoteSpreadsheetRequest
#
# Merge a spreadsheet file into other spreadsheet in cloud storage, and output a specified format file.
# 
# @name  string (required)  The name of the workbook file to be split.  
# @mergedSpreadsheet  string (required)    
# @folder  string   The folder path where the workbook is stored.  
# @outFormat  string   The out file format.  
# @mergeInOneSheet  boolean   Whether to combine all data into a single worksheet.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'MergeRemoteSpreadsheetRequest',
            description => 'MergeRemoteSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'merge_remote_spreadsheet' } = { 
    	summary => 'Merge a spreadsheet file into other spreadsheet in cloud storage, and output a specified format file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub merge_remote_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# SplitSpreadsheetRequest
#
# Split a local spreadsheet into the specified format, multi-file.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @from  int   Begin worksheet index.  
# @to  int   End worksheet index.  
# @outFormat  string   The out file format.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SplitSpreadsheetRequest',
            description => 'SplitSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'split_spreadsheet' } = { 
    	summary => 'Split a local spreadsheet into the specified format, multi-file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub split_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# SplitRemoteSpreadsheetRequest
#
# Split a spreadsheet in cloud storage into the specified format, multi-file.
# 
# @name  string (required)  The name of the workbook file to be split.  
# @folder  string   The folder path where the workbook is stored.  
# @from  int   Begin worksheet index.  
# @to  int   End worksheet index.  
# @outFormat  string   The desired output format (e.g., "Xlsx", "Pdf", "Csv").  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @fontsLocation  string   Use Custom fonts.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SplitRemoteSpreadsheetRequest',
            description => 'SplitRemoteSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'split_remote_spreadsheet' } = { 
    	summary => 'Split a spreadsheet in cloud storage into the specified format, multi-file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub split_remote_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# GetPublicKeyRequest
#
# Get an asymmetric public key.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'GetPublicKeyRequest',
            description => 'GetPublicKey Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_public_key' } = { 
    	summary => 'Get an asymmetric public key.',
        params => $params,
        returns => 'CellsCloudPublicKeyResponse',
    };
}
#
# @return CellsCloudPublicKeyResponse
#
sub get_public_key{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudPublicKeyResponse', $response);
    return $_response_object;
}

#
# SearchSpreadsheetContentRequest
#
# Search text in the local spreadsheet.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @searchText  string (required)  The searched text.  
# @ignoringCase  boolean   Ignore the text of the search.  
# @worksheet  string   Specify the worksheet for the lookup.  
# @cellArea  string   Specify the cell area for the lookup  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchSpreadsheetContentRequest',
            description => 'SearchSpreadsheetContent Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_spreadsheet_content' } = { 
    	summary => 'Search text in the local spreadsheet.',
        params => $params,
        returns => 'SearchResponse',
    };
}
#
# @return SearchResponse
#
sub search_spreadsheet_content{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SearchResponse', $response);
    return $_response_object;
}

#
# SearchContentInRemoteSpreadsheetRequest
#
# Search text in the remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be search.  
# @searchText  string (required)  The searched text.  
# @ignoringCase  boolean   Ignore the text of the search.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchContentInRemoteSpreadsheetRequest',
            description => 'SearchContentInRemoteSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_content_in_remote_spreadsheet' } = { 
    	summary => 'Search text in the remoted spreadsheet.',
        params => $params,
        returns => 'SearchResponse',
    };
}
#
# @return SearchResponse
#
sub search_content_in_remote_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SearchResponse', $response);
    return $_response_object;
}

#
# SearchContentInRemoteWorksheetRequest
#
# Search text in the worksheet of remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be search.  
# @worksheet  string (required)  The name of worksheet  
# @searchText  string (required)  The searched text.  
# @ignoringCase  boolean   Ignore the text of the search.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchContentInRemoteWorksheetRequest',
            description => 'SearchContentInRemoteWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_content_in_remote_worksheet' } = { 
    	summary => 'Search text in the worksheet of remoted spreadsheet.',
        params => $params,
        returns => 'SearchResponse',
    };
}
#
# @return SearchResponse
#
sub search_content_in_remote_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SearchResponse', $response);
    return $_response_object;
}

#
# SearchContentInRemoteRangeRequest
#
# Search text in the range of remoted spreadsheet.
# 
# @name  string (required)    
# @worksheet  string (required)    
# @cellArea  string (required)    
# @searchText  string (required)    
# @ignoringCase  boolean     
# @folder  string     
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchContentInRemoteRangeRequest',
            description => 'SearchContentInRemoteRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_content_in_remote_range' } = { 
    	summary => 'Search text in the range of remoted spreadsheet.',
        params => $params,
        returns => 'SearchResponse',
    };
}
#
# @return SearchResponse
#
sub search_content_in_remote_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SearchResponse', $response);
    return $_response_object;
}

#
# ReplaceSpreadsheetContentRequest
#
# Replace text in the local spreadsheet.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @searchText  string (required)  The searched text.  
# @replaceText  string (required)  The replaced text.  
# @worksheet  string   Specify the worksheet for the replace.  
# @cellArea  string   Specify the cell area for the replace.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ReplaceSpreadsheetContentRequest',
            description => 'ReplaceSpreadsheetContent Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'replace_spreadsheet_content' } = { 
    	summary => 'Replace text in the local spreadsheet.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub replace_spreadsheet_content{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# ReplaceContentInRemoteSpreadsheetRequest
#
# Replace text in the remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be replace.  
# @searchText  string (required)  The searched text.  
# @replaceText  string (required)  The replaced text.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ReplaceContentInRemoteSpreadsheetRequest',
            description => 'ReplaceContentInRemoteSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'replace_content_in_remote_spreadsheet' } = { 
    	summary => 'Replace text in the remoted spreadsheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub replace_content_in_remote_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# ReplaceContentInRemoteWorksheetRequest
#
# Replace text in the worksheet of remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be replace.  
# @worksheet  string (required)  Specify the worksheet for the replace.  
# @searchText  string (required)  The searched text.  
# @replaceText  string (required)  The replaced text.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ReplaceContentInRemoteWorksheetRequest',
            description => 'ReplaceContentInRemoteWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'replace_content_in_remote_worksheet' } = { 
    	summary => 'Replace text in the worksheet of remoted spreadsheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub replace_content_in_remote_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# ReplaceContentInRemoteRangeRequest
#
# Replace text in the range of remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be replace.  
# @searchText  string (required)  The searched text.  
# @replaceText  string (required)  The replaced text.  
# @worksheet  string (required)  The worksheet name.  
# @cellArea  string (required)  The cell area for the replace.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'ReplaceContentInRemoteRangeRequest',
            description => 'ReplaceContentInRemoteRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'replace_content_in_remote_range' } = { 
    	summary => 'Replace text in the range of remoted spreadsheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub replace_content_in_remote_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# SearchSpreadsheetBrokenLinksRequest
#
# Search broken links in the local spreadsheet.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @worksheet  string   Specify the worksheet for the replace.  
# @cellArea  string   Specify the cell area for the replace.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchSpreadsheetBrokenLinksRequest',
            description => 'SearchSpreadsheetBrokenLinks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_spreadsheet_broken_links' } = { 
    	summary => 'Search broken links in the local spreadsheet.',
        params => $params,
        returns => 'BrokenLinksReponse',
    };
}
#
# @return BrokenLinksReponse
#
sub search_spreadsheet_broken_links{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('BrokenLinksReponse', $response);
    return $_response_object;
}

#
# SearchBrokenLinksInRemoteSpreadsheetRequest
#
# Search broken links in the remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be search.  
# @worksheet  string   Specify the worksheet for the lookup.  
# @cellArea  string   Specify the cell area for the lookup  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchBrokenLinksInRemoteSpreadsheetRequest',
            description => 'SearchBrokenLinksInRemoteSpreadsheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_broken_links_in_remote_spreadsheet' } = { 
    	summary => 'Search broken links in the remoted spreadsheet.',
        params => $params,
        returns => 'BrokenLinksReponse',
    };
}
#
# @return BrokenLinksReponse
#
sub search_broken_links_in_remote_spreadsheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('BrokenLinksReponse', $response);
    return $_response_object;
}

#
# SearchBrokenLinksInRemoteWorksheetRequest
#
# Search broken links in the worksheet of remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be search.  
# @worksheet  string (required)  Specify the worksheet for the lookup.  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchBrokenLinksInRemoteWorksheetRequest',
            description => 'SearchBrokenLinksInRemoteWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_broken_links_in_remote_worksheet' } = { 
    	summary => 'Search broken links in the worksheet of remoted spreadsheet.',
        params => $params,
        returns => 'BrokenLinksReponse',
    };
}
#
# @return BrokenLinksReponse
#
sub search_broken_links_in_remote_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('BrokenLinksReponse', $response);
    return $_response_object;
}

#
# SearchBrokenLinksInRemoteRangeRequest
#
# Search broken links in the range of remoted spreadsheet.
# 
# @name  string (required)  The name of the workbook file to be search.  
# @worksheet  string (required)  Specify the worksheet for the lookup.  
# @cellArea  string (required)  Specify the cell area for the lookup  
# @folder  string   The folder path where the workbook is stored.  
# @storageName  string   (Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SearchBrokenLinksInRemoteRangeRequest',
            description => 'SearchBrokenLinksInRemoteRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'search_broken_links_in_remote_range' } = { 
    	summary => 'Search broken links in the range of remoted spreadsheet.',
        params => $params,
        returns => 'BrokenLinksReponse',
    };
}
#
# @return BrokenLinksReponse
#
sub search_broken_links_in_remote_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('BrokenLinksReponse', $response);
    return $_response_object;
}

#
# SpecRequest
#
# Get the specifications
# 
# @version  string (required)    
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'SpecRequest',
            description => 'Spec Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'spec' } = { 
    	summary => 'Get the specifications',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub spec{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# CodegenSpecRequest
#
# 
# 
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'CodegenSpecRequest',
            description => 'CodegenSpec Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'codegen_spec' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub codegen_spec{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# DeleteSpreadsheetBlankRowsRequest
#
# Delete all blank rows which do not contain any data or other object.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteSpreadsheetBlankRowsRequest',
            description => 'DeleteSpreadsheetBlankRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_spreadsheet_blank_rows' } = { 
    	summary => 'Delete all blank rows which do not contain any data or other object.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub delete_spreadsheet_blank_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# DeleteSpreadsheetBlankColumnsRequest
#
# Delete all blank columns which do not contain any data.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteSpreadsheetBlankColumnsRequest',
            description => 'DeleteSpreadsheetBlankColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_spreadsheet_blank_columns' } = { 
    	summary => 'Delete all blank columns which do not contain any data.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub delete_spreadsheet_blank_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# DeleteSpreadsheetBlankWorksheetsRequest
#
# Delete all blank worksheets which do not contain any data or other object.
# 
# @Spreadsheet  string (required)  Upload spreadsheet file.  
# @outPath  string   (Optional) The folder path where the workbook is stored. The default is null.  
# @outStorageName  string   Output file Storage Name.  
# @regoin  string   The spreadsheet region setting.  
# @password  string   The password for opening spreadsheet file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteSpreadsheetBlankWorksheetsRequest',
            description => 'DeleteSpreadsheetBlankWorksheets Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_spreadsheet_blank_worksheets' } = { 
    	summary => 'Delete all blank worksheets which do not contain any data or other object.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub delete_spreadsheet_blank_worksheets{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# DownloadFileRequest
#
# 
# 
# @path  string (required)    
# @storageName  string     
# @versionId  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'DownloadFileRequest',
            description => 'DownloadFile Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'download_file' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub download_file{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# UploadFileRequest
#
# 
# 
# @UploadFiles  string (required)  Upload files to cloud storage.  
# @path  string (required)    
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'UploadFileRequest',
            description => 'UploadFile Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'upload_file' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesUploadResult',
    };
}
#
# @return FilesUploadResult
#
sub upload_file{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesUploadResult', $response);
    return $_response_object;
}

#
# CopyFileRequest
#
# 
# 
# @srcPath  string (required)    
# @destPath  string (required)    
# @srcStorageName  string     
# @destStorageName  string     
# @versionId  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'CopyFileRequest',
            description => 'CopyFile Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'copy_file' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub copy_file{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# MoveFileRequest
#
# 
# 
# @srcPath  string (required)    
# @destPath  string (required)    
# @srcStorageName  string     
# @destStorageName  string     
# @versionId  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'MoveFileRequest',
            description => 'MoveFile Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'move_file' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub move_file{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# DeleteFileRequest
#
# 
# 
# @path  string (required)    
# @storageName  string     
# @versionId  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteFileRequest',
            description => 'DeleteFile Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_file' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub delete_file{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# GetFilesListRequest
#
# 
# 
# @path  string     
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'GetFilesListRequest',
            description => 'GetFilesList Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_files_list' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesList',
    };
}
#
# @return FilesList
#
sub get_files_list{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesList', $response);
    return $_response_object;
}

#
# CreateFolderRequest
#
# 
# 
# @path  string (required)    
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'CreateFolderRequest',
            description => 'CreateFolder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'create_folder' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub create_folder{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# CopyFolderRequest
#
# 
# 
# @srcPath  string (required)    
# @destPath  string (required)    
# @srcStorageName  string     
# @destStorageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'CopyFolderRequest',
            description => 'CopyFolder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'copy_folder' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub copy_folder{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# MoveFolderRequest
#
# 
# 
# @srcPath  string (required)    
# @destPath  string (required)    
# @srcStorageName  string     
# @destStorageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'MoveFolderRequest',
            description => 'MoveFolder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'move_folder' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub move_folder{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# DeleteFolderRequest
#
# 
# 
# @path  string (required)    
# @storageName  string     
# @recursive  boolean      
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteFolderRequest',
            description => 'DeleteFolder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_folder' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}
#
# @return 
#
sub delete_folder{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('', $response);
    return $_response_object;
}

#
# StorageExistsRequest
#
# 
# 
# @storageName  string (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'StorageExistsRequest',
            description => 'StorageExists Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'storage_exists' } = { 
    	summary => '',
        params => $params,
        returns => 'StorageExist',
    };
}
#
# @return StorageExist
#
sub storage_exists{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('StorageExist', $response);
    return $_response_object;
}

#
# ObjectExistsRequest
#
# 
# 
# @path  string (required)    
# @storageName  string     
# @versionId  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'ObjectExistsRequest',
            description => 'ObjectExists Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'object_exists' } = { 
    	summary => '',
        params => $params,
        returns => 'ObjectExist',
    };
}
#
# @return ObjectExist
#
sub object_exists{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ObjectExist', $response);
    return $_response_object;
}

#
# GetDiscUsageRequest
#
# 
# 
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'GetDiscUsageRequest',
            description => 'GetDiscUsage Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_disc_usage' } = { 
    	summary => '',
        params => $params,
        returns => 'DiscUsage',
    };
}
#
# @return DiscUsage
#
sub get_disc_usage{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DiscUsage', $response);
    return $_response_object;
}

#
# GetFileVersionsRequest
#
# 
# 
# @path  string (required)    
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'GetFileVersionsRequest',
            description => 'GetFileVersions Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_file_versions' } = { 
    	summary => '',
        params => $params,
        returns => 'FileVersions',
    };
}
#
# @return FileVersions
#
sub get_file_versions{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileVersions', $response);
    return $_response_object;
}

#
# PostAnalyzeExcelRequest
#
# Perform business analysis of data in Excel files.
# 
# @analyzeExcelRequest  AnalyzeExcelRequest (required)  Excel files and analysis output requirements   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAnalyzeExcelRequest',
            description => 'PostAnalyzeExcel Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_analyze_excel' } = { 
    	summary => 'Perform business analysis of data in Excel files.',
        params => $params,
        returns => 'ARRAY[AnalyzedResult]',
    };
}
#
# @return ARRAY[AnalyzedResult]
#
sub post_analyze_excel{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[AnalyzedResult]', $response);
    return $_response_object;
}

#
# GetWorksheetAutoFilterRequest
#
# Retrieve the description of auto filters from a worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetAutoFilterRequest',
            description => 'GetWorksheetAutoFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_auto_filter' } = { 
    	summary => 'Retrieve the description of auto filters from a worksheet.',
        params => $params,
        returns => 'AutoFilterResponse',
    };
}
#
# @return AutoFilterResponse
#
sub get_worksheet_auto_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AutoFilterResponse', $response);
    return $_response_object;
}

#
# PutWorksheetDateFilterRequest
#
# Apply a date filter in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @dateTimeGroupingType  string (required)  Specifies how to group dateTime values (Day, Hour, Minute, Month, Second, Year).  
# @year  int   The year.  
# @month  int   The month.  
# @day  int   The day.  
# @hour  int   The hour.  
# @minute  int   The minute.  
# @second  int   The second.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetDateFilterRequest',
            description => 'PutWorksheetDateFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_date_filter' } = { 
    	summary => 'Apply a date filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_date_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFilterRequest
#
# Add a filter for a column in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @criteria  string (required)  The custom criteria.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFilterRequest',
            description => 'PutWorksheetFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_filter' } = { 
    	summary => 'Add a filter for a column in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetIconFilterRequest
#
# Add an icon filter in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @iconSetType  string (required)  The icon set type.  
# @iconId  int (required)  The icon id.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetIconFilterRequest',
            description => 'PutWorksheetIconFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_icon_filter' } = { 
    	summary => 'Add an icon filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_icon_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetCustomFilterRequest
#
# Filter a list with custom criteria in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @operatorType1  string (required)  The filter operator type  
# @criteria1  string (required)  The custom criteria.  
# @isAnd  boolean   true/false  
# @operatorType2  string     
# @criteria2  string   The custom criteria.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetCustomFilterRequest',
            description => 'PutWorksheetCustomFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_custom_filter' } = { 
    	summary => 'Filter a list with custom criteria in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_custom_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetDynamicFilterRequest
#
# Add a dynamic filter in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @dynamicFilterType  string (required)  Dynamic filter type.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetDynamicFilterRequest',
            description => 'PutWorksheetDynamicFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_dynamic_filter' } = { 
    	summary => 'Add a dynamic filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_dynamic_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFilterTop10Request
#
# Filter the top 10 items in the list in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @isTop  boolean (required)  Indicates whether filter from top or bottom  
# @isPercent  boolean (required)  Indicates whether the items is percent or count  
# @itemCount  int (required)  The item count  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFilterTop10Request',
            description => 'PutWorksheetFilterTop10 Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_filter_top10' } = { 
    	summary => 'Filter the top 10 items in the list in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_filter_top10{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetColorFilterRequest
#
# Add a color filter in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified AutoFilter applies.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @colorFilter  ColorFilterRequest (required)  color filter request.  
# @matchBlanks  boolean   Match all blank cell in the list.  
# @refresh  boolean   Refresh auto filters to hide or unhide the rows.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetColorFilterRequest',
            description => 'PutWorksheetColorFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_color_filter' } = { 
    	summary => 'Add a color filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_color_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetMatchBlanksRequest
#
# Match all blank cells in the list.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetMatchBlanksRequest',
            description => 'PostWorksheetMatchBlanks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_match_blanks' } = { 
    	summary => 'Match all blank cells in the list.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_match_blanks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetMatchNonBlanksRequest
#
# Match all not blank cells in the list.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetMatchNonBlanksRequest',
            description => 'PostWorksheetMatchNonBlanks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_match_non_blanks' } = { 
    	summary => 'Match all not blank cells in the list.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_match_non_blanks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetAutoFilterRefreshRequest
#
# Refresh auto filters in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetAutoFilterRefreshRequest',
            description => 'PostWorksheetAutoFilterRefresh Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_auto_filter_refresh' } = { 
    	summary => 'Refresh auto filters in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_auto_filter_refresh{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetDateFilterRequest
#
# Remove a date filter in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @dateTimeGroupingType  string (required)  Specifies how to group dateTime values.  
# @year  int   The year.  
# @month  int   The month.  
# @day  int   The day.  
# @hour  int   The hour.  
# @minute  int   The minute.  
# @second  int   The second.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetDateFilterRequest',
            description => 'DeleteWorksheetDateFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_date_filter' } = { 
    	summary => 'Remove a date filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_date_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetFilterRequest
#
# Delete a filter for a column in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @fieldIndex  int (required)  The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  
# @criteria  string   The custom criteria.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetFilterRequest',
            description => 'DeleteWorksheetFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_filter' } = { 
    	summary => 'Delete a filter for a column in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetAutoshapesRequest
#
# Get autoshapes description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Document`s folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetAutoshapesRequest',
            description => 'GetWorksheetAutoshapes Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_autoshapes' } = { 
    	summary => 'Get autoshapes description in worksheet.',
        params => $params,
        returns => 'AutoShapesResponse',
    };
}
#
# @return AutoShapesResponse
#
sub get_worksheet_autoshapes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AutoShapesResponse', $response);
    return $_response_object;
}

#
# GetWorksheetAutoshapeWithFormatRequest
#
# Get autoshape description in some format.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @autoshapeNumber  int (required)  The autoshape number.  
# @format  string   Autoshape conversion format.  
# @folder  string   The document folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetAutoshapeWithFormatRequest',
            description => 'GetWorksheetAutoshapeWithFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_autoshape_with_format' } = { 
    	summary => 'Get autoshape description in some format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_autoshape_with_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostBatchConvertRequest
#
# Batch converting files that meet specific matching conditions.
# 
# @batchConvertRequest  BatchConvertRequest (required)  BatchConvertRequest Batch conversion file request.    
#
{
    my $params = {
       'request' =>{
            data_type => 'PostBatchConvertRequest',
            description => 'PostBatchConvert Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_batch_convert' } = { 
    	summary => 'Batch converting files that meet specific matching conditions.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_batch_convert{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostBatchProtectRequest
#
# Batch protecting files that meet specific matching conditions.
# 
# @batchProtectRequest  BatchProtectRequest (required)  BatchProtectRequest Batch protection file request.     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostBatchProtectRequest',
            description => 'PostBatchProtect Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_batch_protect' } = { 
    	summary => 'Batch protecting files that meet specific matching conditions.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_batch_protect{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostBatchLockRequest
#
# Batch locking files that meet specific matching conditions.
# 
# @batchLockRequest  BatchLockRequest (required)  BatchLockRequest Batch locking file request.     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostBatchLockRequest',
            description => 'PostBatchLock Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_batch_lock' } = { 
    	summary => 'Batch locking files that meet specific matching conditions.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_batch_lock{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostBatchUnlockRequest
#
# Batch unlocking files that meet specific matching conditions.
# 
# @batchLockRequest  BatchLockRequest (required)  BatchLockRequest Batch locking file request.     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostBatchUnlockRequest',
            description => 'PostBatchUnlock Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_batch_unlock' } = { 
    	summary => 'Batch unlocking files that meet specific matching conditions.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_batch_unlock{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostBatchSplitRequest
#
# Batch splitting files that meet specific matching conditions.
# 
# @batchSplitRequest  BatchSplitRequest (required)  BatchSplitRequest Batch splitting file request.     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostBatchSplitRequest',
            description => 'PostBatchSplit Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_batch_split' } = { 
    	summary => 'Batch splitting files that meet specific matching conditions.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_batch_split{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostClearContentsRequest
#
# Clear cell area contents in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string   Represents the range to which the specified cells applies.  
# @startRow  int   The start row index.  
# @startColumn  int   The start column index.  
# @endRow  int   The end row index.  
# @endColumn  int   The end column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostClearContentsRequest',
            description => 'PostClearContents Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_clear_contents' } = { 
    	summary => 'Clear cell area contents in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_clear_contents{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostClearFormatsRequest
#
# Clear cell formats in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string   Represents the range to which the specified cells applies.  
# @startRow  int   The start row index.  
# @startColumn  int   The start column index.  
# @endRow  int   The end row index.  
# @endColumn  int   The end column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostClearFormatsRequest',
            description => 'PostClearFormats Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_clear_formats' } = { 
    	summary => 'Clear cell formats in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_clear_formats{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetRangeStyleRequest
#
# Update cell range styles in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  Represents the range to which the specified cells applies.  
# @style  Style (required)  Style with update style settings.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetRangeStyleRequest',
            description => 'PostUpdateWorksheetRangeStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_range_style' } = { 
    	summary => 'Update cell range styles in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_range_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetMergeRequest
#
# Merge cells in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int (required)  The start row index.  
# @startColumn  int (required)  The start column index.  
# @totalRows  int (required)  The total rows number.  
# @totalColumns  int (required)  The total columns number.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetMergeRequest',
            description => 'PostWorksheetMerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_merge' } = { 
    	summary => 'Merge cells in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_merge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetUnmergeRequest
#
# Unmerge cells in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int (required)  The start row index.  
# @startColumn  int (required)  The start column index.  
# @totalRows  int (required)  The total rows number.  
# @totalColumns  int (required)  The total columns number.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetUnmergeRequest',
            description => 'PostWorksheetUnmerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_unmerge' } = { 
    	summary => 'Unmerge cells in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_unmerge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCellsRequest
#
# Retrieve cell descriptions in a specified format.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @offest  int   Begginig offset.  
# @count  int   Maximum amount of cells in the response.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCellsRequest',
            description => 'GetWorksheetCells Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_cells' } = { 
    	summary => 'Retrieve cell descriptions in a specified format.',
        params => $params,
        returns => 'CellsResponse',
    };
}
#
# @return CellsResponse
#
sub get_worksheet_cells{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCellRequest
#
# Retrieve cell data using either cell reference or method name in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellOrMethodName  string (required)  The cell`s or method name. (Method name like firstcell, endcell etc.)  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCellRequest',
            description => 'GetWorksheetCell Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_cell' } = { 
    	summary => 'Retrieve cell data using either cell reference or method name in the worksheet.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_cell{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# GetWorksheetCellStyleRequest
#
# Retrieve cell style descriptions in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  Cell`s name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCellStyleRequest',
            description => 'GetWorksheetCellStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_cell_style' } = { 
    	summary => 'Retrieve cell style descriptions in the worksheet.',
        params => $params,
        returns => 'StyleResponse',
    };
}
#
# @return StyleResponse
#
sub get_worksheet_cell_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('StyleResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellSetValueRequest
#
# Set cell value using cell name in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @value  string   The cell value.  
# @type  string   The value type.  
# @formula  string   Formula for cell  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellSetValueRequest',
            description => 'PostWorksheetCellSetValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cell_set_value' } = { 
    	summary => 'Set cell value using cell name in the worksheet.',
        params => $params,
        returns => 'CellResponse',
    };
}
#
# @return CellResponse
#
sub post_worksheet_cell_set_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetCellStyleRequest
#
# Set cell style using cell name in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @style  Style (required)  Style with update style settings.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetCellStyleRequest',
            description => 'PostUpdateWorksheetCellStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_cell_style' } = { 
    	summary => 'Set cell style using cell name in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_cell_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostSetCellRangeValueRequest
#
# Set the value of the range in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellarea  string (required)  Cell area (like "A1:C2")  
# @value  string (required)  Range value  
# @type  string (required)  Value data type (like "int")  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSetCellRangeValueRequest',
            description => 'PostSetCellRangeValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_set_cell_range_value' } = { 
    	summary => 'Set the value of the range in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_set_cell_range_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCopyCellIntoCellRequest
#
# Copy data from a source cell to a destination cell in the worksheet.
# 
# @name  string (required)  The file name.  
# @destCellName  string (required)  The destination cell name.  
# @sheetName  string (required)  The destination worksheet name.  
# @worksheet  string (required)  The source worksheet name.  
# @cellname  string   The source cell name.  
# @row  int   The source row index.  
# @column  int   The source column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCopyCellIntoCellRequest',
            description => 'PostCopyCellIntoCell Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_copy_cell_into_cell' } = { 
    	summary => 'Copy data from a source cell to a destination cell in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_copy_cell_into_cell{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetCellHtmlStringRequest
#
# Retrieve the HTML string containing data and specific formats in this cell.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetCellHtmlStringRequest',
            description => 'GetCellHtmlString Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_cell_html_string' } = { 
    	summary => 'Retrieve the HTML string containing data and specific formats in this cell.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_cell_html_string{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostSetCellHtmlStringRequest
#
# Set the HTML string containing data and specific formats in this cell.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSetCellHtmlStringRequest',
            description => 'PostSetCellHtmlString Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_set_cell_html_string' } = { 
    	summary => 'Set the HTML string containing data and specific formats in this cell.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_set_cell_html_string{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCellCalculateRequest
#
# Calculate cell formula in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @options  CalculationOptions   Calculation Options  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCellCalculateRequest',
            description => 'PostCellCalculate Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_cell_calculate' } = { 
    	summary => 'Calculate cell formula in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_cell_calculate{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCellCharactersRequest
#
# Set cell characters in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @options  ARRAY[FontSetting]     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCellCharactersRequest',
            description => 'PostCellCharacters Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_cell_characters' } = { 
    	summary => 'Set cell characters in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_cell_characters{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetColumnsRequest
#
# Retrieve descriptions of worksheet columns.
# 
# @name  string   The file name.  
# @sheetName  string   The worksheet name.  
# @offset  int   The workdook folder.  
# @count  int     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetColumnsRequest',
            description => 'GetWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_columns' } = { 
    	summary => 'Retrieve descriptions of worksheet columns.',
        params => $params,
        returns => 'ColumnsResponse',
    };
}
#
# @return ColumnsResponse
#
sub get_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ColumnsResponse', $response);
    return $_response_object;
}

#
# PostSetWorksheetColumnWidthRequest
#
# Set worksheet column width.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @width  double (required)  Gets and sets the column width in unit of characters.  
# @count  int     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSetWorksheetColumnWidthRequest',
            description => 'PostSetWorksheetColumnWidth Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_set_worksheet_column_width' } = { 
    	summary => 'Set worksheet column width.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_set_worksheet_column_width{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetColumnRequest
#
# Retrieve worksheet column data by column index.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetColumnRequest',
            description => 'GetWorksheetColumn Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_column' } = { 
    	summary => 'Retrieve worksheet column data by column index.',
        params => $params,
        returns => 'ColumnResponse',
    };
}
#
# @return ColumnResponse
#
sub get_worksheet_column{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ColumnResponse', $response);
    return $_response_object;
}

#
# PutInsertWorksheetColumnsRequest
#
# Insert worksheet columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @columns  int (required)  The number of columns.  
# @updateReference  boolean   Indicates if references in other worksheets will be updated.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutInsertWorksheetColumnsRequest',
            description => 'PutInsertWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_insert_worksheet_columns' } = { 
    	summary => 'Insert worksheet columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_insert_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetColumnsRequest
#
# Delete worksheet columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @columns  int (required)  The number of columns.  
# @updateReference  boolean (required)  Indicates if references in other worksheets will be updated.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetColumnsRequest',
            description => 'DeleteWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_columns' } = { 
    	summary => 'Delete worksheet columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostHideWorksheetColumnsRequest
#
# Hide worksheet columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startColumn  int (required)  The begin column index to be operated.  
# @totalColumns  int (required)  Number of columns to be operated.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostHideWorksheetColumnsRequest',
            description => 'PostHideWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_hide_worksheet_columns' } = { 
    	summary => 'Hide worksheet columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_hide_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUnhideWorksheetColumnsRequest
#
# Unhide worksheet columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startColumn  int (required)  The begin column index to be operated.  
# @totalColumns  int (required)  Number of columns to be operated.  
# @width  double   Gets and sets the column width in unit of characters.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUnhideWorksheetColumnsRequest',
            description => 'PostUnhideWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_unhide_worksheet_columns' } = { 
    	summary => 'Unhide worksheet columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_unhide_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostGroupWorksheetColumnsRequest
#
# Group worksheet columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first column index to be operated.  
# @lastIndex  int (required)  The last column index to be operated.  
# @hide  boolean   columns visible state  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostGroupWorksheetColumnsRequest',
            description => 'PostGroupWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_group_worksheet_columns' } = { 
    	summary => 'Group worksheet columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_group_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUngroupWorksheetColumnsRequest
#
# Ungroup worksheet columns.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first column index to be operated.  
# @lastIndex  int (required)  The last column index to be operated.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUngroupWorksheetColumnsRequest',
            description => 'PostUngroupWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_ungroup_worksheet_columns' } = { 
    	summary => 'Ungroup worksheet columns.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_ungroup_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCopyWorksheetColumnsRequest
#
# Copy data from source columns to destination columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceColumnIndex  int (required)  Source column index  
# @destinationColumnIndex  int (required)  Destination column index  
# @columnNumber  int (required)  The copied column number  
# @worksheet  string   The destination worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCopyWorksheetColumnsRequest',
            description => 'PostCopyWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_copy_worksheet_columns' } = { 
    	summary => 'Copy data from source columns to destination columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_copy_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostColumnStyleRequest
#
# Set column style in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @style  Style (required)  Represents display style of excel document,such as font,color,alignment,border,etc.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostColumnStyleRequest',
            description => 'PostColumnStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_column_style' } = { 
    	summary => 'Set column style in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_column_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetRowsRequest
#
# Retrieve descriptions of rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @offset  int   Row offset.  
# @count  int   Display rows number.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetRowsRequest',
            description => 'GetWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_rows' } = { 
    	summary => 'Retrieve descriptions of rows in the worksheet.',
        params => $params,
        returns => 'RowsResponse',
    };
}
#
# @return RowsResponse
#
sub get_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RowsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetRowRequest
#
# Retrieve row data by the row`s index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetRowRequest',
            description => 'GetWorksheetRow Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_row' } = { 
    	summary => 'Retrieve row data by the row`s index in the worksheet.',
        params => $params,
        returns => 'RowResponse',
    };
}
#
# @return RowResponse
#
sub get_worksheet_row{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RowResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetRowRequest
#
# Delete a row in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetRowRequest',
            description => 'DeleteWorksheetRow Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_row' } = { 
    	summary => 'Delete a row in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_row{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetRowsRequest
#
# Delete several rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int   Number of rows to be operated.  
# @updateReference  boolean   Indicates if update references in other worksheets.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetRowsRequest',
            description => 'DeleteWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_rows' } = { 
    	summary => 'Delete several rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutInsertWorksheetRowsRequest
#
# Insert several new rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int   Number of rows to be operated.  
# @updateReference  boolean   Indicates if update references in other worksheets.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutInsertWorksheetRowsRequest',
            description => 'PutInsertWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_insert_worksheet_rows' } = { 
    	summary => 'Insert several new rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_insert_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutInsertWorksheetRowRequest
#
# Insert a new row in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The new row index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutInsertWorksheetRowRequest',
            description => 'PutInsertWorksheetRow Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_insert_worksheet_row' } = { 
    	summary => 'Insert a new row in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_insert_worksheet_row{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetRowRequest
#
# Update height of rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @height  double   The new row height.  
# @count  int     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetRowRequest',
            description => 'PostUpdateWorksheetRow Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_row' } = { 
    	summary => 'Update height of rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_row{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostHideWorksheetRowsRequest
#
# Hide rows in worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int (required)  Number of rows to be operated.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostHideWorksheetRowsRequest',
            description => 'PostHideWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_hide_worksheet_rows' } = { 
    	summary => 'Hide rows in worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_hide_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUnhideWorksheetRowsRequest
#
# Unhide rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int (required)  Number of rows to be operated.  
# @height  double   The new row height.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUnhideWorksheetRowsRequest',
            description => 'PostUnhideWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_unhide_worksheet_rows' } = { 
    	summary => 'Unhide rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_unhide_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostGroupWorksheetRowsRequest
#
# Group rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first row index to be operated.  
# @lastIndex  int (required)  The last row index to be operated.  
# @hide  boolean   rows visible state  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostGroupWorksheetRowsRequest',
            description => 'PostGroupWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_group_worksheet_rows' } = { 
    	summary => 'Group rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_group_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUngroupWorksheetRowsRequest
#
# Ungroup rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first row index to be operated.  
# @lastIndex  int (required)  The last row index to be operated.  
# @isAll  boolean   Is all row to be operated  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUngroupWorksheetRowsRequest',
            description => 'PostUngroupWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_ungroup_worksheet_rows' } = { 
    	summary => 'Ungroup rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_ungroup_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCopyWorksheetRowsRequest
#
# Copy data and formats from specific entire rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceRowIndex  int (required)  Source row index  
# @destinationRowIndex  int (required)  Destination row index  
# @rowNumber  int (required)  The copied row number  
# @worksheet  string   The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCopyWorksheetRowsRequest',
            description => 'PostCopyWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_copy_worksheet_rows' } = { 
    	summary => 'Copy data and formats from specific entire rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_copy_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostRowStyleRequest
#
# Apply formats to an entire row in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @style  Style (required)  Style description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRowStyleRequest',
            description => 'PostRowStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_row_style' } = { 
    	summary => 'Apply formats to an entire row in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_row_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetCellsCloudServicesHealthCheckRequest
#
# Retrieve cell descriptions in a specified format.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'GetCellsCloudServicesHealthCheckRequest',
            description => 'GetCellsCloudServicesHealthCheck Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_cells_cloud_services_health_check' } = { 
    	summary => 'Retrieve cell descriptions in a specified format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_cells_cloud_services_health_check{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# GetCellsCloudServiceStatusRequest
#
# Aspose.Cells Cloud service health status check.
# 
 
#
{
    my $params = {
       'request' =>{
            data_type => 'GetCellsCloudServiceStatusRequest',
            description => 'GetCellsCloudServiceStatus Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_cells_cloud_service_status' } = { 
    	summary => 'Aspose.Cells Cloud service health status check.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_cells_cloud_service_status{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# GetChartAreaRequest
#
# Retrieve chart area description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartAreaRequest',
            description => 'GetChartArea Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_area' } = { 
    	summary => 'Retrieve chart area description in the worksheet.',
        params => $params,
        returns => 'ChartAreaResponse',
    };
}
#
# @return ChartAreaResponse
#
sub get_chart_area{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ChartAreaResponse', $response);
    return $_response_object;
}

#
# GetChartAreaFillFormatRequest
#
# Retrieve chart area fill format description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartAreaFillFormatRequest',
            description => 'GetChartAreaFillFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_area_fill_format' } = { 
    	summary => 'Retrieve chart area fill format description in the worksheet.',
        params => $params,
        returns => 'FillFormatResponse',
    };
}
#
# @return FillFormatResponse
#
sub get_chart_area_fill_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FillFormatResponse', $response);
    return $_response_object;
}

#
# GetChartAreaBorderRequest
#
# Retrieve chart area border description.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartAreaBorderRequest',
            description => 'GetChartAreaBorder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_area_border' } = { 
    	summary => 'Retrieve chart area border description.',
        params => $params,
        returns => 'LineResponse',
    };
}
#
# @return LineResponse
#
sub get_chart_area_border{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LineResponse', $response);
    return $_response_object;
}

#
# GetWorksheetChartsRequest
#
# Retrieve descriptions of charts in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetChartsRequest',
            description => 'GetWorksheetCharts Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_charts' } = { 
    	summary => 'Retrieve descriptions of charts in the worksheet.',
        params => $params,
        returns => 'ChartsResponse',
    };
}
#
# @return ChartsResponse
#
sub get_worksheet_charts{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ChartsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetChartRequest
#
# Retrieve the chart in a specified format.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartNumber  int (required)  The chart number.  
# @format  string   Chart conversion format.(PNG/TIFF/JPEG/GIF/EMF/BMP)  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetChartRequest',
            description => 'GetWorksheetChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_chart' } = { 
    	summary => 'Retrieve the chart in a specified format.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_chart{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutWorksheetChartRequest
#
# Add a new chart in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartType  string (required)  Chart type, please refer property Type in chart resource.  
# @upperLeftRow  int   Upper-left row for the new chart.  
# @upperLeftColumn  int   Upper-left column for the new chart.  
# @lowerRightRow  int   Lower-left row for the new chart.  
# @lowerRightColumn  int   Lower-left column for the new chart.  
# @area  string   Specify the values from which to plot the data series.  
# @isVertical  boolean   Specify whether to plot the series from a range of cell values by row or by column.   
# @categoryData  string   Get or set the range of category axis values. It can be a range of cells (e.g., "D1:E10").  
# @isAutoGetSerialName  boolean   Specify whether to auto-update the serial name.  
# @title  string   Specify the chart title name.  
# @folder  string   The folder where the file is situated.  
# @dataLabels  boolean   Represents the specified chart`s data label values display behavior. True to display the values, False to hide them.  
# @dataLabelsPosition  string   Represents data label position (Center/InsideBase/InsideEnd/OutsideEnd/Above/Below/Left/Right/BestFit/Moved).  
# @pivotTableSheet  string   The source is the data of the pivotTable. If PivotSource is not empty, the chart is a PivotChart.  
# @pivotTableName  string   The pivot table name.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetChartRequest',
            description => 'PutWorksheetChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_chart' } = { 
    	summary => 'Add a new chart in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_chart{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetChartRequest
#
# Delete a chart by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetChartRequest',
            description => 'DeleteWorksheetChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_chart' } = { 
    	summary => 'Delete a chart by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_chart{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetChartRequest
#
# Update chart properties in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @chart  Chart (required)  Chart Represents a specified chart.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetChartRequest',
            description => 'PostWorksheetChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_chart' } = { 
    	summary => 'Update chart properties in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_chart{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetChartLegendRequest
#
# Retrieve chart legend description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetChartLegendRequest',
            description => 'GetWorksheetChartLegend Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_chart_legend' } = { 
    	summary => 'Retrieve chart legend description in the worksheet.',
        params => $params,
        returns => 'LegendResponse',
    };
}
#
# @return LegendResponse
#
sub get_worksheet_chart_legend{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LegendResponse', $response);
    return $_response_object;
}

#
# PostWorksheetChartLegendRequest
#
# Update chart legend in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @legend  Legend (required)    
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetChartLegendRequest',
            description => 'PostWorksheetChartLegend Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_chart_legend' } = { 
    	summary => 'Update chart legend in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_chart_legend{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetChartLegendRequest
#
# Show chart legend in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetChartLegendRequest',
            description => 'PutWorksheetChartLegend Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_chart_legend' } = { 
    	summary => 'Show chart legend in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_chart_legend{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetChartLegendRequest
#
# Hides chart legend in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetChartLegendRequest',
            description => 'DeleteWorksheetChartLegend Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_chart_legend' } = { 
    	summary => 'Hides chart legend in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_chart_legend{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetChartsRequest
#
# Clear the charts in the worksheets.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetChartsRequest',
            description => 'DeleteWorksheetCharts Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_charts' } = { 
    	summary => 'Clear the charts in the worksheets.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_charts{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetChartTitleRequest
#
# Retrieve chart title description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetChartTitleRequest',
            description => 'GetWorksheetChartTitle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_chart_title' } = { 
    	summary => 'Retrieve chart title description in the worksheet.',
        params => $params,
        returns => 'TitleResponse',
    };
}
#
# @return TitleResponse
#
sub get_worksheet_chart_title{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TitleResponse', $response);
    return $_response_object;
}

#
# PostWorksheetChartTitleRequest
#
# Update chart title in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @title  Title (required)  TitleChart title  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetChartTitleRequest',
            description => 'PostWorksheetChartTitle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_chart_title' } = { 
    	summary => 'Update chart title in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_chart_title{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetChartTitleRequest
#
# Set chart title in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @title  Title   TitleChart title.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetChartTitleRequest',
            description => 'PutWorksheetChartTitle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_chart_title' } = { 
    	summary => 'Set chart title in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_chart_title{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetChartTitleRequest
#
# Hide chart title in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetChartTitleRequest',
            description => 'DeleteWorksheetChartTitle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_chart_title' } = { 
    	summary => 'Hide chart title in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_chart_title{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetChartSeriesAxisRequest
#
# Retrieve descriptions of chart seriesaxis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartSeriesAxisRequest',
            description => 'GetChartSeriesAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_series_axis' } = { 
    	summary => 'Retrieve descriptions of chart seriesaxis in the chart.',
        params => $params,
        returns => 'AxisResponse',
    };
}
#
# @return AxisResponse
#
sub get_chart_series_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AxisResponse', $response);
    return $_response_object;
}

#
# GetChartCategoryAxisRequest
#
# Retrieve descriptions of chart series axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartCategoryAxisRequest',
            description => 'GetChartCategoryAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_category_axis' } = { 
    	summary => 'Retrieve descriptions of chart series axis in the chart.',
        params => $params,
        returns => 'AxisResponse',
    };
}
#
# @return AxisResponse
#
sub get_chart_category_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AxisResponse', $response);
    return $_response_object;
}

#
# GetChartValueAxisRequest
#
# Retrieve chart value axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartValueAxisRequest',
            description => 'GetChartValueAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_value_axis' } = { 
    	summary => 'Retrieve chart value axis in the chart.',
        params => $params,
        returns => 'AxisResponse',
    };
}
#
# @return AxisResponse
#
sub get_chart_value_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AxisResponse', $response);
    return $_response_object;
}

#
# GetChartSecondCategoryAxisRequest
#
# Retrieve chart second category axis in the chart
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartSecondCategoryAxisRequest',
            description => 'GetChartSecondCategoryAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_second_category_axis' } = { 
    	summary => 'Retrieve chart second category axis in the chart',
        params => $params,
        returns => 'AxisResponse',
    };
}
#
# @return AxisResponse
#
sub get_chart_second_category_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AxisResponse', $response);
    return $_response_object;
}

#
# GetChartSecondValueAxisRequest
#
# Retrieve chart second value axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetChartSecondValueAxisRequest',
            description => 'GetChartSecondValueAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_chart_second_value_axis' } = { 
    	summary => 'Retrieve chart second value axis in the chart.',
        params => $params,
        returns => 'AxisResponse',
    };
}
#
# @return AxisResponse
#
sub get_chart_second_value_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('AxisResponse', $response);
    return $_response_object;
}

#
# PostChartSeriesAxisRequest
#
# Update chart series axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @axis  Axis (required)  Axis   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostChartSeriesAxisRequest',
            description => 'PostChartSeriesAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_chart_series_axis' } = { 
    	summary => 'Update chart series axis in the chart.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_chart_series_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostChartCategoryAxisRequest
#
# Update chart category axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @axis  Axis (required)  Axis   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostChartCategoryAxisRequest',
            description => 'PostChartCategoryAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_chart_category_axis' } = { 
    	summary => 'Update chart category axis in the chart.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_chart_category_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostChartValueAxisRequest
#
# Update chart value axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @axis  Axis (required)  Axis   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostChartValueAxisRequest',
            description => 'PostChartValueAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_chart_value_axis' } = { 
    	summary => 'Update chart value axis in the chart.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_chart_value_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostChartSecondCategoryAxisRequest
#
# Update chart sencond category axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @axis  Axis (required)  Axis   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostChartSecondCategoryAxisRequest',
            description => 'PostChartSecondCategoryAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_chart_second_category_axis' } = { 
    	summary => 'Update chart sencond category axis in the chart.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_chart_second_category_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostChartSecondValueAxisRequest
#
# Update chart sencond value axis in the chart.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @axis  Axis (required)  Axis   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostChartSecondValueAxisRequest',
            description => 'PostChartSecondValueAxis Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_chart_second_value_axis' } = { 
    	summary => 'Update chart sencond value axis in the chart.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_chart_second_value_axis{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetConditionalFormattingsRequest
#
# Retrieve descriptions of conditional formattings in a worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetConditionalFormattingsRequest',
            description => 'GetWorksheetConditionalFormattings Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_conditional_formattings' } = { 
    	summary => 'Retrieve descriptions of conditional formattings in a worksheet.',
        params => $params,
        returns => 'ConditionalFormattingsResponse',
    };
}
#
# @return ConditionalFormattingsResponse
#
sub get_worksheet_conditional_formattings{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ConditionalFormattingsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetConditionalFormattingRequest
#
# Retrieve conditional formatting descriptions in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The conditional formatting index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetConditionalFormattingRequest',
            description => 'GetWorksheetConditionalFormatting Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_conditional_formatting' } = { 
    	summary => 'Retrieve conditional formatting descriptions in the worksheet.',
        params => $params,
        returns => 'ConditionalFormattingResponse',
    };
}
#
# @return ConditionalFormattingResponse
#
sub get_worksheet_conditional_formatting{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ConditionalFormattingResponse', $response);
    return $_response_object;
}

#
# PutWorksheetConditionalFormattingRequest
#
# Add conditional formatting in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @formatcondition  FormatCondition (required)    
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetConditionalFormattingRequest',
            description => 'PutWorksheetConditionalFormatting Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_conditional_formatting' } = { 
    	summary => 'Add conditional formatting in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_conditional_formatting{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFormatConditionRequest
#
# Add a format condition in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @type  string (required)  Format condition type(CellValue/Expression/ColorScale/DataBar/IconSet/Top10/UniqueValues/DuplicateValues/ContainsText/NotContainsText/BeginsWith/EndsWith/ContainsBlanks/NotContainsBlanks/ContainsErrors/NotContainsErrors/TimePeriod/AboveAverage).  
# @operatorType  string (required)  Represents the operator type of conditional format and data validation(Between/Equal/GreaterThan/GreaterOrEqual/LessThan/None/NotBetween/NotEqual).  
# @formula1  string (required)  The value or expression associated with conditional formatting.  
# @formula2  string (required)  The value or expression associated with conditional formatting.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFormatConditionRequest',
            description => 'PutWorksheetFormatCondition Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_format_condition' } = { 
    	summary => 'Add a format condition in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_format_condition{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFormatConditionAreaRequest
#
# Add a cell area for the format condition in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFormatConditionAreaRequest',
            description => 'PutWorksheetFormatConditionArea Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_format_condition_area' } = { 
    	summary => 'Add a cell area for the format condition in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_format_condition_area{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFormatConditionConditionRequest
#
# Add a condition for the format condition in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @type  string (required)  Format condition type(CellValue/Expression/ColorScale/DataBar/IconSet/Top10/UniqueValues/DuplicateValues/ContainsText/NotContainsText/BeginsWith/EndsWith/ContainsBlanks/NotContainsBlanks/ContainsErrors/NotContainsErrors/TimePeriod/AboveAverage).  
# @operatorType  string (required)  Represents the operator type of conditional format and data validation(Between/Equal/GreaterThan/GreaterOrEqual/LessThan/None/NotBetween/NotEqual).  
# @formula1  string (required)  The value or expression associated with conditional formatting.  
# @formula2  string (required)  The value or expression associated with conditional formatting.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFormatConditionConditionRequest',
            description => 'PutWorksheetFormatConditionCondition Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_format_condition_condition' } = { 
    	summary => 'Add a condition for the format condition in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_format_condition_condition{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetConditionalFormattingsRequest
#
# Clear all conditional formattings in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetConditionalFormattingsRequest',
            description => 'DeleteWorksheetConditionalFormattings Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_conditional_formattings' } = { 
    	summary => 'Clear all conditional formattings in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_conditional_formattings{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetConditionalFormattingRequest
#
# Remove a conditional formatting.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetConditionalFormattingRequest',
            description => 'DeleteWorksheetConditionalFormatting Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_conditional_formatting' } = { 
    	summary => 'Remove a conditional formatting.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_conditional_formatting{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetConditionalFormattingAreaRequest
#
# Remove cell area from conditional formatting.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int (required)  The start row of the range.  
# @startColumn  int (required)  The start column of the range.  
# @totalRows  int (required)  The number of rows of the range.  
# @totalColumns  int (required)  The number of columns of the range.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetConditionalFormattingAreaRequest',
            description => 'DeleteWorksheetConditionalFormattingArea Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_conditional_formatting_area' } = { 
    	summary => 'Remove cell area from conditional formatting.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_conditional_formatting_area{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorkbookRequest
#
# Retrieve workbooks in various formats.
# 
# @name  string (required)  The file name.  
# @format  string   The conversion format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @password  string   The password needed to open an Excel file.  
# @isAutoFit  boolean   Specifies whether set workbook rows to be autofit.  
# @onlySaveTable  boolean   Specifies whether only save table data.Only use pdf to excel.  
# @folder  string   The folder where the file is situated.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @storageName  string   The storage name where the file is situated.  
# @outStorageName  string   The storage name where the output file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @pageWideFitOnPerSheet  boolean   The page wide fit on worksheet.  
# @pageTallFitOnPerSheet  boolean   The page tall fit on worksheet.  
# @onePagePerSheet  boolean   When converting to PDF format, one page per sheet.  
# @onlyAutofitTable  boolean     
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookRequest',
            description => 'GetWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook' } = { 
    	summary => 'Retrieve workbooks in various formats.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutConvertWorkbookRequest
#
# Convert the workbook from the requested content into files in different formats.
# 
# @File  string (required)  File to upload  
# @format  string (required)  The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @password  string   The password needed to open an Excel file.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @storageName  string   The storage name where the file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @streamFormat  string   The format of the input file stream.   
# @region  string   The regional settings for workbook.  
# @pageWideFitOnPerSheet  boolean   The page wide fit on worksheet.  
# @pageTallFitOnPerSheet  boolean   The page tall fit on worksheet.  
# @sheetName  string   Convert the specified worksheet.   
# @pageIndex  int   Convert the specified page  of worksheet, sheetName is required.   
# @onePagePerSheet  boolean   When converting to PDF format, one page per sheet.   
# @AutoRowsFit  boolean   Auto-fits all rows in this workbook.  
# @AutoColumnsFit  boolean   Auto-fits the columns width in this workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutConvertWorkbookRequest',
            description => 'PutConvertWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_convert_workbook' } = { 
    	summary => 'Convert the workbook from the requested content into files in different formats.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub put_convert_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostWorkbookSaveAsRequest
#
# Save an Excel file in various formats.
# 
# @name  string (required)  The workbook name.  
# @newfilename  string (required)  newfilename to save the result.The `newfilename` should encompass both the filename and extension.  
# @saveOptions  SaveOptions     
# @isAutoFitRows  boolean   Indicates if Autofit rows in workbook.  
# @isAutoFitColumns  boolean   Indicates if Autofit columns in workbook.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @outStorageName  string   The storage name where the output file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @pageWideFitOnPerSheet  boolean   The page wide fit on worksheet.  
# @pageTallFitOnPerSheet  boolean   The page tall fit on worksheet.  
# @onePagePerSheet  boolean     
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookSaveAsRequest',
            description => 'PostWorkbookSaveAs Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_save_as' } = { 
    	summary => 'Save an Excel file in various formats.',
        params => $params,
        returns => 'SaveResponse',
    };
}
#
# @return SaveResponse
#
sub post_workbook_save_as{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SaveResponse', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToPDFRequest
#
# Convert Excel file to PDF files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToPDFRequest',
            description => 'PostConvertWorkbookToPDF Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_pdf' } = { 
    	summary => 'Convert Excel file to PDF files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_pdf{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToPNGRequest
#
# Convert Excel file to PNG files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToPNGRequest',
            description => 'PostConvertWorkbookToPNG Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_png' } = { 
    	summary => 'Convert Excel file to PNG files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_png{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToDocxRequest
#
# Convert Excel file to Docx files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToDocxRequest',
            description => 'PostConvertWorkbookToDocx Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_docx' } = { 
    	summary => 'Convert Excel file to Docx files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_docx{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToPptxRequest
#
# Convert Excel file to Pptx files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToPptxRequest',
            description => 'PostConvertWorkbookToPptx Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_pptx' } = { 
    	summary => 'Convert Excel file to Pptx files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_pptx{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToHtmlRequest
#
# Convert Excel file to HTML files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToHtmlRequest',
            description => 'PostConvertWorkbookToHtml Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_html' } = { 
    	summary => 'Convert Excel file to HTML files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_html{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToMarkdownRequest
#
# Convert Excel file to Markdown files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToMarkdownRequest',
            description => 'PostConvertWorkbookToMarkdown Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_markdown' } = { 
    	summary => 'Convert Excel file to Markdown files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_markdown{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToJsonRequest
#
# Convert Excel file to Json files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToJsonRequest',
            description => 'PostConvertWorkbookToJson Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_json' } = { 
    	summary => 'Convert Excel file to Json files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_json{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToSQLRequest
#
# Convert Excel file to SQL Script files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToSQLRequest',
            description => 'PostConvertWorkbookToSQL Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_sql' } = { 
    	summary => 'Convert Excel file to SQL Script files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_sql{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookToCSVRequest
#
# Convert Excel file to Csv files.
# 
# @File  string (required)  File to upload  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookToCSVRequest',
            description => 'PostConvertWorkbookToCSV Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook_to_csv' } = { 
    	summary => 'Convert Excel file to Csv files.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook_to_csv{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorksheetToImageRequest
#
# 
# 
# @convertWorksheetOptions  ConvertWorksheetOptions (required)    
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorksheetToImageRequest',
            description => 'PostConvertWorksheetToImage Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_worksheet_to_image' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_worksheet_to_image{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertWorkbookRequest
#
# 
# 
# @convertWorkbookOptions  ConvertWorkbookOptions (required)    
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertWorkbookRequest',
            description => 'PostConvertWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_workbook' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# CheckWrokbookExternalReferenceRequest
#
# Export Excel internal elements or the workbook itself to various format files.
# 
# @checkExternalReferenceOptions  CheckExternalReferenceOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'CheckWrokbookExternalReferenceRequest',
            description => 'CheckWrokbookExternalReference Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'check_wrokbook_external_reference' } = { 
    	summary => 'Export Excel internal elements or the workbook itself to various format files.',
        params => $params,
        returns => 'CheckedExternalReferenceResponse',
    };
}
#
# @return CheckedExternalReferenceResponse
#
sub check_wrokbook_external_reference{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CheckedExternalReferenceResponse', $response);
    return $_response_object;
}

#
# CheckWorkbookFormulaErrorsRequest
#
# 
# 
# @formulaErrorOptions  CheckFormulaErrorOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'CheckWorkbookFormulaErrorsRequest',
            description => 'CheckWorkbookFormulaErrors Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'check_workbook_formula_errors' } = { 
    	summary => '',
        params => $params,
        returns => 'CheckedFormulaErrorsResponse',
    };
}
#
# @return CheckedFormulaErrorsResponse
#
sub check_workbook_formula_errors{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CheckedFormulaErrorsResponse', $response);
    return $_response_object;
}

#
# PostExportRequest
#
# Export Excel internal elements or the workbook itself to various format files.
# 
# @File  string (required)  File to upload  
# @objectType  string   Exported object type:workbook/worksheet/chart/comment/picture/shape/listobject/oleobject.  
# @format  string   The conversion format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostExportRequest',
            description => 'PostExport Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_export' } = { 
    	summary => 'Export Excel internal elements or the workbook itself to various format files.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_export{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostWorkbookExportXMLRequest
#
# Export XML data from an Excel file.When there are XML Maps in an Excel file, export XML data. When there is no XML map in the Excel file, convert the Excel file to an XML file.
# 
# @name  string (required)  The file name.  
# @password  string   The password needed to open an Excel file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @outStorageName  string   The storage name where the output file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookExportXMLRequest',
            description => 'PostWorkbookExportXML Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_export_xml' } = { 
    	summary => 'Export XML data from an Excel file.When there are XML Maps in an Excel file, export XML data. When there is no XML map in the Excel file, convert the Excel file to an XML file.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_workbook_export_xml{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostWorkbookImportJsonRequest
#
# Import a JSON data file into the workbook. The JSON data file can either be a cloud file or data from an HTTP URI.
# 
# @name  string (required)  The file name.  
# @importJsonRequest  ImportJsonRequest (required)  Import Json request.  
# @password  string   The password needed to open an Excel file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @outStorageName  string   The storage name where the output file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookImportJsonRequest',
            description => 'PostWorkbookImportJson Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_import_json' } = { 
    	summary => 'Import a JSON data file into the workbook. The JSON data file can either be a cloud file or data from an HTTP URI.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_workbook_import_json{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostWorkbookImportXMLRequest
#
# Import an XML data file into an Excel file. The XML data file can either be a cloud file or data from an HTTP URI.
# 
# @name  string (required)  The file name.  
# @importXMLRequest  ImportXMLRequest (required)  Import XML request.  
# @password  string   The password needed to open an Excel file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @outStorageName  string   The storage name where the output file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookImportXMLRequest',
            description => 'PostWorkbookImportXML Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_import_xml' } = { 
    	summary => 'Import an XML data file into an Excel file. The XML data file can either be a cloud file or data from an HTTP URI.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_workbook_import_xml{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostImportDataRequest
#
# Import data into the Excel file.
# 
# @name  string (required)  The file name.  
# @importOption  ImportOption   Import option. They are include of ImportCSVDataOption, ImportBatchDataOption, ImportPictureOption, ImportStringArrayOption, Import2DimensionStringArrayOption, and so on.    
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @region  string   The regional settings for workbook.  
# @FontsLocation  string   Use Custom fonts.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostImportDataRequest',
            description => 'PostImportData Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_import_data' } = { 
    	summary => 'Import data into the Excel file.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_import_data{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorkbookDataCleansingRequest
#
# Data cleaning of spreadsheet files is a data management process used to identify, correct, and remove errors, incompleteness, duplicates, or inaccuracies in tables and ranges.
# 
# @name  string (required)  The file name.  
# @dataCleansing  DataCleansing (required)  data cleansing content.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @password  string   The file password.   
# @region  string   The regional settings for workbook.  
# @checkExcelRestriction  boolean      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookDataCleansingRequest',
            description => 'PostWorkbookDataCleansing Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_data_cleansing' } = { 
    	summary => 'Data cleaning of spreadsheet files is a data management process used to identify, correct, and remove errors, incompleteness, duplicates, or inaccuracies in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_workbook_data_cleansing{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostDataCleansingRequest
#
# Data cleansing of spreadsheet files is a data management process used to identify, correct, and remove errors, incompleteness, duplicates, or inaccuracies in tables and ranges.
# 
# @dataCleansingRequest  DataCleansingRequest (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDataCleansingRequest',
            description => 'PostDataCleansing Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_data_cleansing' } = { 
    	summary => 'Data cleansing of spreadsheet files is a data management process used to identify, correct, and remove errors, incompleteness, duplicates, or inaccuracies in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_data_cleansing{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostWorkbookDataDeduplicationRequest
#
# Data deduplication of spreadsheet files is mainly used to eliminate duplicate data in tables and ranges.
# 
# @name  string (required)    
# @deduplicationRegion  DeduplicationRegion (required)    
# @folder  string     
# @storageName  string     
# @password  string     
# @region  string     
# @checkExcelRestriction  boolean      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookDataDeduplicationRequest',
            description => 'PostWorkbookDataDeduplication Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_data_deduplication' } = { 
    	summary => 'Data deduplication of spreadsheet files is mainly used to eliminate duplicate data in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_workbook_data_deduplication{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostDataDeduplicationRequest
#
# Data deduplication of spreadsheet files is mainly used to eliminate duplicate data in tables and ranges.
# 
# @dataDeduplicationRequest  DataDeduplicationRequest (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDataDeduplicationRequest',
            description => 'PostDataDeduplication Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_data_deduplication' } = { 
    	summary => 'Data deduplication of spreadsheet files is mainly used to eliminate duplicate data in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_data_deduplication{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostWorkbookDataFillRequest
#
# Data filling for spreadsheet files is primarily used to fill empty data in tables and ranges.
# 
# @name  string (required)    
# @dataFill  DataFill (required)    
# @folder  string     
# @storageName  string     
# @password  string     
# @region  string     
# @checkExcelRestriction  boolean      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookDataFillRequest',
            description => 'PostWorkbookDataFill Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_data_fill' } = { 
    	summary => 'Data filling for spreadsheet files is primarily used to fill empty data in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_workbook_data_fill{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostDataFillRequest
#
# Data filling for spreadsheet files is primarily used to fill empty data in tables and ranges.
# 
# @dataFillRequest  DataFillRequest (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDataFillRequest',
            description => 'PostDataFill Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_data_fill' } = { 
    	summary => 'Data filling for spreadsheet files is primarily used to fill empty data in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_data_fill{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostDeleteIncompleteRowsRequest
#
# Deleting incomplete rows of spreadsheet files is mainly used to eliminate incomplete rows in tables and ranges.
# 
# @deleteIncompleteRowsRequest  DeleteIncompleteRowsRequest (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDeleteIncompleteRowsRequest',
            description => 'PostDeleteIncompleteRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_delete_incomplete_rows' } = { 
    	summary => 'Deleting incomplete rows of spreadsheet files is mainly used to eliminate incomplete rows in tables and ranges.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_delete_incomplete_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostDataTransformationRequest
#
# Transform spreadsheet data is mainly used to pivot columns, unpivot columns.
# 
# @dataTransformationRequest  DataTransformationRequest (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDataTransformationRequest',
            description => 'PostDataTransformation Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_data_transformation' } = { 
    	summary => 'Transform spreadsheet data is mainly used to pivot columns, unpivot columns.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_data_transformation{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# GetWorksheetHyperlinksRequest
#
# Retrieve descriptions of hyperlinks in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetHyperlinksRequest',
            description => 'GetWorksheetHyperlinks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_hyperlinks' } = { 
    	summary => 'Retrieve descriptions of hyperlinks in the worksheet.',
        params => $params,
        returns => 'HyperlinksResponse',
    };
}
#
# @return HyperlinksResponse
#
sub get_worksheet_hyperlinks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('HyperlinksResponse', $response);
    return $_response_object;
}

#
# GetWorksheetHyperlinkRequest
#
# Retrieve hyperlink description by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetHyperlinkRequest',
            description => 'GetWorksheetHyperlink Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_hyperlink' } = { 
    	summary => 'Retrieve hyperlink description by index in the worksheet.',
        params => $params,
        returns => 'HyperlinkResponse',
    };
}
#
# @return HyperlinkResponse
#
sub get_worksheet_hyperlink{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('HyperlinkResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetHyperlinkRequest
#
# Delete hyperlink by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetHyperlinkRequest',
            description => 'DeleteWorksheetHyperlink Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_hyperlink' } = { 
    	summary => 'Delete hyperlink by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_hyperlink{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetHyperlinkRequest
#
# Update hyperlink by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @hyperlink  Hyperlink (required)  Hyperlink object  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetHyperlinkRequest',
            description => 'PostWorksheetHyperlink Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_hyperlink' } = { 
    	summary => 'Update hyperlink by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_hyperlink{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetHyperlinkRequest
#
# Add hyperlink in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @firstRow  int (required)  First row of the hyperlink range.  
# @firstColumn  int (required)  First column of the hyperlink range.  
# @totalRows  int (required)  Number of rows in this hyperlink range.  
# @totalColumns  int (required)  Number of columns of this hyperlink range.  
# @address  string (required)  Address of the hyperlink.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetHyperlinkRequest',
            description => 'PutWorksheetHyperlink Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_hyperlink' } = { 
    	summary => 'Add hyperlink in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_hyperlink{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetHyperlinksRequest
#
# Delete all hyperlinks in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetHyperlinksRequest',
            description => 'DeleteWorksheetHyperlinks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_hyperlinks' } = { 
    	summary => 'Delete all hyperlinks in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_hyperlinks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAssembleRequest
#
# Assemble data files with template files to generate files in various formats.
# 
# @File  string (required)  File to upload  
# @datasource  string (required)    
# @outFormat  string   The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAssembleRequest',
            description => 'PostAssemble Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_assemble' } = { 
    	summary => 'Assemble data files with template files to generate files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_assemble{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostCompressRequest
#
# Compress files and generate target files in various formats, supported file formats are include Xls, Xlsx, Xlsm, Xlsb, Ods and more.
# 
# @File  string (required)  File to upload  
# @CompressLevel  int   Compress level. The compression ratio 1-100.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCompressRequest',
            description => 'PostCompress Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_compress' } = { 
    	summary => 'Compress files and generate target files in various formats, supported file formats are include Xls, Xlsx, Xlsm, Xlsb, Ods and more.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_compress{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostMergeRequest
#
# Merge cells in the worksheet.
# 
# @File  string (required)  File to upload  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @mergeToOneSheet  boolean   Merge all workbooks into a sheet.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostMergeRequest',
            description => 'PostMerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_merge' } = { 
    	summary => 'Merge cells in the worksheet.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_merge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostSplitRequest
#
# Split Excel spreadsheet files based on worksheets and create output files in various formats.
# 
# @File  string (required)  File to upload  
# @outFormat  string (required)  The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @from  int   sheet index  
# @to  int   sheet index  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSplitRequest',
            description => 'PostSplit Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_split' } = { 
    	summary => 'Split Excel spreadsheet files based on worksheets and create output files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_split{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostSearchRequest
#
# Search for specified text within Excel files.
# 
# @File  string (required)  File to upload  
# @text  string (required)  Find content  
# @password  string   The password needed to open an Excel file.  
# @sheetname  string   The worksheet name. Locate the specified text content in the worksheet.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSearchRequest',
            description => 'PostSearch Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_search' } = { 
    	summary => 'Search for specified text within Excel files.',
        params => $params,
        returns => 'ARRAY[TextItem]',
    };
}
#
# @return ARRAY[TextItem]
#
sub post_search{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[TextItem]', $response);
    return $_response_object;
}

#
# PostReplaceRequest
#
# Replace specified text with new text in Excel files.
# 
# @File  string (required)  File to upload  
# @text  string (required)  Find content  
# @newtext  string (required)  Replace content  
# @password  string   The password needed to open an Excel file.  
# @sheetname  string   The worksheet name. Locate the specified text content in the worksheet.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostReplaceRequest',
            description => 'PostReplace Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_replace' } = { 
    	summary => 'Replace specified text with new text in Excel files.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_replace{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostImportRequest
#
# Import data into an Excel file and generate output files in various formats.
# 
# @File  string (required)  File to upload  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostImportRequest',
            description => 'PostImport Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_import' } = { 
    	summary => 'Import data into an Excel file and generate output files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_import{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostWatermarkRequest
#
# Add Text Watermark to Excel files and generate output files in various formats.
# 
# @File  string (required)  File to upload  
# @text  string (required)  background text.  
# @color  string (required)  e.g. #1032ff  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWatermarkRequest',
            description => 'PostWatermark Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_watermark' } = { 
    	summary => 'Add Text Watermark to Excel files and generate output files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_watermark{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostClearObjectsRequest
#
# Clear internal elements in Excel files and generate output files in various formats.
# 
# @File  string (required)  File to upload  
# @objecttype  string (required)  chart/comment/picture/shape/listobject/hyperlink/oleobject/pivottable/validation/Background  
# @sheetname  string   The worksheet name, specify the scope of the deletion.  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostClearObjectsRequest',
            description => 'PostClearObjects Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_clear_objects' } = { 
    	summary => 'Clear internal elements in Excel files and generate output files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_clear_objects{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostReverseRequest
#
# Reverse rows or columns in Excel files and create output files in various formats.
# 
# @File  string (required)  File to upload  
# @rotateType  string (required)  rows/cols/both  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostReverseRequest',
            description => 'PostReverse Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_reverse' } = { 
    	summary => 'Reverse rows or columns in Excel files and create output files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_reverse{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostRepairRequest
#
# Repair abnormal files and generate files in various formats.
# 
# @File  string (required)  File to upload  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRepairRequest',
            description => 'PostRepair Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_repair' } = { 
    	summary => 'Repair abnormal files and generate files in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_repair{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostRotateRequest
#
# Rotate rows, columns, or other objects in Excel files and save them in various formats.
# 
# @File  string (required)  File to upload  
# @rotateType  string (required)  270/90/row/col/row2col  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRotateRequest',
            description => 'PostRotate Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_rotate' } = { 
    	summary => 'Rotate rows, columns, or other objects in Excel files and save them in various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_rotate{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostMetadataRequest
#
# Update document properties in Excel file, and save them is various formats.
# 
# @File  string (required)  File to upload  
# @cellsDocuments  ARRAY[CellsDocumentProperty] (required)  document properties  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @region  string   The regional settings for workbook.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostMetadataRequest',
            description => 'PostMetadata Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_metadata' } = { 
    	summary => 'Update document properties in Excel file, and save them is various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_metadata{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# GetMetadataRequest
#
# Get cells document properties.
# 
# @File  string (required)  File to upload  
# @type  string   Cells document property name.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetMetadataRequest',
            description => 'GetMetadata Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_metadata' } = { 
    	summary => 'Get cells document properties.',
        params => $params,
        returns => 'ARRAY[CellsDocumentProperty]',
    };
}
#
# @return ARRAY[CellsDocumentProperty]
#
sub get_metadata{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[CellsDocumentProperty]', $response);
    return $_response_object;
}

#
# DeleteMetadataRequest
#
# Delete cells document properties in Excel file, and save them is various formats.
# 
# @File  string (required)  File to upload  
# @type  string   Cells document property name.  
# @outFormat  string   The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteMetadataRequest',
            description => 'DeleteMetadata Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_metadata' } = { 
    	summary => 'Delete cells document properties in Excel file, and save them is various formats.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub delete_metadata{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# GetWorksheetListObjectsRequest
#
# Retrieve descriptions of ListObjects in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetListObjectsRequest',
            description => 'GetWorksheetListObjects Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_list_objects' } = { 
    	summary => 'Retrieve descriptions of ListObjects in the worksheet.',
        params => $params,
        returns => 'ListObjectsResponse',
    };
}
#
# @return ListObjectsResponse
#
sub get_worksheet_list_objects{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ListObjectsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetListObjectRequest
#
# Retrieve list object description by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listobjectindex  int (required)  list object index.  
# @format  string     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetListObjectRequest',
            description => 'GetWorksheetListObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_list_object' } = { 
    	summary => 'Retrieve list object description by index in the worksheet.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_list_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutWorksheetListObjectRequest
#
# Add a ListObject in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int   The start row of the list range.  
# @startColumn  int   The start column of the list range.  
# @endRow  int   The start row of the list range.  
# @endColumn  int   The start column of the list range.  
# @folder  string   The folder where the file is situated.  
# @hasHeaders  boolean   Indicate whether the range has headers.  
# @displayName  string   Indicate whether display name.  
# @showTotals  boolean   Indicate whether show totals.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetListObjectRequest',
            description => 'PutWorksheetListObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_list_object' } = { 
    	summary => 'Add a ListObject in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_list_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetListObjectsRequest
#
# Delete ListObjects in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetListObjectsRequest',
            description => 'DeleteWorksheetListObjects Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_list_objects' } = { 
    	summary => 'Delete ListObjects in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_list_objects{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetListObjectRequest
#
# Delete list object by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetListObjectRequest',
            description => 'DeleteWorksheetListObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_list_object' } = { 
    	summary => 'Delete list object by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_list_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectRequest
#
# Update list object by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  list Object index  
# @listObject  ListObject (required)  listObject dto in request body.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectRequest',
            description => 'PostWorksheetListObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object' } = { 
    	summary => 'Update list object by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectConvertToRangeRequest
#
# Convert list object to range in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectConvertToRangeRequest',
            description => 'PostWorksheetListObjectConvertToRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object_convert_to_range' } = { 
    	summary => 'Convert list object to range in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object_convert_to_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectSummarizeWithPivotTableRequest
#
# Create a pivot table with a list object in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  The list object index.  
# @destsheetName  string (required)  The target worksheet name.  
# @createPivotTableRequest  CreatePivotTableRequest (required)  Create pivot table request.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectSummarizeWithPivotTableRequest',
            description => 'PostWorksheetListObjectSummarizeWithPivotTable Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object_summarize_with_pivot_table' } = { 
    	summary => 'Create a pivot table with a list object in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object_summarize_with_pivot_table{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectSortTableRequest
#
# Sort list object in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  The list object index.  
# @dataSorter  DataSorter (required)  Represents sort order for the data range.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectSortTableRequest',
            description => 'PostWorksheetListObjectSortTable Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object_sort_table' } = { 
    	summary => 'Sort list object in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object_sort_table{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectRemoveDuplicatesRequest
#
# Remove duplicates in list object.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  The list object index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectRemoveDuplicatesRequest',
            description => 'PostWorksheetListObjectRemoveDuplicates Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object_remove_duplicates' } = { 
    	summary => 'Remove duplicates in list object.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object_remove_duplicates{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListObjectInsertSlicerRequest
#
# Insert slicer for list object.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @columnIndex  int (required)  The index of ListColumn in ListObject.ListColumns   
# @destCellName  string (required)  The cell in the upper-left corner of the Slicer range.   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListObjectInsertSlicerRequest',
            description => 'PostWorksheetListObjectInsertSlicer Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_object_insert_slicer' } = { 
    	summary => 'Insert slicer for list object.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_object_insert_slicer{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListColumnRequest
#
# Update list column in list object.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  The list object index.  
# @columnIndex  int (required)  Represents table column index.  
# @listColumn  ListColumn (required)  Represents table column description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListColumnRequest',
            description => 'PostWorksheetListColumn Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_column' } = { 
    	summary => 'Update list column in list object.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_column{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetListColumnsTotalRequest
#
# Update total of list columns in the table.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @tableTotalRequests  ARRAY[TableTotalRequest] (required)  Represents table column description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetListColumnsTotalRequest',
            description => 'PostWorksheetListColumnsTotal Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_list_columns_total' } = { 
    	summary => 'Update total of list columns in the table.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_list_columns_total{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetOleObjectsRequest
#
# Retrieve descriptions of OLE objects in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetOleObjectsRequest',
            description => 'GetWorksheetOleObjects Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_ole_objects' } = { 
    	summary => 'Retrieve descriptions of OLE objects in the worksheet.',
        params => $params,
        returns => 'OleObjectsResponse',
    };
}
#
# @return OleObjectsResponse
#
sub get_worksheet_ole_objects{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('OleObjectsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetOleObjectRequest
#
# Retrieve the OLE object in a specified format in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @objectNumber  int (required)  The object number.  
# @format  string   Object conversion format(PNG/TIFF/JPEG/GIF/EMF/BMP).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetOleObjectRequest',
            description => 'GetWorksheetOleObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_ole_object' } = { 
    	summary => 'Retrieve the OLE object in a specified format in the worksheet.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_ole_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# DeleteWorksheetOleObjectsRequest
#
# Delete all OLE objects in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetOleObjectsRequest',
            description => 'DeleteWorksheetOleObjects Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_ole_objects' } = { 
    	summary => 'Delete all OLE objects in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_ole_objects{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetOleObjectRequest
#
# Delete an OLE object in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @oleObjectIndex  int (required)  Ole object index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetOleObjectRequest',
            description => 'DeleteWorksheetOleObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_ole_object' } = { 
    	summary => 'Delete an OLE object in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_ole_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetOleObjectRequest
#
# Update an OLE object in worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @oleObjectIndex  int (required)  Ole object index.  
# @ole  OleObject (required)  Ole Object description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetOleObjectRequest',
            description => 'PostUpdateWorksheetOleObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_ole_object' } = { 
    	summary => 'Update an OLE object in worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_ole_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetOleObjectRequest
#
# Add an OLE object in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @upperLeftRow  int   Upper left row index  
# @upperLeftColumn  int   Upper left column index  
# @height  int   Height of oleObject, in unit of pixel  
# @width  int   Width of oleObject, in unit of pixel  
# @oleFile  string   OLE filename path(full file name).  
# @imageFile  string   Image filename path(full file name).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetOleObjectRequest',
            description => 'PutWorksheetOleObject Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_ole_object' } = { 
    	summary => 'Add an OLE object in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_ole_object{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetVerticalPageBreaksRequest
#
# Retrieve descriptions of vertical page breaks in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetVerticalPageBreaksRequest',
            description => 'GetVerticalPageBreaks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_vertical_page_breaks' } = { 
    	summary => 'Retrieve descriptions of vertical page breaks in the worksheet.',
        params => $params,
        returns => 'VerticalPageBreaksResponse',
    };
}
#
# @return VerticalPageBreaksResponse
#
sub get_vertical_page_breaks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('VerticalPageBreaksResponse', $response);
    return $_response_object;
}

#
# GetHorizontalPageBreaksRequest
#
# Retrieve descriptions of horizontal page breaks in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetHorizontalPageBreaksRequest',
            description => 'GetHorizontalPageBreaks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_horizontal_page_breaks' } = { 
    	summary => 'Retrieve descriptions of horizontal page breaks in the worksheet.',
        params => $params,
        returns => 'HorizontalPageBreaksResponse',
    };
}
#
# @return HorizontalPageBreaksResponse
#
sub get_horizontal_page_breaks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('HorizontalPageBreaksResponse', $response);
    return $_response_object;
}

#
# GetVerticalPageBreakRequest
#
# Retrieve a vertical page break description in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The zero based index of the element.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetVerticalPageBreakRequest',
            description => 'GetVerticalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_vertical_page_break' } = { 
    	summary => 'Retrieve a vertical page break description in the worksheet.',
        params => $params,
        returns => 'VerticalPageBreakResponse',
    };
}
#
# @return VerticalPageBreakResponse
#
sub get_vertical_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('VerticalPageBreakResponse', $response);
    return $_response_object;
}

#
# GetHorizontalPageBreakRequest
#
# Retrieve a horizontal page break descripton in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The zero based index of the element.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetHorizontalPageBreakRequest',
            description => 'GetHorizontalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_horizontal_page_break' } = { 
    	summary => 'Retrieve a horizontal page break descripton in the worksheet.',
        params => $params,
        returns => 'HorizontalPageBreakResponse',
    };
}
#
# @return HorizontalPageBreakResponse
#
sub get_horizontal_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('HorizontalPageBreakResponse', $response);
    return $_response_object;
}

#
# PutVerticalPageBreakRequest
#
# Add a vertical page break in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellname  string   Cell name  
# @column  int   Column index, zero based.  
# @row  int   Row index, zero based.  
# @startRow  int   Start row index, zero based.  
# @endRow  int   End row index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutVerticalPageBreakRequest',
            description => 'PutVerticalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_vertical_page_break' } = { 
    	summary => 'Add a vertical page break in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_vertical_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutHorizontalPageBreakRequest
#
# Add a horizontal page breaks in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellname  string   Cell name  
# @row  int   Row index, zero based.  
# @column  int   Column index, zero based.  
# @startColumn  int   Start column index, zero based.  
# @endColumn  int   End column index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutHorizontalPageBreakRequest',
            description => 'PutHorizontalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_horizontal_page_break' } = { 
    	summary => 'Add a horizontal page breaks in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_horizontal_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteVerticalPageBreaksRequest
#
# Delete vertical page breaks in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @column  int   Column index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteVerticalPageBreaksRequest',
            description => 'DeleteVerticalPageBreaks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_vertical_page_breaks' } = { 
    	summary => 'Delete vertical page breaks in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_vertical_page_breaks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteHorizontalPageBreaksRequest
#
# Delete horizontal page breaks in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int   Row index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteHorizontalPageBreaksRequest',
            description => 'DeleteHorizontalPageBreaks Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_horizontal_page_breaks' } = { 
    	summary => 'Delete horizontal page breaks in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_horizontal_page_breaks{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteVerticalPageBreakRequest
#
# Delete a vertical page break in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Removes the vertical page break element at a specified name. Element index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteVerticalPageBreakRequest',
            description => 'DeleteVerticalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_vertical_page_break' } = { 
    	summary => 'Delete a vertical page break in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_vertical_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteHorizontalPageBreakRequest
#
# Delete a horizontal page break in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Removes the horizontal page break element at a specified name. Element index, zero based.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteHorizontalPageBreakRequest',
            description => 'DeleteHorizontalPageBreak Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_horizontal_page_break' } = { 
    	summary => 'Delete a horizontal page break in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_horizontal_page_break{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetPageSetupRequest
#
# Retrieve page setup description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetPageSetupRequest',
            description => 'GetPageSetup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_page_setup' } = { 
    	summary => 'Retrieve page setup description in the worksheet.',
        params => $params,
        returns => 'PageSetupResponse',
    };
}
#
# @return PageSetupResponse
#
sub get_page_setup{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PageSetupResponse', $response);
    return $_response_object;
}

#
# PostPageSetupRequest
#
# Update page setup in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pageSetup  PageSetup (required)  PageSetup Page Setup description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPageSetupRequest',
            description => 'PostPageSetup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_page_setup' } = { 
    	summary => 'Update page setup in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_page_setup{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteHeaderFooterRequest
#
# Clear header and footer in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteHeaderFooterRequest',
            description => 'DeleteHeaderFooter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_header_footer' } = { 
    	summary => 'Clear header and footer in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_header_footer{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetHeaderRequest
#
# Retrieve page header description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetHeaderRequest',
            description => 'GetHeader Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_header' } = { 
    	summary => 'Retrieve page header description in the worksheet.',
        params => $params,
        returns => 'PageSectionsResponse',
    };
}
#
# @return PageSectionsResponse
#
sub get_header{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PageSectionsResponse', $response);
    return $_response_object;
}

#
# PostHeaderRequest
#
# Update page header in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @section  int (required)  0:Left Section. 1:Center Section 2:Right Section  
# @script  string (required)  Header format script.  
# @isFirstPage  boolean (required)  Is first page(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostHeaderRequest',
            description => 'PostHeader Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_header' } = { 
    	summary => 'Update page header in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_header{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetFooterRequest
#
# Retrieve page footer description in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetFooterRequest',
            description => 'GetFooter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_footer' } = { 
    	summary => 'Retrieve page footer description in the worksheet.',
        params => $params,
        returns => 'PageSectionsResponse',
    };
}
#
# @return PageSectionsResponse
#
sub get_footer{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PageSectionsResponse', $response);
    return $_response_object;
}

#
# PostFooterRequest
#
# Update page footer in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @section  int (required)  0:Left Section. 1:Center Section 2:Right Section  
# @script  string (required)  Header format script.  
# @isFirstPage  boolean (required)  Is first page(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostFooterRequest',
            description => 'PostFooter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_footer' } = { 
    	summary => 'Update page footer in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_footer{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostFitWideToPagesRequest
#
# Set the scale at which the page will fit wide when printed on the sheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostFitWideToPagesRequest',
            description => 'PostFitWideToPages Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_fit_wide_to_pages' } = { 
    	summary => 'Set the scale at which the page will fit wide when printed on the sheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_fit_wide_to_pages{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostFitTallToPagesRequest
#
# Set the scale at which the page will fit tall when printed on the sheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostFitTallToPagesRequest',
            description => 'PostFitTallToPages Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_fit_tall_to_pages' } = { 
    	summary => 'Set the scale at which the page will fit tall when printed on the sheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_fit_tall_to_pages{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPicturesRequest
#
# Retrieve descriptions of pictures in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPicturesRequest',
            description => 'GetWorksheetPictures Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_pictures' } = { 
    	summary => 'Retrieve descriptions of pictures in the worksheet.',
        params => $params,
        returns => 'PicturesResponse',
    };
}
#
# @return PicturesResponse
#
sub get_worksheet_pictures{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PicturesResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPictureWithFormatRequest
#
# Retrieve a picture by number in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pictureNumber  int (required)  The picture index.  
# @format  string (required)  Picture conversion format(PNG/TIFF/JPEG/GIF/EMF/BMP).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPictureWithFormatRequest',
            description => 'GetWorksheetPictureWithFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_picture_with_format' } = { 
    	summary => 'Retrieve a picture by number in the worksheet.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_picture_with_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutWorksheetAddPictureRequest
#
# Add a new picture in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @picture  Picture   Pictute object  
# @upperLeftRow  int   The image upper left row.  
# @upperLeftColumn  int   The image upper left column.  
# @lowerRightRow  int   The image low right row.  
# @lowerRightColumn  int   The image low right column.  
# @picturePath  string   The picture path, if not provided the picture data is inspected in the request body.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetAddPictureRequest',
            description => 'PutWorksheetAddPicture Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_add_picture' } = { 
    	summary => 'Add a new picture in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_add_picture{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# AddPictureInCellRequest
#
# add new picture in the cells.
# 
# @name  string (required)    
# @sheetName  string (required)    
# @cellName  string (required)    
# @picturePath  string (required)    
# @folder  string     
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'AddPictureInCellRequest',
            description => 'AddPictureInCell Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'add_picture_in_cell' } = { 
    	summary => 'add new picture in the cells.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub add_picture_in_cell{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetPictureRequest
#
# Update a picture by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pictureIndex  int (required)  The picture`s index.  
# @picture  Picture (required)  Picture object description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetPictureRequest',
            description => 'PostWorksheetPicture Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_picture' } = { 
    	summary => 'Update a picture by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_picture{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPictureRequest
#
# Delete a picture object by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worsheet name.  
# @pictureIndex  int (required)  Picture index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPictureRequest',
            description => 'DeleteWorksheetPicture Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_picture' } = { 
    	summary => 'Delete a picture object by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_picture{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPicturesRequest
#
# Delete all pictures in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPicturesRequest',
            description => 'DeleteWorksheetPictures Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_pictures' } = { 
    	summary => 'Delete all pictures in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_pictures{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPivotTablesRequest
#
# Retrieve descriptions of pivottables  in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPivotTablesRequest',
            description => 'GetWorksheetPivotTables Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_pivot_tables' } = { 
    	summary => 'Retrieve descriptions of pivottables  in the worksheet.',
        params => $params,
        returns => 'PivotTablesResponse',
    };
}
#
# @return PivotTablesResponse
#
sub get_worksheet_pivot_tables{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PivotTablesResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPivotTableRequest
#
# Retrieve PivotTable information by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivottableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPivotTableRequest',
            description => 'GetWorksheetPivotTable Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_pivot_table' } = { 
    	summary => 'Retrieve PivotTable information by index in the worksheet.',
        params => $params,
        returns => 'PivotTableResponse',
    };
}
#
# @return PivotTableResponse
#
sub get_worksheet_pivot_table{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PivotTableResponse', $response);
    return $_response_object;
}

#
# GetPivotTableFieldRequest
#
# Retrieve descriptions of pivot fields in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @pivotFieldIndex  int (required)  The pivot field index of PivotTable.  
# @pivotFieldType  string (required)  The field area type(column/row).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetPivotTableFieldRequest',
            description => 'GetPivotTableField Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_pivot_table_field' } = { 
    	summary => 'Retrieve descriptions of pivot fields in the PivotTable.',
        params => $params,
        returns => 'PivotFieldResponse',
    };
}
#
# @return PivotFieldResponse
#
sub get_pivot_table_field{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PivotFieldResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPivotTableFiltersRequest
#
# Gets PivotTable filters in worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPivotTableFiltersRequest',
            description => 'GetWorksheetPivotTableFilters Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_pivot_table_filters' } = { 
    	summary => 'Gets PivotTable filters in worksheet.',
        params => $params,
        returns => 'PivotFiltersResponse',
    };
}
#
# @return PivotFiltersResponse
#
sub get_worksheet_pivot_table_filters{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PivotFiltersResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPivotTableFilterRequest
#
# Retrieve PivotTable filters in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index in the worksheet.  
# @filterIndex  int (required)  The pivot filter index of PivotTable.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPivotTableFilterRequest',
            description => 'GetWorksheetPivotTableFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_pivot_table_filter' } = { 
    	summary => 'Retrieve PivotTable filters in the worksheet.',
        params => $params,
        returns => 'PivotFilterResponse',
    };
}
#
# @return PivotFilterResponse
#
sub get_worksheet_pivot_table_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('PivotFilterResponse', $response);
    return $_response_object;
}

#
# PutWorksheetPivotTableRequest
#
# Add a PivotTable in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @sourceData  string   The data for the new PivotTable cache.  
# @destCellName  string   The cell in the upper-left corner of the destination range for the PivotTable report.  
# @tableName  string   The name of the new PivotTable.  
# @useSameSource  boolean   Indicates whether using same data source when another existing PivotTable has used this data source. If the property is true, it will save memory.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetPivotTableRequest',
            description => 'PutWorksheetPivotTable Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_pivot_table' } = { 
    	summary => 'Add a PivotTable in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_pivot_table{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutPivotTableFieldRequest
#
# Add a pivot field in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @pivotFieldType  string (required)  The fields area type.  
# @pivotTableFieldRequest  PivotTableFieldRequest (required)  PivotTableFieldRequest The PivotTable field request.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutPivotTableFieldRequest',
            description => 'PutPivotTableField Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_pivot_table_field' } = { 
    	summary => 'Add a pivot field in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_pivot_table_field{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetPivotTableFilterRequest
#
# Add a pivot filter to the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @filter  PivotFilter (required)  PivotFilter Pivot filter description.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetPivotTableFilterRequest',
            description => 'PutWorksheetPivotTableFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_pivot_table_filter' } = { 
    	summary => 'Add a pivot filter to the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_pivot_table_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableFieldHideItemRequest
#
# Hide a pivot field item in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @fieldIndex  int (required)  The pivot field index.  
# @itemIndex  int (required)  The index of the pivot item in the pivot field.  
# @isHide  boolean (required)  Whether the specific PivotItem is hidden(true/false).  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableFieldHideItemRequest',
            description => 'PostPivotTableFieldHideItem Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_field_hide_item' } = { 
    	summary => 'Hide a pivot field item in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_field_hide_item{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableFieldMoveToRequest
#
# Move a pivot field in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @fieldIndex  int (required)  The pivot field index.  
# @from  string (required)  The fields area type(Column/Row/Page/Data/Undefined).  
# @to  string (required)  The fields area type(Column/Row/Page/Data/Undefined).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableFieldMoveToRequest',
            description => 'PostPivotTableFieldMoveTo Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_field_move_to' } = { 
    	summary => 'Move a pivot field in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_field_move_to{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableCellStyleRequest
#
# Update cell style in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @column  int (required)  The column index of the cell.  
# @row  int (required)  The row index of the cell.  
# @style  Style (required)  Style Style description in request body.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableCellStyleRequest',
            description => 'PostPivotTableCellStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_cell_style' } = { 
    	summary => 'Update cell style in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_cell_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableStyleRequest
#
# Update style in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @style  Style (required)  StyleStyle description in request body.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableStyleRequest',
            description => 'PostPivotTableStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_style' } = { 
    	summary => 'Update style in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableUpdatePivotFieldsRequest
#
# Update pivot fields in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @pivotField  PivotField (required)  PivotFieldRepresents pivot field.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableUpdatePivotFieldsRequest',
            description => 'PostPivotTableUpdatePivotFields Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_update_pivot_fields' } = { 
    	summary => 'Update pivot fields in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_update_pivot_fields{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostPivotTableUpdatePivotFieldRequest
#
# Update pivot field in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @pivotFieldIndex  int (required)  The pivot field index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @pivotField  PivotField (required)  Represents pivot field.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostPivotTableUpdatePivotFieldRequest',
            description => 'PostPivotTableUpdatePivotField Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_update_pivot_field' } = { 
    	summary => 'Update pivot field in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_pivot_table_update_pivot_field{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetPivotTableCalculateRequest
#
# Calculate pivottable`s data to cells.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetPivotTableCalculateRequest',
            description => 'PostWorksheetPivotTableCalculate Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_pivot_table_calculate' } = { 
    	summary => 'Calculate pivottable`s data to cells.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_pivot_table_calculate{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetPivotTableMoveRequest
#
# Move PivotTable in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @row  int   Row index.  
# @column  int   Column index.  
# @destCellName  string   The dest cell name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetPivotTableMoveRequest',
            description => 'PostWorksheetPivotTableMove Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_pivot_table_move' } = { 
    	summary => 'Move PivotTable in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_pivot_table_move{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPivotTablesRequest
#
# Delete PivotTables in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPivotTablesRequest',
            description => 'DeleteWorksheetPivotTables Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_pivot_tables' } = { 
    	summary => 'Delete PivotTables in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_pivot_tables{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPivotTableRequest
#
# Delete PivotTable by index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPivotTableRequest',
            description => 'DeleteWorksheetPivotTable Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_pivot_table' } = { 
    	summary => 'Delete PivotTable by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_pivot_table{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeletePivotTableFieldRequest
#
# Delete a pivot field in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldType  string (required)  The fields area type.  
# @pivotTableFieldRequest  PivotTableFieldRequest (required)  PivotTableFieldRequest PivotTable field request.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeletePivotTableFieldRequest',
            description => 'DeletePivotTableField Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_pivot_table_field' } = { 
    	summary => 'Delete a pivot field in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_pivot_table_field{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPivotTableFiltersRequest
#
# Delete all pivot filters in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  The PivotTable index.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPivotTableFiltersRequest',
            description => 'DeleteWorksheetPivotTableFilters Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_pivot_table_filters' } = { 
    	summary => 'Delete all pivot filters in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_pivot_table_filters{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetPivotTableFilterRequest
#
# Delete a pivot filter in the PivotTable.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @fieldIndex  int (required)  Gets the PivotField Object at the specific index.  
# @needReCalculate  boolean   Whether the specific PivotTable calculate(true/false).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetPivotTableFilterRequest',
            description => 'DeleteWorksheetPivotTableFilter Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_pivot_table_filter' } = { 
    	summary => 'Delete a pivot filter in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_pivot_table_filter{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetDocumentPropertiesRequest
#
# Retrieve descriptions of Excel file properties.
# 
# @name  string (required)  The workbook name.  
# @type  string   Excel property type.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetDocumentPropertiesRequest',
            description => 'GetDocumentProperties Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_document_properties' } = { 
    	summary => 'Retrieve descriptions of Excel file properties.',
        params => $params,
        returns => 'CellsDocumentPropertiesResponse',
    };
}
#
# @return CellsDocumentPropertiesResponse
#
sub get_document_properties{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsDocumentPropertiesResponse', $response);
    return $_response_object;
}

#
# PutDocumentPropertyRequest
#
# Set or add an Excel property.
# 
# @name  string (required)  The workbook name.  
# @property  CellsDocumentProperty (required)  Get or set the value of the property.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutDocumentPropertyRequest',
            description => 'PutDocumentProperty Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_document_property' } = { 
    	summary => 'Set or add an Excel property.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_document_property{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetDocumentPropertyRequest
#
# Get Excel property by name.
# 
# @name  string (required)  The workbook name.  
# @propertyName  string (required)  The property name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetDocumentPropertyRequest',
            description => 'GetDocumentProperty Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_document_property' } = { 
    	summary => 'Get Excel property by name.',
        params => $params,
        returns => 'CellsDocumentPropertyResponse',
    };
}
#
# @return CellsDocumentPropertyResponse
#
sub get_document_property{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsDocumentPropertyResponse', $response);
    return $_response_object;
}

#
# DeleteDocumentPropertyRequest
#
# Delete an Excel property.
# 
# @name  string (required)  The workbook name.  
# @propertyName  string (required)  The property name.  
# @type  string     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteDocumentPropertyRequest',
            description => 'DeleteDocumentProperty Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_document_property' } = { 
    	summary => 'Delete an Excel property.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_document_property{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteDocumentPropertiesRequest
#
# Delete all custom document properties and reset built-in ones.
# 
# @name  string (required)  The workbook name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteDocumentPropertiesRequest',
            description => 'DeleteDocumentProperties Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_document_properties' } = { 
    	summary => 'Delete all custom document properties and reset built-in ones.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_document_properties{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostDigitalSignatureRequest
#
# Excel file digital signature.
# 
# @name  string (required)  The file name.  
# @digitalsignaturefile  string (required)  The digital signature file path should include both the folder and the file name, along with the extension.  
# @password  string (required)  The password needed to open an Excel file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostDigitalSignatureRequest',
            description => 'PostDigitalSignature Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_digital_signature' } = { 
    	summary => 'Excel file digital signature.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_digital_signature{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostEncryptWorkbookRequest
#
# Excel Encryption.
# 
# @name  string (required)  The file name.  
# @encryption  WorkbookEncryptionRequest (required)  WorkbookEncryptionRequestEncryption parameters.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostEncryptWorkbookRequest',
            description => 'PostEncryptWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_encrypt_workbook' } = { 
    	summary => 'Excel Encryption.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_encrypt_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteDecryptWorkbookRequest
#
# Excel files decryption.
# 
# @name  string (required)  The file name.  
# @encryption  WorkbookEncryptionRequest (required)  WorkbookEncryptionRequestEncryption parameters.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteDecryptWorkbookRequest',
            description => 'DeleteDecryptWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_decrypt_workbook' } = { 
    	summary => 'Excel files decryption.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_decrypt_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostProtectWorkbookRequest
#
# Excel protection.
# 
# @name  string (required)  The file name.  
# @protectWorkbookRequest  ProtectWorkbookRequest (required)  The protection settings.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostProtectWorkbookRequest',
            description => 'PostProtectWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_protect_workbook' } = { 
    	summary => 'Excel protection.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_protect_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteUnProtectWorkbookRequest
#
# Excel unprotection.
# 
# @name  string (required)  The file name.  
# @password  string (required)  Protection settings, only password can be specified.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteUnProtectWorkbookRequest',
            description => 'DeleteUnProtectWorkbook Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_un_protect_workbook' } = { 
    	summary => 'Excel unprotection.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_un_protect_workbook{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutDocumentProtectFromChangesRequest
#
# Excel file write protection.
# 
# @name  string (required)  The file name.  
# @password  PasswordRequest (required)  The password needed to open an Excel file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutDocumentProtectFromChangesRequest',
            description => 'PutDocumentProtectFromChanges Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_document_protect_from_changes' } = { 
    	summary => 'Excel file write protection.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_document_protect_from_changes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteDocumentUnProtectFromChangesRequest
#
# Excel file cancel write protection.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteDocumentUnProtectFromChangesRequest',
            description => 'DeleteDocumentUnProtectFromChanges Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_document_un_protect_from_changes' } = { 
    	summary => 'Excel file cancel write protection.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_document_un_protect_from_changes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUnlockRequest
#
# Unlock Excel files.
# 
# @File  string (required)  File to upload  
# @password  string (required)  The password needed to open an Excel file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUnlockRequest',
            description => 'PostUnlock Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_unlock' } = { 
    	summary => 'Unlock Excel files.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_unlock{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostLockRequest
#
# Lock Excel files.
# 
# @File  string (required)  File to upload  
# @password  string (required)  The password needed to open an Excel file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostLockRequest',
            description => 'PostLock Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_lock' } = { 
    	summary => 'Lock Excel files.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_lock{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostProtectRequest
#
# Excel files encryption.
# 
# @File  string (required)  File to upload  
# @protectWorkbookRequest  ProtectWorkbookRequest (required)    
# @password  string   The password needed to open an Excel file.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostProtectRequest',
            description => 'PostProtect Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_protect' } = { 
    	summary => 'Excel files encryption.',
        params => $params,
        returns => 'FilesResult',
    };
}
#
# @return FilesResult
#
sub post_protect{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangesCopyRequest
#
# Copy content from the source range to the destination range in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeCopyRequest (required)  RangeCopyRequestcopydata,copystyle,copyto,copyvalue  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangesCopyRequest',
            description => 'PostWorksheetCellsRangesCopy Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_ranges_copy' } = { 
    	summary => 'Copy content from the source range to the destination range in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_ranges_copy{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeMergeRequest
#
# Merge a range of cells into a single cell.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  Rangerange description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeMergeRequest',
            description => 'PostWorksheetCellsRangeMerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_merge' } = { 
    	summary => 'Merge a range of cells into a single cell.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_merge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeUnMergeRequest
#
# Unmerge merged cells within this range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  Range range description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeUnMergeRequest',
            description => 'PostWorksheetCellsRangeUnMerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_un_merge' } = { 
    	summary => 'Unmerge merged cells within this range.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_un_merge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeStyleRequest
#
# Set the style for the specified range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeSetStyleRequest (required)  RangeSetStyleRequest Range Set Style Request   
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeStyleRequest',
            description => 'PostWorksheetCellsRangeStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_style' } = { 
    	summary => 'Set the style for the specified range.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCellsRangeValueRequest
#
# Retrieve the values of cells within the specified range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @namerange  string   The range name.  
# @firstRow  int   Gets the index of the first row of the range.  
# @firstColumn  int   Gets the index of the first columnn of the range.  
# @rowCount  int   Gets the count of rows in the range.  
# @columnCount  int   Gets the count of columns in the range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCellsRangeValueRequest',
            description => 'GetWorksheetCellsRangeValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_cells_range_value' } = { 
    	summary => 'Retrieve the values of cells within the specified range.',
        params => $params,
        returns => 'RangeValueResponse',
    };
}
#
# @return RangeValueResponse
#
sub get_worksheet_cells_range_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RangeValueResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeValueRequest
#
# Assign a value to the range; if necessary, the value will be converted to another data type, and the cell`s number format will be reset.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  The range in worksheet.   
# @Value  string (required)  Input value.  
# @isConverted  boolean   True: converted to other data type if appropriate.  
# @setStyle  boolean   True: set the number format to cell`s style when converting to other data type.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeValueRequest',
            description => 'PostWorksheetCellsRangeValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_value' } = { 
    	summary => 'Assign a value to the range; if necessary, the value will be converted to another data type, and the cell`s number format will be reset.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeMoveToRequest
#
# Move the current range to the destination range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  range in worksheet   
# @destRow  int (required)  The start row of the dest range.  
# @destColumn  int (required)  The start column of the dest range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeMoveToRequest',
            description => 'PostWorksheetCellsRangeMoveTo Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_move_to' } = { 
    	summary => 'Move the current range to the destination range.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_move_to{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeSortRequest
#
# Perform data sorting around a range of cells.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeSortRequest  RangeSortRequest (required)  RangeSortRequest Range Sort Request   
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeSortRequest',
            description => 'PostWorksheetCellsRangeSort Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_sort' } = { 
    	summary => 'Perform data sorting around a range of cells.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_sort{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeOutlineBorderRequest
#
# Apply an outline border around a range of cells.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeSetOutlineBorderRequest (required)  RangeSetOutlineBorderRequest Range Set OutlineBorder Request.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeOutlineBorderRequest',
            description => 'PostWorksheetCellsRangeOutlineBorder Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_outline_border' } = { 
    	summary => 'Apply an outline border around a range of cells.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_outline_border{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeColumnWidthRequest
#
# Set the column width of the specified range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  Range The range object.  
# @value  double (required)  Sets the column width of this range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeColumnWidthRequest',
            description => 'PostWorksheetCellsRangeColumnWidth Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_column_width' } = { 
    	summary => 'Set the column width of the specified range.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_column_width{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeRowHeightRequest
#
# Sets row height of range.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  The range object.  
# @value  double (required)  Sets the column height of this range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeRowHeightRequest',
            description => 'PostWorksheetCellsRangeRowHeight Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_row_height' } = { 
    	summary => 'Sets row height of range.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_cells_range_row_height{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCellsRangeToImageRequest
#
# 
# 
# @name  string (required)    
# @sheetName  string (required)    
# @rangeConvertRequest  RangeConvertRequest (required)    
# @folder  string     
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCellsRangeToImageRequest',
            description => 'PostWorksheetCellsRangeToImage Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_cells_range_to_image' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_worksheet_cells_range_to_image{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutWorksheetCellsRangeRequest
#
# Insert a range of cells and shift existing cells based on the specified shift option.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  The range object.  
# @shift  string (required)  Represent the shift options when deleting a range of cells(Down/Left/None/Right/Up).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetCellsRangeRequest',
            description => 'PutWorksheetCellsRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_cells_range' } = { 
    	summary => 'Insert a range of cells and shift existing cells based on the specified shift option.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_cells_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetCellsRangeRequest
#
# Delete a range of cells and shift existing cells based on the specified shift option.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string (required)  The range object.  
# @shift  string (required)  Represent the shift options when deleting a range of cells(Down/Left/None/Right/Up).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetCellsRangeRequest',
            description => 'DeleteWorksheetCellsRange Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_cells_range' } = { 
    	summary => 'Delete a range of cells and shift existing cells based on the specified shift option.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_cells_range{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetShapesRequest
#
# Retrieve descriptions of shapes in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetShapesRequest',
            description => 'GetWorksheetShapes Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_shapes' } = { 
    	summary => 'Retrieve descriptions of shapes in the worksheet.',
        params => $params,
        returns => 'ShapesResponse',
    };
}
#
# @return ShapesResponse
#
sub get_worksheet_shapes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapesResponse', $response);
    return $_response_object;
}

#
# GetWorksheetShapeRequest
#
# Retrieve description of shape in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetShapeRequest',
            description => 'GetWorksheetShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_shape' } = { 
    	summary => 'Retrieve description of shape in the worksheet.',
        params => $params,
        returns => 'ShapeResponse',
    };
}
#
# @return ShapeResponse
#
sub get_worksheet_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeResponse', $response);
    return $_response_object;
}

#
# PutWorksheetShapeRequest
#
# Add a shape in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeDTO  Shape     
# @DrawingType  string   Shape object type  
# @upperLeftRow  int   Upper left row index.  
# @upperLeftColumn  int   Upper left column index.  
# @top  int   Represents the vertical offset of Spinner from its left row, in unit of pixel.  
# @left  int   Represents the horizontal offset of Spinner from its left column, in unit of pixel.  
# @width  int   Represents the height of Spinner, in unit of pixel.  
# @height  int   Represents the width of Spinner, in unit of pixel.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetShapeRequest',
            description => 'PutWorksheetShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_shape' } = { 
    	summary => 'Add a shape in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetShapesRequest
#
# Delete all shapes in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetShapesRequest',
            description => 'DeleteWorksheetShapes Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_shapes' } = { 
    	summary => 'Delete all shapes in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_shapes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetShapeRequest
#
# Delete a shape in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetShapeRequest',
            description => 'DeleteWorksheetShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_shape' } = { 
    	summary => 'Delete a shape in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetShapeRequest
#
# Update a shape in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @dto  Shape (required)  The shape description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetShapeRequest',
            description => 'PostWorksheetShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_shape' } = { 
    	summary => 'Update a shape in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetGroupShapeRequest
#
# Group shapes in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @listShape  ARRAY[int?] (required)  Shape index array.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetGroupShapeRequest',
            description => 'PostWorksheetGroupShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_group_shape' } = { 
    	summary => 'Group shapes in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_group_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetUngroupShapeRequest
#
# Ungroup shapes in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)    
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetUngroupShapeRequest',
            description => 'PostWorksheetUngroupShape Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_ungroup_shape' } = { 
    	summary => 'Ungroup shapes in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_ungroup_shape{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetSparklineGroupsRequest
#
# Retrieve descriptions of sparkline groups in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetSparklineGroupsRequest',
            description => 'GetWorksheetSparklineGroups Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_sparkline_groups' } = { 
    	summary => 'Retrieve descriptions of sparkline groups in the worksheet.',
        params => $params,
        returns => 'SparklineGroupsResponse',
    };
}
#
# @return SparklineGroupsResponse
#
sub get_worksheet_sparkline_groups{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SparklineGroupsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetSparklineGroupRequest
#
# Retrieve description of a sparkline group in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineIndex  int (required)  The zero based index of the element.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetSparklineGroupRequest',
            description => 'GetWorksheetSparklineGroup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_sparkline_group' } = { 
    	summary => 'Retrieve description of a sparkline group in the worksheet.',
        params => $params,
        returns => 'SparklineGroupResponse',
    };
}
#
# @return SparklineGroupResponse
#
sub get_worksheet_sparkline_group{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SparklineGroupResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetSparklineGroupsRequest
#
# Delete sparkline groups in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetSparklineGroupsRequest',
            description => 'DeleteWorksheetSparklineGroups Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_sparkline_groups' } = { 
    	summary => 'Delete sparkline groups in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_sparkline_groups{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetSparklineGroupRequest
#
# Delete a sparkline group in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineIndex  int (required)  The zero based index of the element.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetSparklineGroupRequest',
            description => 'DeleteWorksheetSparklineGroup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_sparkline_group' } = { 
    	summary => 'Delete a sparkline group in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_sparkline_group{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetSparklineGroupRequest
#
# Add a sparkline group in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @type  string (required)  Represents the sparkline types(Line/Column/Stacked).  
# @dataRange  string (required)  Specifies the data range of the sparkline group.  
# @isVertical  boolean (required)  Specifies whether to plot the sparklines from the data range by row or by column.  
# @locationRange  string (required)  Specifies where the sparklines to be placed.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetSparklineGroupRequest',
            description => 'PutWorksheetSparklineGroup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_sparkline_group' } = { 
    	summary => 'Add a sparkline group in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_sparkline_group{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetSparklineGroupRequest
#
# Update a sparkline group in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineGroupIndex  int (required)  The zero based index of the element.  
# @sparklineGroup  SparklineGroup (required)  Spark line group description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetSparklineGroupRequest',
            description => 'PostWorksheetSparklineGroup Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_sparkline_group' } = { 
    	summary => 'Update a sparkline group in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_sparkline_group{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCharacterCountRequest
#
# 
# 
# @characterCountOptions  CharacterCountOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCharacterCountRequest',
            description => 'PostCharacterCount Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_character_count' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_character_count{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostWordsCountRequest
#
# 
# 
# @wordsCountOptions  WordsCountOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWordsCountRequest',
            description => 'PostWordsCount Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_words_count' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_words_count{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostSpecifyWordsCountRequest
#
# 
# 
# @specifyWordsCountOptions  SpecifyWordsCountOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSpecifyWordsCountRequest',
            description => 'PostSpecifyWordsCount Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_specify_words_count' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_specify_words_count{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostRunTaskRequest
#
# Run tasks.
# 
# @TaskData  TaskData (required)  Task Data Descrition   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRunTaskRequest',
            description => 'PostRunTask Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_run_task' } = { 
    	summary => 'Run tasks.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_run_task{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PostAddTextContentRequest
#
# Adds text content to a workbook at specified positions within cells based on provided options using ASP.NET Core Web API.
# 
# @addTextOptions  AddTextOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAddTextContentRequest',
            description => 'PostAddTextContent Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_add_text_content' } = { 
    	summary => 'Adds text content to a workbook at specified positions within cells based on provided options using ASP.NET Core Web API.',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_add_text_content{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostTrimContentRequest
#
# 
# 
# @trimContentOptions  TrimContentOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostTrimContentRequest',
            description => 'PostTrimContent Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_trim_content' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_trim_content{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostUpdateWordCaseRequest
#
# 
# 
# @wordCaseOptions  WordCaseOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWordCaseRequest',
            description => 'PostUpdateWordCase Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_word_case' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_update_word_case{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostRemoveCharactersRequest
#
# 
# 
# @removeCharactersOptions  RemoveCharactersOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRemoveCharactersRequest',
            description => 'PostRemoveCharacters Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_remove_characters' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_remove_characters{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostConvertTextRequest
#
# 
# 
# @convertTextOptions  ConvertTextOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostConvertTextRequest',
            description => 'PostConvertText Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_convert_text' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_convert_text{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostRemoveDuplicatesRequest
#
# 
# 
# @removeDuplicatesOptions  RemoveDuplicatesOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRemoveDuplicatesRequest',
            description => 'PostRemoveDuplicates Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_remove_duplicates' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_remove_duplicates{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostExtractTextRequest
#
# 
# 
# @extractTextOptions  ExtractTextOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostExtractTextRequest',
            description => 'PostExtractText Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_extract_text' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_extract_text{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# PostSplitTextRequest
#
# 
# 
# @splitTextOptions  SplitTextOptions (required)     
#
{
    my $params = {
       'request' =>{
            data_type => 'PostSplitTextRequest',
            description => 'PostSplitText Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_split_text' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
    };
}
#
# @return FileInfo
#
sub post_split_text{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# GetWorkbookDefaultStyleRequest
#
# Retrieve the description of the default style for the workbook .
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookDefaultStyleRequest',
            description => 'GetWorkbookDefaultStyle Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_default_style' } = { 
    	summary => 'Retrieve the description of the default style for the workbook .',
        params => $params,
        returns => 'StyleResponse',
    };
}
#
# @return StyleResponse
#
sub get_workbook_default_style{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('StyleResponse', $response);
    return $_response_object;
}

#
# GetWorkbookTextItemsRequest
#
# Retrieve text items in the workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookTextItemsRequest',
            description => 'GetWorkbookTextItems Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_text_items' } = { 
    	summary => 'Retrieve text items in the workbook.',
        params => $params,
        returns => 'TextItemsResponse',
    };
}
#
# @return TextItemsResponse
#
sub get_workbook_text_items{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItemsResponse', $response);
    return $_response_object;
}

#
# GetWorkbookNamesRequest
#
# Retrieve named ranges in the workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookNamesRequest',
            description => 'GetWorkbookNames Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_names' } = { 
    	summary => 'Retrieve named ranges in the workbook.',
        params => $params,
        returns => 'NamesResponse',
    };
}
#
# @return NamesResponse
#
sub get_workbook_names{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('NamesResponse', $response);
    return $_response_object;
}

#
# PutWorkbookNameRequest
#
# Define a new name in the workbook.
# 
# @name  string (required)  The file name.  
# @newName  Name (required)  Name  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorkbookNameRequest',
            description => 'PutWorkbookName Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_workbook_name' } = { 
    	summary => 'Define a new name in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_workbook_name{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorkbookNameRequest
#
# Retrieve description of a named range in the workbook.
# 
# @name  string (required)  The file name.  
# @nameName  string (required)  The name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookNameRequest',
            description => 'GetWorkbookName Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_name' } = { 
    	summary => 'Retrieve description of a named range in the workbook.',
        params => $params,
        returns => 'NameResponse',
    };
}
#
# @return NameResponse
#
sub get_workbook_name{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('NameResponse', $response);
    return $_response_object;
}

#
# PostWorkbookNameRequest
#
# Update a named range in the workbook.
# 
# @name  string (required)  The file name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @newName  Name (required)  Namenew name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookNameRequest',
            description => 'PostWorkbookName Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_name' } = { 
    	summary => 'Update a named range in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_workbook_name{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorkbookNameValueRequest
#
# Retrieve the value of a named range in the workbook.
# 
# @name  string (required)  The file name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookNameValueRequest',
            description => 'GetWorkbookNameValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_name_value' } = { 
    	summary => 'Retrieve the value of a named range in the workbook.',
        params => $params,
        returns => 'RangeValueResponse',
    };
}
#
# @return RangeValueResponse
#
sub get_workbook_name_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RangeValueResponse', $response);
    return $_response_object;
}

#
# DeleteWorkbookNamesRequest
#
# Delete all named ranges in the workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorkbookNamesRequest',
            description => 'DeleteWorkbookNames Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_workbook_names' } = { 
    	summary => 'Delete all named ranges in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_workbook_names{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorkbookNameRequest
#
# Delete a named range in the workbook.
# 
# @name  string (required)  The file name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorkbookNameRequest',
            description => 'DeleteWorkbookName Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_workbook_name' } = { 
    	summary => 'Delete a named range in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_workbook_name{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorkbooksMergeRequest
#
# Merge a workbook into the existing workbook.
# 
# @name  string (required)  The file name.  
# @mergeWith  string (required)  The workbook to merge with.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @mergedStorageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbooksMergeRequest',
            description => 'PostWorkbooksMerge Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbooks_merge' } = { 
    	summary => 'Merge a workbook into the existing workbook.',
        params => $params,
        returns => 'WorkbookResponse',
    };
}
#
# @return WorkbookResponse
#
sub post_workbooks_merge{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('WorkbookResponse', $response);
    return $_response_object;
}

#
# PostWorkbooksTextSearchRequest
#
# Search for text in the workbook.
# 
# @name  string (required)  The file name.  
# @text  string (required)  Text sample.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbooksTextSearchRequest',
            description => 'PostWorkbooksTextSearch Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbooks_text_search' } = { 
    	summary => 'Search for text in the workbook.',
        params => $params,
        returns => 'TextItemsResponse',
    };
}
#
# @return TextItemsResponse
#
sub post_workbooks_text_search{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItemsResponse', $response);
    return $_response_object;
}

#
# PostWorkbookTextReplaceRequest
#
# Replace text in the workbook.
# 
# @name  string (required)  The file name.  
# @oldValue  string (required)  The old value.  
# @newValue  string (required)  The new value.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookTextReplaceRequest',
            description => 'PostWorkbookTextReplace Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_text_replace' } = { 
    	summary => 'Replace text in the workbook.',
        params => $params,
        returns => 'WorkbookReplaceResponse',
    };
}
#
# @return WorkbookReplaceResponse
#
sub post_workbook_text_replace{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('WorkbookReplaceResponse', $response);
    return $_response_object;
}

#
# PostWorkbookGetSmartMarkerResultRequest
#
# Smart marker processing.
# 
# @name  string (required)  The file name.  
# @xmlFile  string   The xml file full path, if empty the data is read from request body.  
# @folder  string   The folder where the file is situated.  
# @outPath  string   The path to save result  
# @storageName  string   The storage name where the file is situated.  
# @outStorageName  string   The storage name where the result file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookGetSmartMarkerResultRequest',
            description => 'PostWorkbookGetSmartMarkerResult Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_get_smart_marker_result' } = { 
    	summary => 'Smart marker processing.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub post_workbook_get_smart_marker_result{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutWorkbookCreateRequest
#
# Create a new workbook using different methods.
# 
# @name  string (required)  The new document name.  
# @templateFile  string   The template file, if the data not provided default workbook is created.  
# @dataFile  string   Smart marker data file, if the data not provided the request content is checked for the data.  
# @isWriteOver  boolean   Specifies whether to write over targer file.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @checkExcelRestriction  boolean      
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorkbookCreateRequest',
            description => 'PutWorkbookCreate Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_workbook_create' } = { 
    	summary => 'Create a new workbook using different methods.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_workbook_create{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorkbookSplitRequest
#
# Split the workbook with a specific format.
# 
# @name  string (required)  The file name.  
# @format  string   Split format.  
# @outFolder  string     
# @from  int   Start worksheet index.  
# @to  int   End worksheet index.  
# @horizontalResolution  int   Image horizontal resolution.  
# @verticalResolution  int   Image vertical resolution.  
# @splitNameRule  string   rule name : sheetname  newguid   
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @outStorageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookSplitRequest',
            description => 'PostWorkbookSplit Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_split' } = { 
    	summary => 'Split the workbook with a specific format.',
        params => $params,
        returns => 'SplitResultResponse',
    };
}
#
# @return SplitResultResponse
#
sub post_workbook_split{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SplitResultResponse', $response);
    return $_response_object;
}

#
# PostWorkbookCalculateFormulaRequest
#
# Calculate all formulas in the workbook.
# 
# @name  string (required)  The file name.  
# @options  CalculationOptions   CalculationOptions Calculation Options.  
# @ignoreError  boolean   ignore Error.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookCalculateFormulaRequest',
            description => 'PostWorkbookCalculateFormula Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_calculate_formula' } = { 
    	summary => 'Calculate all formulas in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_workbook_calculate_formula{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAutofitWorkbookRowsRequest
#
# Autofit rows in the workbook.
# 
# @name  string (required)  The file name.  
# @startRow  int   Start row.  
# @endRow  int   End row.  
# @onlyAuto  boolean   Only auto.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @firstColumn  int   First column index.  
# @lastColumn  int   Last column index.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAutofitWorkbookRowsRequest',
            description => 'PostAutofitWorkbookRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_autofit_workbook_rows' } = { 
    	summary => 'Autofit rows in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_autofit_workbook_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAutofitWorkbookColumnsRequest
#
# Autofit columns in the workbook.
# 
# @name  string (required)    
# @startColumn  int   The start column index.  
# @endColumn  int   The end column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAutofitWorkbookColumnsRequest',
            description => 'PostAutofitWorkbookColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_autofit_workbook_columns' } = { 
    	summary => 'Autofit columns in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_autofit_workbook_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorkbookSettingsRequest
#
# Retrieve descriptions of workbook settings.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorkbookSettingsRequest',
            description => 'GetWorkbookSettings Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook_settings' } = { 
    	summary => 'Retrieve descriptions of workbook settings.',
        params => $params,
        returns => 'WorkbookSettingsResponse',
    };
}
#
# @return WorkbookSettingsResponse
#
sub get_workbook_settings{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('WorkbookSettingsResponse', $response);
    return $_response_object;
}

#
# PostWorkbookSettingsRequest
#
# Update setting in the workbook.
# 
# @name  string (required)  The file name.  
# @settings  WorkbookSettings (required)  Workbook Setting description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorkbookSettingsRequest',
            description => 'PostWorkbookSettings Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_settings' } = { 
    	summary => 'Update setting in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_workbook_settings{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorkbookBackgroundRequest
#
# Set background in the workbook.
# 
# @name  string (required)  The file name.  
# @picPath  string   The picture full path.  
# @imageAdaptOption  string     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @File  string   File to upload   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorkbookBackgroundRequest',
            description => 'PutWorkbookBackground Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_workbook_background' } = { 
    	summary => 'Set background in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_workbook_background{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorkbookBackgroundRequest
#
# Delete background in the workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorkbookBackgroundRequest',
            description => 'DeleteWorkbookBackground Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_workbook_background' } = { 
    	summary => 'Delete background in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_workbook_background{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorkbookWaterMarkerRequest
#
# Set water marker in the workbook.
# 
# @name  string (required)  The file name.  
# @textWaterMarkerRequest  TextWaterMarkerRequest (required)  Text water marker request  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorkbookWaterMarkerRequest',
            description => 'PutWorkbookWaterMarker Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_workbook_water_marker' } = { 
    	summary => 'Set water marker in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_workbook_water_marker{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetPageCountRequest
#
# Get page count in the workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetPageCountRequest',
            description => 'GetPageCount Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_page_count' } = { 
    	summary => 'Get page count in the workbook.',
        params => $params,
        returns => 'int',
    };
}
#
# @return int
#
sub get_page_count{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('int', $response);
    return $_response_object;
}

#
# GetAllStylesRequest
#
# Get all style in the workbook.
# 
# @name  string (required)    
# @folder  string     
# @storageName  string      
#
{
    my $params = {
       'request' =>{
            data_type => 'GetAllStylesRequest',
            description => 'GetAllStyles Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_all_styles' } = { 
    	summary => 'Get all style in the workbook.',
        params => $params,
        returns => 'StylesResponse',
    };
}
#
# @return StylesResponse
#
sub get_all_styles{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('StylesResponse', $response);
    return $_response_object;
}

#
# GetWorksheetsRequest
#
# Retrieve the description of worksheets from a workbook.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetsRequest',
            description => 'GetWorksheets Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheets' } = { 
    	summary => 'Retrieve the description of worksheets from a workbook.',
        params => $params,
        returns => 'WorksheetsResponse',
    };
}
#
# @return WorksheetsResponse
#
sub get_worksheets{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('WorksheetsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetWithFormatRequest
#
# Retrieve the worksheet in a specified format from the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @format  string   Export format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @verticalResolution  int   Image vertical resolution.  
# @horizontalResolution  int   Image horizontal resolution.  
# @area  string   Represents the range to be printed.  
# @pageIndex  int   Represents the page to be printed  
# @onePagePerSheet  boolean     
# @printHeadings  boolean     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetWithFormatRequest',
            description => 'GetWorksheetWithFormat Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_with_format' } = { 
    	summary => 'Retrieve the worksheet in a specified format from the workbook.',
        params => $params,
        returns => 'string',
    };
}
#
# @return string
#
sub get_worksheet_with_format{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# PutChangeVisibilityWorksheetRequest
#
# Change worksheet visibility in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  Worksheet name.  
# @isVisible  boolean (required)  New worksheet visibility value.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutChangeVisibilityWorksheetRequest',
            description => 'PutChangeVisibilityWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_change_visibility_worksheet' } = { 
    	summary => 'Change worksheet visibility in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_change_visibility_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutActiveWorksheetRequest
#
# Set active worksheet index in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutActiveWorksheetRequest',
            description => 'PutActiveWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_active_worksheet' } = { 
    	summary => 'Set active worksheet index in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_active_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutInsertNewWorksheetRequest
#
# Insert a new worksheet in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)    
# @sheettype  string (required)  Specifies the worksheet type(VB/Worksheet/Chart/BIFF4Macro/InternationalMacro/Other/Dialog).  
# @newsheetname  string     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutInsertNewWorksheetRequest',
            description => 'PutInsertNewWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_insert_new_worksheet' } = { 
    	summary => 'Insert a new worksheet in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_insert_new_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutAddNewWorksheetRequest
#
# Add a new worksheet in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The new sheet name.  
# @position  int   The new sheet position.  
# @sheettype  string   Specifies the worksheet type(VB/Worksheet/Chart/BIFF4Macro/InternationalMacro/Other/Dialog).  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutAddNewWorksheetRequest',
            description => 'PutAddNewWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_add_new_worksheet' } = { 
    	summary => 'Add a new worksheet in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_add_new_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetRequest
#
# Delete a worksheet in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetRequest',
            description => 'DeleteWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet' } = { 
    	summary => 'Delete a worksheet in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetsRequest
#
# Delete matched worksheets in the workbook.
# 
# @name  string (required)    
# @matchCondition  MatchConditionRequest     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetsRequest',
            description => 'DeleteWorksheets Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheets' } = { 
    	summary => 'Delete matched worksheets in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheets{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostMoveWorksheetRequest
#
# Move worksheet in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @moving  WorksheetMovingRequest (required)  WorksheetMovingRequest with moving parameters.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostMoveWorksheetRequest',
            description => 'PostMoveWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_move_worksheet' } = { 
    	summary => 'Move worksheet in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_move_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutProtectWorksheetRequest
#
# Protect worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @protectParameter  ProtectSheetParameter (required)  ProtectSheetParameter with protection settings.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutProtectWorksheetRequest',
            description => 'PutProtectWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_protect_worksheet' } = { 
    	summary => 'Protect worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_protect_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteUnprotectWorksheetRequest
#
# Unprotect worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @protectParameter  ProtectSheetParameter (required)  WorksheetResponse with protection settings. Only password is used here.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteUnprotectWorksheetRequest',
            description => 'DeleteUnprotectWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_unprotect_worksheet' } = { 
    	summary => 'Unprotect worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_unprotect_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetTextItemsRequest
#
# Retrieve text items in the worksheet.
# 
# @name  string (required)  Workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetTextItemsRequest',
            description => 'GetWorksheetTextItems Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_text_items' } = { 
    	summary => 'Retrieve text items in the worksheet.',
        params => $params,
        returns => 'TextItemsResponse',
    };
}
#
# @return TextItemsResponse
#
sub get_worksheet_text_items{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItemsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCommentsRequest
#
# Retrieve the description of comments in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCommentsRequest',
            description => 'GetWorksheetComments Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_comments' } = { 
    	summary => 'Retrieve the description of comments in the worksheet.',
        params => $params,
        returns => 'CommentsResponse',
    };
}
#
# @return CommentsResponse
#
sub get_worksheet_comments{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CommentsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCommentRequest
#
# Retrieve the description of comment in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCommentRequest',
            description => 'GetWorksheetComment Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_comment' } = { 
    	summary => 'Retrieve the description of comment in the worksheet.',
        params => $params,
        returns => 'CommentResponse',
    };
}
#
# @return CommentResponse
#
sub get_worksheet_comment{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CommentResponse', $response);
    return $_response_object;
}

#
# PutWorksheetCommentRequest
#
# Add cell comment in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @comment  Comment (required)  Comment object.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetCommentRequest',
            description => 'PutWorksheetComment Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_comment' } = { 
    	summary => 'Add cell comment in the worksheet.',
        params => $params,
        returns => 'CommentResponse',
    };
}
#
# @return CommentResponse
#
sub put_worksheet_comment{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CommentResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCommentRequest
#
# Update cell comment in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @comment  Comment (required)  Comment object.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCommentRequest',
            description => 'PostWorksheetComment Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_comment' } = { 
    	summary => 'Update cell comment in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_comment{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetCommentRequest
#
# Delete cell comment in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetCommentRequest',
            description => 'DeleteWorksheetComment Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_comment' } = { 
    	summary => 'Delete cell comment in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_comment{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetCommentsRequest
#
# Delete all comments in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetCommentsRequest',
            description => 'DeleteWorksheetComments Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_comments' } = { 
    	summary => 'Delete all comments in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_comments{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetMergedCellsRequest
#
# Get worksheet merged cells.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The workseet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetMergedCellsRequest',
            description => 'GetWorksheetMergedCells Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_merged_cells' } = { 
    	summary => 'Get worksheet merged cells.',
        params => $params,
        returns => 'MergedCellsResponse',
    };
}
#
# @return MergedCellsResponse
#
sub get_worksheet_merged_cells{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('MergedCellsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetMergedCellRequest
#
# Retrieve description of a merged cell by its index in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  Worksheet name.  
# @mergedCellIndex  int (required)  Merged cell index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetMergedCellRequest',
            description => 'GetWorksheetMergedCell Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_merged_cell' } = { 
    	summary => 'Retrieve description of a merged cell by its index in the worksheet.',
        params => $params,
        returns => 'MergedCellResponse',
    };
}
#
# @return MergedCellResponse
#
sub get_worksheet_merged_cell{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('MergedCellResponse', $response);
    return $_response_object;
}

#
# GetWorksheetCalculateFormulaRequest
#
# Calculate formula in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @formula  string (required)  The formula.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetCalculateFormulaRequest',
            description => 'GetWorksheetCalculateFormula Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_calculate_formula' } = { 
    	summary => 'Calculate formula in the worksheet.',
        params => $params,
        returns => 'SingleValueResponse',
    };
}
#
# @return SingleValueResponse
#
sub get_worksheet_calculate_formula{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SingleValueResponse', $response);
    return $_response_object;
}

#
# PostWorksheetCalculateFormulaRequest
#
# Calculate formula in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  Worksheet name.  
# @formula  string (required)  The formula.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetCalculateFormulaRequest',
            description => 'PostWorksheetCalculateFormula Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_calculate_formula' } = { 
    	summary => 'Calculate formula in the worksheet.',
        params => $params,
        returns => 'SingleValueResponse',
    };
}
#
# @return SingleValueResponse
#
sub post_worksheet_calculate_formula{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SingleValueResponse', $response);
    return $_response_object;
}

#
# PostWorksheetTextSearchRequest
#
# Search for text in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @text  string (required)  Text to search.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetTextSearchRequest',
            description => 'PostWorksheetTextSearch Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_text_search' } = { 
    	summary => 'Search for text in the worksheet.',
        params => $params,
        returns => 'TextItemsResponse',
    };
}
#
# @return TextItemsResponse
#
sub post_worksheet_text_search{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItemsResponse', $response);
    return $_response_object;
}

#
# PostWorksheetTextReplaceRequest
#
# Replace old text with new text in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  Worksheet name.  
# @oldValue  string (required)  The old text to replace.  
# @newValue  string (required)  The new text to replace by.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetTextReplaceRequest',
            description => 'PostWorksheetTextReplace Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_text_replace' } = { 
    	summary => 'Replace old text with new text in the worksheet.',
        params => $params,
        returns => 'WorksheetReplaceResponse',
    };
}
#
# @return WorksheetReplaceResponse
#
sub post_worksheet_text_replace{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('WorksheetReplaceResponse', $response);
    return $_response_object;
}

#
# PostWorksheetRangeSortRequest
#
# Sort a range in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @cellArea  string (required)  The area needed to sort.  
# @dataSorter  DataSorter (required)  DataSorter with sorting settings.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetRangeSortRequest',
            description => 'PostWorksheetRangeSort Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_range_sort' } = { 
    	summary => 'Sort a range in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_range_sort{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAutofitWorksheetRowRequest
#
# Autofit a row in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @firstColumn  int   The first column index.  
# @lastColumn  int   The last column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @rowCount  int      
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAutofitWorksheetRowRequest',
            description => 'PostAutofitWorksheetRow Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_autofit_worksheet_row' } = { 
    	summary => 'Autofit a row in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_autofit_worksheet_row{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAutofitWorksheetRowsRequest
#
# Autofit rows in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int   The start row index.  
# @endRow  int   The end row index.  
# @onlyAuto  boolean   Autofits all rows in this worksheet.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAutofitWorksheetRowsRequest',
            description => 'PostAutofitWorksheetRows Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_autofit_worksheet_rows' } = { 
    	summary => 'Autofit rows in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_autofit_worksheet_rows{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostAutofitWorksheetColumnsRequest
#
# Autofit columns in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @startColumn  int   The start column index.  
# @endColumn  int   The end column index.  
# @onlyAuto  boolean     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostAutofitWorksheetColumnsRequest',
            description => 'PostAutofitWorksheetColumns Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_autofit_worksheet_columns' } = { 
    	summary => 'Autofit columns in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_autofit_worksheet_columns{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetBackgroundRequest
#
# Set background image in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @picPath  string   picture full filename.  
# @imageAdaptOption  string     
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.  
# @File  string   File to upload   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetBackgroundRequest',
            description => 'PutWorksheetBackground Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_background' } = { 
    	summary => 'Set background image in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_background{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetBackgroundRequest
#
# Delete background image in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetBackgroundRequest',
            description => 'DeleteWorksheetBackground Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_background' } = { 
    	summary => 'Delete background image in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_background{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PutWorksheetFreezePanesRequest
#
# Set freeze panes in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int (required)  Row index.  
# @column  int (required)  Column index.  
# @freezedRows  int (required)  Number of visible rows in top pane, no more than row index.  
# @freezedColumns  int (required)  Number of visible columns in left pane, no more than column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetFreezePanesRequest',
            description => 'PutWorksheetFreezePanes Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_freeze_panes' } = { 
    	summary => 'Set freeze panes in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_freeze_panes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetFreezePanesRequest
#
# Unfreeze panes in worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int (required)  Row index.  
# @column  int (required)  Column index.  
# @freezedRows  int (required)  Number of visible rows in top pane, no more than row index.  
# @freezedColumns  int (required)  Number of visible columns in left pane, no more than column index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetFreezePanesRequest',
            description => 'DeleteWorksheetFreezePanes Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_freeze_panes' } = { 
    	summary => 'Unfreeze panes in worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_freeze_panes{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostCopyWorksheetRequest
#
# Copy contents and formats from another worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceSheet  string (required)  Source worksheet.  
# @options  CopyOptions (required)  Represents the copy options.  
# @sourceWorkbook  string   source Workbook.  
# @sourceFolder  string   Original workbook folder.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostCopyWorksheetRequest',
            description => 'PostCopyWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_copy_worksheet' } = { 
    	summary => 'Copy contents and formats from another worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_copy_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostRenameWorksheetRequest
#
# Rename worksheet in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @newname  string (required)  New worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostRenameWorksheetRequest',
            description => 'PostRenameWorksheet Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_rename_worksheet' } = { 
    	summary => 'Rename worksheet in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_rename_worksheet{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetPropertyRequest
#
# Update worksheet properties in the workbook.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @sheet  Worksheet (required)  The worksheet description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetPropertyRequest',
            description => 'PostUpdateWorksheetProperty Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_property' } = { 
    	summary => 'Update worksheet properties in the workbook.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_property{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetNamedRangesRequest
#
# Retrieve descriptions of ranges in the worksheets.
# 
# @name  string (required)  The file name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetNamedRangesRequest',
            description => 'GetNamedRanges Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_named_ranges' } = { 
    	summary => 'Retrieve descriptions of ranges in the worksheets.',
        params => $params,
        returns => 'RangesResponse',
    };
}
#
# @return RangesResponse
#
sub get_named_ranges{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RangesResponse', $response);
    return $_response_object;
}

#
# GetNamedRangeValueRequest
#
# Retrieve values in range.
# 
# @name  string (required)  The file name.  
# @namerange  string (required)  Range name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetNamedRangeValueRequest',
            description => 'GetNamedRangeValue Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_named_range_value' } = { 
    	summary => 'Retrieve values in range.',
        params => $params,
        returns => 'RangeValueResponse',
    };
}
#
# @return RangeValueResponse
#
sub get_named_range_value{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('RangeValueResponse', $response);
    return $_response_object;
}

#
# PostUpdateWorksheetZoomRequest
#
# Update the scaling percentage in the worksheet. It should be between 10 and 400.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @value  int (required)  Represents the scaling factor in percentage. It should be between 10 and 400.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostUpdateWorksheetZoomRequest',
            description => 'PostUpdateWorksheetZoom Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_update_worksheet_zoom' } = { 
    	summary => 'Update the scaling percentage in the worksheet. It should be between 10 and 400.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_update_worksheet_zoom{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# GetWorksheetPageCountRequest
#
# Get page count in the worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetPageCountRequest',
            description => 'GetWorksheetPageCount Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_page_count' } = { 
    	summary => 'Get page count in the worksheet.',
        params => $params,
        returns => 'int',
    };
}
#
# @return int
#
sub get_worksheet_page_count{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('int', $response);
    return $_response_object;
}

#
# GetWorksheetValidationsRequest
#
# Retrieve descriptions of validations in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetValidationsRequest',
            description => 'GetWorksheetValidations Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_validations' } = { 
    	summary => 'Retrieve descriptions of validations in the worksheet.',
        params => $params,
        returns => 'ValidationsResponse',
    };
}
#
# @return ValidationsResponse
#
sub get_worksheet_validations{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ValidationsResponse', $response);
    return $_response_object;
}

#
# GetWorksheetValidationRequest
#
# Retrieve a validation by its index in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'GetWorksheetValidationRequest',
            description => 'GetWorksheetValidation Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_validation' } = { 
    	summary => 'Retrieve a validation by its index in the worksheet.',
        params => $params,
        returns => 'ValidationResponse',
    };
}
#
# @return ValidationResponse
#
sub get_worksheet_validation{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ValidationResponse', $response);
    return $_response_object;
}

#
# PutWorksheetValidationRequest
#
# Add a validation at index in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string   Specified cells area  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PutWorksheetValidationRequest',
            description => 'PutWorksheetValidation Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_validation' } = { 
    	summary => 'Add a validation at index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_validation{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# PostWorksheetValidationRequest
#
# Update a validation by index in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @validation  Validation (required)  Validation description.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorksheetValidationRequest',
            description => 'PostWorksheetValidation Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worksheet_validation' } = { 
    	summary => 'Update a validation by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub post_worksheet_validation{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetValidationRequest
#
# Delete a validation by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetValidationRequest',
            description => 'DeleteWorksheetValidation Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_validation' } = { 
    	summary => 'Delete a validation by index in worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_validation{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}

#
# DeleteWorksheetValidationsRequest
#
# Delete all validations in the worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetValidationsRequest',
            description => 'DeleteWorksheetValidations Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_validations' } = { 
    	summary => 'Delete all validations in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_validations{
    my ($self, %args) = @_;
    my $request = $args{'request'};
    my $response = $request->run_http_request('client' => $self->{api_client} );
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('CellsCloudResponse', $response);
    return $_response_object;
}
