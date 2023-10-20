=begin comment

Copyright (c) 2023 Aspose.Cells Cloud
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

package AsposeCellsCloud::Request::PostRotateRequest;

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
# PostRotateRequest.File : 270/90/row/col/row2col  ,
# PostRotateRequest.rotateType : 270/90/row/col/row2col  ,
# PostRotateRequest.format : CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers  ,
# PostRotateRequest.password :   ,
# PostRotateRequest.checkExcelRestriction :    

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'post_rotate' } = { 
    	summary => 'Reverse rows or columns of Excel files, save as kinds of format files.',
        params => $params,
        returns => 'FilesResult',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = '/cells/rotate';

    my $_method = 'POST';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->rotate_type){
        $query_params->{'rotateType'} = $client->to_query_value($self->rotate_type);      
    }

    if(defined $self->format){
        $query_params->{'format'} = $client->to_query_value($self->format);      
    }

    if(defined $self->password){
        $query_params->{'password'} = $client->to_query_value($self->password);      
    }

    if(defined $self->check_excel_restriction){
        $query_params->{'checkExcelRestriction'} = $client->to_query_value($self->check_excel_restriction);      
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
     	description => '270/90/row/col/row2col',
     	format => '',
     	read_only => '',
     		},
     'rotate_type' => {
     	datatype => 'string',
     	base_name => 'rotateType',
     	description => '270/90/row/col/row2col',
     	format => '',
     	read_only => '',
     		},
     'format' => {
     	datatype => 'string',
     	base_name => 'format',
     	description => 'CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers',
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
     'check_excel_restriction' => {
     	datatype => 'string',
     	base_name => 'checkExcelRestriction',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});


__PACKAGE__->attribute_map( {
    'file' => 'File',
    'rotate_type' => 'rotateType',
    'format' => 'format',
    'password' => 'password',
    'check_excel_restriction' => 'checkExcelRestriction' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;