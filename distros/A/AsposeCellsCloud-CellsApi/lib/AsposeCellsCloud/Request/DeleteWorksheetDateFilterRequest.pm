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

package AsposeCellsCloud::Request::DeleteWorksheetDateFilterRequest;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON ;
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;
use File::Basename;

use base ("Class::Accessor", "Class::Data::Inheritable");

__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('method_documentation' => {}); 
__PACKAGE__->mk_classdata('class_documentation' => {});


# new object
sub new { 
    my ($class, %args) = @_; 

	my $self = bless {}, $class;

	foreach my $attribute (keys %{$class->attribute_map}) {
		my $args_key = $class->attribute_map->{$attribute};
		$self->$attribute( $args{ $args_key } );
	}

	return $self;
}  


# Run Operation Request
# DeleteWorksheetDateFilterRequest.name : The workbook name.  ,
# DeleteWorksheetDateFilterRequest.sheetName : The worksheet name.  ,
# DeleteWorksheetDateFilterRequest.fieldIndex : The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).  ,
# DeleteWorksheetDateFilterRequest.dateTimeGroupingType : Specifies how to group dateTime values.  ,
# DeleteWorksheetDateFilterRequest.year : The year.  ,
# DeleteWorksheetDateFilterRequest.month : The month.  ,
# DeleteWorksheetDateFilterRequest.day : The day.  ,
# DeleteWorksheetDateFilterRequest.hour : The hour.  ,
# DeleteWorksheetDateFilterRequest.minute : The minute.  ,
# DeleteWorksheetDateFilterRequest.second : The second.  ,
# DeleteWorksheetDateFilterRequest.folder : The folder where the file is situated.  ,
# DeleteWorksheetDateFilterRequest.storageName : The storage name where the file is situated.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'delete_worksheet_date_filter' } = { 
    	summary => 'Remove a date filter in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}/autoFilter/dateFilter';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('application/json');
    if(defined $self->name){
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $client->to_path_value($self->name);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    }

    if(defined $self->sheet_name){
        my $_base_variable = "{" . "sheetName" . "}";
        my $_base_value = $client->to_path_value($self->sheet_name);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    } 
    if(defined $self->field_index){
        $query_params->{'fieldIndex'} = $client->to_query_value($self->field_index);      
    }

    if(defined $self->date_time_grouping_type){
        $query_params->{'dateTimeGroupingType'} = $client->to_query_value($self->date_time_grouping_type);      
    }

    if(defined $self->year){
        $query_params->{'year'} = $client->to_query_value($self->year);      
    }

    if(defined $self->month){
        $query_params->{'month'} = $client->to_query_value($self->month);      
    }

    if(defined $self->day){
        $query_params->{'day'} = $client->to_query_value($self->day);      
    }

    if(defined $self->hour){
        $query_params->{'hour'} = $client->to_query_value($self->hour);      
    }

    if(defined $self->minute){
        $query_params->{'minute'} = $client->to_query_value($self->minute);      
    }

    if(defined $self->second){
        $query_params->{'second'} = $client->to_query_value($self->second);      
    }

    if(defined $self->folder){
        $query_params->{'folder'} = $client->to_query_value($self->folder);      
    }

    if(defined $self->storage_name){
        $query_params->{'storageName'} = $client->to_query_value($self->storage_name);      
    } 
    my $_body_data;

 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'name',
     	description => 'The workbook name.',
     	format => '',
     	read_only => '',
     		},
     'sheet_name' => {
     	datatype => 'string',
     	base_name => 'sheetName',
     	description => 'The worksheet name.',
     	format => '',
     	read_only => '',
     		},
     'field_index' => {
     	datatype => 'int',
     	base_name => 'fieldIndex',
     	description => 'The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).',
     	format => '',
     	read_only => '',
     		},
     'date_time_grouping_type' => {
     	datatype => 'string',
     	base_name => 'dateTimeGroupingType',
     	description => 'Specifies how to group dateTime values.',
     	format => '',
     	read_only => '',
     		},
     'year' => {
     	datatype => 'int',
     	base_name => 'year',
     	description => 'The year.',
     	format => '',
     	read_only => '',
     		},
     'month' => {
     	datatype => 'int',
     	base_name => 'month',
     	description => 'The month.',
     	format => '',
     	read_only => '',
     		},
     'day' => {
     	datatype => 'int',
     	base_name => 'day',
     	description => 'The day.',
     	format => '',
     	read_only => '',
     		},
     'hour' => {
     	datatype => 'int',
     	base_name => 'hour',
     	description => 'The hour.',
     	format => '',
     	read_only => '',
     		},
     'minute' => {
     	datatype => 'int',
     	base_name => 'minute',
     	description => 'The minute.',
     	format => '',
     	read_only => '',
     		},
     'second' => {
     	datatype => 'int',
     	base_name => 'second',
     	description => 'The second.',
     	format => '',
     	read_only => '',
     		},
     'folder' => {
     	datatype => 'string',
     	base_name => 'folder',
     	description => 'The folder where the file is situated.',
     	format => '',
     	read_only => '',
     		},
     'storage_name' => {
     	datatype => 'string',
     	base_name => 'storageName',
     	description => 'The storage name where the file is situated.',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'name' => 'name',
    'sheet_name' => 'sheetName',
    'field_index' => 'fieldIndex',
    'date_time_grouping_type' => 'dateTimeGroupingType',
    'year' => 'year',
    'month' => 'month',
    'day' => 'day',
    'hour' => 'hour',
    'minute' => 'minute',
    'second' => 'second',
    'folder' => 'folder',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;