=begin comment

Copyright (c) 2024 Aspose.Cells Cloud
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

package AsposeCellsCloud::Object::CellsDrawing;

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
use AsposeCellsCloud::Object::Font;
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
                                  class => 'CellsDrawing',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
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
     'auto_shape_type' => {
     	datatype => 'string',
     	base_name => 'AutoShapeType',
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
     'upper_left_row' => {
     	datatype => 'int',
     	base_name => 'UpperLeftRow',
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
     'upper_left_column' => {
     	datatype => 'int',
     	base_name => 'UpperLeftColumn',
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
     'lower_right_row' => {
     	datatype => 'int',
     	base_name => 'LowerRightRow',
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
     'lower_right_column' => {
     	datatype => 'int',
     	base_name => 'LowerRightColumn',
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
     'width' => {
     	datatype => 'int',
     	base_name => 'Width',
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
     'x' => {
     	datatype => 'int',
     	base_name => 'X',
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
     'rotation_angle' => {
     	datatype => 'double',
     	base_name => 'RotationAngle',
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
     'text' => {
     	datatype => 'string',
     	base_name => 'Text',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'alternative_text' => {
     	datatype => 'string',
     	base_name => 'AlternativeText',
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
     'text_horizontal_overflow' => {
     	datatype => 'string',
     	base_name => 'TextHorizontalOverflow',
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
     'text_vertical_alignment' => {
     	datatype => 'string',
     	base_name => 'TextVerticalAlignment',
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
     'is_group' => {
     	datatype => 'boolean',
     	base_name => 'IsGroup',
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
     'is_lock_aspect_ratio' => {
     	datatype => 'boolean',
     	base_name => 'IsLockAspectRatio',
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
     'is_printable' => {
     	datatype => 'boolean',
     	base_name => 'IsPrintable',
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
     'z_order_position' => {
     	datatype => 'int',
     	base_name => 'ZOrderPosition',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'font' => {
     	datatype => 'Font',
     	base_name => 'Font',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'hyperlink' => {
     	datatype => 'string',
     	base_name => 'Hyperlink',
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
});

__PACKAGE__->swagger_types( {
    'name' => 'string',
    'mso_drawing_type' => 'string',
    'auto_shape_type' => 'string',
    'placement' => 'string',
    'upper_left_row' => 'int',
    'top' => 'int',
    'upper_left_column' => 'int',
    'left' => 'int',
    'lower_right_row' => 'int',
    'bottom' => 'int',
    'lower_right_column' => 'int',
    'right' => 'int',
    'width' => 'int',
    'height' => 'int',
    'x' => 'int',
    'y' => 'int',
    'rotation_angle' => 'double',
    'html_text' => 'string',
    'text' => 'string',
    'alternative_text' => 'string',
    'text_horizontal_alignment' => 'string',
    'text_horizontal_overflow' => 'string',
    'text_orientation_type' => 'string',
    'text_vertical_alignment' => 'string',
    'text_vertical_overflow' => 'string',
    'is_group' => 'boolean',
    'is_hidden' => 'boolean',
    'is_lock_aspect_ratio' => 'boolean',
    'is_locked' => 'boolean',
    'is_printable' => 'boolean',
    'is_text_wrapped' => 'boolean',
    'is_word_art' => 'boolean',
    'linked_cell' => 'string',
    'z_order_position' => 'int',
    'font' => 'Font',
    'hyperlink' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'name' => 'Name',
    'mso_drawing_type' => 'MsoDrawingType',
    'auto_shape_type' => 'AutoShapeType',
    'placement' => 'Placement',
    'upper_left_row' => 'UpperLeftRow',
    'top' => 'Top',
    'upper_left_column' => 'UpperLeftColumn',
    'left' => 'Left',
    'lower_right_row' => 'LowerRightRow',
    'bottom' => 'Bottom',
    'lower_right_column' => 'LowerRightColumn',
    'right' => 'Right',
    'width' => 'Width',
    'height' => 'Height',
    'x' => 'X',
    'y' => 'Y',
    'rotation_angle' => 'RotationAngle',
    'html_text' => 'HtmlText',
    'text' => 'Text',
    'alternative_text' => 'AlternativeText',
    'text_horizontal_alignment' => 'TextHorizontalAlignment',
    'text_horizontal_overflow' => 'TextHorizontalOverflow',
    'text_orientation_type' => 'TextOrientationType',
    'text_vertical_alignment' => 'TextVerticalAlignment',
    'text_vertical_overflow' => 'TextVerticalOverflow',
    'is_group' => 'IsGroup',
    'is_hidden' => 'IsHidden',
    'is_lock_aspect_ratio' => 'IsLockAspectRatio',
    'is_locked' => 'IsLocked',
    'is_printable' => 'IsPrintable',
    'is_text_wrapped' => 'IsTextWrapped',
    'is_word_art' => 'IsWordArt',
    'linked_cell' => 'LinkedCell',
    'z_order_position' => 'ZOrderPosition',
    'font' => 'Font',
    'hyperlink' => 'Hyperlink',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;