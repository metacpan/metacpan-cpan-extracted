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

package AsposeCellsCloud::Object::TextOptions;

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
use AsposeCellsCloud::Object::CellsColor;
use AsposeCellsCloud::Object::Color;
use AsposeCellsCloud::Object::FillFormat;
use AsposeCellsCloud::Object::Font;
use AsposeCellsCloud::Object::LineFormat;
use AsposeCellsCloud::Object::ShadowEffect; 


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


__PACKAGE__->class_documentation({description => 'Represents the text options.',
                                  class => 'TextOptions',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'fill' => {
     	datatype => 'FillFormat',
     	base_name => 'Fill',
     	description => 'Represents fill format.',
     	format => '',
     	read_only => '',
     		},
     'kerning' => {
     	datatype => 'double',
     	base_name => 'Kerning',
     	description => 'Represents kerning.',
     	format => '',
     	read_only => '',
     		},
     'outline' => {
     	datatype => 'LineFormat',
     	base_name => 'Outline',
     	description => 'Represents outline format.',
     	format => '',
     	read_only => '',
     		},
     'shadow' => {
     	datatype => 'ShadowEffect',
     	base_name => 'Shadow',
     	description => 'Represents shadow effect.',
     	format => '',
     	read_only => '',
     		},
     'spacing' => {
     	datatype => 'double',
     	base_name => 'Spacing',
     	description => 'Represents spacing.',
     	format => '',
     	read_only => '',
     		},
     'underline_color' => {
     	datatype => 'CellsColor',
     	base_name => 'UnderlineColor',
     	description => 'Represents under line color.',
     	format => '',
     	read_only => '',
     		},
     'color' => {
     	datatype => 'Color',
     	base_name => 'Color',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'double_size' => {
     	datatype => 'double',
     	base_name => 'DoubleSize',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_bold' => {
     	datatype => 'boolean',
     	base_name => 'IsBold',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_italic' => {
     	datatype => 'boolean',
     	base_name => 'IsItalic',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_strikeout' => {
     	datatype => 'boolean',
     	base_name => 'IsStrikeout',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_subscript' => {
     	datatype => 'boolean',
     	base_name => 'IsSubscript',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_superscript' => {
     	datatype => 'boolean',
     	base_name => 'IsSuperscript',
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
     'size' => {
     	datatype => 'int',
     	base_name => 'Size',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'underline' => {
     	datatype => 'string',
     	base_name => 'Underline',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'fill' => 'FillFormat',
    'kerning' => 'double',
    'outline' => 'LineFormat',
    'shadow' => 'ShadowEffect',
    'spacing' => 'double',
    'underline_color' => 'CellsColor',
    'color' => 'Color',
    'double_size' => 'double',
    'is_bold' => 'boolean',
    'is_italic' => 'boolean',
    'is_strikeout' => 'boolean',
    'is_subscript' => 'boolean',
    'is_superscript' => 'boolean',
    'name' => 'string',
    'size' => 'int',
    'underline' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'fill' => 'Fill',
    'kerning' => 'Kerning',
    'outline' => 'Outline',
    'shadow' => 'Shadow',
    'spacing' => 'Spacing',
    'underline_color' => 'UnderlineColor',
    'color' => 'Color',
    'double_size' => 'DoubleSize',
    'is_bold' => 'IsBold',
    'is_italic' => 'IsItalic',
    'is_strikeout' => 'IsStrikeout',
    'is_subscript' => 'IsSubscript',
    'is_superscript' => 'IsSuperscript',
    'name' => 'Name',
    'size' => 'Size',
    'underline' => 'Underline' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;