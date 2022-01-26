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


package AsposeCellsCloud::Object::Chart;

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
                                  class => 'Chart',
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
    'first_slice_angle' => {
    	datatype => 'int',
    	base_name => 'FirstSliceAngle',
    	description => 'Gets or sets the angle of the first pie-chart or doughnut-chart slice, in degrees (clockwise from vertical). Applies only to pie, 3-D pie, and doughnut charts, 0 to 360.',
    	format => '',
    	read_only => '',
    		},
    'floor' => {
    	datatype => 'LinkElement',
    	base_name => 'Floor',
    	description => 'Returns a Floor object that represents the walls of a 3-D chart.             ',
    	format => '',
    	read_only => '',
    		},
    'plot_empty_cells_type' => {
    	datatype => 'string',
    	base_name => 'PlotEmptyCellsType',
    	description => 'Gets and sets how to plot the empty cells.',
    	format => '',
    	read_only => '',
    		},
    'auto_scaling' => {
    	datatype => 'boolean',
    	base_name => 'AutoScaling',
    	description => 'True if Microsoft Excel scales a 3-D chart so that it&#39;s closer in size to the equivalent 2-D chart. The RightAngleAxes property must be True.',
    	format => '',
    	read_only => '',
    		},
    'style' => {
    	datatype => 'int',
    	base_name => 'Style',
    	description => 'Gets and sets the builtin style.',
    	format => '',
    	read_only => '',
    		},
    'series_axis' => {
    	datatype => 'LinkElement',
    	base_name => 'SeriesAxis',
    	description => 'Gets the chart&#39;s series axis.',
    	format => '',
    	read_only => '',
    		},
    'value_axis' => {
    	datatype => 'LinkElement',
    	base_name => 'ValueAxis',
    	description => 'Gets the chart&#39;s Y axis.',
    	format => '',
    	read_only => '',
    		},
    'show_data_table' => {
    	datatype => 'boolean',
    	base_name => 'ShowDataTable',
    	description => 'Gets or sets a value indicating whether the chart displays a data table.',
    	format => '',
    	read_only => '',
    		},
    'is3_d' => {
    	datatype => 'boolean',
    	base_name => 'Is3D',
    	description => 'Indicates whether the chart is a 3d chart.',
    	format => '',
    	read_only => '',
    		},
    'chart_area' => {
    	datatype => 'LinkElement',
    	base_name => 'ChartArea',
    	description => 'Gets the chart area in the worksheet',
    	format => '',
    	read_only => '',
    		},
    'elevation' => {
    	datatype => 'int',
    	base_name => 'Elevation',
    	description => 'Represents the elevation of the 3-D chart view, in degrees.',
    	format => '',
    	read_only => '',
    		},
    'side_wall' => {
    	datatype => 'LinkElement',
    	base_name => 'SideWall',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'type' => {
    	datatype => 'string',
    	base_name => 'Type',
    	description => 'Gets or sets a chart&#39;s type.',
    	format => '',
    	read_only => '',
    		},
    'title' => {
    	datatype => 'LinkElement',
    	base_name => 'Title',
    	description => 'Gets the chart&#39;s title.',
    	format => '',
    	read_only => '',
    		},
    'walls' => {
    	datatype => 'LinkElement',
    	base_name => 'Walls',
    	description => 'Returns a Walls object that represents the walls of a 3-D chart.',
    	format => '',
    	read_only => '',
    		},
    'back_wall' => {
    	datatype => 'LinkElement',
    	base_name => 'BackWall',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'chart_data_table' => {
    	datatype => 'LinkElement',
    	base_name => 'ChartDataTable',
    	description => 'Represents the chart data table.',
    	format => '',
    	read_only => '',
    		},
    'height_percent' => {
    	datatype => 'int',
    	base_name => 'HeightPercent',
    	description => 'Returns or sets the height of a 3-D chart as a percentage of the chart width (between 5 and 500 percent).',
    	format => '',
    	read_only => '',
    		},
    'gap_width' => {
    	datatype => 'int',
    	base_name => 'GapWidth',
    	description => 'Returns or sets the space between bar or column clusters, as a percentage of the bar or column width. The value of this property must be between 0 and 500.             ',
    	format => '',
    	read_only => '',
    		},
    'legend' => {
    	datatype => 'LinkElement',
    	base_name => 'Legend',
    	description => 'Gets the chart legend.',
    	format => '',
    	read_only => '',
    		},
    'chart_object' => {
    	datatype => 'LinkElement',
    	base_name => 'ChartObject',
    	description => 'Represents the chartShape;',
    	format => '',
    	read_only => '',
    		},
    'is_rectangular_cornered' => {
    	datatype => 'boolean',
    	base_name => 'IsRectangularCornered',
    	description => 'Gets or sets a value indicating whether the chart displays a data table.',
    	format => '',
    	read_only => '',
    		},
    'second_category_axis' => {
    	datatype => 'LinkElement',
    	base_name => 'SecondCategoryAxis',
    	description => 'Gets the chart&#39;s second X axis.',
    	format => '',
    	read_only => '',
    		},
    'second_value_axis' => {
    	datatype => 'LinkElement',
    	base_name => 'SecondValueAxis',
    	description => 'Gets the chart&#39;s second Y axis.',
    	format => '',
    	read_only => '',
    		},
    'placement' => {
    	datatype => 'string',
    	base_name => 'Placement',
    	description => 'Represents the way the chart is attached to the cells below it.',
    	format => '',
    	read_only => '',
    		},
    'name' => {
    	datatype => 'string',
    	base_name => 'Name',
    	description => 'Gets and sets the name of the chart.',
    	format => '',
    	read_only => '',
    		},
    'size_with_window' => {
    	datatype => 'boolean',
    	base_name => 'SizeWithWindow',
    	description => 'True if Microsoft Excel resizes the chart to match the size of the chart sheet window.',
    	format => '',
    	read_only => '',
    		},
    'right_angle_axes' => {
    	datatype => 'boolean',
    	base_name => 'RightAngleAxes',
    	description => 'True if the chart axes are at right angles.Applies only for 3-D charts(except Column3D and 3-D Pie Charts).',
    	format => '',
    	read_only => '',
    		},
    'plot_visible_cells' => {
    	datatype => 'boolean',
    	base_name => 'PlotVisibleCells',
    	description => 'Indicates whether only plot visible cells.',
    	format => '',
    	read_only => '',
    		},
    'show_legend' => {
    	datatype => 'boolean',
    	base_name => 'ShowLegend',
    	description => 'Gets or sets a value indicating whether the chart legend will be displayed. Default is true.',
    	format => '',
    	read_only => '',
    		},
    'pivot_source' => {
    	datatype => 'string',
    	base_name => 'PivotSource',
    	description => 'The source is the data of the pivotTable.If PivotSource is not empty ,the chart is PivotChart.',
    	format => '',
    	read_only => '',
    		},
    'depth_percent' => {
    	datatype => 'int',
    	base_name => 'DepthPercent',
    	description => 'Represents the depth of a 3-D chart as a percentage of the chart width (between 20 and 2000 percent).',
    	format => '',
    	read_only => '',
    		},
    'print_size' => {
    	datatype => 'string',
    	base_name => 'PrintSize',
    	description => 'Gets and sets the printed chart size.',
    	format => '',
    	read_only => '',
    		},
    'gap_depth' => {
    	datatype => 'int',
    	base_name => 'GapDepth',
    	description => 'Gets or sets the distance between the data series in a 3-D chart, as a percentage of the marker width.The value of this property must be between 0 and 500.',
    	format => '',
    	read_only => '',
    		},
    'shapes' => {
    	datatype => 'LinkElement',
    	base_name => 'Shapes',
    	description => 'Returns all drawing shapes in this chart.',
    	format => '',
    	read_only => '',
    		},
    'walls_and_gridlines2_d' => {
    	datatype => 'boolean',
    	base_name => 'WallsAndGridlines2D',
    	description => 'True if gridlines are drawn two-dimensionally on a 3-D chart.',
    	format => '',
    	read_only => '',
    		},
    'n_series' => {
    	datatype => 'LinkElement',
    	base_name => 'NSeries',
    	description => 'Gets a SeriesCollection collection representing the data series in the chart.',
    	format => '',
    	read_only => '',
    		},
    'rotation_angle' => {
    	datatype => 'int',
    	base_name => 'RotationAngle',
    	description => 'Represents the rotation of the 3-D chart view (the rotation of the plot area around the z-axis, in degrees).',
    	format => '',
    	read_only => '',
    		},
    'plot_area' => {
    	datatype => 'LinkElement',
    	base_name => 'PlotArea',
    	description => 'Gets the chart&#39;s plot area which includes axis tick lables.',
    	format => '',
    	read_only => '',
    		},
    'category_axis' => {
    	datatype => 'LinkElement',
    	base_name => 'CategoryAxis',
    	description => 'Gets the chart&#39;s X axis. The property is read only',
    	format => '',
    	read_only => '',
    		},
    'perspective' => {
    	datatype => 'int',
    	base_name => 'Perspective',
    	description => 'Returns or sets the perspective for the 3-D chart view. Must be between 0 and 100.This property is ignored if the RightAngleAxes property is True.',
    	format => '',
    	read_only => '',
    		},
    'hide_pivot_field_buttons' => {
    	datatype => 'boolean',
    	base_name => 'HidePivotFieldButtons',
    	description => 'Indicates whether hide the pivot chart field buttons only when the chart is PivotChart',
    	format => '',
    	read_only => '',
    		},
    'page_setup' => {
    	datatype => 'LinkElement',
    	base_name => 'PageSetup',
    	description => 'Represents the page setup description in this chart.',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'link' => 'Link',
    'first_slice_angle' => 'int',
    'floor' => 'LinkElement',
    'plot_empty_cells_type' => 'string',
    'auto_scaling' => 'boolean',
    'style' => 'int',
    'series_axis' => 'LinkElement',
    'value_axis' => 'LinkElement',
    'show_data_table' => 'boolean',
    'is3_d' => 'boolean',
    'chart_area' => 'LinkElement',
    'elevation' => 'int',
    'side_wall' => 'LinkElement',
    'type' => 'string',
    'title' => 'LinkElement',
    'walls' => 'LinkElement',
    'back_wall' => 'LinkElement',
    'chart_data_table' => 'LinkElement',
    'height_percent' => 'int',
    'gap_width' => 'int',
    'legend' => 'LinkElement',
    'chart_object' => 'LinkElement',
    'is_rectangular_cornered' => 'boolean',
    'second_category_axis' => 'LinkElement',
    'second_value_axis' => 'LinkElement',
    'placement' => 'string',
    'name' => 'string',
    'size_with_window' => 'boolean',
    'right_angle_axes' => 'boolean',
    'plot_visible_cells' => 'boolean',
    'show_legend' => 'boolean',
    'pivot_source' => 'string',
    'depth_percent' => 'int',
    'print_size' => 'string',
    'gap_depth' => 'int',
    'shapes' => 'LinkElement',
    'walls_and_gridlines2_d' => 'boolean',
    'n_series' => 'LinkElement',
    'rotation_angle' => 'int',
    'plot_area' => 'LinkElement',
    'category_axis' => 'LinkElement',
    'perspective' => 'int',
    'hide_pivot_field_buttons' => 'boolean',
    'page_setup' => 'LinkElement'
} );

__PACKAGE__->attribute_map( {
    'link' => 'link',
    'first_slice_angle' => 'FirstSliceAngle',
    'floor' => 'Floor',
    'plot_empty_cells_type' => 'PlotEmptyCellsType',
    'auto_scaling' => 'AutoScaling',
    'style' => 'Style',
    'series_axis' => 'SeriesAxis',
    'value_axis' => 'ValueAxis',
    'show_data_table' => 'ShowDataTable',
    'is3_d' => 'Is3D',
    'chart_area' => 'ChartArea',
    'elevation' => 'Elevation',
    'side_wall' => 'SideWall',
    'type' => 'Type',
    'title' => 'Title',
    'walls' => 'Walls',
    'back_wall' => 'BackWall',
    'chart_data_table' => 'ChartDataTable',
    'height_percent' => 'HeightPercent',
    'gap_width' => 'GapWidth',
    'legend' => 'Legend',
    'chart_object' => 'ChartObject',
    'is_rectangular_cornered' => 'IsRectangularCornered',
    'second_category_axis' => 'SecondCategoryAxis',
    'second_value_axis' => 'SecondValueAxis',
    'placement' => 'Placement',
    'name' => 'Name',
    'size_with_window' => 'SizeWithWindow',
    'right_angle_axes' => 'RightAngleAxes',
    'plot_visible_cells' => 'PlotVisibleCells',
    'show_legend' => 'ShowLegend',
    'pivot_source' => 'PivotSource',
    'depth_percent' => 'DepthPercent',
    'print_size' => 'PrintSize',
    'gap_depth' => 'GapDepth',
    'shapes' => 'Shapes',
    'walls_and_gridlines2_d' => 'WallsAndGridlines2D',
    'n_series' => 'NSeries',
    'rotation_angle' => 'RotationAngle',
    'plot_area' => 'PlotArea',
    'category_axis' => 'CategoryAxis',
    'perspective' => 'Perspective',
    'hide_pivot_field_buttons' => 'HidePivotFieldButtons',
    'page_setup' => 'PageSetup'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
