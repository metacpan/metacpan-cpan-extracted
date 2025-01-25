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

package AsposeCellsCloud::Object::StyleFormatCondition;

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
use AsposeCellsCloud::Object::AboveAverage;
use AsposeCellsCloud::Object::ColorScale;
use AsposeCellsCloud::Object::DataBar;
use AsposeCellsCloud::Object::FormatCondition;
use AsposeCellsCloud::Object::IconSet;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::Style;
use AsposeCellsCloud::Object::Top10; 


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


__PACKAGE__->class_documentation({description => 'Represents style format condition.',
                                  class => 'StyleFormatCondition',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'priority' => {
     	datatype => 'int',
     	base_name => 'Priority',
     	description => '',
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
     'stop_if_true' => {
     	datatype => 'boolean',
     	base_name => 'StopIfTrue',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'above_average' => {
     	datatype => 'AboveAverage',
     	base_name => 'AboveAverage',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'color_scale' => {
     	datatype => 'ColorScale',
     	base_name => 'ColorScale',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_bar' => {
     	datatype => 'DataBar',
     	base_name => 'DataBar',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'formula1' => {
     	datatype => 'string',
     	base_name => 'Formula1',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'formula2' => {
     	datatype => 'string',
     	base_name => 'Formula2',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'icon_set' => {
     	datatype => 'IconSet',
     	base_name => 'IconSet',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'operator' => {
     	datatype => 'string',
     	base_name => 'Operator',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'style' => {
     	datatype => 'Style',
     	base_name => 'Style',
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
     'time_period' => {
     	datatype => 'string',
     	base_name => 'TimePeriod',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'top10' => {
     	datatype => 'Top10',
     	base_name => 'Top10',
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
    'priority' => 'int',
    'type' => 'string',
    'stop_if_true' => 'boolean',
    'above_average' => 'AboveAverage',
    'color_scale' => 'ColorScale',
    'data_bar' => 'DataBar',
    'formula1' => 'string',
    'formula2' => 'string',
    'icon_set' => 'IconSet',
    'operator' => 'string',
    'style' => 'Style',
    'text' => 'string',
    'time_period' => 'string',
    'top10' => 'Top10',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'priority' => 'Priority',
    'type' => 'Type',
    'stop_if_true' => 'StopIfTrue',
    'above_average' => 'AboveAverage',
    'color_scale' => 'ColorScale',
    'data_bar' => 'DataBar',
    'formula1' => 'Formula1',
    'formula2' => 'Formula2',
    'icon_set' => 'IconSet',
    'operator' => 'Operator',
    'style' => 'Style',
    'text' => 'Text',
    'time_period' => 'TimePeriod',
    'top10' => 'Top10',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;