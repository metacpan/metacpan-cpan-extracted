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

package AsposeCellsCloud::Request::ExtractTextRequest;

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
# ExtractTextRequest.Spreadsheet : Upload spreadsheet file.  ,
# ExtractTextRequest.extractTextType : Indicates extract text type.  ,
# ExtractTextRequest.beforeText : Indicates extracting the text before the specified characters or substrings.  ,
# ExtractTextRequest.afterText : Indicates extracting the text after the specified characters or substrings.  ,
# ExtractTextRequest.beforePosition : Indicates retrieving the first character or a specified number of characters from the left side of the selected cell.  ,
# ExtractTextRequest.afterPosition : Indicates retrieving the first character or a specified number of characters from the right side of the selected cell.  ,
# ExtractTextRequest.outPositionRange : Indicates the output location for the extracted text.  ,
# ExtractTextRequest.worksheet : Specify the worksheet of spreadsheet.  ,
# ExtractTextRequest.range : Specify the worksheet range of spreadsheet.  ,
# ExtractTextRequest.outPath : (Optional) The folder path where the workbook is stored. The default is null.  ,
# ExtractTextRequest.outStorageName : Output file Storage Name.  ,
# ExtractTextRequest.region : The spreadsheet region setting.  ,
# ExtractTextRequest.password : The password for opening spreadsheet file.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'extract_text' } = { 
    	summary => 'Indicates extracting substrings, text characters, and numbers from a spreadsheet cell into another cell without having to use complex FIND, MIN, LEFT, or RIGHT formulas.',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v4.0/cells/content/extract/text';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->extract_text_type){
        $query_params->{'extractTextType'} = $client->to_query_value($self->extract_text_type);      
    }

    if(defined $self->before_text){
        $query_params->{'beforeText'} = $client->to_query_value($self->before_text);      
    }

    if(defined $self->after_text){
        $query_params->{'afterText'} = $client->to_query_value($self->after_text);      
    }

    if(defined $self->before_position){
        $query_params->{'beforePosition'} = $client->to_query_value($self->before_position);      
    }

    if(defined $self->after_position){
        $query_params->{'afterPosition'} = $client->to_query_value($self->after_position);      
    }

    if(defined $self->out_position_range){
        $query_params->{'outPositionRange'} = $client->to_query_value($self->out_position_range);      
    }

    if(defined $self->worksheet){
        $query_params->{'worksheet'} = $client->to_query_value($self->worksheet);      
    }

    if(defined $self->range){
        $query_params->{'range'} = $client->to_query_value($self->range);      
    }

    if(defined $self->out_path){
        $query_params->{'outPath'} = $client->to_query_value($self->out_path);      
    }

    if(defined $self->out_storage_name){
        $query_params->{'outStorageName'} = $client->to_query_value($self->out_storage_name);      
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
     'extract_text_type' => {
     	datatype => 'string',
     	base_name => 'extractTextType',
     	description => 'Indicates extract text type.',
     	format => '',
     	read_only => '',
     		},
     'before_text' => {
     	datatype => 'string',
     	base_name => 'beforeText',
     	description => 'Indicates extracting the text before the specified characters or substrings.',
     	format => '',
     	read_only => '',
     		},
     'after_text' => {
     	datatype => 'string',
     	base_name => 'afterText',
     	description => 'Indicates extracting the text after the specified characters or substrings.',
     	format => '',
     	read_only => '',
     		},
     'before_position' => {
     	datatype => 'int',
     	base_name => 'beforePosition',
     	description => 'Indicates retrieving the first character or a specified number of characters from the left side of the selected cell.',
     	format => '',
     	read_only => '',
     		},
     'after_position' => {
     	datatype => 'int',
     	base_name => 'afterPosition',
     	description => 'Indicates retrieving the first character or a specified number of characters from the right side of the selected cell.',
     	format => '',
     	read_only => '',
     		},
     'out_position_range' => {
     	datatype => 'string',
     	base_name => 'outPositionRange',
     	description => 'Indicates the output location for the extracted text.',
     	format => '',
     	read_only => '',
     		},
     'worksheet' => {
     	datatype => 'string',
     	base_name => 'worksheet',
     	description => 'Specify the worksheet of spreadsheet.',
     	format => '',
     	read_only => '',
     		},
     'range' => {
     	datatype => 'string',
     	base_name => 'range',
     	description => 'Specify the worksheet range of spreadsheet.',
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
    'extract_text_type' => 'extractTextType',
    'before_text' => 'beforeText',
    'after_text' => 'afterText',
    'before_position' => 'beforePosition',
    'after_position' => 'afterPosition',
    'out_position_range' => 'outPositionRange',
    'worksheet' => 'worksheet',
    'range' => 'range',
    'out_path' => 'outPath',
    'out_storage_name' => 'outStorageName',
    'region' => 'region',
    'password' => 'password' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;