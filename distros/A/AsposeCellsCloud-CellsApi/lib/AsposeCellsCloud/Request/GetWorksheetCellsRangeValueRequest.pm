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

package AsposeCellsCloud::Request::GetWorksheetCellsRangeValueRequest;

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
# GetWorksheetCellsRangeValueRequest.name : The file name.  ,
# GetWorksheetCellsRangeValueRequest.sheetName : The worksheet name.  ,
# GetWorksheetCellsRangeValueRequest.namerange : The range name.  ,
# GetWorksheetCellsRangeValueRequest.firstRow : Gets the index of the first row of the range.  ,
# GetWorksheetCellsRangeValueRequest.firstColumn : Gets the index of the first columnn of the range.  ,
# GetWorksheetCellsRangeValueRequest.rowCount : Gets the count of rows in the range.  ,
# GetWorksheetCellsRangeValueRequest.columnCount : Gets the count of columns in the range.  ,
# GetWorksheetCellsRangeValueRequest.folder : Original workbook folder.  ,
# GetWorksheetCellsRangeValueRequest.storageName : Storage name.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_cells_range_value' } = { 
    	summary => 'Retrieve the values of cells within the specified range.',
        params => $params,
        returns => 'RangeValueResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}/ranges/value';

    my $_method = 'GET';
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
    if(defined $self->namerange){
        $query_params->{'namerange'} = $client->to_query_value($self->namerange);      
    }

    if(defined $self->first_row){
        $query_params->{'firstRow'} = $client->to_query_value($self->first_row);      
    }

    if(defined $self->first_column){
        $query_params->{'firstColumn'} = $client->to_query_value($self->first_column);      
    }

    if(defined $self->row_count){
        $query_params->{'rowCount'} = $client->to_query_value($self->row_count);      
    }

    if(defined $self->column_count){
        $query_params->{'columnCount'} = $client->to_query_value($self->column_count);      
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
     	description => 'The file name.',
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
     'namerange' => {
     	datatype => 'string',
     	base_name => 'namerange',
     	description => 'The range name.',
     	format => '',
     	read_only => '',
     		},
     'first_row' => {
     	datatype => 'int',
     	base_name => 'firstRow',
     	description => 'Gets the index of the first row of the range.',
     	format => '',
     	read_only => '',
     		},
     'first_column' => {
     	datatype => 'int',
     	base_name => 'firstColumn',
     	description => 'Gets the index of the first columnn of the range.',
     	format => '',
     	read_only => '',
     		},
     'row_count' => {
     	datatype => 'int',
     	base_name => 'rowCount',
     	description => 'Gets the count of rows in the range.',
     	format => '',
     	read_only => '',
     		},
     'column_count' => {
     	datatype => 'int',
     	base_name => 'columnCount',
     	description => 'Gets the count of columns in the range.',
     	format => '',
     	read_only => '',
     		},
     'folder' => {
     	datatype => 'string',
     	base_name => 'folder',
     	description => 'Original workbook folder.',
     	format => '',
     	read_only => '',
     		},
     'storage_name' => {
     	datatype => 'string',
     	base_name => 'storageName',
     	description => 'Storage name.',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'name' => 'name',
    'sheet_name' => 'sheetName',
    'namerange' => 'namerange',
    'first_row' => 'firstRow',
    'first_column' => 'firstColumn',
    'row_count' => 'rowCount',
    'column_count' => 'columnCount',
    'folder' => 'folder',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;