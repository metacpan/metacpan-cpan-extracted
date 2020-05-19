=begin comment

Copyright (c) 2020 Aspose.Cells Cloud
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


package AsposeCellsCloud::Object::HtmlSaveOptions;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON qw(decode_json);
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;

use AsposeCellsCloud::Object::SaveOptions;

use base ("Class::Accessor", "Class::Data::Inheritable");



__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('swagger_types' => {});
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

# return perl hash
sub to_hash {
    return decode_json(JSON->new->convert_blessed->encode( shift ));
}

# used by JSON for serialization
sub TO_JSON { 
    my $self = shift;
    my $_data = {};
    foreach my $_key (keys %{$self->attribute_map}) {
        if (defined $self->{$_key}) {
            $_data->{$self->attribute_map->{$_key}} = $self->{$_key};
        }
    }
    return $_data;
}

# from Perl hashref
sub from_hash {
    my ($self, $hash) = @_;

    # loop through attributes and use swagger_types to deserialize the data
    while ( my ($_key, $_type) = each %{$self->swagger_types} ) {
    	my $_json_attribute = $self->attribute_map->{$_key}; 
        if ($_type =~ /^array\[/i) { # array
            my $_subclass = substr($_type, 6, -1);
            my @_array = ();
            foreach my $_element (@{$hash->{$_json_attribute}}) {
                push @_array, $self->_deserialize($_subclass, $_element);
            }
            $self->{$_key} = \@_array;
        } elsif (exists $hash->{$_json_attribute}) { #hash(model), primitive, datetime
            $self->{$_key} = $self->_deserialize($_type, $hash->{$_json_attribute});
        } else {
        	$log->debugf("Warning: %s (%s) does not exist in input hash\n", $_key, $_json_attribute);
        }
    }
  
    return $self;
}

# deserialize non-array data
sub _deserialize {
    my ($self, $type, $data) = @_;
    $log->debugf("deserializing %s with %s",Dumper($data), $type);
        
    if ($type eq 'DateTime') {
        return DateTime->from_epoch(epoch => str2time($data));
    } elsif ( grep( /^$type$/, ('int', 'double', 'string', 'boolean'))) {
        return $data;
    } else { # hash(model)
        my $_instance = eval "AsposeCellsCloud::Object::$type->new()";
        return $_instance->from_hash($data);
    }
}



__PACKAGE__->class_documentation({description => '',
                                  class => 'HtmlSaveOptions',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'enable_http_compression' => {
    	datatype => 'boolean',
    	base_name => 'EnableHTTPCompression',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'save_format' => {
    	datatype => 'string',
    	base_name => 'SaveFormat',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'clear_data' => {
    	datatype => 'boolean',
    	base_name => 'ClearData',
    	description => 'Make the workbook empty after saving the file.',
    	format => '',
    	read_only => '',
    		},
    'cached_file_folder' => {
    	datatype => 'string',
    	base_name => 'CachedFileFolder',
    	description => 'The cached file folder is used to store some large data.',
    	format => '',
    	read_only => '',
    		},
    'validate_merged_areas' => {
    	datatype => 'boolean',
    	base_name => 'ValidateMergedAreas',
    	description => 'Indicates whether validate merged areas before saving the file. The default value is false.             ',
    	format => '',
    	read_only => '',
    		},
    'refresh_chart_cache' => {
    	datatype => 'boolean',
    	base_name => 'RefreshChartCache',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'create_directory' => {
    	datatype => 'boolean',
    	base_name => 'CreateDirectory',
    	description => 'If true and the directory does not exist, the directory will be automatically created before saving the file.             ',
    	format => '',
    	read_only => '',
    		},
    'sort_names' => {
    	datatype => 'boolean',
    	base_name => 'SortNames',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'attached_files_directory' => {
    	datatype => 'string',
    	base_name => 'AttachedFilesDirectory',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'attached_files_url_prefix' => {
    	datatype => 'string',
    	base_name => 'AttachedFilesUrlPrefix',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'encoding' => {
    	datatype => 'string',
    	base_name => 'Encoding',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'export_active_worksheet_only' => {
    	datatype => 'boolean',
    	base_name => 'ExportActiveWorksheetOnly',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'export_chart_image_format' => {
    	datatype => 'string',
    	base_name => 'ExportChartImageFormat',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'export_images_as_base64' => {
    	datatype => 'boolean',
    	base_name => 'ExportImagesAsBase64',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'hidden_col_display_type' => {
    	datatype => 'string',
    	base_name => 'HiddenColDisplayType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'hidden_row_display_type' => {
    	datatype => 'string',
    	base_name => 'HiddenRowDisplayType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'html_cross_string_type' => {
    	datatype => 'string',
    	base_name => 'HtmlCrossStringType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_exp_image_to_temp_dir' => {
    	datatype => 'boolean',
    	base_name => 'IsExpImageToTempDir',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'page_title' => {
    	datatype => 'string',
    	base_name => 'PageTitle',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'parse_html_tag_in_cell' => {
    	datatype => 'boolean',
    	base_name => 'ParseHtmlTagInCell',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'enable_http_compression' => 'boolean',
    'save_format' => 'string',
    'clear_data' => 'boolean',
    'cached_file_folder' => 'string',
    'validate_merged_areas' => 'boolean',
    'refresh_chart_cache' => 'boolean',
    'create_directory' => 'boolean',
    'sort_names' => 'boolean',
    'attached_files_directory' => 'string',
    'attached_files_url_prefix' => 'string',
    'encoding' => 'string',
    'export_active_worksheet_only' => 'boolean',
    'export_chart_image_format' => 'string',
    'export_images_as_base64' => 'boolean',
    'hidden_col_display_type' => 'string',
    'hidden_row_display_type' => 'string',
    'html_cross_string_type' => 'string',
    'is_exp_image_to_temp_dir' => 'boolean',
    'page_title' => 'string',
    'parse_html_tag_in_cell' => 'boolean'
} );

__PACKAGE__->attribute_map( {
    'enable_http_compression' => 'EnableHTTPCompression',
    'save_format' => 'SaveFormat',
    'clear_data' => 'ClearData',
    'cached_file_folder' => 'CachedFileFolder',
    'validate_merged_areas' => 'ValidateMergedAreas',
    'refresh_chart_cache' => 'RefreshChartCache',
    'create_directory' => 'CreateDirectory',
    'sort_names' => 'SortNames',
    'attached_files_directory' => 'AttachedFilesDirectory',
    'attached_files_url_prefix' => 'AttachedFilesUrlPrefix',
    'encoding' => 'Encoding',
    'export_active_worksheet_only' => 'ExportActiveWorksheetOnly',
    'export_chart_image_format' => 'ExportChartImageFormat',
    'export_images_as_base64' => 'ExportImagesAsBase64',
    'hidden_col_display_type' => 'HiddenColDisplayType',
    'hidden_row_display_type' => 'HiddenRowDisplayType',
    'html_cross_string_type' => 'HtmlCrossStringType',
    'is_exp_image_to_temp_dir' => 'IsExpImageToTempDir',
    'page_title' => 'PageTitle',
    'parse_html_tag_in_cell' => 'ParseHtmlTagInCell'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
