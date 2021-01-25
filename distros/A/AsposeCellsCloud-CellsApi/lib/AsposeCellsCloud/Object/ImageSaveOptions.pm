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


package AsposeCellsCloud::Object::ImageSaveOptions;

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
                                  class => 'ImageSaveOptions',
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
    'chart_image_type' => {
    	datatype => 'string',
    	base_name => 'ChartImageType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'embeded_image_name_in_svg' => {
    	datatype => 'string',
    	base_name => 'EmbededImageNameInSvg',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'horizontal_resolution' => {
    	datatype => 'int',
    	base_name => 'HorizontalResolution',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'image_format' => {
    	datatype => 'string',
    	base_name => 'ImageFormat',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_cell_auto_fit' => {
    	datatype => 'boolean',
    	base_name => 'IsCellAutoFit',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'one_page_per_sheet' => {
    	datatype => 'boolean',
    	base_name => 'OnePagePerSheet',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'only_area' => {
    	datatype => 'boolean',
    	base_name => 'OnlyArea',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'printing_page' => {
    	datatype => 'string',
    	base_name => 'PrintingPage',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'print_with_status_dialog' => {
    	datatype => 'int',
    	base_name => 'PrintWithStatusDialog',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'quality' => {
    	datatype => 'int',
    	base_name => 'Quality',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'tiff_compression' => {
    	datatype => 'string',
    	base_name => 'TiffCompression',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'vertical_resolution' => {
    	datatype => 'int',
    	base_name => 'VerticalResolution',
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
    'chart_image_type' => 'string',
    'embeded_image_name_in_svg' => 'string',
    'horizontal_resolution' => 'int',
    'image_format' => 'string',
    'is_cell_auto_fit' => 'boolean',
    'one_page_per_sheet' => 'boolean',
    'only_area' => 'boolean',
    'printing_page' => 'string',
    'print_with_status_dialog' => 'int',
    'quality' => 'int',
    'tiff_compression' => 'string',
    'vertical_resolution' => 'int'
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
    'chart_image_type' => 'ChartImageType',
    'embeded_image_name_in_svg' => 'EmbededImageNameInSvg',
    'horizontal_resolution' => 'HorizontalResolution',
    'image_format' => 'ImageFormat',
    'is_cell_auto_fit' => 'IsCellAutoFit',
    'one_page_per_sheet' => 'OnePagePerSheet',
    'only_area' => 'OnlyArea',
    'printing_page' => 'PrintingPage',
    'print_with_status_dialog' => 'PrintWithStatusDialog',
    'quality' => 'Quality',
    'tiff_compression' => 'TiffCompression',
    'vertical_resolution' => 'VerticalResolution'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
