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

package AsposeCellsCloud::Request::PostWorkbookSaveAsRequest;

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
# PostWorkbookSaveAsRequest.name : The workbook name.  ,
# PostWorkbookSaveAsRequest.newfilename : newfilename to save the result.The `newfilename` should encompass both the filename and extension.  ,
# PostWorkbookSaveAsRequest.saveOptions :   ,
# PostWorkbookSaveAsRequest.isAutoFitRows : Indicates if Autofit rows in workbook.  ,
# PostWorkbookSaveAsRequest.isAutoFitColumns : Indicates if Autofit columns in workbook.  ,
# PostWorkbookSaveAsRequest.folder : The folder where the file is situated.  ,
# PostWorkbookSaveAsRequest.storageName : The storage name where the file is situated.  ,
# PostWorkbookSaveAsRequest.outStorageName : The storage name where the output file is situated.  ,
# PostWorkbookSaveAsRequest.checkExcelRestriction : Whether check restriction of excel file when user modify cells related objects.  ,
# PostWorkbookSaveAsRequest.region : The regional settings for workbook.  ,
# PostWorkbookSaveAsRequest.pageWideFitOnPerSheet : The page wide fit on worksheet.  ,
# PostWorkbookSaveAsRequest.pageTallFitOnPerSheet : The page tall fit on worksheet.  ,
# PostWorkbookSaveAsRequest.onePagePerSheet :   ,
# PostWorkbookSaveAsRequest.FontsLocation : Use Custom fonts.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_save_as' } = { 
    	summary => 'Save an Excel file in various formats.',
        params => $params,
        returns => 'SaveResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/SaveAs';

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
    if(defined $self->newfilename){
        $query_params->{'newfilename'} = $client->to_query_value($self->newfilename);      
    }

    if(defined $self->is_auto_fit_rows){
        $query_params->{'isAutoFitRows'} = $client->to_query_value($self->is_auto_fit_rows);      
    }

    if(defined $self->is_auto_fit_columns){
        $query_params->{'isAutoFitColumns'} = $client->to_query_value($self->is_auto_fit_columns);      
    }

    if(defined $self->folder){
        $query_params->{'folder'} = $client->to_query_value($self->folder);      
    }

    if(defined $self->storage_name){
        $query_params->{'storageName'} = $client->to_query_value($self->storage_name);      
    }

    if(defined $self->out_storage_name){
        $query_params->{'outStorageName'} = $client->to_query_value($self->out_storage_name);      
    }

    if(defined $self->check_excel_restriction){
        $query_params->{'checkExcelRestriction'} = $client->to_query_value($self->check_excel_restriction);      
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

    if(defined $self->one_page_per_sheet){
        $query_params->{'onePagePerSheet'} = $client->to_query_value($self->one_page_per_sheet);      
    }

    if(defined $self->fonts_location){
        $query_params->{'FontsLocation'} = $client->to_query_value($self->fonts_location);      
    } 
    my $_body_data;


    # body params
    if (defined $self->save_options) {
         $_body_data = JSON->new->convert_blessed->encode( $self->save_options);
    }

 

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
     'newfilename' => {
     	datatype => 'string',
     	base_name => 'newfilename',
     	description => 'newfilename to save the result.The `newfilename` should encompass both the filename and extension.',
     	format => '',
     	read_only => '',
     		},
     'save_options' => {
     	datatype => 'SaveOptions',
     	base_name => 'saveOptions',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_auto_fit_rows' => {
     	datatype => 'string',
     	base_name => 'isAutoFitRows',
     	description => 'Indicates if Autofit rows in workbook.',
     	format => '',
     	read_only => '',
     		},
     'is_auto_fit_columns' => {
     	datatype => 'string',
     	base_name => 'isAutoFitColumns',
     	description => 'Indicates if Autofit columns in workbook.',
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
     'out_storage_name' => {
     	datatype => 'string',
     	base_name => 'outStorageName',
     	description => 'The storage name where the output file is situated.',
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
     'one_page_per_sheet' => {
     	datatype => 'string',
     	base_name => 'onePagePerSheet',
     	description => '',
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
    'name' => 'name',
    'newfilename' => 'newfilename',
    'save_options' => 'saveOptions',
    'is_auto_fit_rows' => 'isAutoFitRows',
    'is_auto_fit_columns' => 'isAutoFitColumns',
    'folder' => 'folder',
    'storage_name' => 'storageName',
    'out_storage_name' => 'outStorageName',
    'check_excel_restriction' => 'checkExcelRestriction',
    'region' => 'region',
    'page_wide_fit_on_per_sheet' => 'pageWideFitOnPerSheet',
    'page_tall_fit_on_per_sheet' => 'pageTallFitOnPerSheet',
    'one_page_per_sheet' => 'onePagePerSheet',
    'fonts_location' => 'FontsLocation' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;