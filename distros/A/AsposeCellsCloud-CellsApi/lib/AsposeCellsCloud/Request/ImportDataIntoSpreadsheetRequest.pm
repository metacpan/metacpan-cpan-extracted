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

package AsposeCellsCloud::Request::ImportDataIntoSpreadsheetRequest;

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
# ImportDataIntoSpreadsheetRequest.datafile : Upload data file.  ,
# ImportDataIntoSpreadsheetRequest.Spreadsheet : Upload spreadsheet file.  ,
# ImportDataIntoSpreadsheetRequest.worksheet : Specify the worksheet for importing data  ,
# ImportDataIntoSpreadsheetRequest.startcell : Specify the starting position for importing data  ,
# ImportDataIntoSpreadsheetRequest.insert : The specified import data is for insertion and overwrite.  ,
# ImportDataIntoSpreadsheetRequest.convertNumericData : Specify whether to convert numerical data  ,
# ImportDataIntoSpreadsheetRequest.splitter : Specify the delimiter for the CSV format.  ,
# ImportDataIntoSpreadsheetRequest.outPath : (Optional) The folder path where the workbook is stored. The default is null.  ,
# ImportDataIntoSpreadsheetRequest.outStorageName : Output file Storage Name.  ,
# ImportDataIntoSpreadsheetRequest.fontsLocation : Use Custom fonts.  ,
# ImportDataIntoSpreadsheetRequest.region : The spreadsheet region setting.  ,
# ImportDataIntoSpreadsheetRequest.password : The password for opening spreadsheet file.   

{
    my $params = {
       'client' =>{
            data_type => 'ApiClient',
            description => 'API Client.',
            required => '0',
       }
    };
    __PACKAGE__->method_documentation->{ 'import_data_into_spreadsheet' } = { 
    	summary => 'Import data into a spreadsheet from a supported data file format.',
        params => $params,
        returns => 'string',
    };
}

sub run_http_request {
    my ($self, %args) = @_;

    my $client = $args{'client'};

    # parse inputs
    my $_resource_path = 'v4.0/cells/import/data';

    my $_method = 'PUT';
    my $query_params = {};
    my $header_params = {};
    my $form_params = {};


    my $_header_accept = $client->select_header_accept('application/json');
    if ($_header_accept) {
        $header_params->{'Accept'} = $_header_accept;
    }
    $header_params->{'Content-Type'} = $client->select_header_content_type('multipart/form-data');
 
    if(defined $self->worksheet){
        $query_params->{'worksheet'} = $client->to_query_value($self->worksheet);      
    }

    if(defined $self->startcell){
        $query_params->{'startcell'} = $client->to_query_value($self->startcell);      
    }

    if(defined $self->insert){
        $query_params->{'insert'} = $client->to_query_value($self->insert);      
    }

    if(defined $self->convert_numeric_data){
        $query_params->{'convertNumericData'} = $client->to_query_value($self->convert_numeric_data);      
    }

    if(defined $self->splitter){
        $query_params->{'splitter'} = $client->to_query_value($self->splitter);      
    }

    if(defined $self->out_path){
        $query_params->{'outPath'} = $client->to_query_value($self->out_path);      
    }

    if(defined $self->out_storage_name){
        $query_params->{'outStorageName'} = $client->to_query_value($self->out_storage_name);      
    }

    if(defined $self->fonts_location){
        $query_params->{'fontsLocation'} = $client->to_query_value($self->fonts_location);      
    }

    if(defined $self->region){
        $query_params->{'region'} = $client->to_query_value($self->region);      
    }

    if(defined $self->password){
        $query_params->{'password'} = $client->to_query_value($self->password);      
    } 
    my $_body_data;


    $form_params->{basename($self->datafile)} = [$self->datafile ,basename($self->datafile),'application/octet-stream'];


    $form_params->{basename($self->spreadsheet)} = [$self->spreadsheet ,basename($self->spreadsheet),'application/octet-stream'];
 

    # authentication setting, if any
    my $auth_settings = [qw()];

    # make the API Call
    my $response = $client->call_api($_resource_path, $_method, $query_params, $form_params, $header_params, $_body_data, $auth_settings);
    return $response;
}


__PACKAGE__->method_documentation({
     'datafile' => {
     	datatype => 'string',
     	base_name => 'datafile',
     	description => 'Upload data file.',
     	format => '',
     	read_only => '',
     		},
     'spreadsheet' => {
     	datatype => 'string',
     	base_name => 'Spreadsheet',
     	description => 'Upload spreadsheet file.',
     	format => '',
     	read_only => '',
     		},
     'worksheet' => {
     	datatype => 'string',
     	base_name => 'worksheet',
     	description => 'Specify the worksheet for importing data',
     	format => '',
     	read_only => '',
     		},
     'startcell' => {
     	datatype => 'string',
     	base_name => 'startcell',
     	description => 'Specify the starting position for importing data',
     	format => '',
     	read_only => '',
     		},
     'insert' => {
     	datatype => 'string',
     	base_name => 'insert',
     	description => 'The specified import data is for insertion and overwrite.',
     	format => '',
     	read_only => '',
     		},
     'convert_numeric_data' => {
     	datatype => 'string',
     	base_name => 'convertNumericData',
     	description => 'Specify whether to convert numerical data',
     	format => '',
     	read_only => '',
     		},
     'splitter' => {
     	datatype => 'string',
     	base_name => 'splitter',
     	description => 'Specify the delimiter for the CSV format.',
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
     'fonts_location' => {
     	datatype => 'string',
     	base_name => 'fontsLocation',
     	description => 'Use Custom fonts.',
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
    'datafile' => 'datafile',
    'spreadsheet' => 'Spreadsheet',
    'worksheet' => 'worksheet',
    'startcell' => 'startcell',
    'insert' => 'insert',
    'convert_numeric_data' => 'convertNumericData',
    'splitter' => 'splitter',
    'out_path' => 'outPath',
    'out_storage_name' => 'outStorageName',
    'fonts_location' => 'fontsLocation',
    'region' => 'region',
    'password' => 'password' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;