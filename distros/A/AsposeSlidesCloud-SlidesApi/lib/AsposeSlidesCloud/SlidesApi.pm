=begin comment

Copyright (c) 2019 Aspose Pty Ltd

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

package AsposeSlidesCloud::SlidesApi;

require 5.6.0;
use strict;
use warnings;
use utf8; 
use Exporter;
use Carp qw( croak );
use Log::Any qw($log);

use AsposeSlidesCloud::ApiClient;

use base "Class::Data::Inheritable";

__PACKAGE__->mk_classdata('method_documentation' => {});

sub new {
    my $class = shift;
    my %params = @_;
    my $api_client = AsposeSlidesCloud::ApiClient->new(@_);

    bless { api_client => $api_client }, $class;
}


#
# copy_file
#
# Copy file
# 
# @param string $src_path Source file path e.g. &#39;/folder/file.ext&#39; (required)
# @param string $dest_path Destination file path (required)
# @param string $src_storage_name Source storage name (optional)
# @param string $dest_storage_name Destination storage name (optional)
# @param string $version_id File version ID to copy (optional)
{
    my $params = {
    'src_path' => {
        data_type => 'string',
        description => 'Source file path e.g. &#39;/folder/file.ext&#39;',
        required => '1',
    },
    'dest_path' => {
        data_type => 'string',
        description => 'Destination file path',
        required => '1',
    },
    'src_storage_name' => {
        data_type => 'string',
        description => 'Source storage name',
        required => '0',
    },
    'dest_storage_name' => {
        data_type => 'string',
        description => 'Destination storage name',
        required => '0',
    },
    'version_id' => {
        data_type => 'string',
        description => 'File version ID to copy',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'copy_file' } = { 
    	summary => 'Copy file',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub copy_file {
    my ($self, %args) = @_;

    # verify the required parameter 'src_path' is set
    unless (exists $args{'src_path'}) {
      croak("Missing the required parameter 'src_path' when calling copy_file");
    }

    # verify the required parameter 'dest_path' is set
    unless (exists $args{'dest_path'}) {
      croak("Missing the required parameter 'dest_path' when calling copy_file");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/file/copy/{srcPath}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'dest_path'} && defined $args{'dest_path'}) {
        $query_params->{'destPath'} = $self->{api_client}->to_query_value($args{'dest_path'});
    }

    # query params
    if (exists $args{'src_storage_name'} && defined $args{'src_storage_name'}) {
        $query_params->{'srcStorageName'} = $self->{api_client}->to_query_value($args{'src_storage_name'});
    }

    # query params
    if (exists $args{'dest_storage_name'} && defined $args{'dest_storage_name'}) {
        $query_params->{'destStorageName'} = $self->{api_client}->to_query_value($args{'dest_storage_name'});
    }

    # query params
    if (exists $args{'version_id'} && defined $args{'version_id'}) {
        $query_params->{'versionId'} = $self->{api_client}->to_query_value($args{'version_id'});
    }

    # path params
    if ( exists $args{'src_path'}) {
        my $_base_variable = "{" . "srcPath" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'src_path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# copy_folder
#
# Copy folder
# 
# @param string $src_path Source folder path e.g. &#39;/src&#39; (required)
# @param string $dest_path Destination folder path e.g. &#39;/dst&#39; (required)
# @param string $src_storage_name Source storage name (optional)
# @param string $dest_storage_name Destination storage name (optional)
{
    my $params = {
    'src_path' => {
        data_type => 'string',
        description => 'Source folder path e.g. &#39;/src&#39;',
        required => '1',
    },
    'dest_path' => {
        data_type => 'string',
        description => 'Destination folder path e.g. &#39;/dst&#39;',
        required => '1',
    },
    'src_storage_name' => {
        data_type => 'string',
        description => 'Source storage name',
        required => '0',
    },
    'dest_storage_name' => {
        data_type => 'string',
        description => 'Destination storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'copy_folder' } = { 
    	summary => 'Copy folder',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub copy_folder {
    my ($self, %args) = @_;

    # verify the required parameter 'src_path' is set
    unless (exists $args{'src_path'}) {
      croak("Missing the required parameter 'src_path' when calling copy_folder");
    }

    # verify the required parameter 'dest_path' is set
    unless (exists $args{'dest_path'}) {
      croak("Missing the required parameter 'dest_path' when calling copy_folder");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/folder/copy/{srcPath}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'dest_path'} && defined $args{'dest_path'}) {
        $query_params->{'destPath'} = $self->{api_client}->to_query_value($args{'dest_path'});
    }

    # query params
    if (exists $args{'src_storage_name'} && defined $args{'src_storage_name'}) {
        $query_params->{'srcStorageName'} = $self->{api_client}->to_query_value($args{'src_storage_name'});
    }

    # query params
    if (exists $args{'dest_storage_name'} && defined $args{'dest_storage_name'}) {
        $query_params->{'destStorageName'} = $self->{api_client}->to_query_value($args{'dest_storage_name'});
    }

    # path params
    if ( exists $args{'src_path'}) {
        my $_base_variable = "{" . "srcPath" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'src_path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# create_folder
#
# Create the folder
# 
# @param string $path Folder path to create e.g. &#39;folder_1/folder_2/&#39; (required)
# @param string $storage_name Storage name (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'Folder path to create e.g. &#39;folder_1/folder_2/&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'create_folder' } = { 
    	summary => 'Create the folder',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub create_folder {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling create_folder");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/folder/{path}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# delete_file
#
# Delete file
# 
# @param string $path File path e.g. &#39;/folder/file.ext&#39; (required)
# @param string $storage_name Storage name (optional)
# @param string $version_id File version ID to delete (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'File path e.g. &#39;/folder/file.ext&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    'version_id' => {
        data_type => 'string',
        description => 'File version ID to delete',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_file' } = { 
    	summary => 'Delete file',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub delete_file {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_file");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/file/{path}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # query params
    if (exists $args{'version_id'} && defined $args{'version_id'}) {
        $query_params->{'versionId'} = $self->{api_client}->to_query_value($args{'version_id'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# delete_folder
#
# Delete folder
# 
# @param string $path Folder path e.g. &#39;/folder&#39; (required)
# @param string $storage_name Storage name (optional)
# @param boolean $recursive Enable to delete folders, subfolders and files (optional, default to false)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'Folder path e.g. &#39;/folder&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    'recursive' => {
        data_type => 'boolean',
        description => 'Enable to delete folders, subfolders and files',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_folder' } = { 
    	summary => 'Delete folder',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub delete_folder {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_folder");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/folder/{path}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # query params
    if (exists $args{'recursive'} && defined $args{'recursive'}) {
        $query_params->{'recursive'} = $self->{api_client}->to_boolean_query_value($args{'recursive'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# delete_notes_slide
#
# Remove notes slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide' } = { 
    	summary => 'Remove notes slide.',
        params => $params,
        returns => 'Slide',
        };
}
# @return Slide
#
sub delete_notes_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slide', $response);
    return $_response_object;
}

#
# delete_notes_slide_paragraph
#
# Remove a paragraph.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_paragraph' } = { 
    	summary => 'Remove a paragraph.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub delete_notes_slide_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_notes_slide_paragraph");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_notes_slide_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# delete_notes_slide_paragraphs
#
# Remove a range of paragraphs.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $paragraphs The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraphs' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_paragraphs' } = { 
    	summary => 'Remove a range of paragraphs.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub delete_notes_slide_paragraphs {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_paragraphs");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_paragraphs");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_paragraphs");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_notes_slide_paragraphs");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'paragraphs'} && defined $args{'paragraphs'}) {
        $query_params->{'paragraphs'} = $self->{api_client}->to_query_value($args{'paragraphs'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# delete_notes_slide_portion
#
# Remove a portion.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_portion' } = { 
    	summary => 'Remove a portion.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub delete_notes_slide_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_notes_slide_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_notes_slide_portion");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling delete_notes_slide_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# delete_notes_slide_portions
#
# Remove a range of portions.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $portions The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portions' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_portions' } = { 
    	summary => 'Remove a range of portions.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub delete_notes_slide_portions {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_portions");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_portions");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_portions");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_notes_slide_portions");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_notes_slide_portions");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'portions'} && defined $args{'portions'}) {
        $query_params->{'portions'} = $self->{api_client}->to_query_value($args{'portions'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# delete_notes_slide_shape
#
# Remove a shape.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_shape' } = { 
    	summary => 'Remove a shape.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub delete_notes_slide_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_shape");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_notes_slide_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# delete_notes_slide_shapes
#
# Remove a range of shapes.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param string $shapes The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shapes' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_notes_slide_shapes' } = { 
    	summary => 'Remove a range of shapes.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub delete_notes_slide_shapes {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_notes_slide_shapes");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_notes_slide_shapes");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_notes_slide_shapes");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'shapes'} && defined $args{'shapes'}) {
        $query_params->{'shapes'} = $self->{api_client}->to_query_value($args{'shapes'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# delete_paragraph
#
# Remove a paragraph.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_paragraph' } = { 
    	summary => 'Remove a paragraph.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub delete_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_paragraph");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# delete_paragraphs
#
# Remove a range of paragraphs.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $paragraphs The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraphs' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_paragraphs' } = { 
    	summary => 'Remove a range of paragraphs.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub delete_paragraphs {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_paragraphs");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_paragraphs");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_paragraphs");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_paragraphs");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'paragraphs'} && defined $args{'paragraphs'}) {
        $query_params->{'paragraphs'} = $self->{api_client}->to_query_value($args{'paragraphs'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# delete_portion
#
# Remove a portion.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_portion' } = { 
    	summary => 'Remove a portion.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub delete_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_portion");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling delete_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# delete_portions
#
# Remove a range of portions.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $portions The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portions' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_portions' } = { 
    	summary => 'Remove a range of portions.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub delete_portions {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_portions");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_portions");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_portions");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_portions");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling delete_portions");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'portions'} && defined $args{'portions'}) {
        $query_params->{'portions'} = $self->{api_client}->to_query_value($args{'portions'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# delete_slide_animation
#
# Remove animation from a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation' } = { 
    	summary => 'Remove animation from a slide.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_animation_effect
#
# Remove an effect from slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $effect_index Index of the effect to be removed. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'effect_index' => {
        data_type => 'int',
        description => 'Index of the effect to be removed.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation_effect' } = { 
    	summary => 'Remove an effect from slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation_effect");
    }

    # verify the required parameter 'effect_index' is set
    unless (exists $args{'effect_index'}) {
      croak("Missing the required parameter 'effect_index' when calling delete_slide_animation_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/mainSequence/{effectIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'effect_index'}) {
        my $_base_variable = "{" . "effectIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'effect_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_animation_interactive_sequence
#
# Remove an interactive sequence from slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $sequence_index The index of an interactive sequence to be deleted. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'sequence_index' => {
        data_type => 'int',
        description => 'The index of an interactive sequence to be deleted.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation_interactive_sequence' } = { 
    	summary => 'Remove an interactive sequence from slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation_interactive_sequence {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation_interactive_sequence");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation_interactive_sequence");
    }

    # verify the required parameter 'sequence_index' is set
    unless (exists $args{'sequence_index'}) {
      croak("Missing the required parameter 'sequence_index' when calling delete_slide_animation_interactive_sequence");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences/{sequenceIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'sequence_index'}) {
        my $_base_variable = "{" . "sequenceIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'sequence_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_animation_interactive_sequence_effect
#
# Remove an effect from slide animation interactive sequence.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $sequence_index Interactive sequence index. (required)
# @param int $effect_index Index of the effect to be removed. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'sequence_index' => {
        data_type => 'int',
        description => 'Interactive sequence index.',
        required => '1',
    },
    'effect_index' => {
        data_type => 'int',
        description => 'Index of the effect to be removed.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation_interactive_sequence_effect' } = { 
    	summary => 'Remove an effect from slide animation interactive sequence.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation_interactive_sequence_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'sequence_index' is set
    unless (exists $args{'sequence_index'}) {
      croak("Missing the required parameter 'sequence_index' when calling delete_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'effect_index' is set
    unless (exists $args{'effect_index'}) {
      croak("Missing the required parameter 'effect_index' when calling delete_slide_animation_interactive_sequence_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences/{sequenceIndex}/{effectIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'sequence_index'}) {
        my $_base_variable = "{" . "sequenceIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'sequence_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'effect_index'}) {
        my $_base_variable = "{" . "effectIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'effect_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_animation_interactive_sequences
#
# Clear all interactive sequences from slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation_interactive_sequences' } = { 
    	summary => 'Clear all interactive sequences from slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation_interactive_sequences {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation_interactive_sequences");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation_interactive_sequences");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_animation_main_sequence
#
# Clear main sequence in slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_animation_main_sequence' } = { 
    	summary => 'Clear main sequence in slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub delete_slide_animation_main_sequence {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_animation_main_sequence");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_animation_main_sequence");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/mainSequence';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# delete_slide_by_index
#
# Delete a presentation slide by index.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_by_index' } = { 
    	summary => 'Delete a presentation slide by index.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub delete_slide_by_index {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_by_index");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_by_index");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# delete_slide_shape
#
# Remove a shape.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_shape' } = { 
    	summary => 'Remove a shape.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub delete_slide_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_slide_shape");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling delete_slide_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# delete_slide_shapes
#
# Remove a range of shapes.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param string $shapes The indices of the shapes to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shapes' => {
        data_type => 'string',
        description => 'The indices of the shapes to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slide_shapes' } = { 
    	summary => 'Remove a range of shapes.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub delete_slide_shapes {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slide_shapes");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slide_shapes");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling delete_slide_shapes");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'shapes'} && defined $args{'shapes'}) {
        $query_params->{'shapes'} = $self->{api_client}->to_query_value($args{'shapes'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# delete_slides_clean_slides_list
#
# Delete presentation slides.
# 
# @param string $name Document name. (required)
# @param string $slides The indices of the slides to be deleted; delete all by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slides' => {
        data_type => 'string',
        description => 'The indices of the slides to be deleted; delete all by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slides_clean_slides_list' } = { 
    	summary => 'Delete presentation slides.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub delete_slides_clean_slides_list {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slides_clean_slides_list");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'slides'} && defined $args{'slides'}) {
        $query_params->{'slides'} = $self->{api_client}->to_query_value($args{'slides'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# delete_slides_document_properties
#
# Clean document properties.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slides_document_properties' } = { 
    	summary => 'Clean document properties.',
        params => $params,
        returns => 'DocumentProperties',
        };
}
# @return DocumentProperties
#
sub delete_slides_document_properties {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slides_document_properties");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperties', $response);
    return $_response_object;
}

#
# delete_slides_document_property
#
# Delete document property.
# 
# @param string $name Document name. (required)
# @param string $property_name The property name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'property_name' => {
        data_type => 'string',
        description => 'The property name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slides_document_property' } = { 
    	summary => 'Delete document property.',
        params => $params,
        returns => 'DocumentProperties',
        };
}
# @return DocumentProperties
#
sub delete_slides_document_property {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slides_document_property");
    }

    # verify the required parameter 'property_name' is set
    unless (exists $args{'property_name'}) {
      croak("Missing the required parameter 'property_name' when calling delete_slides_document_property");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'property_name'}) {
        my $_base_variable = "{" . "propertyName" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'property_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperties', $response);
    return $_response_object;
}

#
# delete_slides_slide_background
#
# Remove background from a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'delete_slides_slide_background' } = { 
    	summary => 'Remove background from a slide.',
        params => $params,
        returns => 'SlideBackground',
        };
}
# @return SlideBackground
#
sub delete_slides_slide_background {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling delete_slides_slide_background");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling delete_slides_slide_background");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background';

    my $_method = 'DELETE';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideBackground', $response);
    return $_response_object;
}

#
# download_file
#
# Download file
# 
# @param string $path File path e.g. &#39;/folder/file.ext&#39; (required)
# @param string $storage_name Storage name (optional)
# @param string $version_id File version ID to download (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'File path e.g. &#39;/folder/file.ext&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    'version_id' => {
        data_type => 'string',
        description => 'File version ID to download',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'download_file' } = { 
    	summary => 'Download file',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub download_file {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling download_file");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/file/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # query params
    if (exists $args{'version_id'} && defined $args{'version_id'}) {
        $query_params->{'versionId'} = $self->{api_client}->to_query_value($args{'version_id'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# get_disc_usage
#
# Get disc usage
# 
# @param string $storage_name Storage name (optional)
{
    my $params = {
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_disc_usage' } = { 
    	summary => 'Get disc usage',
        params => $params,
        returns => 'DiscUsage',
        };
}
# @return DiscUsage
#
sub get_disc_usage {
    my ($self, %args) = @_;

    # parse inputs
    my $_resource_path = '/slides/storage/disc';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DiscUsage', $response);
    return $_response_object;
}

#
# get_file_versions
#
# Get file versions
# 
# @param string $path File path e.g. &#39;/file.ext&#39; (required)
# @param string $storage_name Storage name (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'File path e.g. &#39;/file.ext&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_file_versions' } = { 
    	summary => 'Get file versions',
        params => $params,
        returns => 'FileVersions',
        };
}
# @return FileVersions
#
sub get_file_versions {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_file_versions");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/version/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FileVersions', $response);
    return $_response_object;
}

#
# get_files_list
#
# Get all files and folders within a folder
# 
# @param string $path Folder path e.g. &#39;/folder&#39; (required)
# @param string $storage_name Storage name (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'Folder path e.g. &#39;/folder&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_files_list' } = { 
    	summary => 'Get all files and folders within a folder',
        params => $params,
        returns => 'FilesList',
        };
}
# @return FilesList
#
sub get_files_list {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_files_list");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/folder/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesList', $response);
    return $_response_object;
}

#
# get_layout_slide
#
# Read presentation layoutSlide info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_layout_slide' } = { 
    	summary => 'Read presentation layoutSlide info.',
        params => $params,
        returns => 'LayoutSlide',
        };
}
# @return LayoutSlide
#
sub get_layout_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_layout_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_layout_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/layoutSlides/{slideIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LayoutSlide', $response);
    return $_response_object;
}

#
# get_layout_slides_list
#
# Read presentation layoutSlides info.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_layout_slides_list' } = { 
    	summary => 'Read presentation layoutSlides info.',
        params => $params,
        returns => 'LayoutSlides',
        };
}
# @return LayoutSlides
#
sub get_layout_slides_list {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_layout_slides_list");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/layoutSlides';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LayoutSlides', $response);
    return $_response_object;
}

#
# get_master_slide
#
# Read presentation masterSlide info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_master_slide' } = { 
    	summary => 'Read presentation masterSlide info.',
        params => $params,
        returns => 'MasterSlide',
        };
}
# @return MasterSlide
#
sub get_master_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_master_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_master_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/masterSlides/{slideIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('MasterSlide', $response);
    return $_response_object;
}

#
# get_master_slides_list
#
# Read presentation masterSlides info.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_master_slides_list' } = { 
    	summary => 'Read presentation masterSlides info.',
        params => $params,
        returns => 'MasterSlides',
        };
}
# @return MasterSlides
#
sub get_master_slides_list {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_master_slides_list");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/masterSlides';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('MasterSlides', $response);
    return $_response_object;
}

#
# get_notes_slide
#
# Read notes slide info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide' } = { 
    	summary => 'Read notes slide info.',
        params => $params,
        returns => 'NotesSlide',
        };
}
# @return NotesSlide
#
sub get_notes_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('NotesSlide', $response);
    return $_response_object;
}

#
# get_notes_slide_shape
#
# Read slide shape info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shape' } = { 
    	summary => 'Read slide shape info.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub get_notes_slide_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shape");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_notes_slide_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# get_notes_slide_shape_paragraph
#
# Read shape paragraph info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shape_paragraph' } = { 
    	summary => 'Read shape paragraph info.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub get_notes_slide_shape_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_notes_slide_shape_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# get_notes_slide_shape_paragraphs
#
# Read shape paragraphs info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shape_paragraphs' } = { 
    	summary => 'Read shape paragraphs info.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub get_notes_slide_shape_paragraphs {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shape_paragraphs");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shape_paragraphs");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shape_paragraphs");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_notes_slide_shape_paragraphs");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# get_notes_slide_shape_portion
#
# Read paragraph portion info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shape_portion' } = { 
    	summary => 'Read paragraph portion info.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub get_notes_slide_shape_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shape_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shape_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shape_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_notes_slide_shape_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_notes_slide_shape_portion");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling get_notes_slide_shape_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# get_notes_slide_shape_portions
#
# Read paragraph portions info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shape_portions' } = { 
    	summary => 'Read paragraph portions info.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub get_notes_slide_shape_portions {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shape_portions");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shape_portions");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shape_portions");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_notes_slide_shape_portions");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_notes_slide_shape_portions");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# get_notes_slide_shapes
#
# Read slide shapes info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_shapes' } = { 
    	summary => 'Read slide shapes info.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub get_notes_slide_shapes {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_shapes");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_shapes");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_notes_slide_shapes");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# get_notes_slide_with_format
#
# Convert notes slide to the specified image format.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $format Output file format. (required)
# @param int $width Output file width. (optional)
# @param int $height Output file height. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param string $fonts_folder Storage folder containing custom fonts to be used with the document. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Output file format.',
        required => '1',
    },
    'width' => {
        data_type => 'int',
        description => 'Output file width.',
        required => '0',
    },
    'height' => {
        data_type => 'int',
        description => 'Output file height.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Storage folder containing custom fonts to be used with the document.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_notes_slide_with_format' } = { 
    	summary => 'Convert notes slide to the specified image format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub get_notes_slide_with_format {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_notes_slide_with_format");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_notes_slide_with_format");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling get_notes_slide_with_format");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/{format}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'width'} && defined $args{'width'}) {
        $query_params->{'width'} = $self->{api_client}->to_query_value($args{'width'});
    }

    # query params
    if (exists $args{'height'} && defined $args{'height'}) {
        $query_params->{'height'} = $self->{api_client}->to_query_value($args{'height'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# get_paragraph_portion
#
# Read paragraph portion info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_paragraph_portion' } = { 
    	summary => 'Read paragraph portion info.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub get_paragraph_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_paragraph_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_paragraph_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_paragraph_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_paragraph_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_paragraph_portion");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling get_paragraph_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# get_paragraph_portions
#
# Read paragraph portions info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_paragraph_portions' } = { 
    	summary => 'Read paragraph portions info.',
        params => $params,
        returns => 'Portions',
        };
}
# @return Portions
#
sub get_paragraph_portions {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_paragraph_portions");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_paragraph_portions");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_paragraph_portions");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_paragraph_portions");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_paragraph_portions");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portions', $response);
    return $_response_object;
}

#
# get_slide_animation
#
# Read slide animation effects.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $shape_index Shape index. If specified, only effects related to that shape are returned. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index. If specified, only effects related to that shape are returned.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slide_animation' } = { 
    	summary => 'Read slide animation effects.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub get_slide_animation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slide_animation");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slide_animation");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_slide_animation");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'shape_index'} && defined $args{'shape_index'}) {
        $query_params->{'shapeIndex'} = $self->{api_client}->to_query_value($args{'shape_index'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# get_slide_shape
#
# Read slide shape info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slide_shape' } = { 
    	summary => 'Read slide shape info.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub get_slide_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slide_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slide_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_slide_shape");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_slide_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# get_slide_shape_paragraph
#
# Read shape paragraph info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slide_shape_paragraph' } = { 
    	summary => 'Read shape paragraph info.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub get_slide_shape_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slide_shape_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slide_shape_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_slide_shape_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_slide_shape_paragraph");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling get_slide_shape_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# get_slide_shape_paragraphs
#
# Read shape paragraphs info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slide_shape_paragraphs' } = { 
    	summary => 'Read shape paragraphs info.',
        params => $params,
        returns => 'Paragraphs',
        };
}
# @return Paragraphs
#
sub get_slide_shape_paragraphs {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slide_shape_paragraphs");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slide_shape_paragraphs");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_slide_shape_paragraphs");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling get_slide_shape_paragraphs");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraphs', $response);
    return $_response_object;
}

#
# get_slide_shapes
#
# Read slide shapes info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slide_shapes' } = { 
    	summary => 'Read slide shapes info.',
        params => $params,
        returns => 'Shapes',
        };
}
# @return Shapes
#
sub get_slide_shapes {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slide_shapes");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slide_shapes");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling get_slide_shapes");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Shapes', $response);
    return $_response_object;
}

#
# get_slides_api_info
#
# Get API info.
# 
{
    my $params = {
    };
    __PACKAGE__->method_documentation->{ 'get_slides_api_info' } = { 
    	summary => 'Get API info.',
        params => $params,
        returns => 'ApiInfo',
        };
}
# @return ApiInfo
#
sub get_slides_api_info {
    my ($self, %args) = @_;

    # parse inputs
    my $_resource_path = '/slides/info';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ApiInfo', $response);
    return $_response_object;
}

#
# get_slides_document
#
# Read presentation info.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $storage Documentstorage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Documentstorage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_document' } = { 
    	summary => 'Read presentation info.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub get_slides_document {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_document");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# get_slides_document_properties
#
# Read presentation document properties.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_document_properties' } = { 
    	summary => 'Read presentation document properties.',
        params => $params,
        returns => 'DocumentProperties',
        };
}
# @return DocumentProperties
#
sub get_slides_document_properties {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_document_properties");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperties', $response);
    return $_response_object;
}

#
# get_slides_document_property
#
# Read presentation document property.
# 
# @param string $name Document name. (required)
# @param string $property_name The property name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'property_name' => {
        data_type => 'string',
        description => 'The property name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_document_property' } = { 
    	summary => 'Read presentation document property.',
        params => $params,
        returns => 'DocumentProperty',
        };
}
# @return DocumentProperty
#
sub get_slides_document_property {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_document_property");
    }

    # verify the required parameter 'property_name' is set
    unless (exists $args{'property_name'}) {
      croak("Missing the required parameter 'property_name' when calling get_slides_document_property");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'property_name'}) {
        my $_base_variable = "{" . "propertyName" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'property_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperty', $response);
    return $_response_object;
}

#
# get_slides_image_with_default_format
#
# Get image binary data.
# 
# @param string $name Document name. (required)
# @param int $index Image index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'index' => {
        data_type => 'int',
        description => 'Image index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_image_with_default_format' } = { 
    	summary => 'Get image binary data.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub get_slides_image_with_default_format {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_image_with_default_format");
    }

    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling get_slides_image_with_default_format");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/images/{index}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'index'}) {
        my $_base_variable = "{" . "index" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# get_slides_image_with_format
#
# Get image in specified format.
# 
# @param string $name Document name. (required)
# @param int $index Image index. (required)
# @param string $format Export format (png, jpg, gif). (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'index' => {
        data_type => 'int',
        description => 'Image index.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export format (png, jpg, gif).',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_image_with_format' } = { 
    	summary => 'Get image in specified format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub get_slides_image_with_format {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_image_with_format");
    }

    # verify the required parameter 'index' is set
    unless (exists $args{'index'}) {
      croak("Missing the required parameter 'index' when calling get_slides_image_with_format");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling get_slides_image_with_format");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/images/{index}/{format}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'index'}) {
        my $_base_variable = "{" . "index" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# get_slides_images
#
# Read presentation images info.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_images' } = { 
    	summary => 'Read presentation images info.',
        params => $params,
        returns => 'Images',
        };
}
# @return Images
#
sub get_slides_images {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_images");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/images';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Images', $response);
    return $_response_object;
}

#
# get_slides_placeholder
#
# Read slide placeholder info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $placeholder_index Placeholder index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'placeholder_index' => {
        data_type => 'int',
        description => 'Placeholder index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_placeholder' } = { 
    	summary => 'Read slide placeholder info.',
        params => $params,
        returns => 'Placeholder',
        };
}
# @return Placeholder
#
sub get_slides_placeholder {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_placeholder");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_placeholder");
    }

    # verify the required parameter 'placeholder_index' is set
    unless (exists $args{'placeholder_index'}) {
      croak("Missing the required parameter 'placeholder_index' when calling get_slides_placeholder");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/placeholders/{placeholderIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'placeholder_index'}) {
        my $_base_variable = "{" . "placeholderIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'placeholder_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Placeholder', $response);
    return $_response_object;
}

#
# get_slides_placeholders
#
# Read slide placeholders info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_placeholders' } = { 
    	summary => 'Read slide placeholders info.',
        params => $params,
        returns => 'Placeholders',
        };
}
# @return Placeholders
#
sub get_slides_placeholders {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_placeholders");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_placeholders");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/placeholders';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Placeholders', $response);
    return $_response_object;
}

#
# get_slides_presentation_text_items
#
# Extract presentation text items.
# 
# @param string $name Document name. (required)
# @param boolean $with_empty True to incude empty items. (optional, default to false)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'with_empty' => {
        data_type => 'boolean',
        description => 'True to incude empty items.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_presentation_text_items' } = { 
    	summary => 'Extract presentation text items.',
        params => $params,
        returns => 'TextItems',
        };
}
# @return TextItems
#
sub get_slides_presentation_text_items {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_presentation_text_items");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/textItems';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'with_empty'} && defined $args{'with_empty'}) {
        $query_params->{'withEmpty'} = $self->{api_client}->to_boolean_query_value($args{'with_empty'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItems', $response);
    return $_response_object;
}

#
# get_slides_slide
#
# Read presentation slide info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slide' } = { 
    	summary => 'Read presentation slide info.',
        params => $params,
        returns => 'Slide',
        };
}
# @return Slide
#
sub get_slides_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slide', $response);
    return $_response_object;
}

#
# get_slides_slide_background
#
# Read slide background info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slide_background' } = { 
    	summary => 'Read slide background info.',
        params => $params,
        returns => 'SlideBackground',
        };
}
# @return SlideBackground
#
sub get_slides_slide_background {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slide_background");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_slide_background");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideBackground', $response);
    return $_response_object;
}

#
# get_slides_slide_comments
#
# Read presentation slide comments.
# 
# @param string $name Document name. (required)
# @param int $slide_index The position of the slide to be reordered. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'The position of the slide to be reordered.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slide_comments' } = { 
    	summary => 'Read presentation slide comments.',
        params => $params,
        returns => 'SlideComments',
        };
}
# @return SlideComments
#
sub get_slides_slide_comments {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slide_comments");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_slide_comments");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/comments';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideComments', $response);
    return $_response_object;
}

#
# get_slides_slide_images
#
# Read slide images info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slide_images' } = { 
    	summary => 'Read slide images info.',
        params => $params,
        returns => 'Images',
        };
}
# @return Images
#
sub get_slides_slide_images {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slide_images");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_slide_images");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/images';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Images', $response);
    return $_response_object;
}

#
# get_slides_slide_text_items
#
# Extract slide text items.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param boolean $with_empty True to incude empty items. (optional, default to false)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'with_empty' => {
        data_type => 'boolean',
        description => 'True to incude empty items.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slide_text_items' } = { 
    	summary => 'Extract slide text items.',
        params => $params,
        returns => 'TextItems',
        };
}
# @return TextItems
#
sub get_slides_slide_text_items {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slide_text_items");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_slide_text_items");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/textItems';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'with_empty'} && defined $args{'with_empty'}) {
        $query_params->{'withEmpty'} = $self->{api_client}->to_boolean_query_value($args{'with_empty'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('TextItems', $response);
    return $_response_object;
}

#
# get_slides_slides_list
#
# Read presentation slides info.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_slides_list' } = { 
    	summary => 'Read presentation slides info.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub get_slides_slides_list {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_slides_list");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# get_slides_theme
#
# Read slide theme info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_theme' } = { 
    	summary => 'Read slide theme info.',
        params => $params,
        returns => 'Theme',
        };
}
# @return Theme
#
sub get_slides_theme {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_theme");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_theme");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Theme', $response);
    return $_response_object;
}

#
# get_slides_theme_color_scheme
#
# Read slide theme color scheme info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_theme_color_scheme' } = { 
    	summary => 'Read slide theme color scheme info.',
        params => $params,
        returns => 'ColorScheme',
        };
}
# @return ColorScheme
#
sub get_slides_theme_color_scheme {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_theme_color_scheme");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_theme_color_scheme");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/colorScheme';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ColorScheme', $response);
    return $_response_object;
}

#
# get_slides_theme_font_scheme
#
# Read slide theme font scheme info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_theme_font_scheme' } = { 
    	summary => 'Read slide theme font scheme info.',
        params => $params,
        returns => 'FontScheme',
        };
}
# @return FontScheme
#
sub get_slides_theme_font_scheme {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_theme_font_scheme");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_theme_font_scheme");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/fontScheme';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FontScheme', $response);
    return $_response_object;
}

#
# get_slides_theme_format_scheme
#
# Read slide theme format scheme info.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_slides_theme_format_scheme' } = { 
    	summary => 'Read slide theme format scheme info.',
        params => $params,
        returns => 'FormatScheme',
        };
}
# @return FormatScheme
#
sub get_slides_theme_format_scheme {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling get_slides_theme_format_scheme");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling get_slides_theme_format_scheme");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/theme/formatScheme';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FormatScheme', $response);
    return $_response_object;
}

#
# move_file
#
# Move file
# 
# @param string $src_path Source file path e.g. &#39;/src.ext&#39; (required)
# @param string $dest_path Destination file path e.g. &#39;/dest.ext&#39; (required)
# @param string $src_storage_name Source storage name (optional)
# @param string $dest_storage_name Destination storage name (optional)
# @param string $version_id File version ID to move (optional)
{
    my $params = {
    'src_path' => {
        data_type => 'string',
        description => 'Source file path e.g. &#39;/src.ext&#39;',
        required => '1',
    },
    'dest_path' => {
        data_type => 'string',
        description => 'Destination file path e.g. &#39;/dest.ext&#39;',
        required => '1',
    },
    'src_storage_name' => {
        data_type => 'string',
        description => 'Source storage name',
        required => '0',
    },
    'dest_storage_name' => {
        data_type => 'string',
        description => 'Destination storage name',
        required => '0',
    },
    'version_id' => {
        data_type => 'string',
        description => 'File version ID to move',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'move_file' } = { 
    	summary => 'Move file',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub move_file {
    my ($self, %args) = @_;

    # verify the required parameter 'src_path' is set
    unless (exists $args{'src_path'}) {
      croak("Missing the required parameter 'src_path' when calling move_file");
    }

    # verify the required parameter 'dest_path' is set
    unless (exists $args{'dest_path'}) {
      croak("Missing the required parameter 'dest_path' when calling move_file");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/file/move/{srcPath}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'dest_path'} && defined $args{'dest_path'}) {
        $query_params->{'destPath'} = $self->{api_client}->to_query_value($args{'dest_path'});
    }

    # query params
    if (exists $args{'src_storage_name'} && defined $args{'src_storage_name'}) {
        $query_params->{'srcStorageName'} = $self->{api_client}->to_query_value($args{'src_storage_name'});
    }

    # query params
    if (exists $args{'dest_storage_name'} && defined $args{'dest_storage_name'}) {
        $query_params->{'destStorageName'} = $self->{api_client}->to_query_value($args{'dest_storage_name'});
    }

    # query params
    if (exists $args{'version_id'} && defined $args{'version_id'}) {
        $query_params->{'versionId'} = $self->{api_client}->to_query_value($args{'version_id'});
    }

    # path params
    if ( exists $args{'src_path'}) {
        my $_base_variable = "{" . "srcPath" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'src_path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# move_folder
#
# Move folder
# 
# @param string $src_path Folder path to move e.g. &#39;/folder&#39; (required)
# @param string $dest_path Destination folder path to move to e.g &#39;/dst&#39; (required)
# @param string $src_storage_name Source storage name (optional)
# @param string $dest_storage_name Destination storage name (optional)
{
    my $params = {
    'src_path' => {
        data_type => 'string',
        description => 'Folder path to move e.g. &#39;/folder&#39;',
        required => '1',
    },
    'dest_path' => {
        data_type => 'string',
        description => 'Destination folder path to move to e.g &#39;/dst&#39;',
        required => '1',
    },
    'src_storage_name' => {
        data_type => 'string',
        description => 'Source storage name',
        required => '0',
    },
    'dest_storage_name' => {
        data_type => 'string',
        description => 'Destination storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'move_folder' } = { 
    	summary => 'Move folder',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub move_folder {
    my ($self, %args) = @_;

    # verify the required parameter 'src_path' is set
    unless (exists $args{'src_path'}) {
      croak("Missing the required parameter 'src_path' when calling move_folder");
    }

    # verify the required parameter 'dest_path' is set
    unless (exists $args{'dest_path'}) {
      croak("Missing the required parameter 'dest_path' when calling move_folder");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/folder/move/{srcPath}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'dest_path'} && defined $args{'dest_path'}) {
        $query_params->{'destPath'} = $self->{api_client}->to_query_value($args{'dest_path'});
    }

    # query params
    if (exists $args{'src_storage_name'} && defined $args{'src_storage_name'}) {
        $query_params->{'srcStorageName'} = $self->{api_client}->to_query_value($args{'src_storage_name'});
    }

    # query params
    if (exists $args{'dest_storage_name'} && defined $args{'dest_storage_name'}) {
        $query_params->{'destStorageName'} = $self->{api_client}->to_query_value($args{'dest_storage_name'});
    }

    # path params
    if ( exists $args{'src_path'}) {
        my $_base_variable = "{" . "srcPath" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'src_path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# object_exists
#
# Check if file or folder exists
# 
# @param string $path File or folder path e.g. &#39;/file.ext&#39; or &#39;/folder&#39; (required)
# @param string $storage_name Storage name (optional)
# @param string $version_id File version ID (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'File or folder path e.g. &#39;/file.ext&#39; or &#39;/folder&#39;',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    'version_id' => {
        data_type => 'string',
        description => 'File version ID',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'object_exists' } = { 
    	summary => 'Check if file or folder exists',
        params => $params,
        returns => 'ObjectExist',
        };
}
# @return ObjectExist
#
sub object_exists {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling object_exists");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/exist/{path}';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # query params
    if (exists $args{'version_id'} && defined $args{'version_id'}) {
        $query_params->{'versionId'} = $self->{api_client}->to_query_value($args{'version_id'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ObjectExist', $response);
    return $_response_object;
}

#
# post_add_new_paragraph
#
# Creates new paragraph.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param Paragraph $dto Paragraph DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $position Position of the new paragraph in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Paragraph',
        description => 'Paragraph DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new paragraph in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_add_new_paragraph' } = { 
    	summary => 'Creates new paragraph.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub post_add_new_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_add_new_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_add_new_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_add_new_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_add_new_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# post_add_new_portion
#
# Creates new portion.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param Portion $dto Portion DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $position Position of the new portion in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Portion',
        description => 'Portion DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new portion in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_add_new_portion' } = { 
    	summary => 'Creates new portion.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub post_add_new_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_add_new_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_add_new_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_add_new_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_add_new_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling post_add_new_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# post_add_new_shape
#
# Create new shape.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param ShapeBase $dto Shape DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $shape_to_clone Optional index for clone shape instead of adding a new one. (optional)
# @param int $position Position of the new shape in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'dto' => {
        data_type => 'ShapeBase',
        description => 'Shape DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'shape_to_clone' => {
        data_type => 'int',
        description => 'Optional index for clone shape instead of adding a new one.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new shape in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_add_new_shape' } = { 
    	summary => 'Create new shape.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub post_add_new_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_add_new_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_add_new_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_add_new_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'shape_to_clone'} && defined $args{'shape_to_clone'}) {
        $query_params->{'shapeToClone'} = $self->{api_client}->to_query_value($args{'shape_to_clone'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# post_add_notes_slide
#
# Add new notes slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param NotesSlide $dto A NotesSlide object with notes slide data. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'dto' => {
        data_type => 'NotesSlide',
        description => 'A NotesSlide object with notes slide data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_add_notes_slide' } = { 
    	summary => 'Add new notes slide.',
        params => $params,
        returns => 'NotesSlide',
        };
}
# @return NotesSlide
#
sub post_add_notes_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_add_notes_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_add_notes_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('NotesSlide', $response);
    return $_response_object;
}

#
# post_copy_layout_slide_from_source_presentation
#
# Copy layoutSlide from source presentation.
# 
# @param string $name Document name. (required)
# @param string $clone_from Name of the document to clone layoutSlide from. (required)
# @param int $clone_from_position Position of cloned layout slide. (required)
# @param string $clone_from_password Password for the document to clone layoutSlide from. (optional)
# @param string $clone_from_storage Storage of the document to clone layoutSlide from. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'clone_from' => {
        data_type => 'string',
        description => 'Name of the document to clone layoutSlide from.',
        required => '1',
    },
    'clone_from_position' => {
        data_type => 'int',
        description => 'Position of cloned layout slide.',
        required => '1',
    },
    'clone_from_password' => {
        data_type => 'string',
        description => 'Password for the document to clone layoutSlide from.',
        required => '0',
    },
    'clone_from_storage' => {
        data_type => 'string',
        description => 'Storage of the document to clone layoutSlide from.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_copy_layout_slide_from_source_presentation' } = { 
    	summary => 'Copy layoutSlide from source presentation.',
        params => $params,
        returns => 'LayoutSlide',
        };
}
# @return LayoutSlide
#
sub post_copy_layout_slide_from_source_presentation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_copy_layout_slide_from_source_presentation");
    }

    # verify the required parameter 'clone_from' is set
    unless (exists $args{'clone_from'}) {
      croak("Missing the required parameter 'clone_from' when calling post_copy_layout_slide_from_source_presentation");
    }

    # verify the required parameter 'clone_from_position' is set
    unless (exists $args{'clone_from_position'}) {
      croak("Missing the required parameter 'clone_from_position' when calling post_copy_layout_slide_from_source_presentation");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/layoutSlides';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'clone_from'} && defined $args{'clone_from'}) {
        $query_params->{'cloneFrom'} = $self->{api_client}->to_query_value($args{'clone_from'});
    }

    # query params
    if (exists $args{'clone_from_position'} && defined $args{'clone_from_position'}) {
        $query_params->{'cloneFromPosition'} = $self->{api_client}->to_query_value($args{'clone_from_position'});
    }

    # query params
    if (exists $args{'clone_from_password'} && defined $args{'clone_from_password'}) {
        $query_params->{'cloneFromPassword'} = $self->{api_client}->to_query_value($args{'clone_from_password'});
    }

    # query params
    if (exists $args{'clone_from_storage'} && defined $args{'clone_from_storage'}) {
        $query_params->{'cloneFromStorage'} = $self->{api_client}->to_query_value($args{'clone_from_storage'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LayoutSlide', $response);
    return $_response_object;
}

#
# post_copy_master_slide_from_source_presentation
#
# Copy masterSlide from source presentation.
# 
# @param string $name Document name. (required)
# @param string $clone_from Name of the document to clone masterSlide from. (required)
# @param int $clone_from_position Position of cloned master slide. (required)
# @param string $clone_from_password Password for the document to clone masterSlide from. (optional)
# @param string $clone_from_storage Storage of the document to clone masterSlide from. (optional)
# @param boolean $apply_to_all True to apply cloned master slide to every existing slide. (optional, default to false)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'clone_from' => {
        data_type => 'string',
        description => 'Name of the document to clone masterSlide from.',
        required => '1',
    },
    'clone_from_position' => {
        data_type => 'int',
        description => 'Position of cloned master slide.',
        required => '1',
    },
    'clone_from_password' => {
        data_type => 'string',
        description => 'Password for the document to clone masterSlide from.',
        required => '0',
    },
    'clone_from_storage' => {
        data_type => 'string',
        description => 'Storage of the document to clone masterSlide from.',
        required => '0',
    },
    'apply_to_all' => {
        data_type => 'boolean',
        description => 'True to apply cloned master slide to every existing slide.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_copy_master_slide_from_source_presentation' } = { 
    	summary => 'Copy masterSlide from source presentation.',
        params => $params,
        returns => 'MasterSlide',
        };
}
# @return MasterSlide
#
sub post_copy_master_slide_from_source_presentation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_copy_master_slide_from_source_presentation");
    }

    # verify the required parameter 'clone_from' is set
    unless (exists $args{'clone_from'}) {
      croak("Missing the required parameter 'clone_from' when calling post_copy_master_slide_from_source_presentation");
    }

    # verify the required parameter 'clone_from_position' is set
    unless (exists $args{'clone_from_position'}) {
      croak("Missing the required parameter 'clone_from_position' when calling post_copy_master_slide_from_source_presentation");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/masterSlides';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'clone_from'} && defined $args{'clone_from'}) {
        $query_params->{'cloneFrom'} = $self->{api_client}->to_query_value($args{'clone_from'});
    }

    # query params
    if (exists $args{'clone_from_position'} && defined $args{'clone_from_position'}) {
        $query_params->{'cloneFromPosition'} = $self->{api_client}->to_query_value($args{'clone_from_position'});
    }

    # query params
    if (exists $args{'clone_from_password'} && defined $args{'clone_from_password'}) {
        $query_params->{'cloneFromPassword'} = $self->{api_client}->to_query_value($args{'clone_from_password'});
    }

    # query params
    if (exists $args{'clone_from_storage'} && defined $args{'clone_from_storage'}) {
        $query_params->{'cloneFromStorage'} = $self->{api_client}->to_query_value($args{'clone_from_storage'});
    }

    # query params
    if (exists $args{'apply_to_all'} && defined $args{'apply_to_all'}) {
        $query_params->{'applyToAll'} = $self->{api_client}->to_boolean_query_value($args{'apply_to_all'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('MasterSlide', $response);
    return $_response_object;
}

#
# post_notes_slide_add_new_paragraph
#
# Creates new paragraph.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param Paragraph $dto Paragraph DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $position Position of the new paragraph in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Paragraph',
        description => 'Paragraph DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new paragraph in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_notes_slide_add_new_paragraph' } = { 
    	summary => 'Creates new paragraph.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub post_notes_slide_add_new_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_notes_slide_add_new_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_notes_slide_add_new_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_notes_slide_add_new_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_notes_slide_add_new_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# post_notes_slide_add_new_portion
#
# Creates new portion.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param Portion $dto Portion DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $position Position of the new portion in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Portion',
        description => 'Portion DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new portion in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_notes_slide_add_new_portion' } = { 
    	summary => 'Creates new portion.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub post_notes_slide_add_new_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_notes_slide_add_new_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_notes_slide_add_new_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_notes_slide_add_new_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_notes_slide_add_new_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling post_notes_slide_add_new_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# post_notes_slide_add_new_shape
#
# Create new shape.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param ShapeBase $dto Shape DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param int $shape_to_clone Optional index for clone shape instead of adding a new one. (optional)
# @param int $position Position of the new shape in the list. Default is at the end of the list. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'dto' => {
        data_type => 'ShapeBase',
        description => 'Shape DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'shape_to_clone' => {
        data_type => 'int',
        description => 'Optional index for clone shape instead of adding a new one.',
        required => '0',
    },
    'position' => {
        data_type => 'int',
        description => 'Position of the new shape in the list. Default is at the end of the list.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_notes_slide_add_new_shape' } = { 
    	summary => 'Create new shape.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub post_notes_slide_add_new_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_notes_slide_add_new_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_notes_slide_add_new_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_notes_slide_add_new_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'shape_to_clone'} && defined $args{'shape_to_clone'}) {
        $query_params->{'shapeToClone'} = $self->{api_client}->to_query_value($args{'shape_to_clone'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# post_notes_slide_shape_save_as
#
# Render shape to specified picture format.
# 
# @param string $name Presentation name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Index of shape starting from 1 (required)
# @param string $format Export picture format. (required)
# @param IShapeExportOptions $options export options (optional)
# @param string $password Document password. (optional)
# @param string $folder Presentation folder. (optional)
# @param string $storage Presentation storage. (optional)
# @param double $scale_x X scale ratio. (optional, default to 0.0)
# @param double $scale_y Y scale ratio. (optional, default to 0.0)
# @param string $bounds Shape thumbnail bounds type. (optional, default to 1)
# @param string $fonts_folder Fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Presentation name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Index of shape starting from 1',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export picture format.',
        required => '1',
    },
    'options' => {
        data_type => 'IShapeExportOptions',
        description => 'export options',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Presentation folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Presentation storage.',
        required => '0',
    },
    'scale_x' => {
        data_type => 'double',
        description => 'X scale ratio.',
        required => '0',
    },
    'scale_y' => {
        data_type => 'double',
        description => 'Y scale ratio.',
        required => '0',
    },
    'bounds' => {
        data_type => 'string',
        description => 'Shape thumbnail bounds type.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_notes_slide_shape_save_as' } = { 
    	summary => 'Render shape to specified picture format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_notes_slide_shape_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_notes_slide_shape_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_notes_slide_shape_save_as");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_notes_slide_shape_save_as");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_notes_slide_shape_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_notes_slide_shape_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/{format}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'scale_x'} && defined $args{'scale_x'}) {
        $query_params->{'scaleX'} = $self->{api_client}->to_query_value($args{'scale_x'});
    }

    # query params
    if (exists $args{'scale_y'} && defined $args{'scale_y'}) {
        $query_params->{'scaleY'} = $self->{api_client}->to_query_value($args{'scale_y'});
    }

    # query params
    if (exists $args{'bounds'} && defined $args{'bounds'}) {
        $query_params->{'bounds'} = $self->{api_client}->to_query_value($args{'bounds'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_presentation_merge
#
# Merge the presentation with other presentations specified in the request parameter.
# 
# @param string $name Document name. (required)
# @param PresentationsMergeRequest $request PresentationsMergeRequest with a list of presentations to merge. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'request' => {
        data_type => 'PresentationsMergeRequest',
        description => 'PresentationsMergeRequest with a list of presentations to merge.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_presentation_merge' } = { 
    	summary => 'Merge the presentation with other presentations specified in the request parameter.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub post_presentation_merge {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_presentation_merge");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/merge';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'request'}) {
        $_body_data = $args{'request'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# post_shape_save_as
#
# Render shape to specified picture format.
# 
# @param string $name Presentation name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Index of shape starting from 1 (required)
# @param string $format Export picture format. (required)
# @param IShapeExportOptions $options export options (optional)
# @param string $password Document password. (optional)
# @param string $folder Presentation folder. (optional)
# @param string $storage Presentation storage. (optional)
# @param double $scale_x X scale ratio. (optional, default to 0.0)
# @param double $scale_y Y scale ratio. (optional, default to 0.0)
# @param string $bounds Shape thumbnail bounds type. (optional, default to 1)
# @param string $fonts_folder Fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Presentation name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Index of shape starting from 1',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export picture format.',
        required => '1',
    },
    'options' => {
        data_type => 'IShapeExportOptions',
        description => 'export options',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Presentation folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Presentation storage.',
        required => '0',
    },
    'scale_x' => {
        data_type => 'double',
        description => 'X scale ratio.',
        required => '0',
    },
    'scale_y' => {
        data_type => 'double',
        description => 'Y scale ratio.',
        required => '0',
    },
    'bounds' => {
        data_type => 'string',
        description => 'Shape thumbnail bounds type.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_shape_save_as' } = { 
    	summary => 'Render shape to specified picture format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_shape_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_shape_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_shape_save_as");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling post_shape_save_as");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling post_shape_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_shape_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/{format}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'scale_x'} && defined $args{'scale_x'}) {
        $query_params->{'scaleX'} = $self->{api_client}->to_query_value($args{'scale_x'});
    }

    # query params
    if (exists $args{'scale_y'} && defined $args{'scale_y'}) {
        $query_params->{'scaleY'} = $self->{api_client}->to_query_value($args{'scale_y'});
    }

    # query params
    if (exists $args{'bounds'} && defined $args{'bounds'}) {
        $query_params->{'bounds'} = $self->{api_client}->to_query_value($args{'bounds'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_slide_animation_effect
#
# Add an effect to slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param Effect $effect Animation effect DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'effect' => {
        data_type => 'Effect',
        description => 'Animation effect DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slide_animation_effect' } = { 
    	summary => 'Add an effect to slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub post_slide_animation_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slide_animation_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slide_animation_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/mainSequence';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'effect'}) {
        $_body_data = $args{'effect'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# post_slide_animation_interactive_sequence
#
# Set slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param InteractiveSequence $sequence Animation sequence DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'sequence' => {
        data_type => 'InteractiveSequence',
        description => 'Animation sequence DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slide_animation_interactive_sequence' } = { 
    	summary => 'Set slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub post_slide_animation_interactive_sequence {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slide_animation_interactive_sequence");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slide_animation_interactive_sequence");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'sequence'}) {
        $_body_data = $args{'sequence'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# post_slide_animation_interactive_sequence_effect
#
# Add an animation effect to a slide interactive sequence.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $sequence_index The position of the interactive sequence. (required)
# @param Effect $effect Animation effect DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'sequence_index' => {
        data_type => 'int',
        description => 'The position of the interactive sequence.',
        required => '1',
    },
    'effect' => {
        data_type => 'Effect',
        description => 'Animation effect DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slide_animation_interactive_sequence_effect' } = { 
    	summary => 'Add an animation effect to a slide interactive sequence.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub post_slide_animation_interactive_sequence_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'sequence_index' is set
    unless (exists $args{'sequence_index'}) {
      croak("Missing the required parameter 'sequence_index' when calling post_slide_animation_interactive_sequence_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences/{sequenceIndex}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'sequence_index'}) {
        my $_base_variable = "{" . "sequenceIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'sequence_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'effect'}) {
        $_body_data = $args{'effect'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# post_slide_save_as
#
# Save a slide to a specified format.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $format Output file format. (required)
# @param ExportOptions $options Export options. (optional)
# @param int $width Output file width; 0 to not adjust the size. Default is 0. (optional, default to 0)
# @param int $height Output file height; 0 to not adjust the size. Default is 0. (optional, default to 0)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param string $fonts_folder Storage folder containing custom fonts to be used with the document. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Output file format.',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => 'Export options.',
        required => '0',
    },
    'width' => {
        data_type => 'int',
        description => 'Output file width; 0 to not adjust the size. Default is 0.',
        required => '0',
    },
    'height' => {
        data_type => 'int',
        description => 'Output file height; 0 to not adjust the size. Default is 0.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Storage folder containing custom fonts to be used with the document.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slide_save_as' } = { 
    	summary => 'Save a slide to a specified format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_slide_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slide_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slide_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_slide_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/{format}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'width'} && defined $args{'width'}) {
        $query_params->{'width'} = $self->{api_client}->to_query_value($args{'width'});
    }

    # query params
    if (exists $args{'height'} && defined $args{'height'}) {
        $query_params->{'height'} = $self->{api_client}->to_query_value($args{'height'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_slides_add
#
# Create a slide.
# 
# @param string $name Document name. (required)
# @param int $position The target position at which to create the slide. Add to the end by default. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param string $layout_alias Alias of layout slide for new slide. Alias may be the type of layout, name of layout slide or index (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'position' => {
        data_type => 'int',
        description => 'The target position at which to create the slide. Add to the end by default.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'layout_alias' => {
        data_type => 'string',
        description => 'Alias of layout slide for new slide. Alias may be the type of layout, name of layout slide or index',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_add' } = { 
    	summary => 'Create a slide.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub post_slides_add {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_add");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'layout_alias'} && defined $args{'layout_alias'}) {
        $query_params->{'layoutAlias'} = $self->{api_client}->to_query_value($args{'layout_alias'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# post_slides_convert
#
# Convert presentation from request content to format specified.
# 
# @param string $format Export format. (required)
# @param File $document Document data. (optional)
# @param string $password Document password. (optional)
# @param string $fonts_folder Custom fonts folder. (optional)
{
    my $params = {
    'format' => {
        data_type => 'string',
        description => 'Export format.',
        required => '1',
    },
    'document' => {
        data_type => 'File',
        description => 'Document data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Custom fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_convert' } = { 
    	summary => 'Convert presentation from request content to format specified.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_slides_convert {
    my ($self, %args) = @_;

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_slides_convert");
    }

    # parse inputs
    my $_resource_path = '/slides/convert/{format}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/octet-stream', 'multipart/form-data');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'document'}) {
        $_body_data = $args{'document'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_slides_copy
#
# Copy a slide from the current or another presentation.
# 
# @param string $name Document name. (required)
# @param int $slide_to_copy The index of the slide to be copied from the source presentation. (required)
# @param int $position The target position at which to copy the slide. Copy to the end by default. (optional)
# @param string $source Name of the document to copy a slide from. (optional)
# @param string $source_password Password for the document to copy a slide from. (optional)
# @param string $source_storage Template storage name. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_to_copy' => {
        data_type => 'int',
        description => 'The index of the slide to be copied from the source presentation.',
        required => '1',
    },
    'position' => {
        data_type => 'int',
        description => 'The target position at which to copy the slide. Copy to the end by default.',
        required => '0',
    },
    'source' => {
        data_type => 'string',
        description => 'Name of the document to copy a slide from.',
        required => '0',
    },
    'source_password' => {
        data_type => 'string',
        description => 'Password for the document to copy a slide from.',
        required => '0',
    },
    'source_storage' => {
        data_type => 'string',
        description => 'Template storage name.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_copy' } = { 
    	summary => 'Copy a slide from the current or another presentation.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub post_slides_copy {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_copy");
    }

    # verify the required parameter 'slide_to_copy' is set
    unless (exists $args{'slide_to_copy'}) {
      croak("Missing the required parameter 'slide_to_copy' when calling post_slides_copy");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/copy';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'slide_to_copy'} && defined $args{'slide_to_copy'}) {
        $query_params->{'slideToCopy'} = $self->{api_client}->to_query_value($args{'slide_to_copy'});
    }

    # query params
    if (exists $args{'position'} && defined $args{'position'}) {
        $query_params->{'position'} = $self->{api_client}->to_query_value($args{'position'});
    }

    # query params
    if (exists $args{'source'} && defined $args{'source'}) {
        $query_params->{'source'} = $self->{api_client}->to_query_value($args{'source'});
    }

    # query params
    if (exists $args{'source_password'} && defined $args{'source_password'}) {
        $query_params->{'sourcePassword'} = $self->{api_client}->to_query_value($args{'source_password'});
    }

    # query params
    if (exists $args{'source_storage'} && defined $args{'source_storage'}) {
        $query_params->{'sourceStorage'} = $self->{api_client}->to_query_value($args{'source_storage'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# post_slides_document
#
# Create a presentation.
# 
# @param string $name Document name. (required)
# @param File $data Document input data. (optional)
# @param string $input_password The password for input document. (optional)
# @param string $password The document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'data' => {
        data_type => 'File',
        description => 'Document input data.',
        required => '0',
    },
    'input_password' => {
        data_type => 'string',
        description => 'The password for input document.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'The document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_document' } = { 
    	summary => 'Create a presentation.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub post_slides_document {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_document");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/octet-stream', 'multipart/form-data');

    # query params
    if (exists $args{'input_password'} && defined $args{'input_password'}) {
        $query_params->{'inputPassword'} = $self->{api_client}->to_query_value($args{'input_password'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'data'}) {
        $_body_data = $args{'data'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# post_slides_document_from_html
#
# Create presentation document from html.
# 
# @param string $name Document name. (required)
# @param string $html HTML data. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'html' => {
        data_type => 'string',
        description => 'HTML data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_document_from_html' } = { 
    	summary => 'Create presentation document from html.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub post_slides_document_from_html {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_document_from_html");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/fromHtml';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'html'}) {
        $_body_data = $args{'html'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# post_slides_document_from_source
#
# Create a presentation from an existing source.
# 
# @param string $name Document name. (required)
# @param string $source_path Template file path. (optional)
# @param string $source_password Template file password. (optional)
# @param string $source_storage Template storage name. (optional)
# @param string $password The document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'source_path' => {
        data_type => 'string',
        description => 'Template file path.',
        required => '0',
    },
    'source_password' => {
        data_type => 'string',
        description => 'Template file password.',
        required => '0',
    },
    'source_storage' => {
        data_type => 'string',
        description => 'Template storage name.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'The document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_document_from_source' } = { 
    	summary => 'Create a presentation from an existing source.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub post_slides_document_from_source {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_document_from_source");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/fromSource';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'source_path'} && defined $args{'source_path'}) {
        $query_params->{'sourcePath'} = $self->{api_client}->to_query_value($args{'source_path'});
    }

    # query params
    if (exists $args{'source_password'} && defined $args{'source_password'}) {
        $query_params->{'sourcePassword'} = $self->{api_client}->to_query_value($args{'source_password'});
    }

    # query params
    if (exists $args{'source_storage'} && defined $args{'source_storage'}) {
        $query_params->{'sourceStorage'} = $self->{api_client}->to_query_value($args{'source_storage'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# post_slides_document_from_template
#
# Create a presentation.
# 
# @param string $name Document name. (required)
# @param string $template_path Template file path. (required)
# @param string $data Document input data. (optional)
# @param string $template_password Template file password. (optional)
# @param string $template_storage Template storage name. (optional)
# @param boolean $is_image_data_embedded True if image data is embedded. (optional, default to false)
# @param string $password The document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'template_path' => {
        data_type => 'string',
        description => 'Template file path.',
        required => '1',
    },
    'data' => {
        data_type => 'string',
        description => 'Document input data.',
        required => '0',
    },
    'template_password' => {
        data_type => 'string',
        description => 'Template file password.',
        required => '0',
    },
    'template_storage' => {
        data_type => 'string',
        description => 'Template storage name.',
        required => '0',
    },
    'is_image_data_embedded' => {
        data_type => 'boolean',
        description => 'True if image data is embedded.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'The document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_document_from_template' } = { 
    	summary => 'Create a presentation.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub post_slides_document_from_template {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_document_from_template");
    }

    # verify the required parameter 'template_path' is set
    unless (exists $args{'template_path'}) {
      croak("Missing the required parameter 'template_path' when calling post_slides_document_from_template");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/fromTemplate';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'template_path'} && defined $args{'template_path'}) {
        $query_params->{'templatePath'} = $self->{api_client}->to_query_value($args{'template_path'});
    }

    # query params
    if (exists $args{'template_password'} && defined $args{'template_password'}) {
        $query_params->{'templatePassword'} = $self->{api_client}->to_query_value($args{'template_password'});
    }

    # query params
    if (exists $args{'template_storage'} && defined $args{'template_storage'}) {
        $query_params->{'templateStorage'} = $self->{api_client}->to_query_value($args{'template_storage'});
    }

    # query params
    if (exists $args{'is_image_data_embedded'} && defined $args{'is_image_data_embedded'}) {
        $query_params->{'isImageDataEmbedded'} = $self->{api_client}->to_boolean_query_value($args{'is_image_data_embedded'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'data'}) {
        $_body_data = $args{'data'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# post_slides_pipeline
#
# Performs slides pipeline.
# 
# @param Pipeline $pipeline A Pipeline object. (optional)
{
    my $params = {
    'pipeline' => {
        data_type => 'Pipeline',
        description => 'A Pipeline object.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_pipeline' } = { 
    	summary => 'Performs slides pipeline.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_slides_pipeline {
    my ($self, %args) = @_;

    # parse inputs
    my $_resource_path = '/slides/pipeline';

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

    my $_body_data;
    # body params
    if ( exists $args{'pipeline'}) {
        $_body_data = $args{'pipeline'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_slides_presentation_replace_text
#
# Replace text with a new value.
# 
# @param string $name Document name. (required)
# @param string $old_value Text value to be replaced. (required)
# @param string $new_value Text value to replace with. (required)
# @param boolean $ignore_case True if character case must be ignored. (optional, default to false)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'old_value' => {
        data_type => 'string',
        description => 'Text value to be replaced.',
        required => '1',
    },
    'new_value' => {
        data_type => 'string',
        description => 'Text value to replace with.',
        required => '1',
    },
    'ignore_case' => {
        data_type => 'boolean',
        description => 'True if character case must be ignored.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_presentation_replace_text' } = { 
    	summary => 'Replace text with a new value.',
        params => $params,
        returns => 'DocumentReplaceResult',
        };
}
# @return DocumentReplaceResult
#
sub post_slides_presentation_replace_text {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_presentation_replace_text");
    }

    # verify the required parameter 'old_value' is set
    unless (exists $args{'old_value'}) {
      croak("Missing the required parameter 'old_value' when calling post_slides_presentation_replace_text");
    }

    # verify the required parameter 'new_value' is set
    unless (exists $args{'new_value'}) {
      croak("Missing the required parameter 'new_value' when calling post_slides_presentation_replace_text");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/replaceText';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'old_value'} && defined $args{'old_value'}) {
        $query_params->{'oldValue'} = $self->{api_client}->to_query_value($args{'old_value'});
    }

    # query params
    if (exists $args{'new_value'} && defined $args{'new_value'}) {
        $query_params->{'newValue'} = $self->{api_client}->to_query_value($args{'new_value'});
    }

    # query params
    if (exists $args{'ignore_case'} && defined $args{'ignore_case'}) {
        $query_params->{'ignoreCase'} = $self->{api_client}->to_boolean_query_value($args{'ignore_case'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentReplaceResult', $response);
    return $_response_object;
}

#
# post_slides_reorder
#
# Reorder presentation slide position.
# 
# @param string $name Document name. (required)
# @param int $slide_index The position of the slide to be reordered. (required)
# @param int $new_position The new position of the reordered slide. (required)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'The position of the slide to be reordered.',
        required => '1',
    },
    'new_position' => {
        data_type => 'int',
        description => 'The new position of the reordered slide.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_reorder' } = { 
    	summary => 'Reorder presentation slide position.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub post_slides_reorder {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_reorder");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slides_reorder");
    }

    # verify the required parameter 'new_position' is set
    unless (exists $args{'new_position'}) {
      croak("Missing the required parameter 'new_position' when calling post_slides_reorder");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/move';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'new_position'} && defined $args{'new_position'}) {
        $query_params->{'newPosition'} = $self->{api_client}->to_query_value($args{'new_position'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# post_slides_reorder_many
#
# Reorder presentation slides positions.
# 
# @param string $name Document name. (required)
# @param string $old_positions A comma separated array of positions of slides to be reordered. (optional)
# @param string $new_positions A comma separated array of new slide positions. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'old_positions' => {
        data_type => 'string',
        description => 'A comma separated array of positions of slides to be reordered.',
        required => '0',
    },
    'new_positions' => {
        data_type => 'string',
        description => 'A comma separated array of new slide positions.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_reorder_many' } = { 
    	summary => 'Reorder presentation slides positions.',
        params => $params,
        returns => 'Slides',
        };
}
# @return Slides
#
sub post_slides_reorder_many {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_reorder_many");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/reorder';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'old_positions'} && defined $args{'old_positions'}) {
        $query_params->{'oldPositions'} = $self->{api_client}->to_query_value($args{'old_positions'});
    }

    # query params
    if (exists $args{'new_positions'} && defined $args{'new_positions'}) {
        $query_params->{'newPositions'} = $self->{api_client}->to_query_value($args{'new_positions'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slides', $response);
    return $_response_object;
}

#
# post_slides_save_as
#
# Save a presentation to a specified format.
# 
# @param string $name Document name. (required)
# @param string $format Export format. (required)
# @param ExportOptions $options Export options. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
# @param string $fonts_folder Custom fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export format.',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => 'Export options.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Custom fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_save_as' } = { 
    	summary => 'Save a presentation to a specified format.',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub post_slides_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling post_slides_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/{format}';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('multipart/form-data');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# post_slides_set_document_properties
#
# Set document properties.
# 
# @param string $name Document name. (required)
# @param DocumentProperties $properties New properties. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'properties' => {
        data_type => 'DocumentProperties',
        description => 'New properties.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_set_document_properties' } = { 
    	summary => 'Set document properties.',
        params => $params,
        returns => 'DocumentProperties',
        };
}
# @return DocumentProperties
#
sub post_slides_set_document_properties {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_set_document_properties");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'properties'}) {
        $_body_data = $args{'properties'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperties', $response);
    return $_response_object;
}

#
# post_slides_slide_replace_text
#
# Replace text with a new value.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $old_value Text value to be replaced. (required)
# @param string $new_value Text value to replace with. (required)
# @param boolean $ignore_case True if character case must be ignored. (optional, default to false)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'old_value' => {
        data_type => 'string',
        description => 'Text value to be replaced.',
        required => '1',
    },
    'new_value' => {
        data_type => 'string',
        description => 'Text value to replace with.',
        required => '1',
    },
    'ignore_case' => {
        data_type => 'boolean',
        description => 'True if character case must be ignored.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_slide_replace_text' } = { 
    	summary => 'Replace text with a new value.',
        params => $params,
        returns => 'SlideReplaceResult',
        };
}
# @return SlideReplaceResult
#
sub post_slides_slide_replace_text {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_slide_replace_text");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling post_slides_slide_replace_text");
    }

    # verify the required parameter 'old_value' is set
    unless (exists $args{'old_value'}) {
      croak("Missing the required parameter 'old_value' when calling post_slides_slide_replace_text");
    }

    # verify the required parameter 'new_value' is set
    unless (exists $args{'new_value'}) {
      croak("Missing the required parameter 'new_value' when calling post_slides_slide_replace_text");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/replaceText';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'old_value'} && defined $args{'old_value'}) {
        $query_params->{'oldValue'} = $self->{api_client}->to_query_value($args{'old_value'});
    }

    # query params
    if (exists $args{'new_value'} && defined $args{'new_value'}) {
        $query_params->{'newValue'} = $self->{api_client}->to_query_value($args{'new_value'});
    }

    # query params
    if (exists $args{'ignore_case'} && defined $args{'ignore_case'}) {
        $query_params->{'ignoreCase'} = $self->{api_client}->to_boolean_query_value($args{'ignore_case'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideReplaceResult', $response);
    return $_response_object;
}

#
# post_slides_split
#
# Splitting presentations. Create one image per slide.
# 
# @param string $name Document name. (required)
# @param ExportOptions $options Export options. (optional)
# @param string $format Export format. Default value is jpeg. (optional, default to 0)
# @param int $width The width of created images. (optional)
# @param int $height The height of created images. (optional)
# @param int $to The last slide number for splitting, if is not specified splitting ends at the last slide of the document. (optional)
# @param int $from The start slide number for splitting, if is not specified splitting starts from the first slide of the presentation. (optional)
# @param string $dest_folder Folder on storage where images are going to be uploaded. If not specified then images are uploaded to same folder as presentation. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
# @param string $fonts_folder Custom fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => 'Export options.',
        required => '0',
    },
    'format' => {
        data_type => 'string',
        description => 'Export format. Default value is jpeg.',
        required => '0',
    },
    'width' => {
        data_type => 'int',
        description => 'The width of created images.',
        required => '0',
    },
    'height' => {
        data_type => 'int',
        description => 'The height of created images.',
        required => '0',
    },
    'to' => {
        data_type => 'int',
        description => 'The last slide number for splitting, if is not specified splitting ends at the last slide of the document.',
        required => '0',
    },
    'from' => {
        data_type => 'int',
        description => 'The start slide number for splitting, if is not specified splitting starts from the first slide of the presentation.',
        required => '0',
    },
    'dest_folder' => {
        data_type => 'string',
        description => 'Folder on storage where images are going to be uploaded. If not specified then images are uploaded to same folder as presentation.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Custom fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'post_slides_split' } = { 
    	summary => 'Splitting presentations. Create one image per slide.',
        params => $params,
        returns => 'SplitDocumentResult',
        };
}
# @return SplitDocumentResult
#
sub post_slides_split {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling post_slides_split");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/split';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'format'} && defined $args{'format'}) {
        $query_params->{'format'} = $self->{api_client}->to_query_value($args{'format'});
    }

    # query params
    if (exists $args{'width'} && defined $args{'width'}) {
        $query_params->{'width'} = $self->{api_client}->to_query_value($args{'width'});
    }

    # query params
    if (exists $args{'height'} && defined $args{'height'}) {
        $query_params->{'height'} = $self->{api_client}->to_query_value($args{'height'});
    }

    # query params
    if (exists $args{'to'} && defined $args{'to'}) {
        $query_params->{'to'} = $self->{api_client}->to_query_value($args{'to'});
    }

    # query params
    if (exists $args{'from'} && defined $args{'from'}) {
        $query_params->{'from'} = $self->{api_client}->to_query_value($args{'from'});
    }

    # query params
    if (exists $args{'dest_folder'} && defined $args{'dest_folder'}) {
        $query_params->{'destFolder'} = $self->{api_client}->to_query_value($args{'dest_folder'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SplitDocumentResult', $response);
    return $_response_object;
}

#
# put_layout_slide
#
# Update a layoutSlide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param LayoutSlide $slide_dto Slide update data. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'slide_dto' => {
        data_type => 'LayoutSlide',
        description => 'Slide update data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_layout_slide' } = { 
    	summary => 'Update a layoutSlide.',
        params => $params,
        returns => 'LayoutSlide',
        };
}
# @return LayoutSlide
#
sub put_layout_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_layout_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_layout_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/layoutSlides/{slideIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'slide_dto'}) {
        $_body_data = $args{'slide_dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('LayoutSlide', $response);
    return $_response_object;
}

#
# put_notes_slide_shape_save_as
#
# Render shape to specified picture format.
# 
# @param string $name Presentation name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Index of shape starting from 1 (required)
# @param string $format Export picture format. (required)
# @param string $out_path Output path. (required)
# @param IShapeExportOptions $options export options (optional)
# @param string $password Document password. (optional)
# @param string $folder Presentation folder. (optional)
# @param string $storage Presentation storage. (optional)
# @param double $scale_x X scale ratio. (optional, default to 0.0)
# @param double $scale_y Y scale ratio. (optional, default to 0.0)
# @param string $bounds Shape thumbnail bounds type. (optional, default to 1)
# @param string $fonts_folder Fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Presentation name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Index of shape starting from 1',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export picture format.',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => 'Output path.',
        required => '1',
    },
    'options' => {
        data_type => 'IShapeExportOptions',
        description => 'export options',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Presentation folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Presentation storage.',
        required => '0',
    },
    'scale_x' => {
        data_type => 'double',
        description => 'X scale ratio.',
        required => '0',
    },
    'scale_y' => {
        data_type => 'double',
        description => 'Y scale ratio.',
        required => '0',
    },
    'bounds' => {
        data_type => 'string',
        description => 'Shape thumbnail bounds type.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_notes_slide_shape_save_as' } = { 
    	summary => 'Render shape to specified picture format.',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub put_notes_slide_shape_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_notes_slide_shape_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_notes_slide_shape_save_as");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_notes_slide_shape_save_as");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_notes_slide_shape_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling put_notes_slide_shape_save_as");
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling put_notes_slide_shape_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/{format}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'scale_x'} && defined $args{'scale_x'}) {
        $query_params->{'scaleX'} = $self->{api_client}->to_query_value($args{'scale_x'});
    }

    # query params
    if (exists $args{'scale_y'} && defined $args{'scale_y'}) {
        $query_params->{'scaleY'} = $self->{api_client}->to_query_value($args{'scale_y'});
    }

    # query params
    if (exists $args{'bounds'} && defined $args{'bounds'}) {
        $query_params->{'bounds'} = $self->{api_client}->to_query_value($args{'bounds'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# put_presentation_merge
#
# Merge the presentation with other presentations or some of their slides specified in the request parameter.
# 
# @param string $name Document name. (required)
# @param OrderedMergeRequest $request OrderedMergeRequest with a list of presentations and slide indices to merge. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'request' => {
        data_type => 'OrderedMergeRequest',
        description => 'OrderedMergeRequest with a list of presentations and slide indices to merge.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_presentation_merge' } = { 
    	summary => 'Merge the presentation with other presentations or some of their slides specified in the request parameter.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub put_presentation_merge {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_presentation_merge");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/merge';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'request'}) {
        $_body_data = $args{'request'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# put_set_paragraph_portion_properties
#
# Update portion properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param Portion $dto Portion DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Portion',
        description => 'Portion DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_set_paragraph_portion_properties' } = { 
    	summary => 'Update portion properties.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub put_set_paragraph_portion_properties {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_set_paragraph_portion_properties");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_set_paragraph_portion_properties");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_set_paragraph_portion_properties");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_set_paragraph_portion_properties");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling put_set_paragraph_portion_properties");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling put_set_paragraph_portion_properties");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# put_set_paragraph_properties
#
# Update paragraph properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param Paragraph $dto Paragraph DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Paragraph',
        description => 'Paragraph DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_set_paragraph_properties' } = { 
    	summary => 'Update paragraph properties.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub put_set_paragraph_properties {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_set_paragraph_properties");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_set_paragraph_properties");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_set_paragraph_properties");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_set_paragraph_properties");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling put_set_paragraph_properties");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# put_shape_save_as
#
# Render shape to specified picture format.
# 
# @param string $name Presentation name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Index of shape starting from 1 (required)
# @param string $format Export picture format. (required)
# @param string $out_path Output path. (required)
# @param IShapeExportOptions $options export options (optional)
# @param string $password Document password. (optional)
# @param string $folder Presentation folder. (optional)
# @param string $storage Presentation storage. (optional)
# @param double $scale_x X scale ratio. (optional, default to 0.0)
# @param double $scale_y Y scale ratio. (optional, default to 0.0)
# @param string $bounds Shape thumbnail bounds type. (optional, default to 1)
# @param string $fonts_folder Fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Presentation name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Index of shape starting from 1',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export picture format.',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => 'Output path.',
        required => '1',
    },
    'options' => {
        data_type => 'IShapeExportOptions',
        description => 'export options',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Presentation folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Presentation storage.',
        required => '0',
    },
    'scale_x' => {
        data_type => 'double',
        description => 'X scale ratio.',
        required => '0',
    },
    'scale_y' => {
        data_type => 'double',
        description => 'Y scale ratio.',
        required => '0',
    },
    'bounds' => {
        data_type => 'string',
        description => 'Shape thumbnail bounds type.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_shape_save_as' } = { 
    	summary => 'Render shape to specified picture format.',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub put_shape_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_shape_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_shape_save_as");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_shape_save_as");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_shape_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling put_shape_save_as");
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling put_shape_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}/{format}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'scale_x'} && defined $args{'scale_x'}) {
        $query_params->{'scaleX'} = $self->{api_client}->to_query_value($args{'scale_x'});
    }

    # query params
    if (exists $args{'scale_y'} && defined $args{'scale_y'}) {
        $query_params->{'scaleY'} = $self->{api_client}->to_query_value($args{'scale_y'});
    }

    # query params
    if (exists $args{'bounds'} && defined $args{'bounds'}) {
        $query_params->{'bounds'} = $self->{api_client}->to_query_value($args{'bounds'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# put_slide_animation
#
# Set slide animation.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param SlideAnimation $animation Animation DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'animation' => {
        data_type => 'SlideAnimation',
        description => 'Animation DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slide_animation' } = { 
    	summary => 'Set slide animation.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub put_slide_animation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slide_animation");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slide_animation");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'animation'}) {
        $_body_data = $args{'animation'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# put_slide_animation_effect
#
# Modify an animation effect for a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $effect_index The position of the effect to be modified. (required)
# @param Effect $effect Animation effect DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'effect_index' => {
        data_type => 'int',
        description => 'The position of the effect to be modified.',
        required => '1',
    },
    'effect' => {
        data_type => 'Effect',
        description => 'Animation effect DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slide_animation_effect' } = { 
    	summary => 'Modify an animation effect for a slide.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub put_slide_animation_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slide_animation_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slide_animation_effect");
    }

    # verify the required parameter 'effect_index' is set
    unless (exists $args{'effect_index'}) {
      croak("Missing the required parameter 'effect_index' when calling put_slide_animation_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/mainSequence/{effectIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'effect_index'}) {
        my $_base_variable = "{" . "effectIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'effect_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'effect'}) {
        $_body_data = $args{'effect'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# put_slide_animation_interactive_sequence_effect
#
# Modify an animation effect for a slide interactive sequence.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param int $sequence_index The position of the interactive sequence. (required)
# @param int $effect_index The position of the effect to be modified. (required)
# @param Effect $effect Animation effect DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'sequence_index' => {
        data_type => 'int',
        description => 'The position of the interactive sequence.',
        required => '1',
    },
    'effect_index' => {
        data_type => 'int',
        description => 'The position of the effect to be modified.',
        required => '1',
    },
    'effect' => {
        data_type => 'Effect',
        description => 'Animation effect DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slide_animation_interactive_sequence_effect' } = { 
    	summary => 'Modify an animation effect for a slide interactive sequence.',
        params => $params,
        returns => 'SlideAnimation',
        };
}
# @return SlideAnimation
#
sub put_slide_animation_interactive_sequence_effect {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'sequence_index' is set
    unless (exists $args{'sequence_index'}) {
      croak("Missing the required parameter 'sequence_index' when calling put_slide_animation_interactive_sequence_effect");
    }

    # verify the required parameter 'effect_index' is set
    unless (exists $args{'effect_index'}) {
      croak("Missing the required parameter 'effect_index' when calling put_slide_animation_interactive_sequence_effect");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/animation/interactiveSequences/{sequenceIndex}/{effectIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'sequence_index'}) {
        my $_base_variable = "{" . "sequenceIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'sequence_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'effect_index'}) {
        my $_base_variable = "{" . "effectIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'effect_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'effect'}) {
        $_body_data = $args{'effect'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideAnimation', $response);
    return $_response_object;
}

#
# put_slide_save_as
#
# Save a slide to a specified format.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $format Output file format. (required)
# @param string $out_path Path to upload the output file to. (required)
# @param ExportOptions $options Export options. (optional)
# @param int $width Output file width; 0 to not adjust the size. Default is 0. (optional, default to 0)
# @param int $height Output file height; 0 to not adjust the size. Default is 0. (optional, default to 0)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
# @param string $fonts_folder Storage folder containing custom fonts to be used with the document. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Output file format.',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => 'Path to upload the output file to.',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => 'Export options.',
        required => '0',
    },
    'width' => {
        data_type => 'int',
        description => 'Output file width; 0 to not adjust the size. Default is 0.',
        required => '0',
    },
    'height' => {
        data_type => 'int',
        description => 'Output file height; 0 to not adjust the size. Default is 0.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Storage folder containing custom fonts to be used with the document.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slide_save_as' } = { 
    	summary => 'Save a slide to a specified format.',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub put_slide_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slide_save_as");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slide_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling put_slide_save_as");
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling put_slide_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/{format}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'width'} && defined $args{'width'}) {
        $query_params->{'width'} = $self->{api_client}->to_query_value($args{'width'});
    }

    # query params
    if (exists $args{'height'} && defined $args{'height'}) {
        $query_params->{'height'} = $self->{api_client}->to_query_value($args{'height'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# put_slide_shape_info
#
# Update shape properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param ShapeBase $dto Shape DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'dto' => {
        data_type => 'ShapeBase',
        description => 'Shape DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slide_shape_info' } = { 
    	summary => 'Update shape properties.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub put_slide_shape_info {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slide_shape_info");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slide_shape_info");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_slide_shape_info");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_slide_shape_info");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/shapes/{path}/{shapeIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# put_slides_convert
#
# Convert presentation from request content to format specified.
# 
# @param string $format Export format. (required)
# @param string $out_path Path to save result. (required)
# @param File $document Document data. (optional)
# @param string $password Document password. (optional)
# @param string $fonts_folder Custom fonts folder. (optional)
{
    my $params = {
    'format' => {
        data_type => 'string',
        description => 'Export format.',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => 'Path to save result.',
        required => '1',
    },
    'document' => {
        data_type => 'File',
        description => 'Document data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Custom fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_convert' } = { 
    	summary => 'Convert presentation from request content to format specified.',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub put_slides_convert {
    my ($self, %args) = @_;

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling put_slides_convert");
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling put_slides_convert");
    }

    # parse inputs
    my $_resource_path = '/slides/convert/{format}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/octet-stream', 'multipart/form-data');

    # query params
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'document'}) {
        $_body_data = $args{'document'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# put_slides_document_from_html
#
# Update presentation document from html.
# 
# @param string $name Document name. (required)
# @param string $html HTML data. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'html' => {
        data_type => 'string',
        description => 'HTML data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_document_from_html' } = { 
    	summary => 'Update presentation document from html.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub put_slides_document_from_html {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_document_from_html");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/fromHtml';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'html'}) {
        $_body_data = $args{'html'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# put_slides_save_as
#
# Save a presentation to a specified format.
# 
# @param string $name Document name. (required)
# @param string $out_path Output path. (required)
# @param string $format Export format. (required)
# @param ExportOptions $options Export options. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
# @param string $fonts_folder Custom fonts folder. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => 'Output path.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => 'Export format.',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => 'Export options.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => 'Custom fonts folder.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_save_as' } = { 
    	summary => 'Save a presentation to a specified format.',
        params => $params,
        returns => undef,
        };
}
# @return void
#
sub put_slides_save_as {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_save_as");
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling put_slides_save_as");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'}) {
      croak("Missing the required parameter 'format' when calling put_slides_save_as");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/{format}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    return;
}

#
# put_slides_set_document_property
#
# Set document property.
# 
# @param string $name Document name. (required)
# @param string $property_name The property name. (required)
# @param DocumentProperty $property Property with the value. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'property_name' => {
        data_type => 'string',
        description => 'The property name.',
        required => '1',
    },
    'property' => {
        data_type => 'DocumentProperty',
        description => 'Property with the value.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_set_document_property' } = { 
    	summary => 'Set document property.',
        params => $params,
        returns => 'DocumentProperty',
        };
}
# @return DocumentProperty
#
sub put_slides_set_document_property {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_set_document_property");
    }

    # verify the required parameter 'property_name' is set
    unless (exists $args{'property_name'}) {
      croak("Missing the required parameter 'property_name' when calling put_slides_set_document_property");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/documentproperties/{propertyName}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'property_name'}) {
        my $_base_variable = "{" . "propertyName" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'property_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'property'}) {
        $_body_data = $args{'property'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('DocumentProperty', $response);
    return $_response_object;
}

#
# put_slides_slide
#
# Update a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param Slide $slide_dto Slide update data. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'slide_dto' => {
        data_type => 'Slide',
        description => 'Slide update data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_slide' } = { 
    	summary => 'Update a slide.',
        params => $params,
        returns => 'Slide',
        };
}
# @return Slide
#
sub put_slides_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slides_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'slide_dto'}) {
        $_body_data = $args{'slide_dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Slide', $response);
    return $_response_object;
}

#
# put_slides_slide_background
#
# Set background for a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param SlideBackground $background Slide background update data. (optional)
# @param string $folder Document folder. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'background' => {
        data_type => 'SlideBackground',
        description => 'Slide background update data.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_slide_background' } = { 
    	summary => 'Set background for a slide.',
        params => $params,
        returns => 'SlideBackground',
        };
}
# @return SlideBackground
#
sub put_slides_slide_background {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_slide_background");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slides_slide_background");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/background';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'background'}) {
        $_body_data = $args{'background'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideBackground', $response);
    return $_response_object;
}

#
# put_slides_slide_background_color
#
# Set background color for a slide.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $color Slide background target color in RRGGBB format. (required)
# @param string $folder Document folder. (optional)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'color' => {
        data_type => 'string',
        description => 'Slide background target color in RRGGBB format.',
        required => '1',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_slide_background_color' } = { 
    	summary => 'Set background color for a slide.',
        params => $params,
        returns => 'SlideBackground',
        };
}
# @return SlideBackground
#
sub put_slides_slide_background_color {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_slide_background_color");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_slides_slide_background_color");
    }

    # verify the required parameter 'color' is set
    unless (exists $args{'color'}) {
      croak("Missing the required parameter 'color' when calling put_slides_slide_background_color");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/backgroundColor';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'color'} && defined $args{'color'}) {
        $query_params->{'color'} = $self->{api_client}->to_query_value($args{'color'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('SlideBackground', $response);
    return $_response_object;
}

#
# put_slides_slide_size
#
# Set slide size for a presentation.
# 
# @param string $name Document name. (required)
# @param string $password Document password. (optional)
# @param string $storage Document storage. (optional)
# @param string $folder Document folder. (optional)
# @param int $width Slide width. (optional, default to 0)
# @param int $height Slide height. (optional, default to 0)
# @param string $size_type Standard slide size type. (optional)
# @param string $scale_type Standard slide scale type. (optional, default to 0)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'width' => {
        data_type => 'int',
        description => 'Slide width.',
        required => '0',
    },
    'height' => {
        data_type => 'int',
        description => 'Slide height.',
        required => '0',
    },
    'size_type' => {
        data_type => 'string',
        description => 'Standard slide size type.',
        required => '0',
    },
    'scale_type' => {
        data_type => 'string',
        description => 'Standard slide scale type.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_slides_slide_size' } = { 
    	summary => 'Set slide size for a presentation.',
        params => $params,
        returns => 'Document',
        };
}
# @return Document
#
sub put_slides_slide_size {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_slides_slide_size");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slideSize';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'width'} && defined $args{'width'}) {
        $query_params->{'width'} = $self->{api_client}->to_query_value($args{'width'});
    }

    # query params
    if (exists $args{'height'} && defined $args{'height'}) {
        $query_params->{'height'} = $self->{api_client}->to_query_value($args{'height'});
    }

    # query params
    if (exists $args{'size_type'} && defined $args{'size_type'}) {
        $query_params->{'sizeType'} = $self->{api_client}->to_query_value($args{'size_type'});
    }

    # query params
    if (exists $args{'scale_type'} && defined $args{'scale_type'}) {
        $query_params->{'scaleType'} = $self->{api_client}->to_query_value($args{'scale_type'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Document', $response);
    return $_response_object;
}

#
# put_update_notes_slide
#
# Update notes slide properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param NotesSlide $dto A NotesSlide object with notes slide data. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'dto' => {
        data_type => 'NotesSlide',
        description => 'A NotesSlide object with notes slide data.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_update_notes_slide' } = { 
    	summary => 'Update notes slide properties.',
        params => $params,
        returns => 'NotesSlide',
        };
}
# @return NotesSlide
#
sub put_update_notes_slide {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_update_notes_slide");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_update_notes_slide");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('NotesSlide', $response);
    return $_response_object;
}

#
# put_update_notes_slide_shape
#
# Update shape properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param ShapeBase $dto Shape DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'dto' => {
        data_type => 'ShapeBase',
        description => 'Shape DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_update_notes_slide_shape' } = { 
    	summary => 'Update shape properties.',
        params => $params,
        returns => 'ShapeBase',
        };
}
# @return ShapeBase
#
sub put_update_notes_slide_shape {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_update_notes_slide_shape");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_update_notes_slide_shape");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_update_notes_slide_shape");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_update_notes_slide_shape");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('ShapeBase', $response);
    return $_response_object;
}

#
# put_update_notes_slide_shape_paragraph
#
# Update paragraph properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param Paragraph $dto Paragraph DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Paragraph',
        description => 'Paragraph DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_update_notes_slide_shape_paragraph' } = { 
    	summary => 'Update paragraph properties.',
        params => $params,
        returns => 'Paragraph',
        };
}
# @return Paragraph
#
sub put_update_notes_slide_shape_paragraph {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_update_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_update_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_update_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_update_notes_slide_shape_paragraph");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling put_update_notes_slide_shape_paragraph");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Paragraph', $response);
    return $_response_object;
}

#
# put_update_notes_slide_shape_portion
#
# Update portion properties.
# 
# @param string $name Document name. (required)
# @param int $slide_index Slide index. (required)
# @param string $path Shape path (for smart art and group shapes). (required)
# @param int $shape_index Shape index. (required)
# @param int $paragraph_index Paragraph index. (required)
# @param int $portion_index Portion index. (required)
# @param Portion $dto Portion DTO. (optional)
# @param string $password Document password. (optional)
# @param string $folder Document folder. (optional)
# @param string $storage Document storage. (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => 'Document name.',
        required => '1',
    },
    'slide_index' => {
        data_type => 'int',
        description => 'Slide index.',
        required => '1',
    },
    'path' => {
        data_type => 'string',
        description => 'Shape path (for smart art and group shapes).',
        required => '1',
    },
    'shape_index' => {
        data_type => 'int',
        description => 'Shape index.',
        required => '1',
    },
    'paragraph_index' => {
        data_type => 'int',
        description => 'Paragraph index.',
        required => '1',
    },
    'portion_index' => {
        data_type => 'int',
        description => 'Portion index.',
        required => '1',
    },
    'dto' => {
        data_type => 'Portion',
        description => 'Portion DTO.',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => 'Document password.',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => 'Document folder.',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => 'Document storage.',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'put_update_notes_slide_shape_portion' } = { 
    	summary => 'Update portion properties.',
        params => $params,
        returns => 'Portion',
        };
}
# @return Portion
#
sub put_update_notes_slide_shape_portion {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'}) {
      croak("Missing the required parameter 'name' when calling put_update_notes_slide_shape_portion");
    }

    # verify the required parameter 'slide_index' is set
    unless (exists $args{'slide_index'}) {
      croak("Missing the required parameter 'slide_index' when calling put_update_notes_slide_shape_portion");
    }

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling put_update_notes_slide_shape_portion");
    }

    # verify the required parameter 'shape_index' is set
    unless (exists $args{'shape_index'}) {
      croak("Missing the required parameter 'shape_index' when calling put_update_notes_slide_shape_portion");
    }

    # verify the required parameter 'paragraph_index' is set
    unless (exists $args{'paragraph_index'}) {
      croak("Missing the required parameter 'paragraph_index' when calling put_update_notes_slide_shape_portion");
    }

    # verify the required parameter 'portion_index' is set
    unless (exists $args{'portion_index'}) {
      croak("Missing the required parameter 'portion_index' when calling put_update_notes_slide_shape_portion");
    }

    # parse inputs
    my $_resource_path = '/slides/{name}/slides/{slideIndex}/notesSlide/shapes/{path}/{shapeIndex}/paragraphs/{paragraphIndex}/portions/{portionIndex}';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # query params
    if (exists $args{'password'} && defined $args{'password'}) {
        $query_params->{'password'} = $self->{api_client}->to_query_value($args{'password'});
    }

    # query params
    if (exists $args{'folder'} && defined $args{'folder'}) {
        $query_params->{'folder'} = $self->{api_client}->to_query_value($args{'folder'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # path params
    if ( exists $args{'name'}) {
        my $_base_variable = "{" . "name" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'slide_index'}) {
        my $_base_variable = "{" . "slideIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'slide_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'shape_index'}) {
        my $_base_variable = "{" . "shapeIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'shape_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'paragraph_index'}) {
        my $_base_variable = "{" . "paragraphIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'paragraph_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    # path params
    if ( exists $args{'portion_index'}) {
        my $_base_variable = "{" . "portionIndex" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'portion_index'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # body params
    if ( exists $args{'dto'}) {
        $_body_data = $args{'dto'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Portion', $response);
    return $_response_object;
}

#
# storage_exists
#
# Check if storage exists
# 
# @param string $storage_name Storage name (required)
{
    my $params = {
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'storage_exists' } = { 
    	summary => 'Check if storage exists',
        params => $params,
        returns => 'StorageExist',
        };
}
# @return StorageExist
#
sub storage_exists {
    my ($self, %args) = @_;

    # verify the required parameter 'storage_name' is set
    unless (exists $args{'storage_name'}) {
      croak("Missing the required parameter 'storage_name' when calling storage_exists");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/{storageName}/exist';

    my $_method = 'GET';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};

    # 'Accept' and 'Content-Type' header
    my $_header_accept = $self->{api_client}->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $self->{api_client}->select_header_content_type('application/json');

    # path params
    if ( exists $args{'storage_name'}) {
        my $_base_variable = "{" . "storageName" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'storage_name'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('StorageExist', $response);
    return $_response_object;
}

#
# upload_file
#
# Upload file
# 
# @param string $path Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.              (required)
# @param File $file File to upload (required)
# @param string $storage_name Storage name (optional)
{
    my $params = {
    'path' => {
        data_type => 'string',
        description => 'Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.             ',
        required => '1',
    },
    'file' => {
        data_type => 'File',
        description => 'File to upload',
        required => '1',
    },
    'storage_name' => {
        data_type => 'string',
        description => 'Storage name',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'upload_file' } = { 
    	summary => 'Upload file',
        params => $params,
        returns => 'FilesUploadResult',
        };
}
# @return FilesUploadResult
#
sub upload_file {
    my ($self, %args) = @_;

    # verify the required parameter 'path' is set
    unless (exists $args{'path'}) {
      croak("Missing the required parameter 'path' when calling upload_file");
    }

    # verify the required parameter 'file' is set
    unless (exists $args{'file'}) {
      croak("Missing the required parameter 'file' when calling upload_file");
    }

    # parse inputs
    my $_resource_path = '/slides/storage/file/{path}';

    my $_method = 'PUT';
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
    if (exists $args{'storage_name'} && defined $args{'storage_name'}) {
        $query_params->{'storageName'} = $self->{api_client}->to_query_value($args{'storage_name'});
    }

    # path params
    if ( exists $args{'path'}) {
        my $_base_variable = "{" . "path" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'path'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    # form params
    if ( exists $args{'file'} ) {
        $_body_data = $args{'file'};
    }

    # authentication setting, if any
    my $auth_settings = [qw(JWT )];

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $auth_settings);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('FilesUploadResult', $response);
    return $_response_object;
}

1;
