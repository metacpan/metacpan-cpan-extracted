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

package AsposeCellsCloud::Object::Style;

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
use AsposeCellsCloud::Object::Border;
use AsposeCellsCloud::Object::Color;
use AsposeCellsCloud::Object::Font;
use AsposeCellsCloud::Object::ThemeColor; 


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


__PACKAGE__->class_documentation({description => '           Represents display style of excel document,such as font,color,alignment,border,etc.            The Style object contains all style attributes (font, number format, alignment, and so on) as properties.           ',
                                  class => 'Style',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'font' => {
     	datatype => 'Font',
     	base_name => 'Font',
     	description => 'Gets a  object. ',
     	format => '',
     	read_only => '',
     		},
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Gets or sets the name of the style. ',
     	format => '',
     	read_only => '',
     		},
     'culture_custom' => {
     	datatype => 'string',
     	base_name => 'CultureCustom',
     	description => 'Gets and sets the culture-dependent pattern string for number format.            If no number format has been set for this object, null will be returned.            If number format is builtin, the pattern string corresponding to the builtin number will be returned. ',
     	format => '',
     	read_only => '',
     		},
     'custom' => {
     	datatype => 'string',
     	base_name => 'Custom',
     	description => 'Represents the custom number format string of this style object.            If the custom number format is not set(For example, the number format is builtin), "" will be returned. ',
     	format => '',
     	read_only => '',
     		},
     'background_color' => {
     	datatype => 'Color',
     	base_name => 'BackgroundColor',
     	description => 'Gets or sets a style`s background color. ',
     	format => '',
     	read_only => '',
     		},
     'foreground_color' => {
     	datatype => 'Color',
     	base_name => 'ForegroundColor',
     	description => 'Gets or sets a style`s foreground color. ',
     	format => '',
     	read_only => '',
     		},
     'is_formula_hidden' => {
     	datatype => 'boolean',
     	base_name => 'IsFormulaHidden',
     	description => 'Represents if the formula will be hidden when the worksheet is protected. ',
     	format => '',
     	read_only => '',
     		},
     'is_date_time' => {
     	datatype => 'boolean',
     	base_name => 'IsDateTime',
     	description => 'Indicates whether the number format is a date format. ',
     	format => '',
     	read_only => '',
     		},
     'is_text_wrapped' => {
     	datatype => 'boolean',
     	base_name => 'IsTextWrapped',
     	description => 'Gets or sets a value indicating whether the text within a cell is wrapped. ',
     	format => '',
     	read_only => '',
     		},
     'is_gradient' => {
     	datatype => 'boolean',
     	base_name => 'IsGradient',
     	description => 'Indicates whether the cell shading is a gradient pattern. ',
     	format => '',
     	read_only => '',
     		},
     'is_locked' => {
     	datatype => 'boolean',
     	base_name => 'IsLocked',
     	description => 'Gets or sets a value indicating whether a cell can be modified or not. ',
     	format => '',
     	read_only => '',
     		},
     'is_percent' => {
     	datatype => 'boolean',
     	base_name => 'IsPercent',
     	description => 'Indicates whether the number format is a percent format. ',
     	format => '',
     	read_only => '',
     		},
     'shrink_to_fit' => {
     	datatype => 'boolean',
     	base_name => 'ShrinkToFit',
     	description => 'Represents if text automatically shrinks to fit in the available column width. ',
     	format => '',
     	read_only => '',
     		},
     'indent_level' => {
     	datatype => 'int',
     	base_name => 'IndentLevel',
     	description => 'Represents the indent level for the cell or range. Can only be an integer from 0 to 250. ',
     	format => '',
     	read_only => '',
     		},
     'number' => {
     	datatype => 'int',
     	base_name => 'Number',
     	description => 'Gets or sets the display format of numbers and dates. The formatting patterns are different for different regions. ',
     	format => '',
     	read_only => '',
     		},
     'rotation_angle' => {
     	datatype => 'int',
     	base_name => 'RotationAngle',
     	description => 'Represents text rotation angle. ',
     	format => '',
     	read_only => '',
     		},
     'pattern' => {
     	datatype => 'string',
     	base_name => 'Pattern',
     	description => 'Gets or sets the cell background pattern type. ',
     	format => '',
     	read_only => '',
     		},
     'text_direction' => {
     	datatype => 'string',
     	base_name => 'TextDirection',
     	description => 'Represents text reading order. ',
     	format => '',
     	read_only => '',
     		},
     'vertical_alignment' => {
     	datatype => 'string',
     	base_name => 'VerticalAlignment',
     	description => 'Gets or sets the vertical alignment type of the text in a cell. ',
     	format => '',
     	read_only => '',
     		},
     'horizontal_alignment' => {
     	datatype => 'string',
     	base_name => 'HorizontalAlignment',
     	description => 'Gets or sets the horizontal alignment type of the text in a cell. ',
     	format => '',
     	read_only => '',
     		},
     'border_collection' => {
     	datatype => 'ARRAY[Border]',
     	base_name => 'BorderCollection',
     	description => 'A public property named `BorderCollection` that is a list of `Border` objects.',
     	format => '',
     	read_only => '',
     		},
     'background_theme_color' => {
     	datatype => 'ThemeColor',
     	base_name => 'BackgroundThemeColor',
     	description => 'Gets and sets the background theme color. ',
     	format => '',
     	read_only => '',
     		},
     'foreground_theme_color' => {
     	datatype => 'ThemeColor',
     	base_name => 'ForegroundThemeColor',
     	description => 'Gets and sets the foreground theme color. ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'font' => 'Font',
    'name' => 'string',
    'culture_custom' => 'string',
    'custom' => 'string',
    'background_color' => 'Color',
    'foreground_color' => 'Color',
    'is_formula_hidden' => 'boolean',
    'is_date_time' => 'boolean',
    'is_text_wrapped' => 'boolean',
    'is_gradient' => 'boolean',
    'is_locked' => 'boolean',
    'is_percent' => 'boolean',
    'shrink_to_fit' => 'boolean',
    'indent_level' => 'int',
    'number' => 'int',
    'rotation_angle' => 'int',
    'pattern' => 'string',
    'text_direction' => 'string',
    'vertical_alignment' => 'string',
    'horizontal_alignment' => 'string',
    'border_collection' => 'ARRAY[Border]',
    'background_theme_color' => 'ThemeColor',
    'foreground_theme_color' => 'ThemeColor' 
} );

__PACKAGE__->attribute_map( {
    'font' => 'Font',
    'name' => 'Name',
    'culture_custom' => 'CultureCustom',
    'custom' => 'Custom',
    'background_color' => 'BackgroundColor',
    'foreground_color' => 'ForegroundColor',
    'is_formula_hidden' => 'IsFormulaHidden',
    'is_date_time' => 'IsDateTime',
    'is_text_wrapped' => 'IsTextWrapped',
    'is_gradient' => 'IsGradient',
    'is_locked' => 'IsLocked',
    'is_percent' => 'IsPercent',
    'shrink_to_fit' => 'ShrinkToFit',
    'indent_level' => 'IndentLevel',
    'number' => 'Number',
    'rotation_angle' => 'RotationAngle',
    'pattern' => 'Pattern',
    'text_direction' => 'TextDirection',
    'vertical_alignment' => 'VerticalAlignment',
    'horizontal_alignment' => 'HorizontalAlignment',
    'border_collection' => 'BorderCollection',
    'background_theme_color' => 'BackgroundThemeColor',
    'foreground_theme_color' => 'ForegroundThemeColor' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;