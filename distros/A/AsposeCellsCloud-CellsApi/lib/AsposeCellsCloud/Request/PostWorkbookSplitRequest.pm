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

package AsposeCellsCloud::Request::PostWorkbookSplitRequest;

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
# PostWorkbookSplitRequest.name : The file name.  ,
# PostWorkbookSplitRequest.format : Split format.  ,
# PostWorkbookSplitRequest.outFolder :   ,
# PostWorkbookSplitRequest.from : Start worksheet index.  ,
# PostWorkbookSplitRequest.to : End worksheet index.  ,
# PostWorkbookSplitRequest.horizontalResolution : Image horizontal resolution.  ,
# PostWorkbookSplitRequest.verticalResolution : Image vertical resolution.  ,
# PostWorkbookSplitRequest.splitNameRule : rule name : sheetname  newguid   ,
# PostWorkbookSplitRequest.folder : The folder where the file is situated.  ,
# PostWorkbookSplitRequest.storageName : The storage name where the file is situated.  ,
# PostWorkbookSplitRequest.outStorageName :    

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_workbook_split' } = { 
    	summary => 'Split the workbook with a specific format.',
        params => $params,
        returns => 'SplitResultResponse',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v3.0/cells/{name}/split';

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
    if(defined $self->format){
        $query_params->{'format'} = $client->to_query_value($self->format);      
    }

    if(defined $self->out_folder){
        $query_params->{'outFolder'} = $client->to_query_value($self->out_folder);      
    }

    if(defined $self->from){
        $query_params->{'from'} = $client->to_query_value($self->from);      
    }

    if(defined $self->to){
        $query_params->{'to'} = $client->to_query_value($self->to);      
    }

    if(defined $self->horizontal_resolution){
        $query_params->{'horizontalResolution'} = $client->to_query_value($self->horizontal_resolution);      
    }

    if(defined $self->vertical_resolution){
        $query_params->{'verticalResolution'} = $client->to_query_value($self->vertical_resolution);      
    }

    if(defined $self->split_name_rule){
        $query_params->{'splitNameRule'} = $client->to_query_value($self->split_name_rule);      
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
     'format' => {
     	datatype => 'string',
     	base_name => 'format',
     	description => 'Split format.',
     	format => '',
     	read_only => '',
     		},
     'out_folder' => {
     	datatype => 'string',
     	base_name => 'outFolder',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'from' => {
     	datatype => 'int',
     	base_name => 'from',
     	description => 'Start worksheet index.',
     	format => '',
     	read_only => '',
     		},
     'to' => {
     	datatype => 'int',
     	base_name => 'to',
     	description => 'End worksheet index.',
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
     'vertical_resolution' => {
     	datatype => 'int',
     	base_name => 'verticalResolution',
     	description => 'Image vertical resolution.',
     	format => '',
     	read_only => '',
     		},
     'split_name_rule' => {
     	datatype => 'string',
     	base_name => 'splitNameRule',
     	description => 'rule name : sheetname  newguid ',
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
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'name' => 'name',
    'format' => 'format',
    'out_folder' => 'outFolder',
    'from' => 'from',
    'to' => 'to',
    'horizontal_resolution' => 'horizontalResolution',
    'vertical_resolution' => 'verticalResolution',
    'split_name_rule' => 'splitNameRule',
    'folder' => 'folder',
    'storage_name' => 'storageName',
    'out_storage_name' => 'outStorageName' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;