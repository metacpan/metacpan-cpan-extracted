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

package AsposeCellsCloud::Object::ImageOrPrintOptions;

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
                                  class => 'ImageOrPrintOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'text_cross_type' => {
     	datatype => 'string',
     	base_name => 'TextCrossType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'gridline_type' => {
     	datatype => 'string',
     	base_name => 'GridlineType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'output_blank_page_when_nothing_to_print' => {
     	datatype => 'boolean',
     	base_name => 'OutputBlankPageWhenNothingToPrint',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_workbook_default_font' => {
     	datatype => 'boolean',
     	base_name => 'CheckWorkbookDefaultFont',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'default_font' => {
     	datatype => 'string',
     	base_name => 'DefaultFont',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_optimized' => {
     	datatype => 'boolean',
     	base_name => 'IsOptimized',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_count' => {
     	datatype => 'int',
     	base_name => 'PageCount',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_index' => {
     	datatype => 'int',
     	base_name => 'PageIndex',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_font_substitution_char_granularity' => {
     	datatype => 'boolean',
     	base_name => 'IsFontSubstitutionCharGranularity',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'transparent' => {
     	datatype => 'boolean',
     	base_name => 'Transparent',
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
     'svg_fit_to_view_port' => {
     	datatype => 'boolean',
     	base_name => 'SVGFitToViewPort',
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
     'all_columns_in_one_page_per_sheet' => {
     	datatype => 'boolean',
     	base_name => 'AllColumnsInOnePagePerSheet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'print_with_status_dialog' => {
     	datatype => 'boolean',
     	base_name => 'PrintWithStatusDialog',
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
     'vertical_resolution' => {
     	datatype => 'int',
     	base_name => 'VerticalResolution',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'default_edit_language' => {
     	datatype => 'string',
     	base_name => 'DefaultEditLanguage',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'tiff_color_depth' => {
     	datatype => 'string',
     	base_name => 'TiffColorDepth',
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
     'printing_page' => {
     	datatype => 'string',
     	base_name => 'PrintingPage',
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
     'image_type' => {
     	datatype => 'string',
     	base_name => 'ImageType',
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
     'tiff_binarization_method' => {
     	datatype => 'string',
     	base_name => 'TiffBinarizationMethod',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'text_cross_type' => 'string',
    'gridline_type' => 'string',
    'output_blank_page_when_nothing_to_print' => 'boolean',
    'check_workbook_default_font' => 'boolean',
    'default_font' => 'string',
    'is_optimized' => 'boolean',
    'page_count' => 'int',
    'page_index' => 'int',
    'is_font_substitution_char_granularity' => 'boolean',
    'transparent' => 'boolean',
    'only_area' => 'boolean',
    'svg_fit_to_view_port' => 'boolean',
    'embeded_image_name_in_svg' => 'string',
    'all_columns_in_one_page_per_sheet' => 'boolean',
    'print_with_status_dialog' => 'boolean',
    'horizontal_resolution' => 'int',
    'vertical_resolution' => 'int',
    'default_edit_language' => 'string',
    'tiff_color_depth' => 'string',
    'tiff_compression' => 'string',
    'printing_page' => 'string',
    'quality' => 'int',
    'image_type' => 'string',
    'one_page_per_sheet' => 'boolean',
    'tiff_binarization_method' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'text_cross_type' => 'TextCrossType',
    'gridline_type' => 'GridlineType',
    'output_blank_page_when_nothing_to_print' => 'OutputBlankPageWhenNothingToPrint',
    'check_workbook_default_font' => 'CheckWorkbookDefaultFont',
    'default_font' => 'DefaultFont',
    'is_optimized' => 'IsOptimized',
    'page_count' => 'PageCount',
    'page_index' => 'PageIndex',
    'is_font_substitution_char_granularity' => 'IsFontSubstitutionCharGranularity',
    'transparent' => 'Transparent',
    'only_area' => 'OnlyArea',
    'svg_fit_to_view_port' => 'SVGFitToViewPort',
    'embeded_image_name_in_svg' => 'EmbededImageNameInSvg',
    'all_columns_in_one_page_per_sheet' => 'AllColumnsInOnePagePerSheet',
    'print_with_status_dialog' => 'PrintWithStatusDialog',
    'horizontal_resolution' => 'HorizontalResolution',
    'vertical_resolution' => 'VerticalResolution',
    'default_edit_language' => 'DefaultEditLanguage',
    'tiff_color_depth' => 'TiffColorDepth',
    'tiff_compression' => 'TiffCompression',
    'printing_page' => 'PrintingPage',
    'quality' => 'Quality',
    'image_type' => 'ImageType',
    'one_page_per_sheet' => 'OnePagePerSheet',
    'tiff_binarization_method' => 'TiffBinarizationMethod' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;