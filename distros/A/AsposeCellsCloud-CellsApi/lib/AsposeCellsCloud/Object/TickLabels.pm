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

package AsposeCellsCloud::Object::TickLabels;

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
use AsposeCellsCloud::Object::LinkElement; 


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
                                  class => 'TickLabels',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'auto_scale_font' => {
     	datatype => 'boolean',
     	base_name => 'AutoScaleFont',
     	description => 'True if the text in the object changes font size when the object size changes. The default value is True.',
     	format => '',
     	read_only => '',
     		},
     'background_mode' => {
     	datatype => 'string',
     	base_name => 'BackgroundMode',
     	description => 'Gets and sets the display mode of the background',
     	format => '',
     	read_only => '',
     		},
     'font' => {
     	datatype => 'Font',
     	base_name => 'Font',
     	description => 'Returns a  object that represents the font of the specified TickLabels object.',
     	format => '',
     	read_only => '',
     		},
     'number' => {
     	datatype => 'int',
     	base_name => 'Number',
     	description => 'Represents the format number for the TickLabels object.',
     	format => '',
     	read_only => '',
     		},
     'number_format' => {
     	datatype => 'string',
     	base_name => 'NumberFormat',
     	description => 'Represents the format string for the TickLabels object.',
     	format => '',
     	read_only => '',
     		},
     'number_format_linked' => {
     	datatype => 'boolean',
     	base_name => 'NumberFormatLinked',
     	description => 'True if the number format is linked to the cells                         (so that the number format changes in the labels when it changes in the cells).',
     	format => '',
     	read_only => '',
     		},
     'offset' => {
     	datatype => 'int',
     	base_name => 'Offset',
     	description => 'Gets and sets the distance of labels from the axis.',
     	format => '',
     	read_only => '',
     		},
     'rotation_angle' => {
     	datatype => 'int',
     	base_name => 'RotationAngle',
     	description => 'Represents text rotation angle in clockwise.',
     	format => '',
     	read_only => '',
     		},
     'text_direction' => {
     	datatype => 'string',
     	base_name => 'TextDirection',
     	description => 'Represents text reading order.',
     	format => '',
     	read_only => '',
     		},
     'reading_order' => {
     	datatype => 'string',
     	base_name => 'ReadingOrder',
     	description => 'Represents text reading order.',
     	format => '',
     	read_only => '',
     		},
     'direction_type' => {
     	datatype => 'string',
     	base_name => 'DirectionType',
     	description => 'Gets and sets the direction of text.',
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
    'auto_scale_font' => 'boolean',
    'background_mode' => 'string',
    'font' => 'Font',
    'number' => 'int',
    'number_format' => 'string',
    'number_format_linked' => 'boolean',
    'offset' => 'int',
    'rotation_angle' => 'int',
    'text_direction' => 'string',
    'reading_order' => 'string',
    'direction_type' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'auto_scale_font' => 'AutoScaleFont',
    'background_mode' => 'BackgroundMode',
    'font' => 'Font',
    'number' => 'Number',
    'number_format' => 'NumberFormat',
    'number_format_linked' => 'NumberFormatLinked',
    'offset' => 'Offset',
    'rotation_angle' => 'RotationAngle',
    'text_direction' => 'TextDirection',
    'reading_order' => 'ReadingOrder',
    'direction_type' => 'DirectionType',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;