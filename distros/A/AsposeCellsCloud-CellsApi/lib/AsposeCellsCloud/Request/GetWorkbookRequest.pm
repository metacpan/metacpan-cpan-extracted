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

package AsposeCellsCloud::Request::GetWorkbookRequest;

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
# GetWorkbookRequest.name :   ,
# GetWorkbookRequest.format :   ,
# GetWorkbookRequest.password :   ,
# GetWorkbookRequest.isAutoFit :   ,
# GetWorkbookRequest.onlySaveTable :   ,
# GetWorkbookRequest.folder :   ,
# GetWorkbookRequest.outPath :   ,
# GetWorkbookRequest.storageName :   ,
# GetWorkbookRequest.outStorageName :   ,
# GetWorkbookRequest.checkExcelRestriction :   ,
# GetWorkbookRequest.region :   ,
# GetWorkbookRequest.pageWideFitOnPerSheet :   ,
# GetWorkbookRequest.pageTallFitOnPerSheet :    

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'get_workbook' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = '/cells/{name}';

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
    if(defined $self->format){
        $query_params->{'format'} = $client->to_query_value($self->format);      
    }

    if(defined $self->password){
        $query_params->{'password'} = $client->to_query_value($self->password);      
    }

    if(defined $self->is_auto_fit){
        $query_params->{'isAutoFit'} = $client->to_query_value($self->is_auto_fit);      
    }

    if(defined $self->only_save_table){
        $query_params->{'onlySaveTable'} = $client->to_query_value($self->only_save_table);      
    }

    if(defined $self->folder){
        $query_params->{'folder'} = $client->to_query_value($self->folder);      
    }

    if(defined $self->out_path){
        $query_params->{'outPath'} = $client->to_query_value($self->out_path);      
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
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'format' => {
     	datatype => 'string',
     	base_name => 'format',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'password',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_auto_fit' => {
     	datatype => 'string',
     	base_name => 'isAutoFit',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'only_save_table' => {
     	datatype => 'string',
     	base_name => 'onlySaveTable',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'folder' => {
     	datatype => 'string',
     	base_name => 'folder',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'out_path' => {
     	datatype => 'string',
     	base_name => 'outPath',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'storage_name' => {
     	datatype => 'string',
     	base_name => 'storageName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'out_storage_name' => {
     	datatype => 'string',
     	base_name => 'outStorageName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_excel_restriction' => {
     	datatype => 'string',
     	base_name => 'checkExcelRestriction',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'region' => {
     	datatype => 'string',
     	base_name => 'region',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_wide_fit_on_per_sheet' => {
     	datatype => 'string',
     	base_name => 'pageWideFitOnPerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_tall_fit_on_per_sheet' => {
     	datatype => 'string',
     	base_name => 'pageTallFitOnPerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'name' => 'name',
    'format' => 'format',
    'password' => 'password',
    'is_auto_fit' => 'isAutoFit',
    'only_save_table' => 'onlySaveTable',
    'folder' => 'folder',
    'out_path' => 'outPath',
    'storage_name' => 'storageName',
    'out_storage_name' => 'outStorageName',
    'check_excel_restriction' => 'checkExcelRestriction',
    'region' => 'region',
    'page_wide_fit_on_per_sheet' => 'pageWideFitOnPerSheet',
    'page_tall_fit_on_per_sheet' => 'pageTallFitOnPerSheet' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;