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

package AsposeCellsCloud::Request::SplitTableRequest;

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
# SplitTableRequest.Spreadsheet : Upload spreadsheet file.  ,
# SplitTableRequest.worksheet : Worksheet containing the table.  ,
# SplitTableRequest.tableName : Data table that needs to be split.  ,
# SplitTableRequest.splitColumnName : Column name to split by.  ,
# SplitTableRequest.saveSplitColumn : Whether to keep the data in the split column.  ,
# SplitTableRequest.toNewWorkbook : Export destination control: true - Creates new workbook files containing the split data; false - Adds a new worksheet to the current workbook.  ,
# SplitTableRequest.toMultipleFiles : true - Exports table data as **multiple separate files** (returned as ZIP archive);false - Stores all data in a **single file** with multiple sheets. Default: false.  ,
# SplitTableRequest.outPath : (Optional) The folder path where the workbook is stored. The default is null.  ,
# SplitTableRequest.outStorageName : Output file Storage Name.  ,
# SplitTableRequest.fontsLocation : Use Custom fonts.  ,
# SplitTableRequest.region : The spreadsheet region setting.  ,
# SplitTableRequest.password : The password for opening spreadsheet file.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'split_table' } = { 
    	summary => 'Split an Excel worksheet into multiple sheets by column value.',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v4.0/cells/split/table';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->worksheet){
        $query_params->{'worksheet'} = $client->to_query_value($self->worksheet);      
    }

    if(defined $self->table_name){
        $query_params->{'tableName'} = $client->to_query_value($self->table_name);      
    }

    if(defined $self->split_column_name){
        $query_params->{'splitColumnName'} = $client->to_query_value($self->split_column_name);      
    }

    if(defined $self->save_split_column){
        $query_params->{'saveSplitColumn'} = $client->to_query_value($self->save_split_column);      
    }

    if(defined $self->to_new_workbook){
        $query_params->{'toNewWorkbook'} = $client->to_query_value($self->to_new_workbook);      
    }

    if(defined $self->to_multiple_files){
        $query_params->{'toMultipleFiles'} = $client->to_query_value($self->to_multiple_files);      
    }

    if(defined $self->out_path){
        $query_params->{'outPath'} = $client->to_query_value($self->out_path);      
    }

    if(defined $self->out_storage_name){
        $query_params->{'outStorageName'} = $client->to_query_value($self->out_storage_name);      
    }

    if(defined $self->fonts_location){
        $query_params->{'fontsLocation'} = $client->to_query_value($self->fonts_location);      
    }

    if(defined $self->region){
        $query_params->{'region'} = $client->to_query_value($self->region);      
    }

    if(defined $self->password){
        $query_params->{'password'} = $client->to_query_value($self->password);      
    } 
    my $_body_data;


    if (defined $self->spreadsheet) {   
        $form_params->{basename($self->spreadsheet)} = [$self->spreadsheet ,basename($self->spreadsheet),'application/octet-stream'];
    }
 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'spreadsheet' => {
     	datatype => 'string',
     	base_name => 'Spreadsheet',
     	description => 'Upload spreadsheet file.',
     	format => '',
     	read_only => '',
     		},
     'worksheet' => {
     	datatype => 'string',
     	base_name => 'worksheet',
     	description => 'Worksheet containing the table.',
     	format => '',
     	read_only => '',
     		},
     'table_name' => {
     	datatype => 'string',
     	base_name => 'tableName',
     	description => 'Data table that needs to be split.',
     	format => '',
     	read_only => '',
     		},
     'split_column_name' => {
     	datatype => 'string',
     	base_name => 'splitColumnName',
     	description => 'Column name to split by.',
     	format => '',
     	read_only => '',
     		},
     'save_split_column' => {
     	datatype => 'string',
     	base_name => 'saveSplitColumn',
     	description => 'Whether to keep the data in the split column.',
     	format => '',
     	read_only => '',
     		},
     'to_new_workbook' => {
     	datatype => 'string',
     	base_name => 'toNewWorkbook',
     	description => 'Export destination control: true - Creates new workbook files containing the split data; false - Adds a new worksheet to the current workbook.',
     	format => '',
     	read_only => '',
     		},
     'to_multiple_files' => {
     	datatype => 'string',
     	base_name => 'toMultipleFiles',
     	description => 'true - Exports table data as **multiple separate files** (returned as ZIP archive);false - Stores all data in a **single file** with multiple sheets. Default: false.',
     	format => '',
     	read_only => '',
     		},
     'out_path' => {
     	datatype => 'string',
     	base_name => 'outPath',
     	description => '(Optional) The folder path where the workbook is stored. The default is null.',
     	format => '',
     	read_only => '',
     		},
     'out_storage_name' => {
     	datatype => 'string',
     	base_name => 'outStorageName',
     	description => 'Output file Storage Name.',
     	format => '',
     	read_only => '',
     		},
     'fonts_location' => {
     	datatype => 'string',
     	base_name => 'fontsLocation',
     	description => 'Use Custom fonts.',
     	format => '',
     	read_only => '',
     		},
     'region' => {
     	datatype => 'string',
     	base_name => 'region',
     	description => 'The spreadsheet region setting.',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'password',
     	description => 'The password for opening spreadsheet file.',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'spreadsheet' => 'Spreadsheet',
    'worksheet' => 'worksheet',
    'table_name' => 'tableName',
    'split_column_name' => 'splitColumnName',
    'save_split_column' => 'saveSplitColumn',
    'to_new_workbook' => 'toNewWorkbook',
    'to_multiple_files' => 'toMultipleFiles',
    'out_path' => 'outPath',
    'out_storage_name' => 'outStorageName',
    'fonts_location' => 'fontsLocation',
    'region' => 'region',
    'password' => 'password' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;