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

package AsposeCellsCloud::Object::LineFormat;

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
use AsposeCellsCloud::Object::FillFormat;
use AsposeCellsCloud::Object::GradientFill;
use AsposeCellsCloud::Object::PatternFill;
use AsposeCellsCloud::Object::SolidFill;
use AsposeCellsCloud::Object::TextureFill; 


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


__PACKAGE__->class_documentation({description => 'Represents all setting of the line.',
                                  class => 'LineFormat',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'begin_arrowhead_length' => {
     	datatype => 'string',
     	base_name => 'BeginArrowheadLength',
     	description => 'Gets and sets the begin arrow length type of the line.',
     	format => '',
     	read_only => '',
     		},
     'begin_arrowhead_style' => {
     	datatype => 'string',
     	base_name => 'BeginArrowheadStyle',
     	description => 'Gets and sets the begin arrow type of the line.',
     	format => '',
     	read_only => '',
     		},
     'begin_arrowhead_width' => {
     	datatype => 'string',
     	base_name => 'BeginArrowheadWidth',
     	description => 'Gets and sets the begin arrow width type of the line.',
     	format => '',
     	read_only => '',
     		},
     'cap_type' => {
     	datatype => 'string',
     	base_name => 'CapType',
     	description => 'Specifies the ending caps.',
     	format => '',
     	read_only => '',
     		},
     'compound_type' => {
     	datatype => 'string',
     	base_name => 'CompoundType',
     	description => 'Specifies the line compound type.',
     	format => '',
     	read_only => '',
     		},
     'dash_style' => {
     	datatype => 'string',
     	base_name => 'DashStyle',
     	description => 'Specifies the line dash type.',
     	format => '',
     	read_only => '',
     		},
     'end_arrowhead_length' => {
     	datatype => 'string',
     	base_name => 'EndArrowheadLength',
     	description => 'Gets and sets the end arrow length type of the line.',
     	format => '',
     	read_only => '',
     		},
     'end_arrowhead_style' => {
     	datatype => 'string',
     	base_name => 'EndArrowheadStyle',
     	description => 'Gets and sets the end arrow type of the line.',
     	format => '',
     	read_only => '',
     		},
     'end_arrowhead_width' => {
     	datatype => 'string',
     	base_name => 'EndArrowheadWidth',
     	description => 'Gets and sets the end arrow width type of the line.',
     	format => '',
     	read_only => '',
     		},
     'join_type' => {
     	datatype => 'string',
     	base_name => 'JoinType',
     	description => 'Specifies the line join type.',
     	format => '',
     	read_only => '',
     		},
     'weight' => {
     	datatype => 'double',
     	base_name => 'Weight',
     	description => 'Gets or sets the weight of the line in unit of points.',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'solid_fill' => {
     	datatype => 'SolidFill',
     	base_name => 'SolidFill',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'pattern_fill' => {
     	datatype => 'PatternFill',
     	base_name => 'PatternFill',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'texture_fill' => {
     	datatype => 'TextureFill',
     	base_name => 'TextureFill',
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
     'image_data' => {
     	datatype => 'string',
     	base_name => 'ImageData',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'begin_arrowhead_length' => 'string',
    'begin_arrowhead_style' => 'string',
    'begin_arrowhead_width' => 'string',
    'cap_type' => 'string',
    'compound_type' => 'string',
    'dash_style' => 'string',
    'end_arrowhead_length' => 'string',
    'end_arrowhead_style' => 'string',
    'end_arrowhead_width' => 'string',
    'join_type' => 'string',
    'weight' => 'double',
    'type' => 'string',
    'solid_fill' => 'SolidFill',
    'pattern_fill' => 'PatternFill',
    'texture_fill' => 'TextureFill',
    'gradient_fill' => 'GradientFill',
    'image_data' => 'string' 
} );

__PACKAGE__->attribute_map( {
    'begin_arrowhead_length' => 'BeginArrowheadLength',
    'begin_arrowhead_style' => 'BeginArrowheadStyle',
    'begin_arrowhead_width' => 'BeginArrowheadWidth',
    'cap_type' => 'CapType',
    'compound_type' => 'CompoundType',
    'dash_style' => 'DashStyle',
    'end_arrowhead_length' => 'EndArrowheadLength',
    'end_arrowhead_style' => 'EndArrowheadStyle',
    'end_arrowhead_width' => 'EndArrowheadWidth',
    'join_type' => 'JoinType',
    'weight' => 'Weight',
    'type' => 'Type',
    'solid_fill' => 'SolidFill',
    'pattern_fill' => 'PatternFill',
    'texture_fill' => 'TextureFill',
    'gradient_fill' => 'GradientFill',
    'image_data' => 'ImageData' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;