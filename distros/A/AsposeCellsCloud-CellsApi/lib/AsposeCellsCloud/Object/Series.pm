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

package AsposeCellsCloud::Object::Series;

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
use AsposeCellsCloud::Object::DropBars;
use AsposeCellsCloud::Object::ErrorBar;
use AsposeCellsCloud::Object::LegendEntry;
use AsposeCellsCloud::Object::Line;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::LinkElement;
use AsposeCellsCloud::Object::Marker;
use AsposeCellsCloud::Object::Trendlines; 


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


__PACKAGE__->class_documentation({description => 'Encapsulates the object that represents a single data series in a chart.',
                                  class => 'Series',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'area' => {
     	datatype => 'Area',
     	base_name => 'Area',
     	description => 'Represents the background area of Series object.',
     	format => '',
     	read_only => '',
     		},
     'bar3_d_shape_type' => {
     	datatype => 'string',
     	base_name => 'Bar3DShapeType',
     	description => 'Gets or sets the 3D shape type used with the 3-D bar or column chart.',
     	format => '',
     	read_only => '',
     		},
     'border' => {
     	datatype => 'Line',
     	base_name => 'Border',
     	description => 'Represents border of Series object.',
     	format => '',
     	read_only => '',
     		},
     'bubble_scale' => {
     	datatype => 'int',
     	base_name => 'BubbleScale',
     	description => 'Gets or sets the scale factor for bubbles in the specified chart group.                         It can be an integer value from 0 (zero) to 300,                         corresponding to a percentage of the default size.                        Applies only to bubble charts.',
     	format => '',
     	read_only => '',
     		},
     'bubble_sizes' => {
     	datatype => 'string',
     	base_name => 'BubbleSizes',
     	description => 'Gets or sets the bubble sizes values of the chart series.',
     	format => '',
     	read_only => '',
     		},
     'count_of_data_values' => {
     	datatype => 'int',
     	base_name => 'CountOfDataValues',
     	description => 'Gets the number of the data values.',
     	format => '',
     	read_only => '',
     		},
     'data_labels' => {
     	datatype => 'DataLabels',
     	base_name => 'DataLabels',
     	description => 'Represents the DataLabels object for the specified ASeries.',
     	format => '',
     	read_only => '',
     		},
     'display_name' => {
     	datatype => 'string',
     	base_name => 'DisplayName',
     	description => 'Gets the series`s name that displays on the chart graph.',
     	format => '',
     	read_only => '',
     		},
     'doughnut_hole_size' => {
     	datatype => 'int',
     	base_name => 'DoughnutHoleSize',
     	description => 'Returns or sets the size of the hole in a doughnut chart group.                         The hole size is expressed as a percentage of the chart size, between 10 and 90 percent.',
     	format => '',
     	read_only => '',
     		},
     'down_bars' => {
     	datatype => 'DropBars',
     	base_name => 'DownBars',
     	description => 'Returns a  object that represents the down bars on a line chart.                        Applies only to line charts.',
     	format => '',
     	read_only => '',
     		},
     'drop_lines' => {
     	datatype => 'Line',
     	base_name => 'DropLines',
     	description => 'Returns a  object that represents the drop lines for a series on the line chart or area chart.                        Applies only to line chart or area charts.',
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
     'first_slice_angle' => {
     	datatype => 'int',
     	base_name => 'FirstSliceAngle',
     	description => 'Gets or sets the angle of the first pie-chart or doughnut-chart slice, in degrees (clockwise from vertical).                         Applies only to pie, 3-D pie, and doughnut charts, 0 to 360.',
     	format => '',
     	read_only => '',
     		},
     'gap_width' => {
     	datatype => 'int',
     	base_name => 'GapWidth',
     	description => 'Returns or sets the space between bar or column clusters, as a percentage of the bar or column width.                        The value of this property must be between 0 and 500.',
     	format => '',
     	read_only => '',
     		},
     'has3_d_effect' => {
     	datatype => 'boolean',
     	base_name => 'Has3DEffect',
     	description => 'True if the series has a three-dimensional appearance.                         Applies only to bubble charts.',
     	format => '',
     	read_only => '',
     		},
     'has_drop_lines' => {
     	datatype => 'boolean',
     	base_name => 'HasDropLines',
     	description => 'True if the chart has drop lines.                        Applies only to line chart or area charts.',
     	format => '',
     	read_only => '',
     		},
     'has_hi_lo_lines' => {
     	datatype => 'boolean',
     	base_name => 'HasHiLoLines',
     	description => 'True if the line chart has high-low lines.                          Applies only to line charts.',
     	format => '',
     	read_only => '',
     		},
     'has_leader_lines' => {
     	datatype => 'boolean',
     	base_name => 'HasLeaderLines',
     	description => 'True if the series has leader lines.',
     	format => '',
     	read_only => '',
     		},
     'has_radar_axis_labels' => {
     	datatype => 'boolean',
     	base_name => 'HasRadarAxisLabels',
     	description => 'True if a radar chart has category axis labels. Applies only to radar charts.',
     	format => '',
     	read_only => '',
     		},
     'has_series_lines' => {
     	datatype => 'boolean',
     	base_name => 'HasSeriesLines',
     	description => 'True if a stacked column chart or bar chart has series lines or                        if a Pie of Pie chart or Bar of Pie chart has connector lines between the two sections.                         Applies only to stacked column charts, bar charts, Pie of Pie charts, or Bar of Pie charts.',
     	format => '',
     	read_only => '',
     		},
     'has_up_down_bars' => {
     	datatype => 'boolean',
     	base_name => 'HasUpDownBars',
     	description => 'True if a line chart has up and down bars.                        Applies only to line charts.',
     	format => '',
     	read_only => '',
     		},
     'hi_lo_lines' => {
     	datatype => 'Line',
     	base_name => 'HiLoLines',
     	description => 'Returns a HiLoLines object that represents the high-low lines for a series on a line chart.                         Applies only to line charts.',
     	format => '',
     	read_only => '',
     		},
     'is_auto_split' => {
     	datatype => 'boolean',
     	base_name => 'IsAutoSplit',
     	description => 'Indicates whether the threshold value is automatic.',
     	format => '',
     	read_only => '',
     		},
     'is_color_varied' => {
     	datatype => 'boolean',
     	base_name => 'IsColorVaried',
     	description => 'Represents if the color of points is varied.                         The chart must contain only one series.',
     	format => '',
     	read_only => '',
     		},
     'leader_lines' => {
     	datatype => 'Line',
     	base_name => 'LeaderLines',
     	description => 'Represents leader lines on a chart. Leader lines connect data labels to data points.                         This object isn’t a collection; there’s no object that represents a single leader line.',
     	format => '',
     	read_only => '',
     		},
     'legend_entry' => {
     	datatype => 'LegendEntry',
     	base_name => 'LegendEntry',
     	description => 'Gets the legend entry according to this series.',
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
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Gets or sets the name of the data series.',
     	format => '',
     	read_only => '',
     		},
     'overlap' => {
     	datatype => 'int',
     	base_name => 'Overlap',
     	description => 'Specifies how bars and columns are positioned.                        Can be a value between – 100 and 100.                         Applies only to 2-D bar and 2-D column charts.',
     	format => '',
     	read_only => '',
     		},
     'plot_on_second_axis' => {
     	datatype => 'boolean',
     	base_name => 'PlotOnSecondAxis',
     	description => 'Indicates if this series is plotted on second value axis.',
     	format => '',
     	read_only => '',
     		},
     'points' => {
     	datatype => 'LinkElement',
     	base_name => 'Points',
     	description => 'Gets the collection of points in a series in a chart.',
     	format => '',
     	read_only => '',
     		},
     'second_plot_size' => {
     	datatype => 'int',
     	base_name => 'SecondPlotSize',
     	description => 'Returns or sets the size of the secondary section of either a pie of pie chart or a bar of pie chart,                         as a percentage of the size of the primary pie.                        Can be a value from 5 to 200.',
     	format => '',
     	read_only => '',
     		},
     'series_lines' => {
     	datatype => 'Line',
     	base_name => 'SeriesLines',
     	description => 'Returns a SeriesLines object that represents the series lines for a stacked bar chart or a stacked column chart.                        Applies only to stacked bar and stacked column charts.',
     	format => '',
     	read_only => '',
     		},
     'shadow' => {
     	datatype => 'boolean',
     	base_name => 'Shadow',
     	description => 'True if the series has a shadow.',
     	format => '',
     	read_only => '',
     		},
     'show_negative_bubbles' => {
     	datatype => 'boolean',
     	base_name => 'ShowNegativeBubbles',
     	description => 'True if negative bubbles are shown for the chart group. Valid only for bubble charts.',
     	format => '',
     	read_only => '',
     		},
     'size_represents' => {
     	datatype => 'string',
     	base_name => 'SizeRepresents',
     	description => 'Gets or sets what the bubble size represents on a bubble chart.',
     	format => '',
     	read_only => '',
     		},
     'smooth' => {
     	datatype => 'boolean',
     	base_name => 'Smooth',
     	description => 'Represents curve smoothing.                         True if curve smoothing is turned on for the line chart or scatter chart.                        Applies only to line and scatter connected by lines charts.',
     	format => '',
     	read_only => '',
     		},
     'split_type' => {
     	datatype => 'string',
     	base_name => 'SplitType',
     	description => 'Returns or sets a value that how to determine which data points are in the second pie or bar on a pie of pie or bar of                        pie chart.',
     	format => '',
     	read_only => '',
     		},
     'split_value' => {
     	datatype => 'double',
     	base_name => 'SplitValue',
     	description => 'Returns or sets a value that shall be used to determine which data points are in the second pie or bar on                        a pie of pie or bar of pie chart.',
     	format => '',
     	read_only => '',
     		},
     'trend_lines' => {
     	datatype => 'Trendlines',
     	base_name => 'TrendLines',
     	description => 'Returns an object that represents a collection of all the trendlines for the series.',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => 'Gets or sets a data series` type.',
     	format => '',
     	read_only => '',
     		},
     'up_bars' => {
     	datatype => 'DropBars',
     	base_name => 'UpBars',
     	description => 'Returns an DropBars object that represents the up bars on a line chart.                        Applies only to line charts.',
     	format => '',
     	read_only => '',
     		},
     'values' => {
     	datatype => 'string',
     	base_name => 'Values',
     	description => 'Represents the data of the chart series.',
     	format => '',
     	read_only => '',
     		},
     'x_error_bar' => {
     	datatype => 'ErrorBar',
     	base_name => 'XErrorBar',
     	description => 'Represents X direction error bar of the series.',
     	format => '',
     	read_only => '',
     		},
     'x_values' => {
     	datatype => 'string',
     	base_name => 'XValues',
     	description => 'Represents the x values of the chart series.',
     	format => '',
     	read_only => '',
     		},
     'y_error_bar' => {
     	datatype => 'ErrorBar',
     	base_name => 'YErrorBar',
     	description => 'Represents Y direction error bar of the series.',
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
    'bar3_d_shape_type' => 'string',
    'border' => 'Line',
    'bubble_scale' => 'int',
    'bubble_sizes' => 'string',
    'count_of_data_values' => 'int',
    'data_labels' => 'DataLabels',
    'display_name' => 'string',
    'doughnut_hole_size' => 'int',
    'down_bars' => 'DropBars',
    'drop_lines' => 'Line',
    'explosion' => 'int',
    'first_slice_angle' => 'int',
    'gap_width' => 'int',
    'has3_d_effect' => 'boolean',
    'has_drop_lines' => 'boolean',
    'has_hi_lo_lines' => 'boolean',
    'has_leader_lines' => 'boolean',
    'has_radar_axis_labels' => 'boolean',
    'has_series_lines' => 'boolean',
    'has_up_down_bars' => 'boolean',
    'hi_lo_lines' => 'Line',
    'is_auto_split' => 'boolean',
    'is_color_varied' => 'boolean',
    'leader_lines' => 'Line',
    'legend_entry' => 'LegendEntry',
    'marker' => 'Marker',
    'name' => 'string',
    'overlap' => 'int',
    'plot_on_second_axis' => 'boolean',
    'points' => 'LinkElement',
    'second_plot_size' => 'int',
    'series_lines' => 'Line',
    'shadow' => 'boolean',
    'show_negative_bubbles' => 'boolean',
    'size_represents' => 'string',
    'smooth' => 'boolean',
    'split_type' => 'string',
    'split_value' => 'double',
    'trend_lines' => 'Trendlines',
    'type' => 'string',
    'up_bars' => 'DropBars',
    'values' => 'string',
    'x_error_bar' => 'ErrorBar',
    'x_values' => 'string',
    'y_error_bar' => 'ErrorBar',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'area' => 'Area',
    'bar3_d_shape_type' => 'Bar3DShapeType',
    'border' => 'Border',
    'bubble_scale' => 'BubbleScale',
    'bubble_sizes' => 'BubbleSizes',
    'count_of_data_values' => 'CountOfDataValues',
    'data_labels' => 'DataLabels',
    'display_name' => 'DisplayName',
    'doughnut_hole_size' => 'DoughnutHoleSize',
    'down_bars' => 'DownBars',
    'drop_lines' => 'DropLines',
    'explosion' => 'Explosion',
    'first_slice_angle' => 'FirstSliceAngle',
    'gap_width' => 'GapWidth',
    'has3_d_effect' => 'Has3DEffect',
    'has_drop_lines' => 'HasDropLines',
    'has_hi_lo_lines' => 'HasHiLoLines',
    'has_leader_lines' => 'HasLeaderLines',
    'has_radar_axis_labels' => 'HasRadarAxisLabels',
    'has_series_lines' => 'HasSeriesLines',
    'has_up_down_bars' => 'HasUpDownBars',
    'hi_lo_lines' => 'HiLoLines',
    'is_auto_split' => 'IsAutoSplit',
    'is_color_varied' => 'IsColorVaried',
    'leader_lines' => 'LeaderLines',
    'legend_entry' => 'LegendEntry',
    'marker' => 'Marker',
    'name' => 'Name',
    'overlap' => 'Overlap',
    'plot_on_second_axis' => 'PlotOnSecondAxis',
    'points' => 'Points',
    'second_plot_size' => 'SecondPlotSize',
    'series_lines' => 'SeriesLines',
    'shadow' => 'Shadow',
    'show_negative_bubbles' => 'ShowNegativeBubbles',
    'size_represents' => 'SizeRepresents',
    'smooth' => 'Smooth',
    'split_type' => 'SplitType',
    'split_value' => 'SplitValue',
    'trend_lines' => 'TrendLines',
    'type' => 'Type',
    'up_bars' => 'UpBars',
    'values' => 'Values',
    'x_error_bar' => 'XErrorBar',
    'x_values' => 'XValues',
    'y_error_bar' => 'YErrorBar',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;