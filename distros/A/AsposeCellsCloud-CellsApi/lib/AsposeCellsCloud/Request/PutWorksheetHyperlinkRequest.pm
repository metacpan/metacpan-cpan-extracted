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

package AsposeCellsCloud::Request::PutWorksheetHyperlinkRequest;

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
# PutWorksheetHyperlinkRequest.name : The file name.  ,
# PutWorksheetHyperlinkRequest.sheetName : The worksheet name.  ,
# PutWorksheetHyperlinkRequest.firstRow : First row of the hyperlink range.  ,
# PutWorksheetHyperlinkRequest.firstColumn : First column of the hyperlink range.  ,
# PutWorksheetHyperlinkRequest.totalRows : Number of rows in this hyperlink range.  ,
# PutWorksheetHyperlinkRequest.totalColumns : Number of columns of this hyperlink range.  ,
# PutWorksheetHyperlinkRequest.address : Address of the hyperlink.  ,
# PutWorksheetHyperlinkRequest.folder : The folder where the file is situated.  ,
# PutWorksheetHyperlinkRequest.storageName : The storage name where the file is situated.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_worksheet_hyperlink' } = { 
    	summary => 'Add hyperlink in the worksheet.',
        params => $params,
        returns => 'CellsCloudResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}/hyperlinks';

    my $_method = 'PUT';
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
    if(defined $self->first_row){
        $query_params->{'firstRow'} = $client->to_query_value($self->first_row);      
    }

    if(defined $self->first_column){
        $query_params->{'firstColumn'} = $client->to_query_value($self->first_column);      
    }

    if(defined $self->total_rows){
        $query_params->{'totalRows'} = $client->to_query_value($self->total_rows);      
    }

    if(defined $self->total_columns){
        $query_params->{'totalColumns'} = $client->to_query_value($self->total_columns);      
    }

    if(defined $self->address){
        $query_params->{'address'} = $client->to_query_value($self->address);      
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
     'first_row' => {
     	datatype => 'int',
     	base_name => 'firstRow',
     	description => 'First row of the hyperlink range.',
     	format => '',
     	read_only => '',
     		},
     'first_column' => {
     	datatype => 'int',
     	base_name => 'firstColumn',
     	description => 'First column of the hyperlink range.',
     	format => '',
     	read_only => '',
     		},
     'total_rows' => {
     	datatype => 'int',
     	base_name => 'totalRows',
     	description => 'Number of rows in this hyperlink range.',
     	format => '',
     	read_only => '',
     		},
     'total_columns' => {
     	datatype => 'int',
     	base_name => 'totalColumns',
     	description => 'Number of columns of this hyperlink range.',
     	format => '',
     	read_only => '',
     		},
     'address' => {
     	datatype => 'string',
     	base_name => 'address',
     	description => 'Address of the hyperlink.',
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
    'first_row' => 'firstRow',
    'first_column' => 'firstColumn',
    'total_rows' => 'totalRows',
    'total_columns' => 'totalColumns',
    'address' => 'address',
    'folder' => 'folder',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;