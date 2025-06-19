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

package AsposeCellsCloud::Request::PostPivotTableFieldHideItemRequest;

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
# PostPivotTableFieldHideItemRequest.name : The file name.  ,
# PostPivotTableFieldHideItemRequest.sheetName : The worksheet name.  ,
# PostPivotTableFieldHideItemRequest.pivotTableIndex : The PivotTable index.  ,
# PostPivotTableFieldHideItemRequest.pivotFieldType : Represents PivotTable field type(Undefined/Row/Column/Page/Data).  ,
# PostPivotTableFieldHideItemRequest.fieldIndex : The pivot field index.  ,
# PostPivotTableFieldHideItemRequest.itemIndex : The index of the pivot item in the pivot field.  ,
# PostPivotTableFieldHideItemRequest.isHide : Whether the specific PivotItem is hidden(true/false).  ,
# PostPivotTableFieldHideItemRequest.needReCalculate : Whether the specific PivotTable calculate(true/false).  ,
# PostPivotTableFieldHideItemRequest.folder : The folder where the file is situated.  ,
# PostPivotTableFieldHideItemRequest.storageName : The storage name where the file is situated.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_pivot_table_field_hide_item' } = { 
    	summary => 'Hide a pivot field item in the PivotTable.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/Hide';

    my $_method = 'POST';
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

    if(defined $self->pivot_table_index){
        my $_base_variable = "{" . "pivotTableIndex" . "}";
        my $_base_value = $client->to_path_value($self->pivot_table_index);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    } 
    if(defined $self->pivot_field_type){
        $query_params->{'pivotFieldType'} = $client->to_query_value($self->pivot_field_type);      
    }

    if(defined $self->field_index){
        $query_params->{'fieldIndex'} = $client->to_query_value($self->field_index);      
    }

    if(defined $self->item_index){
        $query_params->{'itemIndex'} = $client->to_query_value($self->item_index);      
    }

    if(defined $self->is_hide){
        $query_params->{'isHide'} = $client->to_query_value($self->is_hide);      
    }

    if(defined $self->need_re_calculate){
        $query_params->{'needReCalculate'} = $client->to_query_value($self->need_re_calculate);      
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
     'pivot_table_index' => {
     	datatype => 'int',
     	base_name => 'pivotTableIndex',
     	description => 'The PivotTable index.',
     	format => '',
     	read_only => '',
     		},
     'pivot_field_type' => {
     	datatype => 'string',
     	base_name => 'pivotFieldType',
     	description => 'Represents PivotTable field type(Undefined/Row/Column/Page/Data).',
     	format => '',
     	read_only => '',
     		},
     'field_index' => {
     	datatype => 'int',
     	base_name => 'fieldIndex',
     	description => 'The pivot field index.',
     	format => '',
     	read_only => '',
     		},
     'item_index' => {
     	datatype => 'int',
     	base_name => 'itemIndex',
     	description => 'The index of the pivot item in the pivot field.',
     	format => '',
     	read_only => '',
     		},
     'is_hide' => {
     	datatype => 'string',
     	base_name => 'isHide',
     	description => 'Whether the specific PivotItem is hidden(true/false).',
     	format => '',
     	read_only => '',
     		},
     'need_re_calculate' => {
     	datatype => 'string',
     	base_name => 'needReCalculate',
     	description => 'Whether the specific PivotTable calculate(true/false).',
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
    'pivot_table_index' => 'pivotTableIndex',
    'pivot_field_type' => 'pivotFieldType',
    'field_index' => 'fieldIndex',
    'item_index' => 'itemIndex',
    'is_hide' => 'isHide',
    'need_re_calculate' => 'needReCalculate',
    'folder' => 'folder',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;