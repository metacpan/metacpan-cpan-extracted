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

package AsposeCellsCloud::Request::PutConvertWorkbookRequest;

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
# PutConvertWorkbookRequest.File : File to upload  ,
# PutConvertWorkbookRequest.format : The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).  ,
# PutConvertWorkbookRequest.password : The password needed to open an Excel file.  ,
# PutConvertWorkbookRequest.outPath : Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.  ,
# PutConvertWorkbookRequest.storageName : The storage name where the file is situated.  ,
# PutConvertWorkbookRequest.checkExcelRestriction : Whether check restriction of excel file when user modify cells related objects.  ,
# PutConvertWorkbookRequest.streamFormat : The format of the input file stream.   ,
# PutConvertWorkbookRequest.region : The regional settings for workbook.  ,
# PutConvertWorkbookRequest.pageWideFitOnPerSheet : The page wide fit on worksheet.  ,
# PutConvertWorkbookRequest.pageTallFitOnPerSheet : The page tall fit on worksheet.  ,
# PutConvertWorkbookRequest.sheetName : Convert the specified worksheet.   ,
# PutConvertWorkbookRequest.pageIndex : Convert the specified page  of worksheet, sheetName is required.   ,
# PutConvertWorkbookRequest.onePagePerSheet : When converting to PDF format, one page per sheet.   ,
# PutConvertWorkbookRequest.AutoRowsFit : Auto-fits all rows in this workbook.  ,
# PutConvertWorkbookRequest.AutoColumnsFit : Auto-fits the columns width in this workbook.  ,
# PutConvertWorkbookRequest.FontsLocation : Use Custom fonts.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'put_convert_workbook' } = { 
    	summary => 'Convert the workbook from the requested content into files in different formats.',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/convert';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->format){
        $query_params->{'format'} = $client->to_query_value($self->format);      
    }

    if(defined $self->password){
        $query_params->{'password'} = $client->to_query_value($self->password);      
    }

    if(defined $self->out_path){
        $query_params->{'outPath'} = $client->to_query_value($self->out_path);      
    }

    if(defined $self->storage_name){
        $query_params->{'storageName'} = $client->to_query_value($self->storage_name);      
    }

    if(defined $self->check_excel_restriction){
        $query_params->{'checkExcelRestriction'} = $client->to_query_value($self->check_excel_restriction);      
    }

    if(defined $self->stream_format){
        $query_params->{'streamFormat'} = $client->to_query_value($self->stream_format);      
    }

    if(defined $self->region){
        $query_params->{'region'} = $client->to_query_value($self->region);      
    }

    if(defined $self->page_wide_fit_on_per_sheet){
        $query_params->{'pageWideFitOnPerSheet'} = $client->to_query_value($self->page_wide_fit_on_per_sheet);      
    }

    if(defined $self->page_tall_fit_on_per_sheet){
        $query_params->{'pageTallFitOnPerSheet'} = $client->to_query_value($self->page_tall_fit_on_per_sheet);      
    }

    if(defined $self->sheet_name){
        $query_params->{'sheetName'} = $client->to_query_value($self->sheet_name);      
    }

    if(defined $self->page_index){
        $query_params->{'pageIndex'} = $client->to_query_value($self->page_index);      
    }

    if(defined $self->one_page_per_sheet){
        $query_params->{'onePagePerSheet'} = $client->to_query_value($self->one_page_per_sheet);      
    }

    if(defined $self->auto_rows_fit){
        $query_params->{'AutoRowsFit'} = $client->to_query_value($self->auto_rows_fit);      
    }

    if(defined $self->auto_columns_fit){
        $query_params->{'AutoColumnsFit'} = $client->to_query_value($self->auto_columns_fit);      
    }

    if(defined $self->fonts_location){
        $query_params->{'FontsLocation'} = $client->to_query_value($self->fonts_location);      
    } 
    my $_body_data;


    if (defined $self->file) {   
        my $map_file = $self->file;
        while ( my ($filename,$value) = each( %$map_file ) ) {
                $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }
 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'file' => {
     	datatype => 'string',
     	base_name => 'File',
     	description => 'File to upload',
     	format => '',
     	read_only => '',
     		},
     'format' => {
     	datatype => 'string',
     	base_name => 'format',
     	description => 'The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'password',
     	description => 'The password needed to open an Excel file.',
     	format => '',
     	read_only => '',
     		},
     'out_path' => {
     	datatype => 'string',
     	base_name => 'outPath',
     	description => 'Path to save the result. If it`s a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.',
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
     'check_excel_restriction' => {
     	datatype => 'string',
     	base_name => 'checkExcelRestriction',
     	description => 'Whether check restriction of excel file when user modify cells related objects.',
     	format => '',
     	read_only => '',
     		},
     'stream_format' => {
     	datatype => 'string',
     	base_name => 'streamFormat',
     	description => 'The format of the input file stream. ',
     	format => '',
     	read_only => '',
     		},
     'region' => {
     	datatype => 'string',
     	base_name => 'region',
     	description => 'The regional settings for workbook.',
     	format => '',
     	read_only => '',
     		},
     'page_wide_fit_on_per_sheet' => {
     	datatype => 'string',
     	base_name => 'pageWideFitOnPerSheet',
     	description => 'The page wide fit on worksheet.',
     	format => '',
     	read_only => '',
     		},
     'page_tall_fit_on_per_sheet' => {
     	datatype => 'string',
     	base_name => 'pageTallFitOnPerSheet',
     	description => 'The page tall fit on worksheet.',
     	format => '',
     	read_only => '',
     		},
     'sheet_name' => {
     	datatype => 'string',
     	base_name => 'sheetName',
     	description => 'Convert the specified worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'page_index' => {
     	datatype => 'int',
     	base_name => 'pageIndex',
     	description => 'Convert the specified page  of worksheet, sheetName is required. ',
     	format => '',
     	read_only => '',
     		},
     'one_page_per_sheet' => {
     	datatype => 'string',
     	base_name => 'onePagePerSheet',
     	description => 'When converting to PDF format, one page per sheet. ',
     	format => '',
     	read_only => '',
     		},
     'auto_rows_fit' => {
     	datatype => 'string',
     	base_name => 'AutoRowsFit',
     	description => 'Auto-fits all rows in this workbook.',
     	format => '',
     	read_only => '',
     		},
     'auto_columns_fit' => {
     	datatype => 'string',
     	base_name => 'AutoColumnsFit',
     	description => 'Auto-fits the columns width in this workbook.',
     	format => '',
     	read_only => '',
     		},
     'fonts_location' => {
     	datatype => 'string',
     	base_name => 'FontsLocation',
     	description => 'Use Custom fonts.',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'file' => 'File',
    'format' => 'format',
    'password' => 'password',
    'out_path' => 'outPath',
    'storage_name' => 'storageName',
    'check_excel_restriction' => 'checkExcelRestriction',
    'stream_format' => 'streamFormat',
    'region' => 'region',
    'page_wide_fit_on_per_sheet' => 'pageWideFitOnPerSheet',
    'page_tall_fit_on_per_sheet' => 'pageTallFitOnPerSheet',
    'sheet_name' => 'sheetName',
    'page_index' => 'pageIndex',
    'one_page_per_sheet' => 'onePagePerSheet',
    'auto_rows_fit' => 'AutoRowsFit',
    'auto_columns_fit' => 'AutoColumnsFit',
    'fonts_location' => 'FontsLocation' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;