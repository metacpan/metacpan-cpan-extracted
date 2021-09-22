=begin comment

Copyright (c) 2021 Aspose.Cells Cloud
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


package AsposeCellsCloud::LiteCellsApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);
use JSON;
use AsposeCellsCloud::ApiClient;
use AsposeCellsCloud::Object::CellsDocumentProperty;
use base "Class::Data::Inheritable";

__PACKAGE__->mk_classdata('method_documentation' => {});

sub new {
    my $class = shift;
    my $api_client;

    if ($_[0] && ref $_[0] && ref $_[0] eq 'AsposeCellsCloud::ApiClient' ) {
        $api_client = $_[0];
    } else {
        $api_client = AsposeCellsCloud::ApiClient->new(@_);
    }

    if($api_client->need_auth()){
        my $access_token  =  $api_client->o_auth_post('grant_type' => "client_credentials", 'client_id' => $api_client->{config}->{client_id}, 'client_secret' =>$api_client->{config}->{client_secret})->access_token;
        $api_client->{config}->{access_token} = $access_token;
    }

    bless { api_client => $api_client }, $class;

}


#
# delete_metadata
#
# 
# 
# @param string $file File to upload (required)
# @param string $type  (optional, default to all)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'type' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_metadata' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub delete_metadata {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling delete_metadata");
    }

    # parse inputs
    my $_resource_path = '/cells/metadata/delete';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'type'}) {
        $query_params->{'type'} = $self->{api_client}->to_query_value($args{'type'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# get_metadata
#
# 
# 
# @param string $file File to upload (required)
# @param string $type  (optional, default to all)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'type' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_metadata' } = { 
    	summary => '',
        params => $params,
        returns => 'ARRAY[CellsDocumentProperty]',
        };
}
# @return ARRAY[CellsDocumentProperty]
#
sub get_metadata {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling get_metadata");
    }

    # parse inputs
    my $_resource_path = '/cells/metadata/get';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'type'}) {
        $query_params->{'type'} = $self->{api_client}->to_query_value($args{'type'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[CellsDocumentProperty]', $response);
    return $_response_object;
}

#
# post_assemble
#
# 
# 
# @param string $file File to upload (required)
# @param string $datasource  (required)
# @param string $format  (optional, default to Xlsx)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'datasource' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_assemble' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_assemble {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_assemble");
    }

    # verify the required parameter 'datasource' is set
    unless (exists $args{'datasource'}) {
      croak("Missing the required parameter 'datasource' when calling post_assemble");
    }

    # parse inputs
    my $_resource_path = '/cells/assemble';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'datasource'}) {
        $query_params->{'datasource'} = $self->{api_client}->to_query_value($args{'datasource'});
    }

    # query params
    if ( exists $args{'format'}) {
        $query_params->{'format'} = $self->{api_client}->to_query_value($args{'format'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
   if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_clear_objects
#
# 
# 
# @param File $file File to upload (required)
# @param string $objecttype  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'objecttype' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_clear_objects' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_clear_objects {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_clear_objects");
    }

    # verify the required parameter 'objecttype' is set
    unless (exists $args{'objecttype'}) {
      croak("Missing the required parameter 'objecttype' when calling post_clear_objects");
    }

    # parse inputs
    my $_resource_path = '/cells/clearobjects';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'objecttype'}) {
        $query_params->{'objecttype'} = $self->{api_client}->to_query_value($args{'objecttype'});
    }

    # form params
    # if ( exists $args{'file'} ) {
    #     $form_params->{'File'} = [] unless defined $form_params->{'File'};
    #     push @{$form_params->{'File'}}, $args{'file'};
    #         }
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_export
#
# 
# 
# @param string $file File to upload (required)
# @param string $object_type  (required)
# @param string $format  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'object_type' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_export' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_export {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_export");
    }

    # verify the required parameter 'object_type' is set
    unless (exists $args{'object_type'}) {
      croak("Missing the required parameter 'object_type' when calling post_export");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_export");
    }

    # parse inputs
    my $_resource_path = '/cells/export';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'object_type'}) {
        $query_params->{'objectType'} = $self->{api_client}->to_query_value($args{'object_type'});
    }

    # query params
    if ( exists $args{'format'}) {
        $query_params->{'format'} = $self->{api_client}->to_query_value($args{'format'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
   if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_import
#
# 
# 
# @param File $file File to upload (required)
# @param string $object_type  (required)
# @param string $format  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'import_option' => {
        data_type => 'String',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_import' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_import {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_import");
    }

    # verify the required parameter 'object_type' is set
    unless (exists $args{'import_option'}) {
      croak("Missing the required parameter 'import_option' when calling post_import");
    }

    # parse inputs
    my $_resource_path = '/cells/import';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    $self->{api_client}->check_access_token();

    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
        if ( exists $args{'import_option'} ) {
            $form_params->{'importoption'} =  $args{'import_option'};
        }
    }


    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_merge
#
# 
# 
# @param string $file File to upload (required)
# @param string $format  (optional, default to xlsx)
# @param boolean $merge_to_one_sheet  (optional, default to false)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'merge_to_one_sheet' => {
        data_type => 'boolean',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_merge' } = { 
    	summary => '',
        params => $params,
        returns => 'FileInfo',
        };
}

# @return FileInfo
#
sub post_merge {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_merge");
    }

    # parse inputs
    my $_resource_path = '/cells/merge';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {
        $query_params->{'format'} = $self->{api_client}->to_query_value($args{'format'});
    }

    # query params
    if ( exists $args{'merge_to_one_sheet'}) {
        $query_params->{'mergeToOneSheet'} = $self->{api_client}->to_query_value($args{'merge_to_one_sheet'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileInfo', $response);
    return $_response_object;
}

#
# post_metadata
#
# 
# 
# @param string $file File to upload (required)
# @param CellsDocumentProperty $document_properties Cells document property. (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'document_properties' => {
        data_type => 'array',
        description => 'Cells document property.',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_metadata' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_metadata {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_metadata");
    }

    # verify the required parameter 'document_properties' is set
    unless (exists $args{'document_properties'}) {
      croak("Missing the required parameter 'document_properties' when calling post_metadata");
    }

    # parse inputs
    my $_resource_path = '/cells/metadata/update';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
        if ( exists $args{'document_properties'} ) {
            $form_params->{'documentproperties'} =  $args{'document_properties'};
        }
    }

    

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_protect
#
# 
# 
# @param string $file File to upload (required)
# @param string $password  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_protect' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_protect {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_protect");
    }

    # verify the required parameter 'password' is set
    unless (exists $args{'password'}) {
      croak("Missing the required parameter 'password' when calling post_protect");
    }

    # parse inputs
    my $_resource_path = '/cells/protect';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_search
#
# 
# 
# @param string $file File to upload (required)
# @param string $text  (required)
# @param string $password  (optional)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'text' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_search' } = { 
    	summary => '',
        params => $params,
        returns => 'ARRAY[TextItem]',
        };
}
# @return ARRAY[TextItem]
#
sub post_search {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_search");
    }

    # verify the required parameter 'text' is set
    unless (exists $args{'text'}) {
      croak("Missing the required parameter 'text' when calling post_search");
    }

    # parse inputs
    my $_resource_path = '/cells/search';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'text'}) {
        $query_params->{'text'} = $self->{api_client}->to_query_value($args{'text'});
    }

    # query params
    if ( exists $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ARRAY[TextItem]', $response);
    return $_response_object;
}

#
# post_split
#
# 
# 
# @param string $file File to upload (required)
# @param string $format  (required)
# @param string $password  (optional)
# @param int $from  (optional)
# @param int $to  (optional)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'from' => {
        data_type => 'int',
        description => '',
        required => '0',
    },
    'to' => {
        data_type => 'int',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_split' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_split {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_split");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_split");
    }

    # parse inputs
    my $_resource_path = '/cells/split';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'format'}) {
        $query_params->{'format'} = $self->{api_client}->to_query_value($args{'format'});
    }

    # query params
    if ( exists $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if ( exists $args{'from'}) {
        $query_params->{'from'} = $self->{api_client}->to_query_value($args{'from'});
    }

    # query params
    if ( exists $args{'to'}) {
        $query_params->{'to'} = $self->{api_client}->to_query_value($args{'to'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_unlock
#
# 
# 
# @param string $file File to upload (required)
# @param string $password  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_unlock' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_unlock {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_unlock");
    }

    # verify the required parameter 'password' is set
    unless (exists $args{'password'}) {
      croak("Missing the required parameter 'password' when calling post_unlock");
    }

    # parse inputs
    my $_resource_path = '/cells/unlock';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # body params
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

#
# post_watermark
#
# 
# 
# @param File $file File to upload (required)
# @param string $text  (required)
# @param string $color  (required)
{
    my $params = {
    'file' => {
        data_type => 'hash',
        description => 'File to upload',
        required => '1',
    },
    'text' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'color' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_watermark' } = { 
    	summary => '',
        params => $params,
        returns => 'FilesResult',
        };
}
# @return FilesResult
#
sub post_watermark {
    my ($self, %args) = @_;

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling post_watermark");
    }

    # verify the required parameter 'text' is set
    unless (exists $args{'text'}) {
      croak("Missing the required parameter 'text' when calling post_watermark");
    }

    # verify the required parameter 'color' is set
    unless (exists $args{'color'}) {
      croak("Missing the required parameter 'color' when calling post_watermark");
    }

    # parse inputs
    my $_resource_path = '/cells/watermark';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('multipart/form-data');

    # query params
    if ( exists $args{'text'}) {
        $query_params->{'text'} = $self->{api_client}->to_query_value($args{'text'});
    }

    # query params
    if ( exists $args{'color'}) {
        $query_params->{'color'} = $self->{api_client}->to_query_value($args{'color'});
    }

    # form params
    # if ( exists $args{'file'} ) {
    #     $form_params->{'File'} = [] unless defined $form_params->{'File'};
    #     push @{$form_params->{'File'}}, $args{'file'};
    #         }
    if ( exists $args{'file'} ) {   
        my $map_file =$args{'file'};
        while ( my ($filename,$value) = each( %$map_file ) ) {
             $form_params->{$filename} = [$value ,$filename,'application/octet-stream'];
        }
    }

    $self->{api_client}->check_access_token();
    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesResult', $response);
    return $_response_object;
}

1;
