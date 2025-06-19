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

package AsposeCellsCloud::Request::MoveFileRequest;

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
# MoveFileRequest.srcPath :   ,
# MoveFileRequest.destPath :   ,
# MoveFileRequest.srcStorageName :   ,
# MoveFileRequest.destStorageName :   ,
# MoveFileRequest.versionId :    

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'move_file' } = { 
    	summary => '',
        params => $params,
        returns => '',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v4.0/cells/storage/file/move/{srcPath}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('application/json');
    if(defined $self->src_path){
        my $_base_variable = "{" . "srcPath" . "}";
        my $_base_value = $client->to_path_value($self->src_path);
        $_resource_path =~ s/$_base_variable/$_base_value/g;        
    } 
    if(defined $self->dest_path){
        $query_params->{'destPath'} = $client->to_query_value($self->dest_path);      
    }

    if(defined $self->src_storage_name){
        $query_params->{'srcStorageName'} = $client->to_query_value($self->src_storage_name);      
    }

    if(defined $self->dest_storage_name){
        $query_params->{'destStorageName'} = $client->to_query_value($self->dest_storage_name);      
    }

    if(defined $self->version_id){
        $query_params->{'versionId'} = $client->to_query_value($self->version_id);      
    } 
    my $_body_data;

 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'src_path' => {
     	datatype => 'string',
     	base_name => 'srcPath',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'dest_path' => {
     	datatype => 'string',
     	base_name => 'destPath',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'src_storage_name' => {
     	datatype => 'string',
     	base_name => 'srcStorageName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'dest_storage_name' => {
     	datatype => 'string',
     	base_name => 'destStorageName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'version_id' => {
     	datatype => 'string',
     	base_name => 'versionId',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'src_path' => 'srcPath',
    'dest_path' => 'destPath',
    'src_storage_name' => 'srcStorageName',
    'dest_storage_name' => 'destStorageName',
    'version_id' => 'versionId' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;