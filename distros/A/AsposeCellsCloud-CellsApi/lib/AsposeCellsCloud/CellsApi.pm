=begin comment

Copyright (c) 2023 Aspose.Cells Cloud
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
# Get worksheet columns description.
# 
# @name  string   The workbook name.  
# @sheetName  string   The worksheet name.  
# @offset  int   Original workbook folder.  
# @count  int   Storage name.  
# @folder  string   The workdook folder.  
# @storageName  string      
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
    	summary => 'Get worksheet columns description.',
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
# Sets worksheet column width.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @width  double (required)  Gets and sets the column width in unit of characters.  
# @count  int     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sets worksheet column width.',
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
# Gets worksheet column data by column`s index.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets worksheet column data by column`s index.',
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
# Insert worksheet columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @columns  int (required)  The number of columns.  
# @updateReference  boolean   Indicates if references in other worksheets will be updated.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Insert worksheet columns.',
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
# Delete worksheet columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @columns  int (required)  The number of columns.  
# @updateReference  boolean (required)  Indicates if references in other worksheets will be updated.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete worksheet columns.',
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
# Hide worksheet columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startColumn  int (required)  The begin column index to be operated.  
# @totalColumns  int (required)  Number of columns to be operated.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Hide worksheet columns.',
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
# Unhide worksheet columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startColumn  int (required)  The begin column index to be operated.  
# @totalColumns  int (required)  Number of columns to be operated.  
# @width  double   Gets and sets the column width in unit of characters.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Unhide worksheet columns.',
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
# Group worksheet columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first column index to be operated.  
# @lastIndex  int (required)  The last column index to be operated.  
# @hide  boolean   columns visible state  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Group worksheet columns.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first column index to be operated.  
# @lastIndex  int (required)  The last column index to be operated.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Copy data to destination columns from source columns in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceColumnIndex  int (required)  Source column index  
# @destinationColumnIndex  int (required)  Destination column index  
# @columnNumber  int (required)  The copied column number  
# @worksheet  string   The destination worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Copy data to destination columns from source columns in worksheet.',
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
# Sets column style in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @columnIndex  int (required)  The column index.  
# @style  Style (required)  Represents display style of excel document,such as font,color,alignment,border,etc.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sets column style in worksheet.',
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
# Get rows description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @offset  int   Original workbook folder.  
# @count  int   Storage name.  
# @folder  string     
# @storageName  string      
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
    	summary => 'Get rows description in worksheet.',
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
# Gets row data by row`s index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @folder  string   The workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets row data by row`s index in worksheet.',
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
# Deletes row in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes row in worksheet.',
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
# Delete several rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int   Number of rows to be operated.  
# @updateReference  boolean   Indicates if update references in other worksheets.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete several rows in worksheet.',
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
# Insert several new rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int   Number of rows to be operated.  
# @updateReference  boolean   Indicates if update references in other worksheets.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Insert several new rows in worksheet.',
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
# Inserts new row in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The new row index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Inserts new row in worksheet.',
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
# Updates row in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @height  double   The new row height.  
# @count  int     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates row in worksheet.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int (required)  Number of rows to be operated.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Unhide rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startrow  int (required)  The begin row index to be operated.  
# @totalRows  int (required)  Number of rows to be operated.  
# @height  double   The new row height.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Unhide rows in worksheet.',
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
# Group rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first row index to be operated.  
# @lastIndex  int (required)  The last row index to be operated.  
# @hide  boolean   rows visible state  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Group rows in worksheet.',
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
# Ungroup rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @firstIndex  int (required)  The first row index to be operated.  
# @lastIndex  int (required)  The last row index to be operated.  
# @isAll  boolean   Is all row to be operated  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Ungroup rows in worksheet.',
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
# Copies data and formats of some whole rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceRowIndex  int (required)  Source row index  
# @destinationRowIndex  int (required)  Destination row index  
# @rowNumber  int (required)  The copied row number  
# @worksheet  string   The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Copies data and formats of some whole rows in worksheet.',
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
# Applies formats for a whole row in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  The row index.  
# @style  Style (required)  Style description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Applies formats for a whole row in worksheet.',
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
# PutWorksheetAddChartRequest
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
            data_type => 'PutWorksheetAddChartRequest',
            description => 'PutWorksheetAddChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_add_chart' } = { 
    	summary => 'Add a new chart in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub put_worksheet_add_chart{
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
# DeleteWorksheetDeleteChartRequest
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
            data_type => 'DeleteWorksheetDeleteChartRequest',
            description => 'DeleteWorksheetDeleteChart Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_delete_chart' } = { 
    	summary => 'Delete a chart by index in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_delete_chart{
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
# Show chart legend in worksheet.
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
    	summary => 'Show chart legend in worksheet.',
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
# Hides chart legend in worksheet.
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
    	summary => 'Hides chart legend in worksheet.',
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
# DeleteWorksheetClearChartsRequest
#
# Clear the charts in worksheets.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The folder where the file is situated.  
# @storageName  string   The storage name where the file is situated.   
#
{
    my $params = {
       'request' =>{
            data_type => 'DeleteWorksheetClearChartsRequest',
            description => 'DeleteWorksheetClearCharts Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_clear_charts' } = { 
    	summary => 'Clear the charts in worksheets.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}
#
# @return CellsCloudResponse
#
sub delete_worksheet_clear_charts{
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
# Gets chart title description in worksheet.
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
    	summary => 'Gets chart title description in worksheet.',
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
# Update chart title in worksheet.
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @title  Title (required)  Chart title  
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
    	summary => 'Update chart title in worksheet.',
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
# Add chart title / Set chart title visible
# 
# @name  string (required)  The file name.  
# @sheetName  string (required)  The worksheet name.  
# @chartIndex  int (required)  The chart index.  
# @title  Title   Chart title.  
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
    	summary => 'Add chart title / Set chart title visible',
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
# Hides chart title in worksheet.
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
    	summary => 'Hides chart title in worksheet.',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# 
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
    	summary => '',
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
# Get conditional formattings description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get conditional formattings description.',
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
# Gets conditional formatting description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The conditional formatting index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets conditional formatting description in worksheet.',
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
# Adds a condition formatting in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @formatcondition  FormatCondition (required)    
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a condition formatting in worksheet.',
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
# Adds a format condition in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @type  string (required)  Format condition type(CellValue/Expression/ColorScale/DataBar/IconSet/Top10/UniqueValues/DuplicateValues/ContainsText/NotContainsText/BeginsWith/EndsWith/ContainsBlanks/NotContainsBlanks/ContainsErrors/NotContainsErrors/TimePeriod/AboveAverage).  
# @operatorType  string (required)  Represents the operator type of conditional format and data validation(Between/Equal/GreaterThan/GreaterOrEqual/LessThan/None/NotBetween/NotEqual).  
# @formula1  string (required)  The value or expression associated with conditional formatting.  
# @formula2  string (required)  The value or expression associated with conditional formatting.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a format condition in worksheet.',
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
# Adds a cell area for format condition.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @cellArea  string (required)  Adds a conditional formatted cell range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a cell area for format condition.',
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
# Adds a condition for format condition.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @type  string (required)  Format condition type(CellValue/Expression/ColorScale/DataBar/IconSet/Top10/UniqueValues/DuplicateValues/ContainsText/NotContainsText/BeginsWith/EndsWith/ContainsBlanks/NotContainsBlanks/ContainsErrors/NotContainsErrors/TimePeriod/AboveAverage).  
# @operatorType  string (required)  Represents the operator type of conditional format and data validation(Between/Equal/GreaterThan/GreaterOrEqual/LessThan/None/NotBetween/NotEqual).  
# @formula1  string (required)  The value or expression associated with conditional formatting.  
# @formula2  string (required)  The value or expression associated with conditional formatting.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a condition for format condition.',
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
# Clear all condition formattings.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Clear all condition formattings.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Gets the Conditional Formatting element at the specified index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Removes cell area from conditional formatting.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int (required)  The start row of the range.  
# @startColumn  int (required)  The start column of the range.  
# @totalRows  int (required)  The number of rows of the range.  
# @totalColumns  int (required)  The number of columns of the range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Removes cell area from conditional formatting.',
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
# @File  string (required)  The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @format  string   The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @password  string   The password needed to open an Excel file.  
# @outPath  string   Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  
# @storageName  string   The storage name where the file is situated.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @streamFormat  string   The format of the input file stream.   
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# @File  string (required)  The password needed to open an Excel file.  
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
# @File  string (required)  The password needed to open an Excel file.  
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
# PostExportRequest
#
# Export Excel internal elements or the workbook itself to various format files.
# 
# @File  string (required)  Exported object type:workbook/worksheet/chart/comment/picture/shape/listobject/oleobject.  
# @objectType  string   Exported object type:workbook/worksheet/chart/comment/picture/shape/listobject/oleobject.  
# @format  string   The conversion format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @password  string   The password needed to open an Excel file.  
# @checkExcelRestriction  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @region  string   The regional settings for workbook.   
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
# GetWorksheetHyperlinksRequest
#
# Get hyperlinks description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get hyperlinks description in worksheet.',
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
# Gets hyperlink description by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets hyperlink description by index in worksheet.',
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
# Deletes hyperlink by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes hyperlink by index in worksheet.',
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
# Updates hyperlink by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @hyperlinkIndex  int (required)  The hyperlink`s index.  
# @hyperlink  Hyperlink (required)  Hyperlink object  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates hyperlink by index in worksheet.',
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
# Adds hyperlink in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @firstRow  int (required)  First row of the hyperlink range.  
# @firstColumn  int (required)  First column of the hyperlink range.  
# @totalRows  int (required)  Number of rows in this hyperlink range.  
# @totalColumns  int (required)  Number of columns of this hyperlink range.  
# @address  string (required)  Address of the hyperlink.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds hyperlink in worksheet.',
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
# Delete all hyperlinks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all hyperlinks in worksheet.',
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
# @File  string (required)  The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @datasource  string (required)    
# @format  string   The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
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
# @File  string (required)  Compress level. The compression ratio 1-100.  
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
# @File  string (required)  The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
# @outFormat  string   The password needed to open an Excel file.  
# @mergeToOneSheet  boolean   Whether check restriction of excel file when user modify cells related objects.  
# @password  string   The regional settings for workbook.  
# @checkExcelRestriction  boolean   Upload files.  
# @region  string      
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
# @File  string (required)  The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
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
# @File  string (required)  Find content  
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
# @File  string (required)  Find content  
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
# @File  string (required)  The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
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
# @File  string (required)  e.g. #1032ff  
# @text  string (required)    
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
# @File  string (required)  chart/comment/picture/shape/listobject/hyperlink/oleobject/pivottable/validation/Background  
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
# @File  string (required)  rows/cols/both  
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
# @File  string (required)  The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)  
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
# @File  string (required)  270/90/row/col/row2col  
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
# @File  string (required)  document properties  
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
# @File  string (required)  Cells document property name.  
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
# @File  string (required)  Cells document property name.  
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
# Get listobjects description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get listobjects description in worksheet.',
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
# Gets list object description by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listobjectindex  int (required)  list object index.  
# @format  string     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets list object description by index in worksheet.',
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
# Adds a list object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int   The start row of the list range.  
# @startColumn  int   The start row of the list range.  
# @endRow  int   The start row of the list range.  
# @endColumn  int   The start row of the list range.  
# @folder  string   Original workbook folder.  
# @hasHeaders  boolean   Whether the range has headers.  
# @displayName  string     
# @showTotals  boolean     
# @storageName  string   Storage name.   
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
    	summary => 'Adds a list object in worksheet.',
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
# Delete worksheet list objects in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete worksheet list objects in worksheet.',
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
# Deletes list object by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes list object by index in worksheet.',
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
# Updates list object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  list Object index  
# @listObject  ListObject (required)  listObject dto in request body.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates list object in worksheet.',
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
# Converts list object to range in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Converts list object to range in worksheet.',
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
# Creates pivot table with list object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @destsheetName  string (required)  Target work sheet name.  
# @createPivotTableRequest  CreatePivotTableRequest (required)  Create pivot table request.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Creates pivot table with list object in worksheet.',
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
# Sorts list object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @dataSorter  DataSorter (required)  Represents sort order for the data range.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sorts list object in worksheet.',
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
# Remove duplicates on list object.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Remove duplicates on list object.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @columnIndex  int (required)  The index of ListColumn in ListObject.ListColumns   
# @destCellName  string (required)  The cell in the upper-left corner of the Slicer range.   
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Update list column properties.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @columnIndex  int (required)  Represents table column index.  
# @listColumn  ListColumn (required)  Represents table column description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Update list column properties.',
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
# Update table total of list columns.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @listObjectIndex  int (required)  List object index.  
# @tableTotalRequests  ARRAY[TableTotalRequest] (required)  Represents table column description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Update table total of list columns.',
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
# Get OLE objects description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Document`s folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get OLE objects description in worksheet.',
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
# Gets OLE object info or get the OLE object in some format.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @objectNumber  int (required)  The object number.  
# @format  string   Object conversion format(PNG/TIFF/JPEG/GIF/EMF/BMP).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets OLE object info or get the OLE object in some format.',
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
# Delete all OLE objects in  worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all OLE objects in  worksheet.',
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
# Deletes an OLE object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @oleObjectIndex  int (required)  Ole object index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes an OLE object in worksheet.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @oleObjectIndex  int (required)  Ole object index.  
# @ole  OleObject (required)  Ole Object description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Add an OLE object in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @upperLeftRow  int   Upper left row index  
# @upperLeftColumn  int   Upper left column index  
# @height  int   Height of oleObject, in unit of pixel  
# @width  int   Width of oleObject, in unit of pixel  
# @oleFile  string   OLE filename(full file name).  
# @imageFile  string   Image filename(full file name).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Add an OLE object in worksheet.',
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
# Get vertical page breaks description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get vertical page breaks description in worksheet.',
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
# Get horizontal page breaks descripton in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get horizontal page breaks descripton in worksheet.',
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
# Gets a vertical page break description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The zero based index of the element.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets a vertical page break description in worksheet.',
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
# Gets a horizontal page breaks descripton in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  The zero based index of the element.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets a horizontal page breaks descripton in worksheet.',
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
# Adds a vertical page break in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellname  string   Cell name  
# @column  int   Column index, zero based.  
# @row  int   Row index, zero based.  
# @startRow  int   Start row index, zero based.  
# @endRow  int   End row index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a vertical page break in worksheet.',
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
# Adds a horizontal page breaks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellname  string   Cell name  
# @row  int   Row index, zero based.  
# @column  int   Column index, zero based.  
# @startColumn  int   Start column index, zero based.  
# @endColumn  int   End column index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a horizontal page breaks in worksheet.',
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
# Delete vertical page breaks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @column  int   Column index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete vertical page breaks in worksheet.',
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
# Delete horizontal page breaks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int   Row index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete horizontal page breaks in worksheet.',
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
# Delete a vertical page breaks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Removes the VPageBreak element at a specified name. Element index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete a vertical page breaks in worksheet.',
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
# Delete a horizontal page breaks in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)  Removes the HPageBreak element at a specified name. Element index, zero based.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete a horizontal page breaks in worksheet.',
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
# Gets page setup description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets page setup description in worksheet.',
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
# Updates page setup in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pageSetup  PageSetup (required)  Page Setup description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates page setup in worksheet.',
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
# Clears header footer in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Clears header footer in worksheet.',
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
# Gets page header description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets page header description in worksheet.',
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
# Updates page header in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @section  int (required)  0:Left Section. 1:Center Section 2:Right Section  
# @script  string (required)  Header format script.  
# @isFirstPage  boolean (required)  Is first page(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates page header in worksheet.',
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
# Gets page footer description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets page footer description in worksheet.',
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
# Update  page footer description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @section  int (required)  0:Left Section. 1:Center Section 2:Right Section  
# @script  string (required)  Header format script.  
# @isFirstPage  boolean (required)  Is first page(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Update  page footer description in worksheet.',
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
# GetWorksheetPicturesRequest
#
# Get pictures description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get pictures description in worksheet.',
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
# Gets a picture by number in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pictureNumber  int (required)  The picture number.  
# @format  string (required)  Picture conversion format(PNG/TIFF/JPEG/GIF/EMF/BMP).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets a picture by number in worksheet.',
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
# Adds a new picture in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @picture  Picture   Pictute object  
# @upperLeftRow  int   The image upper left row.  
# @upperLeftColumn  int   The image upper left column.  
# @lowerRightRow  int   The image low right row.  
# @lowerRightColumn  int   The image low right column.  
# @picturePath  string   The picture path, if not provided the picture data is inspected in the request body.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a new picture in worksheet.',
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
# PostWorksheetPictureRequest
#
# Updates a picture by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pictureIndex  int (required)  The picture`s index.  
# @picture  Picture (required)  Picture object description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates a picture by index in worksheet.',
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
# Deletes a picture object in worksheet
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worsheet name.  
# @pictureIndex  int (required)  Picture index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a picture object in worksheet',
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
# Delete all pictures in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all pictures in worksheet.',
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
# Get worksheet pivottables description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get worksheet pivottables description.',
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
# Gets a pivottable info by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivottableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets a pivottable info by index in worksheet.',
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
# Gets pivot field description in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldIndex  int (required)  The field index in the base fields.  
# @pivotFieldType  string (required)  The fields area type(column/row).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets pivot field description in pivot table.',
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
# Gets pivot table filters in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets pivot table filters in worksheet.',
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
# Gets pivot table filters in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @filterIndex  int (required)  Gets the pivotfilter object at the specific index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets pivot table filters in worksheet.',
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
# Adds a pivot table in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @sourceData  string   The data for the new PivotTable cache.  
# @destCellName  string   The cell in the upper-left corner of the PivotTable report`s destination range.  
# @tableName  string   The name of the new PivotTable report.  
# @useSameSource  boolean   Indicates whether using same data source when another existing pivot table has used this data source. If the property is true, it will save memory.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a pivot table in worksheet.',
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
# Adds a pivot field in pivot table
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldType  string (required)  The fields area type.  
# @pivotTableFieldRequest  PivotTableFieldRequest (required)  Dto that conrains field indexes  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a pivot field in pivot table',
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
# Adds a pivot filter for piovt table index
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @filter  PivotFilter (required)  Pivot filter description.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a pivot filter for piovt table index',
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
# Hides pivot field item in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @fieldIndex  int (required)  Gets the PivotField Object at the specific index.  
# @itemIndex  int (required)  The index of the pivotItem in the pivotField.  
# @isHide  boolean (required)  Whether the specific PivotItem is hidden(true/false).  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Hides pivot field item in pivot table.',
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
# Moves pivot field in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @fieldIndex  int (required)  Gets the PivotField Object at the specific index.  
# @from  string (required)  The fields area type(Column/Row/Page/Data/Undefined).  
# @to  string (required)  The fields area type(Column/Row/Page/Data/Undefined).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Moves pivot field in pivot table.',
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
# Updates cell style in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @column  int (required)  Column index of the cell.  
# @row  int (required)  RowIndex of the cell.  
# @style  Style (required)  Style description in request body.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates cell style in pivot table.',
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
# Updates style in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @style  Style (required)  Style description in request body.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates style in pivot table.',
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
# 
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @pivotField  PivotField (required)  Represents pivot field.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => '',
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
# 
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldIndex  int (required)  Gets the PivotField Object at the specific index.  
# @pivotFieldType  string (required)  Represents PivotTable field type(Undefined/Row/Column/Page/Data).  
# @pivotField  PivotField (required)  Represents pivot field.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => '',
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
# Calculates pivottable`s data to cells.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Calculates pivottable`s data to cells.',
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
# Moves pivot table in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @row  int   Row index.  
# @column  int   Column index.  
# @destCellName  string   The dest cell name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Moves pivot table in worksheet.',
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
# Delete pivot tables in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete pivot tables in worksheet.',
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
# Deletes  pivot table by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes  pivot table by index in worksheet.',
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
# Deletes pivot field in pivot table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @pivotFieldType  string (required)  The fields area type.  
# @pivotTableFieldRequest  PivotTableFieldRequest (required)  Pivot table field request.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes pivot field in pivot table.',
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
# Delete all pivot filters in piovt table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all pivot filters in piovt table.',
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
# Deletes a pivot filter in piovt table.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @pivotTableIndex  int (required)  Gets the PivotTable report by index.  
# @fieldIndex  int (required)  Gets the PivotField Object at the specific index.  
# @needReCalculate  boolean   Whether the specific pivot table calculate(true/false).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a pivot filter in piovt table.',
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
# Get document properties description.
# 
# @name  string (required)  The workbook name.  
# @type  string     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get document properties description.',
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
# Sets/creates a sdocument property.
# 
# @name  string (required)  The workbook name.  
# @property  CellsDocumentProperty (required)  Gets or sets the value of the property.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sets/creates a sdocument property.',
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
# Gets document property by name.
# 
# @name  string (required)  The workbook name.  
# @propertyName  string (required)  The property name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets document property by name.',
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
# Deletes a document property.
# 
# @name  string (required)  The workbook name.  
# @propertyName  string (required)  The property name.  
# @type  string     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a document property.',
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
# Delete all custom document properties and clean built-in ones.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all custom document properties and clean built-in ones.',
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
# @File  string (required)  The password needed to open an Excel file.  
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
# @File  string (required)  The password needed to open an Excel file.  
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
# @File  string (required)  The password needed to open an Excel file.  
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
# Copys content to destination range from source range in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeCopyRequest (required)  copydata,copystyle,copyto,copyvalue  
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
    	summary => 'Copys content to destination range from source range in worksheet.',
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
# Combines a range of cells into a single cell.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  range description.  
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
    	summary => 'Combines a range of cells into a single cell.',
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
# Unmerges merged cells of this range.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  range description.  
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
    	summary => 'Unmerges merged cells of this range.',
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
# Sets the style of the range.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeSetStyleRequest (required)  Range Set Style Request   
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
    	summary => 'Sets the style of the range.',
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
# Get the value of cells in range.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @namerange  string   range name.  
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
    	summary => 'Get the value of cells in range.',
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
# Puts a value into the range, if appropriate the value will be converted to other data type and cell`s number format will be reset.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  range in worksheet   
# @Value  string (required)  Input value  
# @isConverted  boolean   True: converted to other data type if appropriate.  
# @setStyle  boolean   True: set the number format to cell`s style when converting to other data type  
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
    	summary => 'Puts a value into the range, if appropriate the value will be converted to other data type and cell`s number format will be reset.',
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
# Moves the current range to the dest range.
# 
# @name  string (required)  The workbook name.  
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
    	summary => 'Moves the current range to the dest range.',
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
# Sets data sort around a range of cells.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeSortRequest  RangeSortRequest (required)  Range Sort Request   
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
    	summary => 'Sets data sort around a range of cells.',
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
# Sets outline border around a range of cells.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rangeOperate  RangeSetOutlineBorderRequest (required)  Range Set OutlineBorder Request.  
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
    	summary => 'Sets outline border around a range of cells.',
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
# Sets column width of range.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  Range (required)  The range object.  
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
    	summary => 'Sets column width of range.',
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
# @name  string (required)  The workbook name.  
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
# PutWorksheetCellsRangeRequest
#
# Inserts a range of cells and shift cells according to the shift option.
# 
# @name  string (required)  The workbook name.  
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
    	summary => 'Inserts a range of cells and shift cells according to the shift option.',
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
# Deletes a range of cells and shift cells according to the shift option.
# 
# @name  string (required)  The workbook name.  
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
    	summary => 'Deletes a range of cells and shift cells according to the shift option.',
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
# Get shapes description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get shapes description in worksheet.',
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
# Gets shape description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets shape description in worksheet.',
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
# Adds shape in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeDTO  Shape     
# @DrawingType  string   shape object type  
# @upperLeftRow  int   Upper left row index.  
# @upperLeftColumn  int   Upper left column index.  
# @top  int   Represents the vertical offset of Spinner from its left row, in unit of pixel.  
# @left  int   Represents the horizontal offset of Spinner from its left column, in unit of pixel.  
# @width  int   Represents the height of Spinner, in unit of pixel.  
# @height  int   Represents the width of Spinner, in unit of pixel.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds shape in worksheet.',
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
# delete all shapes in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'delete all shapes in worksheet.',
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
# Deletes a shape in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a shape in worksheet.',
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
# Updates a shape in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @shapeindex  int (required)  shape index in worksheet shapes.  
# @dto  Shape (required)  The shape description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates a shape in worksheet.',
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
# 
# 
# @name  string (required)    
# @sheetName  string (required)    
# @listShape  ARRAY[int?] (required)    
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# 
# 
# @name  string (required)    
# @sheetName  string (required)    
# @shapeindex  int (required)    
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# Get worksheet sparkline groups description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get worksheet sparkline groups description.',
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
# Get worksheet sparkline group description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineIndex  int (required)  The zero based index of the element.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get worksheet sparkline group description.',
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
# Delete worksheet sparkline groups description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete worksheet sparkline groups description.',
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
# Delete worksheet sparkline group description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineIndex  int (required)  The zero based index of the element.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete worksheet sparkline group description.',
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
# Put worksheet sparkline group description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @type  string (required)  Represents the sparkline types(Line/Column/Stacked).  
# @dataRange  string (required)  Specifies the data range of the sparkline group.  
# @isVertical  boolean (required)  Specifies whether to plot the sparklines from the data range by row or by column.  
# @locationRange  string (required)  Specifies where the sparklines to be placed.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Put worksheet sparkline group description.',
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
# Post worksheet sparkline group description.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sparklineGroupIndex  int (required)  The zero based index of the element.  
# @sparklineGroup  SparklineGroup (required)  Spark line group description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Post worksheet sparkline group description.',
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
# GetWorkbookDefaultStyleRequest
#
# Gets workbook default style description.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets workbook default style description.',
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
# Get workbook`s text items.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get workbook`s text items.',
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
# Get workbook`s names.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get workbook`s names.',
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
# Defines a new name in workbook.
# 
# @name  string (required)  The workbook name.  
# @newName  Name (required)    
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Defines a new name in workbook.',
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
# Gets workbook`s name description.
# 
# @name  string (required)  The workbook name.  
# @nameName  string (required)  The name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets workbook`s name description.',
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
# Update workbook`s name.
# 
# @name  string (required)  The workbook name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @newName  Name (required)  new name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Update workbook`s name.',
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
# Gets workbook`s name value.
# 
# @name  string (required)  The workbook name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets workbook`s name value.',
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
# Delete workbook`s names.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete workbook`s names.',
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
# Gets workbook`s name description.
# 
# @name  string (required)  The workbook name.  
# @nameName  string (required)  the Aspose.Cells.Name element name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets workbook`s name description.',
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
# Merge workbooks.
# 
# @name  string (required)  Workbook name.  
# @mergeWith  string (required)  The workbook to merge with.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.  
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
    	summary => 'Merge workbooks.',
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
# Search text in workbook.
# 
# @name  string (required)  The workbook name.  
# @text  string (required)  Text sample.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Search text in workbook.',
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
# Replaces text in workbook.
# 
# @name  string (required)  The workbook name.  
# @oldValue  string (required)  The old value.  
# @newValue  string (required)  The new value.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Replaces text in workbook.',
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
# Smart marker processing result.
# 
# @name  string (required)  The workbook name.  
# @xmlFile  string   The xml file full path, if empty the data is read from request body.  
# @folder  string   Original workbook folder.  
# @outPath  string   Path to save result  
# @storageName  string   Storage name.  
# @outStorageName  string   Storage name.   
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
    	summary => 'Smart marker processing result.',
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
# Creates new workbook using deferent methods.
# 
# @name  string (required)  The new document name.  
# @templateFile  string   The template file, if the data not provided default workbook is created.  
# @dataFile  string   Smart marker data file, if the data not provided the request content is checked for the data.  
# @isWriteOver  boolean   Specifies whether to write over targer file.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.  
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
    	summary => 'Creates new workbook using deferent methods.',
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
# Splits workbook.
# 
# @name  string (required)  The workbook name.  
# @format  string   Split format.  
# @outFolder  string     
# @from  int   Start worksheet index.  
# @to  int   End worksheet index.  
# @horizontalResolution  int   Image horizontal resolution.  
# @verticalResolution  int   Image vertical resolution.  
# @splitNameRule  string   rule name : sheetname  newguid   
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.  
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
    	summary => 'Splits workbook.',
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
# Calculate all formulas in workbook.
# 
# @name  string (required)  The workbook name.  
# @options  CalculationOptions   Calculation Options.  
# @ignoreError  boolean   ignore Error.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Calculate all formulas in workbook.',
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
# Autofit workbook rows.
# 
# @name  string (required)  The workbook name.  
# @startRow  int   Start row.  
# @endRow  int   End row.  
# @onlyAuto  boolean   Only auto.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Autofit workbook rows.',
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
# 
# 
# @name  string (required)    
# @startColumn  int     
# @endColumn  int     
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# Gets workbook settings description.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets workbook settings description.',
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
# Updates workbook setting.
# 
# @name  string (required)  The workbook name.  
# @settings  WorkbookSettings (required)  Workbook Setting description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates workbook setting.',
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
# Set workbook background.
# 
# @name  string (required)  The workbook name.  
# @picPath  string   picture full path.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.  
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
    	summary => 'Set workbook background.',
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
# Delete workbook background.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete workbook background.',
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
# Set workbook water marker.
# 
# @name  string (required)  The workbook name.  
# @textWaterMarkerRequest  TextWaterMarkerRequest (required)  Text water marker request  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Set workbook water marker.',
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
# 
# 
# @name  string (required)    
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# GetWorksheetsRequest
#
# Get worksheets description.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get worksheets description.',
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
# Gets worksheet in some format.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @format  string   Export format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  
# @verticalResolution  int   Image vertical resolution.  
# @horizontalResolution  int   Image horizontal resolution.  
# @area  string   Represents the range to be printed.  
# @pageIndex  int   Represents the page to be printed  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets worksheet in some format.',
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
# Changes worksheet visibility.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @isVisible  boolean (required)  New worksheet visibility value.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Changes worksheet visibility.',
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
# Active sheet
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Active sheet',
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
# Inserts new worksheet in workbook.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @index  int (required)    
# @sheettype  string (required)  Specifies the worksheet type(VB/Worksheet/Chart/BIFF4Macro/InternationalMacro/Other/Dialog).  
# @newsheetname  string     
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Inserts new worksheet in workbook.',
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
# Adds new worksheet in workbook.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The new sheet name.  
# @position  int   The new sheet position.  
# @sheettype  string   Specifies the worksheet type(VB/Worksheet/Chart/BIFF4Macro/InternationalMacro/Other/Dialog).  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds new worksheet in workbook.',
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
# Deletes a worksheet in workbook.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a worksheet in workbook.',
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
# 
# 
# @name  string (required)    
# @matchCondition  MatchConditionRequest     
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# Move worksheet in workbook.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @moving  WorksheetMovingRequest (required)  WorksheetMovingRequest with moving parameters.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Move worksheet in workbook.',
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
# Protects worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @protectParameter  ProtectSheetParameter (required)  ProtectSheetParameter with protection settings.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Protects worksheet.',
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
# Unprotects worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @protectParameter  ProtectSheetParameter (required)  WorksheetResponse with protection settings. Only password is used here.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Unprotects worksheet.',
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
# Get text items in worksheet.
# 
# @name  string (required)  Workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   The workbook`s folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get text items in worksheet.',
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
# Get comments description in worksheet.
# 
# @name  string (required)  Workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get comments description in worksheet.',
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
# Gets comment by cell name in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets comment by cell name in worksheet.',
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
# Adds cell comment in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @comment  Comment (required)  Comment object.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds cell comment in worksheet.',
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
# Updates cell comment in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @comment  Comment (required)  Comment object.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates cell comment in worksheet.',
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
# Deletes cell comment in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellName  string (required)  The cell name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes cell comment in worksheet.',
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
# Delete all comments in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all comments in worksheet.',
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
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The workseet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
# Gets merged cell description by its index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @mergedCellIndex  int (required)  Merged cell index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets merged cell description by its index in worksheet.',
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
# Calculates formula value in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @formula  string (required)  The formula.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Calculates formula value in worksheet.',
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
# Calculates formula value in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @formula  string (required)  The formula.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Calculates formula value in worksheet.',
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
# Searchs text in worksheet.
# 
# @name  string (required)  The workbook name.  
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
    	summary => 'Searchs text in worksheet.',
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
# PostWorsheetTextReplaceRequest
#
# Replaces text in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  Worksheet name.  
# @oldValue  string (required)  The old text to replace.  
# @newValue  string (required)  The new text to replace by.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
#
{
    my $params = {
       'request' =>{
            data_type => 'PostWorsheetTextReplaceRequest',
            description => 'PostWorsheetTextReplace Request.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_worsheet_text_replace' } = { 
    	summary => 'Replaces text in worksheet.',
        params => $params,
        returns => 'WorksheetReplaceResponse',
    };
}
#
# @return WorksheetReplaceResponse
#
sub post_worsheet_text_replace{
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
# Sorts range in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @cellArea  string (required)  The area needed to sort.  
# @dataSorter  DataSorter (required)  DataSorter with sorting settings.  
# @folder  string   The workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sorts range in worksheet.',
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
# Autofits row in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @rowIndex  int (required)  Row index.  
# @firstColumn  int (required)  First column index.  
# @lastColumn  int (required)  Last column index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Autofits row in worksheet.',
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
# Autofit rows in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @startRow  int   Start row index.  
# @endRow  int   End row index.  
# @onlyAuto  boolean   Autofits all rows in this worksheet.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Autofit rows in worksheet.',
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
# 
# 
# @name  string (required)    
# @sheetName  string (required)    
# @startColumn  int     
# @endColumn  int     
# @onlyAuto  boolean     
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# Sets background image in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @picPath  string   picture full filename.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.  
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
    	summary => 'Sets background image in worksheet.',
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
# Delete background image in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete background image in worksheet.',
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
# Sets freeze panes in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int (required)  Row index.  
# @column  int (required)  Column index.  
# @freezedRows  int (required)  Number of visible rows in top pane, no more than row index.  
# @freezedColumns  int (required)  Number of visible columns in left pane, no more than column index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Sets freeze panes in worksheet.',
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
# Unfreezes panes in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @row  int (required)  Row index.  
# @column  int (required)  Column index.  
# @freezedRows  int (required)  Number of visible rows in top pane, no more than row index.  
# @freezedColumns  int (required)  Number of visible columns in left pane, no more than column index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Unfreezes panes in worksheet.',
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
# Copies contents and formats from another worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sourceSheet  string (required)  Source worksheet.  
# @options  CopyOptions (required)  Represents the copy options.  
# @sourceWorkbook  string   source Workbook.  
# @sourceFolder  string   Original workbook folder.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Copies contents and formats from another worksheet.',
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
# Rename worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @newname  string (required)  New worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Rename worksheet.',
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
# Update worksheet properties.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @sheet  Worksheet (required)  The worksheet description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Update worksheet properties.',
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
# Get worksheets ranges description.
# 
# @name  string (required)  The workbook name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get worksheets ranges description.',
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
# Get range values.
# 
# @name  string (required)  The workbook name.  
# @namerange  string (required)  Range name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get range values.',
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
# Updates worksheet zoom.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @value  int (required)  Represents the scaling factor in percentage. It should be between 10 and 400.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates worksheet zoom.',
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
# 
# 
# @name  string (required)    
# @sheetName  string (required)    
# @folder  string     
# @storageName  string      
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
    	summary => '',
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
# Get validations description in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Get validations description in worksheet.',
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
# Gets a validation by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Gets a validation by index in worksheet.',
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
# Adds a validation at index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @range  string   Specified cells area  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Adds a validation at index in worksheet.',
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
# Updates a validation by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @validation  Validation (required)  Validation description.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Updates a validation by index in worksheet.',
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
# Deletes a validation by index in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @validationIndex  int (required)  The validation index.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Deletes a validation by index in worksheet.',
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
# Delete all validations in worksheet.
# 
# @name  string (required)  The workbook name.  
# @sheetName  string (required)  The worksheet name.  
# @folder  string   Original workbook folder.  
# @storageName  string   Storage name.   
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
    	summary => 'Delete all validations in worksheet.',
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
