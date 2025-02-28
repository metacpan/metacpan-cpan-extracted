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

package AsposeCellsCloud::Object::ErrorBar;

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
use AsposeCellsCloud::Object::GradientFill;
use AsposeCellsCloud::Object::Line;
use AsposeCellsCloud::Object::Link; 


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


__PACKAGE__->class_documentation({description => 'Represents error bar of data series.',
                                  class => 'ErrorBar',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'link' => {
     	datatype => 'Link',
     	base_name => 'Link',
     	description => 'A property named "Link" of type "Link" that can be accessed and modified.',
     	format => '',
     	read_only => '',
     		},
     'amount' => {
     	datatype => 'double',
     	base_name => 'Amount',
     	description => 'Represents amount of error bar.                         The amount must be greater than or equal to zero.',
     	format => '',
     	read_only => '',
     		},
     'display_type' => {
     	datatype => 'string',
     	base_name => 'DisplayType',
     	description => 'Represents error bar display type.',
     	format => '',
     	read_only => '',
     		},
     'minus_value' => {
     	datatype => 'string',
     	base_name => 'MinusValue',
     	description => 'Represents negative error amount when error bar type is Custom.',
     	format => '',
     	read_only => '',
     		},
     'plus_value' => {
     	datatype => 'string',
     	base_name => 'PlusValue',
     	description => 'Represents positive error amount when error bar type is Custom.',
     	format => '',
     	read_only => '',
     		},
     'show_marker_t_top' => {
     	datatype => 'boolean',
     	base_name => 'ShowMarkerTTop',
     	description => 'Indicates if formatting error bars with a T-top.',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => 'Represents error bar amount type.',
     	format => '',
     	read_only => '',
     		},
     'begin_arrow_length' => {
     	datatype => 'string',
     	base_name => 'BeginArrowLength',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'begin_arrow_width' => {
     	datatype => 'string',
     	base_name => 'BeginArrowWidth',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'begin_type' => {
     	datatype => 'string',
     	base_name => 'BeginType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'cap_type' => {
     	datatype => 'string',
     	base_name => 'CapType',
     	description => '',
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
     'compound_type' => {
     	datatype => 'string',
     	base_name => 'CompoundType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'dash_type' => {
     	datatype => 'string',
     	base_name => 'DashType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'end_arrow_length' => {
     	datatype => 'string',
     	base_name => 'EndArrowLength',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'end_arrow_width' => {
     	datatype => 'string',
     	base_name => 'EndArrowWidth',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'end_type' => {
     	datatype => 'string',
     	base_name => 'EndType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'gradient_fill' => {
     	datatype => 'GradientFill',
     	base_name => 'GradientFill',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_auto' => {
     	datatype => 'boolean',
     	base_name => 'IsAuto',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_automatic_color' => {
     	datatype => 'boolean',
     	base_name => 'IsAutomaticColor',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVisible',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'join_type' => {
     	datatype => 'string',
     	base_name => 'JoinType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'style' => {
     	datatype => 'string',
     	base_name => 'Style',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'transparency' => {
     	datatype => 'double',
     	base_name => 'Transparency',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'weight' => {
     	datatype => 'string',
     	base_name => 'Weight',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'weight_pt' => {
     	datatype => 'double',
     	base_name => 'WeightPt',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'link' => 'Link',
    'amount' => 'double',
    'display_type' => 'string',
    'minus_value' => 'string',
    'plus_value' => 'string',
    'show_marker_t_top' => 'boolean',
    'type' => 'string',
    'begin_arrow_length' => 'string',
    'begin_arrow_width' => 'string',
    'begin_type' => 'string',
    'cap_type' => 'string',
    'color' => 'Color',
    'compound_type' => 'string',
    'dash_type' => 'string',
    'end_arrow_length' => 'string',
    'end_arrow_width' => 'string',
    'end_type' => 'string',
    'gradient_fill' => 'GradientFill',
    'is_auto' => 'boolean',
    'is_automatic_color' => 'boolean',
    'is_visible' => 'boolean',
    'join_type' => 'string',
    'style' => 'string',
    'transparency' => 'double',
    'weight' => 'string',
    'weight_pt' => 'double' 
} );

__PACKAGE__->attribute_map( {
    'link' => 'Link',
    'amount' => 'Amount',
    'display_type' => 'DisplayType',
    'minus_value' => 'MinusValue',
    'plus_value' => 'PlusValue',
    'show_marker_t_top' => 'ShowMarkerTTop',
    'type' => 'Type',
    'begin_arrow_length' => 'BeginArrowLength',
    'begin_arrow_width' => 'BeginArrowWidth',
    'begin_type' => 'BeginType',
    'cap_type' => 'CapType',
    'color' => 'Color',
    'compound_type' => 'CompoundType',
    'dash_type' => 'DashType',
    'end_arrow_length' => 'EndArrowLength',
    'end_arrow_width' => 'EndArrowWidth',
    'end_type' => 'EndType',
    'gradient_fill' => 'GradientFill',
    'is_auto' => 'IsAuto',
    'is_automatic_color' => 'IsAutomaticColor',
    'is_visible' => 'IsVisible',
    'join_type' => 'JoinType',
    'style' => 'Style',
    'transparency' => 'Transparency',
    'weight' => 'Weight',
    'weight_pt' => 'WeightPt' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;