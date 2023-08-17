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

package AsposeCellsCloud::Object::DataBar;

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
use AsposeCellsCloud::Object::ConditionalFormattingValue;
use AsposeCellsCloud::Object::DataBarBorder;
use AsposeCellsCloud::Object::NegativeBarFormat; 


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


__PACKAGE__->class_documentation({description => 'Describe the DataBar conditional formatting rule. This conditional formatting   rule displays a gradated data bar in the range of cells.',
                                  class => 'DataBar',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'axis_color' => {
     	datatype => 'Color',
     	base_name => 'AxisColor',
     	description => 'Gets the color of the axis for cells with conditional formatting as data bars.',
     	format => '',
     	read_only => '',
     		},
     'axis_position' => {
     	datatype => 'string',
     	base_name => 'AxisPosition',
     	description => 'Gets or sets the position of the axis of the data bars specified by a conditional   formatting rule.',
     	format => '',
     	read_only => '',
     		},
     'bar_border' => {
     	datatype => 'DataBarBorder',
     	base_name => 'BarBorder',
     	description => 'Gets an object that specifies the border of a data bar.',
     	format => '',
     	read_only => '',
     		},
     'bar_fill_type' => {
     	datatype => 'string',
     	base_name => 'BarFillType',
     	description => 'Gets or sets how a data bar is filled with color.',
     	format => '',
     	read_only => '',
     		},
     'color' => {
     	datatype => 'Color',
     	base_name => 'Color',
     	description => 'Get or set this DataBar`s Color.            ',
     	format => '',
     	read_only => '',
     		},
     'direction' => {
     	datatype => 'string',
     	base_name => 'Direction',
     	description => 'Gets or sets the direction the databar is displayed.',
     	format => '',
     	read_only => '',
     		},
     'max_cfvo' => {
     	datatype => 'ConditionalFormattingValue',
     	base_name => 'MaxCfvo',
     	description => 'Get or set this DataBar`s max value object.  Cannot set null or CFValueObject   with type FormatConditionValueType.Min to it.            ',
     	format => '',
     	read_only => '',
     		},
     'max_length' => {
     	datatype => 'int',
     	base_name => 'MaxLength',
     	description => 'Represents the max length of data bar .',
     	format => '',
     	read_only => '',
     		},
     'min_cfvo' => {
     	datatype => 'ConditionalFormattingValue',
     	base_name => 'MinCfvo',
     	description => 'Get or set this DataBar`s min value object.  Cannot set null or CFValueObject  with type FormatConditionValueType.Max to it.            ',
     	format => '',
     	read_only => '',
     		},
     'min_length' => {
     	datatype => 'int',
     	base_name => 'MinLength',
     	description => 'Represents the min length of data bar .            ',
     	format => '',
     	read_only => '',
     		},
     'negative_bar_format' => {
     	datatype => 'NegativeBarFormat',
     	base_name => 'NegativeBarFormat',
     	description => 'Gets the NegativeBarFormat object associated with a data bar conditional    formatting rule.',
     	format => '',
     	read_only => '',
     		},
     'show_value' => {
     	datatype => 'boolean',
     	base_name => 'ShowValue',
     	description => 'Get or set the flag indicating whether to show the values of the cells on  which this data bar is applied.  Default value is true.            ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'axis_color' => 'Color',
    'axis_position' => 'string',
    'bar_border' => 'DataBarBorder',
    'bar_fill_type' => 'string',
    'color' => 'Color',
    'direction' => 'string',
    'max_cfvo' => 'ConditionalFormattingValue',
    'max_length' => 'int',
    'min_cfvo' => 'ConditionalFormattingValue',
    'min_length' => 'int',
    'negative_bar_format' => 'NegativeBarFormat',
    'show_value' => 'boolean' 
} );

__PACKAGE__->attribute_map( {
    'axis_color' => 'AxisColor',
    'axis_position' => 'AxisPosition',
    'bar_border' => 'BarBorder',
    'bar_fill_type' => 'BarFillType',
    'color' => 'Color',
    'direction' => 'Direction',
    'max_cfvo' => 'MaxCfvo',
    'max_length' => 'MaxLength',
    'min_cfvo' => 'MinCfvo',
    'min_length' => 'MinLength',
    'negative_bar_format' => 'NegativeBarFormat',
    'show_value' => 'ShowValue' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;