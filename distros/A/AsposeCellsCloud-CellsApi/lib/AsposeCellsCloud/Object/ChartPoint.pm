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

package AsposeCellsCloud::Object::ChartPoint;

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
use AsposeCellsCloud::Object::Area;
use AsposeCellsCloud::Object::DataLabels;
use AsposeCellsCloud::Object::Line;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::LinkElement;
use AsposeCellsCloud::Object::Marker; 


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
                                  class => 'ChartPoint',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'area' => {
     	datatype => 'Area',
     	base_name => 'Area',
     	description => 'Gets the area.',
     	format => '',
     	read_only => '',
     		},
     'border' => {
     	datatype => 'Line',
     	base_name => 'Border',
     	description => 'Gets the border.',
     	format => '',
     	read_only => '',
     		},
     'data_labels' => {
     	datatype => 'DataLabels',
     	base_name => 'DataLabels',
     	description => 'Returns a DataLabels object that represents the data label associated with the point.',
     	format => '',
     	read_only => '',
     		},
     'explosion' => {
     	datatype => 'int',
     	base_name => 'Explosion',
     	description => 'The distance of an open pie slice from the center of the pie chart is expressed as a percentage of the pie diameter.',
     	format => '',
     	read_only => '',
     		},
     'marker' => {
     	datatype => 'Marker',
     	base_name => 'Marker',
     	description => 'Gets the marker.',
     	format => '',
     	read_only => '',
     		},
     'shadow' => {
     	datatype => 'boolean',
     	base_name => 'Shadow',
     	description => 'True if the chartpoint has a shadow.',
     	format => '',
     	read_only => '',
     		},
     'x_value' => {
     	datatype => 'string',
     	base_name => 'XValue',
     	description => 'Gets or sets the X value of the chart point.',
     	format => '',
     	read_only => '',
     		},
     'y_value' => {
     	datatype => 'string',
     	base_name => 'YValue',
     	description => 'Gets or sets the Y value of the chart point.',
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
    'area' => 'Area',
    'border' => 'Line',
    'data_labels' => 'DataLabels',
    'explosion' => 'int',
    'marker' => 'Marker',
    'shadow' => 'boolean',
    'x_value' => 'string',
    'y_value' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'area' => 'Area',
    'border' => 'Border',
    'data_labels' => 'DataLabels',
    'explosion' => 'Explosion',
    'marker' => 'Marker',
    'shadow' => 'Shadow',
    'x_value' => 'XValue',
    'y_value' => 'YValue',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;