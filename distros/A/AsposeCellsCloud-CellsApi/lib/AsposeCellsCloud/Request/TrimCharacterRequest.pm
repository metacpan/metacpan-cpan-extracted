=begin comment

Copyright (c) 2026 Aspose.Cells Cloud
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

package AsposeCellsCloud::Request::TrimCharacterRequest;

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
# TrimCharacterRequest.Spreadsheet : Upload spreadsheet file.  ,
# TrimCharacterRequest.trimContent : Specify the trim content.  ,
# TrimCharacterRequest.trimLeading : Specify to trim content from the beginning.  ,
# TrimCharacterRequest.trimTrailing : Specify to trim content from the end.  ,
# TrimCharacterRequest.trimSpaceBetweenWordTo1 : Remove excess spaces between words within a cell.  ,
# TrimCharacterRequest.trimNonBreakingSpaces : Remove non-breaking spaces.  ,
# TrimCharacterRequest.removeExtraLineBreaks : Remove extra line breaks.  ,
# TrimCharacterRequest.removeAllLineBreaks : Remove all line breaks.  ,
# TrimCharacterRequest.worksheet : Specify the worksheet of spreadsheet.  ,
# TrimCharacterRequest.range : Specify the worksheet range of spreadsheet.  ,
# TrimCharacterRequest.outPath : (Optional) The folder path where the workbook is stored. The default is null.  ,
# TrimCharacterRequest.outStorageName : Output file Storage Name.  ,
# TrimCharacterRequest.region : The spreadsheet region setting.  ,
# TrimCharacterRequest.password : The password for opening spreadsheet file.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'trim_character' } = { 
    	summary => 'The TrimSpreadsheetContent API is designed to process and trim content within a spreadsheet. This API allows users to remove extra spaces, line breaks, or other unnecessary characters from the content of selected cells. It is particularly useful for cleaning up data entries and ensuring consistency in spreadsheet formatting',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v4.0/cells/content/trim';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->trim_content){
        $query_params->{'trimContent'} = $client->to_query_value($self->trim_content);      
    }

    if(defined $self->trim_leading){
        $query_params->{'trimLeading'} = $client->to_query_value($self->trim_leading);      
    }

    if(defined $self->trim_trailing){
        $query_params->{'trimTrailing'} = $client->to_query_value($self->trim_trailing);      
    }

    if(defined $self->trim_space_between_word_to1){
        $query_params->{'trimSpaceBetweenWordTo1'} = $client->to_query_value($self->trim_space_between_word_to1);      
    }

    if(defined $self->trim_non_breaking_spaces){
        $query_params->{'trimNonBreakingSpaces'} = $client->to_query_value($self->trim_non_breaking_spaces);      
    }

    if(defined $self->remove_extra_line_breaks){
        $query_params->{'removeExtraLineBreaks'} = $client->to_query_value($self->remove_extra_line_breaks);      
    }

    if(defined $self->remove_all_line_breaks){
        $query_params->{'removeAllLineBreaks'} = $client->to_query_value($self->remove_all_line_breaks);      
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
     'trim_content' => {
     	datatype => 'string',
     	base_name => 'trimContent',
     	description => 'Specify the trim content.',
     	format => '',
     	read_only => '',
     		},
     'trim_leading' => {
     	datatype => 'string',
     	base_name => 'trimLeading',
     	description => 'Specify to trim content from the beginning.',
     	format => '',
     	read_only => '',
     		},
     'trim_trailing' => {
     	datatype => 'string',
     	base_name => 'trimTrailing',
     	description => 'Specify to trim content from the end.',
     	format => '',
     	read_only => '',
     		},
     'trim_space_between_word_to1' => {
     	datatype => 'string',
     	base_name => 'trimSpaceBetweenWordTo1',
     	description => 'Remove excess spaces between words within a cell.',
     	format => '',
     	read_only => '',
     		},
     'trim_non_breaking_spaces' => {
     	datatype => 'string',
     	base_name => 'trimNonBreakingSpaces',
     	description => 'Remove non-breaking spaces.',
     	format => '',
     	read_only => '',
     		},
     'remove_extra_line_breaks' => {
     	datatype => 'string',
     	base_name => 'removeExtraLineBreaks',
     	description => 'Remove extra line breaks.',
     	format => '',
     	read_only => '',
     		},
     'remove_all_line_breaks' => {
     	datatype => 'string',
     	base_name => 'removeAllLineBreaks',
     	description => 'Remove all line breaks.',
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
    'trim_content' => 'trimContent',
    'trim_leading' => 'trimLeading',
    'trim_trailing' => 'trimTrailing',
    'trim_space_between_word_to1' => 'trimSpaceBetweenWordTo1',
    'trim_non_breaking_spaces' => 'trimNonBreakingSpaces',
    'remove_extra_line_breaks' => 'removeExtraLineBreaks',
    'remove_all_line_breaks' => 'removeAllLineBreaks',
    'worksheet' => 'worksheet',
    'range' => 'range',
    'out_path' => 'outPath',
    'out_storage_name' => 'outStorageName',
    'region' => 'region',
    'password' => 'password' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;