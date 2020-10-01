=begin comment

Copyright (c) 2020 Aspose.Cells Cloud
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


package AsposeCellsCloud::Object::SparklineGroup;

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
use AsposeCellsCloud::Object::Sparkline;

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
                                  class => 'SparklineGroup',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'display_hidden' => {
    	datatype => 'boolean',
    	base_name => 'DisplayHidden',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'first_point_color' => {
    	datatype => 'CellsColor',
    	base_name => 'FirstPointColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'high_point_color' => {
    	datatype => 'CellsColor',
    	base_name => 'HighPointColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'horizontal_axis_color' => {
    	datatype => 'CellsColor',
    	base_name => 'HorizontalAxisColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'horizontal_axis_date_range' => {
    	datatype => 'string',
    	base_name => 'HorizontalAxisDateRange',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'last_point_color' => {
    	datatype => 'CellsColor',
    	base_name => 'LastPointColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'line_weight' => {
    	datatype => 'double',
    	base_name => 'LineWeight',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'low_point_color' => {
    	datatype => 'CellsColor',
    	base_name => 'LowPointColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'markers_color' => {
    	datatype => 'CellsColor',
    	base_name => 'MarkersColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'negative_points_color' => {
    	datatype => 'CellsColor',
    	base_name => 'NegativePointsColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'plot_empty_cells_type' => {
    	datatype => 'string',
    	base_name => 'PlotEmptyCellsType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'plot_right_to_left' => {
    	datatype => 'boolean',
    	base_name => 'PlotRightToLeft',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'preset_style' => {
    	datatype => 'string',
    	base_name => 'PresetStyle',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'series_color' => {
    	datatype => 'CellsColor',
    	base_name => 'SeriesColor',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_first_point' => {
    	datatype => 'boolean',
    	base_name => 'ShowFirstPoint',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_high_point' => {
    	datatype => 'boolean',
    	base_name => 'ShowHighPoint',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_horizontal_axis' => {
    	datatype => 'boolean',
    	base_name => 'ShowHorizontalAxis',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_last_point' => {
    	datatype => 'boolean',
    	base_name => 'ShowLastPoint',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_low_point' => {
    	datatype => 'boolean',
    	base_name => 'ShowLowPoint',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_markers' => {
    	datatype => 'boolean',
    	base_name => 'ShowMarkers',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_negative_points' => {
    	datatype => 'boolean',
    	base_name => 'ShowNegativePoints',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'sparkline_collection' => {
    	datatype => 'ARRAY[Sparkline]',
    	base_name => 'SparklineCollection',
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
    'vertical_axis_max_value' => {
    	datatype => 'double',
    	base_name => 'VerticalAxisMaxValue',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'vertical_axis_max_value_type' => {
    	datatype => 'string',
    	base_name => 'VerticalAxisMaxValueType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'vertical_axis_min_value' => {
    	datatype => 'double',
    	base_name => 'VerticalAxisMinValue',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'vertical_axis_min_value_type' => {
    	datatype => 'string',
    	base_name => 'VerticalAxisMinValueType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'display_hidden' => 'boolean',
    'first_point_color' => 'CellsColor',
    'high_point_color' => 'CellsColor',
    'horizontal_axis_color' => 'CellsColor',
    'horizontal_axis_date_range' => 'string',
    'last_point_color' => 'CellsColor',
    'line_weight' => 'double',
    'low_point_color' => 'CellsColor',
    'markers_color' => 'CellsColor',
    'negative_points_color' => 'CellsColor',
    'plot_empty_cells_type' => 'string',
    'plot_right_to_left' => 'boolean',
    'preset_style' => 'string',
    'series_color' => 'CellsColor',
    'show_first_point' => 'boolean',
    'show_high_point' => 'boolean',
    'show_horizontal_axis' => 'boolean',
    'show_last_point' => 'boolean',
    'show_low_point' => 'boolean',
    'show_markers' => 'boolean',
    'show_negative_points' => 'boolean',
    'sparkline_collection' => 'ARRAY[Sparkline]',
    'type' => 'string',
    'vertical_axis_max_value' => 'double',
    'vertical_axis_max_value_type' => 'string',
    'vertical_axis_min_value' => 'double',
    'vertical_axis_min_value_type' => 'string'
} );

__PACKAGE__->attribute_map( {
    'display_hidden' => 'DisplayHidden',
    'first_point_color' => 'FirstPointColor',
    'high_point_color' => 'HighPointColor',
    'horizontal_axis_color' => 'HorizontalAxisColor',
    'horizontal_axis_date_range' => 'HorizontalAxisDateRange',
    'last_point_color' => 'LastPointColor',
    'line_weight' => 'LineWeight',
    'low_point_color' => 'LowPointColor',
    'markers_color' => 'MarkersColor',
    'negative_points_color' => 'NegativePointsColor',
    'plot_empty_cells_type' => 'PlotEmptyCellsType',
    'plot_right_to_left' => 'PlotRightToLeft',
    'preset_style' => 'PresetStyle',
    'series_color' => 'SeriesColor',
    'show_first_point' => 'ShowFirstPoint',
    'show_high_point' => 'ShowHighPoint',
    'show_horizontal_axis' => 'ShowHorizontalAxis',
    'show_last_point' => 'ShowLastPoint',
    'show_low_point' => 'ShowLowPoint',
    'show_markers' => 'ShowMarkers',
    'show_negative_points' => 'ShowNegativePoints',
    'sparkline_collection' => 'SparklineCollection',
    'type' => 'Type',
    'vertical_axis_max_value' => 'VerticalAxisMaxValue',
    'vertical_axis_max_value_type' => 'VerticalAxisMaxValueType',
    'vertical_axis_min_value' => 'VerticalAxisMinValue',
    'vertical_axis_min_value_type' => 'VerticalAxisMinValueType'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
