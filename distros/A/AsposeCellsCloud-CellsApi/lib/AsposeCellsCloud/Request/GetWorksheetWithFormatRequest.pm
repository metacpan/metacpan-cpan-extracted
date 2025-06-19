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

package AsposeCellsCloud::Request::GetWorksheetWithFormatRequest;

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
# GetWorksheetWithFormatRequest.name : The file name.  ,
# GetWorksheetWithFormatRequest.sheetName : The worksheet name.  ,
# GetWorksheetWithFormatRequest.format : Export format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  ,
# GetWorksheetWithFormatRequest.verticalResolution : Image vertical resolution.  ,
# GetWorksheetWithFormatRequest.horizontalResolution : Image horizontal resolution.  ,
# GetWorksheetWithFormatRequest.area : Represents the range to be printed.  ,
# GetWorksheetWithFormatRequest.pageIndex : Represents the page to be printed  ,
# GetWorksheetWithFormatRequest.onePagePerSheet :   ,
# GetWorksheetWithFormatRequest.printHeadings :   ,
# GetWorksheetWithFormatRequest.folder : The folder where the file is situated.  ,
# GetWorksheetWithFormatRequest.storageName : The storage name where the file is situated.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_worksheet_with_format' } = { 
    	summary => 'Retrieve the worksheet in a specified format from the workbook.',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/worksheets/{sheetName}';

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
    if(defined $self->format){
        $query_params->{'format'} = $client->to_query_value($self->format);      
    }

    if(defined $self->vertical_resolution){
        $query_params->{'verticalResolution'} = $client->to_query_value($self->vertical_resolution);      
    }

    if(defined $self->horizontal_resolution){
        $query_params->{'horizontalResolution'} = $client->to_query_value($self->horizontal_resolution);      
    }

    if(defined $self->area){
        $query_params->{'area'} = $client->to_query_value($self->area);      
    }

    if(defined $self->page_index){
        $query_params->{'pageIndex'} = $client->to_query_value($self->page_index);      
    }

    if(defined $self->one_page_per_sheet){
        $query_params->{'onePagePerSheet'} = $client->to_query_value($self->one_page_per_sheet);      
    }

    if(defined $self->print_headings){
        $query_params->{'printHeadings'} = $client->to_query_value($self->print_headings);      
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
     'format' => {
     	datatype => 'string',
     	base_name => 'format',
     	description => 'Export format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).',
     	format => '',
     	read_only => '',
     		},
     'vertical_resolution' => {
     	datatype => 'int',
     	base_name => 'verticalResolution',
     	description => 'Image vertical resolution.',
     	format => '',
     	read_only => '',
     		},
     'horizontal_resolution' => {
     	datatype => 'int',
     	base_name => 'horizontalResolution',
     	description => 'Image horizontal resolution.',
     	format => '',
     	read_only => '',
     		},
     'area' => {
     	datatype => 'string',
     	base_name => 'area',
     	description => 'Represents the range to be printed.',
     	format => '',
     	read_only => '',
     		},
     'page_index' => {
     	datatype => 'int',
     	base_name => 'pageIndex',
     	description => 'Represents the page to be printed',
     	format => '',
     	read_only => '',
     		},
     'one_page_per_sheet' => {
     	datatype => 'string',
     	base_name => 'onePagePerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'print_headings' => {
     	datatype => 'string',
     	base_name => 'printHeadings',
     	description => '',
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
    'format' => 'format',
    'vertical_resolution' => 'verticalResolution',
    'horizontal_resolution' => 'horizontalResolution',
    'area' => 'area',
    'page_index' => 'pageIndex',
    'one_page_per_sheet' => 'onePagePerSheet',
    'print_headings' => 'printHeadings',
    'folder' => 'folder',
    'storage_name' => 'storageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;