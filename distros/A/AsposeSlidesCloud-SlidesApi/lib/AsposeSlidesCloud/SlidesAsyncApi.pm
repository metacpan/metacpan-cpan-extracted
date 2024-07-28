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

package AsposeSlidesCloud::SlidesAsyncApi;

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
# get_operation_result
#
# 
# 
# @param string $id  (required)
{
    my $params = {
    'id' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_operation_result' } = { 
    	summary => '',
        params => $params,
        returns => 'File',
        };
}
# @return File
#
sub get_operation_result {
    my ($self, %args) = @_;

    # verify the required parameter 'id' is set
    unless (exists $args{'id'} && defined $args{'id'} && $args{'id'}) {
      croak("Missing the required parameter 'id' when calling get_operation_result");
    }

    # parse inputs
    my $_resource_path = '/slides/async/{id}/result';

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

    # path params
    if ( exists $args{'id'}) {
        my $_base_variable = "{" . "id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    my $files = [];
    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('File', $response);
    return $_response_object;
}

#
# get_operation_status
#
# 
# 
# @param string $id  (required)
{
    my $params = {
    'id' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    };
    __PACKAGE__->method_documentation->{ 'get_operation_status' } = { 
    	summary => '',
        params => $params,
        returns => 'Operation',
        };
}
# @return Operation
#
sub get_operation_status {
    my ($self, %args) = @_;

    # verify the required parameter 'id' is set
    unless (exists $args{'id'} && defined $args{'id'} && $args{'id'}) {
      croak("Missing the required parameter 'id' when calling get_operation_status");
    }

    # parse inputs
    my $_resource_path = '/slides/async/{id}';

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
    if ( exists $args{'id'}) {
        my $_base_variable = "{" . "id" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'id'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    my $files = [];
    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('Operation', $response);
    return $_response_object;
}

#
# start_convert
#
# 
# 
# @param File $document Document data. (required)
# @param string $format  (required)
# @param string $password  (optional)
# @param string $storage  (optional)
# @param string $fonts_folder  (optional)
# @param int[] $slides  (optional)
# @param ExportOptions $options  (optional)
{
    my $params = {
    'document' => {
        data_type => 'File',
        description => 'Document data.',
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
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'slides' => {
        data_type => 'int[]',
        description => '',
        required => '0',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_convert' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_convert {
    my ($self, %args) = @_;

    # verify the required parameter 'document' is set
    unless (exists $args{'document'} && defined $args{'document'} && $args{'document'}) {
      croak("Missing the required parameter 'document' when calling start_convert");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'} && defined $args{'format'} && $args{'format'}) {
      croak("Missing the required parameter 'format' when calling start_convert");
    }

    # verify enum value
    if (!grep(/^$args{'format'}$/i, ( 'Pdf', 'Xps', 'Tiff', 'Pptx', 'Odp', 'Otp', 'Ppt', 'Pps', 'Ppsx', 'Pptm', 'Ppsm', 'Pot', 'Potx', 'Potm', 'Html', 'Html5', 'Swf', 'Svg', 'Jpeg', 'Png', 'Gif', 'Bmp', 'Fodp', 'Xaml', 'Mpeg4', 'Md', 'Xml' ))) {
      croak("Invalid value for 'format': " . $args{'format'});
    }

    # parse inputs
    my $_resource_path = '/slides/async/convert/{format}';

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
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # query params
    if (exists $args{'slides'} && defined $args{'slides'}) {
        $query_params->{'slides'} = $self->{api_client}->to_query_value($args{'slides'});
    }

    # header params
    if ( exists $args{'password'}) {
        $header_params->{':password'} = $self->{api_client}->to_header_value($args{'password'});
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    my $files = [];
    if ( exists $args{'document'} && $args{'document'}) {
        push(@$files, $args{'document'});
    }
    # body params
    if ( exists $args{'options'} && $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# start_convert_and_save
#
# 
# 
# @param File $document Document data. (required)
# @param string $format  (required)
# @param string $out_path  (required)
# @param string $password  (optional)
# @param string $storage  (optional)
# @param string $fonts_folder  (optional)
# @param int[] $slides  (optional)
# @param ExportOptions $options  (optional)
{
    my $params = {
    'document' => {
        data_type => 'File',
        description => 'Document data.',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'slides' => {
        data_type => 'int[]',
        description => '',
        required => '0',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_convert_and_save' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_convert_and_save {
    my ($self, %args) = @_;

    # verify the required parameter 'document' is set
    unless (exists $args{'document'} && defined $args{'document'} && $args{'document'}) {
      croak("Missing the required parameter 'document' when calling start_convert_and_save");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'} && defined $args{'format'} && $args{'format'}) {
      croak("Missing the required parameter 'format' when calling start_convert_and_save");
    }

    # verify enum value
    if (!grep(/^$args{'format'}$/i, ( 'Pdf', 'Xps', 'Tiff', 'Pptx', 'Odp', 'Otp', 'Ppt', 'Pps', 'Ppsx', 'Pptm', 'Ppsm', 'Pot', 'Potx', 'Potm', 'Html', 'Html5', 'Swf', 'Svg', 'Jpeg', 'Png', 'Gif', 'Bmp', 'Fodp', 'Xaml', 'Mpeg4', 'Md', 'Xml' ))) {
      croak("Invalid value for 'format': " . $args{'format'});
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'} && defined $args{'out_path'} && $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling start_convert_and_save");
    }

    # parse inputs
    my $_resource_path = '/slides/async/convert/{format}';

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
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    # query params
    if (exists $args{'fonts_folder'} && defined $args{'fonts_folder'}) {
        $query_params->{'fontsFolder'} = $self->{api_client}->to_query_value($args{'fonts_folder'});
    }

    # query params
    if (exists $args{'slides'} && defined $args{'slides'}) {
        $query_params->{'slides'} = $self->{api_client}->to_query_value($args{'slides'});
    }

    # header params
    if ( exists $args{'password'}) {
        $header_params->{':password'} = $self->{api_client}->to_header_value($args{'password'});
    }

    # path params
    if ( exists $args{'format'}) {
        my $_base_variable = "{" . "format" . "}";
        my $_base_value = $self->{api_client}->to_path_value($args{'format'});
        $_resource_path =~ s/$_base_variable/$_base_value/g;
    }

    my $_body_data;
    my $files = [];
    if ( exists $args{'document'} && $args{'document'}) {
        push(@$files, $args{'document'});
    }
    # body params
    if ( exists $args{'options'} && $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# start_download_presentation
#
# 
# 
# @param string $name  (required)
# @param string $format  (required)
# @param ExportOptions $options  (optional)
# @param string $password  (optional)
# @param string $folder  (optional)
# @param string $storage  (optional)
# @param string $fonts_folder  (optional)
# @param int[] $slides  (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => '',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'slides' => {
        data_type => 'int[]',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_download_presentation' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_download_presentation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'} && defined $args{'name'} && $args{'name'}) {
      croak("Missing the required parameter 'name' when calling start_download_presentation");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'} && defined $args{'format'} && $args{'format'}) {
      croak("Missing the required parameter 'format' when calling start_download_presentation");
    }

    # verify enum value
    if (!grep(/^$args{'format'}$/i, ( 'Pdf', 'Xps', 'Tiff', 'Pptx', 'Odp', 'Otp', 'Ppt', 'Pps', 'Ppsx', 'Pptm', 'Ppsm', 'Pot', 'Potx', 'Potm', 'Html', 'Html5', 'Swf', 'Svg', 'Jpeg', 'Png', 'Gif', 'Bmp', 'Fodp', 'Xaml', 'Mpeg4', 'Md', 'Xml' ))) {
      croak("Invalid value for 'format': " . $args{'format'});
    }

    # parse inputs
    my $_resource_path = '/slides/async/{name}/{format}';

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

    # query params
    if (exists $args{'slides'} && defined $args{'slides'}) {
        $query_params->{'slides'} = $self->{api_client}->to_query_value($args{'slides'});
    }

    # header params
    if ( exists $args{'password'}) {
        $header_params->{':password'} = $self->{api_client}->to_header_value($args{'password'});
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
    my $files = [];
    # body params
    if ( exists $args{'options'} && $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# start_merge
#
# 
# 
# @param ARRAY[string] $files Files to merge (optional)
# @param OrderedMergeRequest $request  (optional)
# @param string $storage  (optional)
{
    my $params = {
    'files' => {
        data_type => 'ARRAY[string]',
        description => 'Files to merge',
        required => '0',
    },
    'request' => {
        data_type => 'OrderedMergeRequest',
        description => '',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_merge' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_merge {
    my ($self, %args) = @_;

    # parse inputs
    my $_resource_path = '/slides/async/merge';

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
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    my $_body_data;
    my $files = [];
    if ( exists $args{'files'} && $args{'files'}) {
        my $arg_files = $args{'files'};
        push(@$files, @$arg_files);
    }
    # body params
    if ( exists $args{'request'} && $args{'request'}) {
        $_body_data = $args{'request'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# start_merge_and_save
#
# 
# 
# @param string $out_path  (required)
# @param ARRAY[string] $files Files to merge (optional)
# @param OrderedMergeRequest $request  (optional)
# @param string $storage  (optional)
{
    my $params = {
    'out_path' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'files' => {
        data_type => 'ARRAY[string]',
        description => 'Files to merge',
        required => '0',
    },
    'request' => {
        data_type => 'OrderedMergeRequest',
        description => '',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_merge_and_save' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_merge_and_save {
    my ($self, %args) = @_;

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'} && defined $args{'out_path'} && $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling start_merge_and_save");
    }

    # parse inputs
    my $_resource_path = '/slides/async/merge';

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
    if (exists $args{'out_path'} && defined $args{'out_path'}) {
        $query_params->{'outPath'} = $self->{api_client}->to_query_value($args{'out_path'});
    }

    # query params
    if (exists $args{'storage'} && defined $args{'storage'}) {
        $query_params->{'storage'} = $self->{api_client}->to_query_value($args{'storage'});
    }

    my $_body_data;
    my $files = [];
    if ( exists $args{'files'} && $args{'files'}) {
        my $arg_files = $args{'files'};
        push(@$files, @$arg_files);
    }
    # body params
    if ( exists $args{'request'} && $args{'request'}) {
        $_body_data = $args{'request'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

#
# start_save_presentation
#
# 
# 
# @param string $name  (required)
# @param string $format  (required)
# @param string $out_path  (required)
# @param ExportOptions $options  (optional)
# @param string $password  (optional)
# @param string $folder  (optional)
# @param string $storage  (optional)
# @param string $fonts_folder  (optional)
# @param int[] $slides  (optional)
{
    my $params = {
    'name' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'format' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'out_path' => {
        data_type => 'string',
        description => '',
        required => '1',
    },
    'options' => {
        data_type => 'ExportOptions',
        description => '',
        required => '0',
    },
    'password' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'storage' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'fonts_folder' => {
        data_type => 'string',
        description => '',
        required => '0',
    },
    'slides' => {
        data_type => 'int[]',
        description => '',
        required => '0',
    },
    };
    __PACKAGE__->method_documentation->{ 'start_save_presentation' } = { 
    	summary => '',
        params => $params,
        returns => 'string',
        };
}
# @return string
#
sub start_save_presentation {
    my ($self, %args) = @_;

    # verify the required parameter 'name' is set
    unless (exists $args{'name'} && defined $args{'name'} && $args{'name'}) {
      croak("Missing the required parameter 'name' when calling start_save_presentation");
    }

    # verify the required parameter 'format' is set
    unless (exists $args{'format'} && defined $args{'format'} && $args{'format'}) {
      croak("Missing the required parameter 'format' when calling start_save_presentation");
    }

    # verify enum value
    if (!grep(/^$args{'format'}$/i, ( 'Pdf', 'Xps', 'Tiff', 'Pptx', 'Odp', 'Otp', 'Ppt', 'Pps', 'Ppsx', 'Pptm', 'Ppsm', 'Pot', 'Potx', 'Potm', 'Html', 'Html5', 'Swf', 'Svg', 'Jpeg', 'Png', 'Gif', 'Bmp', 'Fodp', 'Xaml', 'Mpeg4', 'Md', 'Xml' ))) {
      croak("Invalid value for 'format': " . $args{'format'});
    }

    # verify the required parameter 'out_path' is set
    unless (exists $args{'out_path'} && defined $args{'out_path'} && $args{'out_path'}) {
      croak("Missing the required parameter 'out_path' when calling start_save_presentation");
    }

    # parse inputs
    my $_resource_path = '/slides/async/{name}/{format}';

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

    # query params
    if (exists $args{'slides'} && defined $args{'slides'}) {
        $query_params->{'slides'} = $self->{api_client}->to_query_value($args{'slides'});
    }

    # header params
    if ( exists $args{'password'}) {
        $header_params->{':password'} = $self->{api_client}->to_header_value($args{'password'});
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
    my $files = [];
    # body params
    if ( exists $args{'options'} && $args{'options'}) {
        $_body_data = $args{'options'};
    }

    # make the API Call
    my $response = $self->{api_client}->call_api($_resource_path, $_method,
                                           $query_params, $form_params,
                                           $header_params, $_body_data, $files);
    if (!$response) {
        return;
    }
    my $_response_object = $self->{api_client}->deserialize('string', $response);
    return $_response_object;
}

1;
