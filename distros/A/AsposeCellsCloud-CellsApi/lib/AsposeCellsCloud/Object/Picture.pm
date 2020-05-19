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


package AsposeCellsCloud::Object::Picture;

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

use AsposeCellsCloud::Object::Color;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::Shape;

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
                                  class => 'Picture',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'alternative_text' => {
    	datatype => 'string',
    	base_name => 'AlternativeText',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'bottom' => {
    	datatype => 'int',
    	base_name => 'Bottom',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'top' => {
    	datatype => 'int',
    	base_name => 'Top',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'width' => {
    	datatype => 'int',
    	base_name => 'Width',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'html_text' => {
    	datatype => 'string',
    	base_name => 'HtmlText',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_vertical_alignment' => {
    	datatype => 'string',
    	base_name => 'TextVerticalAlignment',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'auto_shape_type' => {
    	datatype => 'string',
    	base_name => 'AutoShapeType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_printable' => {
    	datatype => 'boolean',
    	base_name => 'IsPrintable',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'upper_left_column' => {
    	datatype => 'int',
    	base_name => 'UpperLeftColumn',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_lock_aspect_ratio' => {
    	datatype => 'boolean',
    	base_name => 'IsLockAspectRatio',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_group' => {
    	datatype => 'boolean',
    	base_name => 'IsGroup',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'rotation_angle' => {
    	datatype => 'double',
    	base_name => 'RotationAngle',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'z_order_position' => {
    	datatype => 'int',
    	base_name => 'ZOrderPosition',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_horizontal_overflow' => {
    	datatype => 'string',
    	base_name => 'TextHorizontalOverflow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'mso_drawing_type' => {
    	datatype => 'string',
    	base_name => 'MsoDrawingType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_orientation_type' => {
    	datatype => 'string',
    	base_name => 'TextOrientationType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'placement' => {
    	datatype => 'string',
    	base_name => 'Placement',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'name' => {
    	datatype => 'string',
    	base_name => 'Name',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_word_art' => {
    	datatype => 'boolean',
    	base_name => 'IsWordArt',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'linked_cell' => {
    	datatype => 'string',
    	base_name => 'LinkedCell',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'upper_left_row' => {
    	datatype => 'int',
    	base_name => 'UpperLeftRow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_locked' => {
    	datatype => 'boolean',
    	base_name => 'IsLocked',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'lower_right_row' => {
    	datatype => 'int',
    	base_name => 'LowerRightRow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_text_wrapped' => {
    	datatype => 'boolean',
    	base_name => 'IsTextWrapped',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'y' => {
    	datatype => 'int',
    	base_name => 'Y',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'x' => {
    	datatype => 'int',
    	base_name => 'X',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_hidden' => {
    	datatype => 'boolean',
    	base_name => 'IsHidden',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'left' => {
    	datatype => 'int',
    	base_name => 'Left',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'right' => {
    	datatype => 'int',
    	base_name => 'Right',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text' => {
    	datatype => 'string',
    	base_name => 'Text',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'lower_right_column' => {
    	datatype => 'int',
    	base_name => 'LowerRightColumn',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'height' => {
    	datatype => 'int',
    	base_name => 'Height',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_horizontal_alignment' => {
    	datatype => 'string',
    	base_name => 'TextHorizontalAlignment',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_vertical_overflow' => {
    	datatype => 'string',
    	base_name => 'TextVerticalOverflow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'link' => {
    	datatype => 'Link',
    	base_name => 'link',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'source_full_name' => {
    	datatype => 'string',
    	base_name => 'SourceFullName',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'border_line_color' => {
    	datatype => 'Color',
    	base_name => 'BorderLineColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'original_height' => {
    	datatype => 'int',
    	base_name => 'OriginalHeight',
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
    'original_width' => {
    	datatype => 'int',
    	base_name => 'OriginalWidth',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'border_weight' => {
    	datatype => 'double',
    	base_name => 'BorderWeight',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'alternative_text' => 'string',
    'bottom' => 'int',
    'top' => 'int',
    'width' => 'int',
    'html_text' => 'string',
    'text_vertical_alignment' => 'string',
    'auto_shape_type' => 'string',
    'is_printable' => 'boolean',
    'upper_left_column' => 'int',
    'is_lock_aspect_ratio' => 'boolean',
    'is_group' => 'boolean',
    'rotation_angle' => 'double',
    'z_order_position' => 'int',
    'text_horizontal_overflow' => 'string',
    'mso_drawing_type' => 'string',
    'text_orientation_type' => 'string',
    'placement' => 'string',
    'name' => 'string',
    'is_word_art' => 'boolean',
    'linked_cell' => 'string',
    'upper_left_row' => 'int',
    'is_locked' => 'boolean',
    'lower_right_row' => 'int',
    'is_text_wrapped' => 'boolean',
    'y' => 'int',
    'x' => 'int',
    'is_hidden' => 'boolean',
    'left' => 'int',
    'right' => 'int',
    'text' => 'string',
    'lower_right_column' => 'int',
    'height' => 'int',
    'text_horizontal_alignment' => 'string',
    'text_vertical_overflow' => 'string',
    'link' => 'Link',
    'source_full_name' => 'string',
    'border_line_color' => 'Color',
    'original_height' => 'int',
    'image_format' => 'string',
    'original_width' => 'int',
    'border_weight' => 'double'
} );

__PACKAGE__->attribute_map( {
    'alternative_text' => 'AlternativeText',
    'bottom' => 'Bottom',
    'top' => 'Top',
    'width' => 'Width',
    'html_text' => 'HtmlText',
    'text_vertical_alignment' => 'TextVerticalAlignment',
    'auto_shape_type' => 'AutoShapeType',
    'is_printable' => 'IsPrintable',
    'upper_left_column' => 'UpperLeftColumn',
    'is_lock_aspect_ratio' => 'IsLockAspectRatio',
    'is_group' => 'IsGroup',
    'rotation_angle' => 'RotationAngle',
    'z_order_position' => 'ZOrderPosition',
    'text_horizontal_overflow' => 'TextHorizontalOverflow',
    'mso_drawing_type' => 'MsoDrawingType',
    'text_orientation_type' => 'TextOrientationType',
    'placement' => 'Placement',
    'name' => 'Name',
    'is_word_art' => 'IsWordArt',
    'linked_cell' => 'LinkedCell',
    'upper_left_row' => 'UpperLeftRow',
    'is_locked' => 'IsLocked',
    'lower_right_row' => 'LowerRightRow',
    'is_text_wrapped' => 'IsTextWrapped',
    'y' => 'Y',
    'x' => 'X',
    'is_hidden' => 'IsHidden',
    'left' => 'Left',
    'right' => 'Right',
    'text' => 'Text',
    'lower_right_column' => 'LowerRightColumn',
    'height' => 'Height',
    'text_horizontal_alignment' => 'TextHorizontalAlignment',
    'text_vertical_overflow' => 'TextVerticalOverflow',
    'link' => 'link',
    'source_full_name' => 'SourceFullName',
    'border_line_color' => 'BorderLineColor',
    'original_height' => 'OriginalHeight',
    'image_format' => 'ImageFormat',
    'original_width' => 'OriginalWidth',
    'border_weight' => 'BorderWeight'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
