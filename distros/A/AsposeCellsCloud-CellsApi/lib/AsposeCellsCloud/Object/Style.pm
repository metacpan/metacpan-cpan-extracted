=begin comment

Copyright (c) 2022 Aspose.Cells Cloud
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
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::LinkElement;
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



__PACKAGE__->class_documentation({description => '',
                                  class => 'Style',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'link' => {
    	datatype => 'Link',
    	base_name => 'link',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'pattern' => {
    	datatype => 'string',
    	base_name => 'Pattern',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'text_direction' => {
    	datatype => 'string',
    	base_name => 'TextDirection',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'custom' => {
    	datatype => 'string',
    	base_name => 'Custom',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'shrink_to_fit' => {
    	datatype => 'boolean',
    	base_name => 'ShrinkToFit',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_date_time' => {
    	datatype => 'boolean',
    	base_name => 'IsDateTime',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'culture_custom' => {
    	datatype => 'string',
    	base_name => 'CultureCustom',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'rotation_angle' => {
    	datatype => 'int',
    	base_name => 'RotationAngle',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'indent_level' => {
    	datatype => 'int',
    	base_name => 'IndentLevel',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_percent' => {
    	datatype => 'boolean',
    	base_name => 'IsPercent',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'foreground_color' => {
    	datatype => 'Color',
    	base_name => 'ForegroundColor',
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
    'foreground_theme_color' => {
    	datatype => 'ThemeColor',
    	base_name => 'ForegroundThemeColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'border_collection' => {
    	datatype => 'ARRAY[Border]',
    	base_name => 'BorderCollection',
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
    'vertical_alignment' => {
    	datatype => 'string',
    	base_name => 'VerticalAlignment',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'background_color' => {
    	datatype => 'Color',
    	base_name => 'BackgroundColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'background_theme_color' => {
    	datatype => 'ThemeColor',
    	base_name => 'BackgroundThemeColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_formula_hidden' => {
    	datatype => 'boolean',
    	base_name => 'IsFormulaHidden',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_gradient' => {
    	datatype => 'boolean',
    	base_name => 'IsGradient',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'number' => {
    	datatype => 'int',
    	base_name => 'Number',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'horizontal_alignment' => {
    	datatype => 'string',
    	base_name => 'HorizontalAlignment',
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
    'font' => {
    	datatype => 'Font',
    	base_name => 'Font',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'link' => 'Link',
    'pattern' => 'string',
    'text_direction' => 'string',
    'custom' => 'string',
    'shrink_to_fit' => 'boolean',
    'is_date_time' => 'boolean',
    'culture_custom' => 'string',
    'rotation_angle' => 'int',
    'indent_level' => 'int',
    'is_percent' => 'boolean',
    'foreground_color' => 'Color',
    'name' => 'string',
    'foreground_theme_color' => 'ThemeColor',
    'border_collection' => 'ARRAY[Border]',
    'is_locked' => 'boolean',
    'vertical_alignment' => 'string',
    'background_color' => 'Color',
    'background_theme_color' => 'ThemeColor',
    'is_formula_hidden' => 'boolean',
    'is_gradient' => 'boolean',
    'number' => 'int',
    'horizontal_alignment' => 'string',
    'is_text_wrapped' => 'boolean',
    'font' => 'Font'
} );

__PACKAGE__->attribute_map( {
    'link' => 'link',
    'pattern' => 'Pattern',
    'text_direction' => 'TextDirection',
    'custom' => 'Custom',
    'shrink_to_fit' => 'ShrinkToFit',
    'is_date_time' => 'IsDateTime',
    'culture_custom' => 'CultureCustom',
    'rotation_angle' => 'RotationAngle',
    'indent_level' => 'IndentLevel',
    'is_percent' => 'IsPercent',
    'foreground_color' => 'ForegroundColor',
    'name' => 'Name',
    'foreground_theme_color' => 'ForegroundThemeColor',
    'border_collection' => 'BorderCollection',
    'is_locked' => 'IsLocked',
    'vertical_alignment' => 'VerticalAlignment',
    'background_color' => 'BackgroundColor',
    'background_theme_color' => 'BackgroundThemeColor',
    'is_formula_hidden' => 'IsFormulaHidden',
    'is_gradient' => 'IsGradient',
    'number' => 'Number',
    'horizontal_alignment' => 'HorizontalAlignment',
    'is_text_wrapped' => 'IsTextWrapped',
    'font' => 'Font'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
