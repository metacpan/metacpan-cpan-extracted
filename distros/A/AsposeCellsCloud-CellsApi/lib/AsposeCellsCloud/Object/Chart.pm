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
     'auto_scaling' => {
     	datatype => 'boolean',
     	base_name => 'AutoScaling',
     	description => '',
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
     'category_axis' => {
     	datatype => 'LinkElement',
     	base_name => 'CategoryAxis',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'chart_area' => {
     	datatype => 'LinkElement',
     	base_name => 'ChartArea',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'chart_data_table' => {
     	datatype => 'LinkElement',
     	base_name => 'ChartDataTable',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'chart_object' => {
     	datatype => 'LinkElement',
     	base_name => 'ChartObject',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'depth_percent' => {
     	datatype => 'int',
     	base_name => 'DepthPercent',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'elevation' => {
     	datatype => 'int',
     	base_name => 'Elevation',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'first_slice_angle' => {
     	datatype => 'int',
     	base_name => 'FirstSliceAngle',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'floor' => {
     	datatype => 'LinkElement',
     	base_name => 'Floor',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'gap_depth' => {
     	datatype => 'int',
     	base_name => 'GapDepth',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'gap_width' => {
     	datatype => 'int',
     	base_name => 'GapWidth',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'height_percent' => {
     	datatype => 'int',
     	base_name => 'HeightPercent',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'hide_pivot_field_buttons' => {
     	datatype => 'boolean',
     	base_name => 'HidePivotFieldButtons',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is3_d' => {
     	datatype => 'boolean',
     	base_name => 'Is3D',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_rectangular_cornered' => {
     	datatype => 'boolean',
     	base_name => 'IsRectangularCornered',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'legend' => {
     	datatype => 'LinkElement',
     	base_name => 'Legend',
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
     'n_series' => {
     	datatype => 'LinkElement',
     	base_name => 'NSeries',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_setup' => {
     	datatype => 'LinkElement',
     	base_name => 'PageSetup',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'perspective' => {
     	datatype => 'int',
     	base_name => 'Perspective',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'pivot_source' => {
     	datatype => 'string',
     	base_name => 'PivotSource',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'placement' => {
     	datatype => 'string',
     	base_name => 'Placement',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'plot_area' => {
     	datatype => 'LinkElement',
     	base_name => 'PlotArea',
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
     'plot_visible_cells' => {
     	datatype => 'boolean',
     	base_name => 'PlotVisibleCells',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'print_size' => {
     	datatype => 'string',
     	base_name => 'PrintSize',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'right_angle_axes' => {
     	datatype => 'boolean',
     	base_name => 'RightAngleAxes',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'rotation_angle' => {
     	datatype => 'int',
     	base_name => 'RotationAngle',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'second_category_axis' => {
     	datatype => 'LinkElement',
     	base_name => 'SecondCategoryAxis',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'second_value_axis' => {
     	datatype => 'LinkElement',
     	base_name => 'SecondValueAxis',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'series_axis' => {
     	datatype => 'LinkElement',
     	base_name => 'SeriesAxis',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'shapes' => {
     	datatype => 'LinkElement',
     	base_name => 'Shapes',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_data_table' => {
     	datatype => 'boolean',
     	base_name => 'ShowDataTable',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_legend' => {
     	datatype => 'boolean',
     	base_name => 'ShowLegend',
     	description => '',
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
     'size_with_window' => {
     	datatype => 'boolean',
     	base_name => 'SizeWithWindow',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'style' => {
     	datatype => 'int',
     	base_name => 'Style',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'title' => {
     	datatype => 'LinkElement',
     	base_name => 'Title',
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
     'value_axis' => {
     	datatype => 'LinkElement',
     	base_name => 'ValueAxis',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'walls' => {
     	datatype => 'LinkElement',
     	base_name => 'Walls',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'walls_and_gridlines2_d' => {
     	datatype => 'boolean',
     	base_name => 'WallsAndGridlines2D',
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
    'auto_scaling' => 'boolean',
    'back_wall' => 'LinkElement',
    'category_axis' => 'LinkElement',
    'chart_area' => 'LinkElement',
    'chart_data_table' => 'LinkElement',
    'chart_object' => 'LinkElement',
    'depth_percent' => 'int',
    'elevation' => 'int',
    'first_slice_angle' => 'int',
    'floor' => 'LinkElement',
    'gap_depth' => 'int',
    'gap_width' => 'int',
    'height_percent' => 'int',
    'hide_pivot_field_buttons' => 'boolean',
    'is3_d' => 'boolean',
    'is_rectangular_cornered' => 'boolean',
    'legend' => 'LinkElement',
    'name' => 'string',
    'n_series' => 'LinkElement',
    'page_setup' => 'LinkElement',
    'perspective' => 'int',
    'pivot_source' => 'string',
    'placement' => 'string',
    'plot_area' => 'LinkElement',
    'plot_empty_cells_type' => 'string',
    'plot_visible_cells' => 'boolean',
    'print_size' => 'string',
    'right_angle_axes' => 'boolean',
    'rotation_angle' => 'int',
    'second_category_axis' => 'LinkElement',
    'second_value_axis' => 'LinkElement',
    'series_axis' => 'LinkElement',
    'shapes' => 'LinkElement',
    'show_data_table' => 'boolean',
    'show_legend' => 'boolean',
    'side_wall' => 'LinkElement',
    'size_with_window' => 'boolean',
    'style' => 'int',
    'title' => 'LinkElement',
    'type' => 'string',
    'value_axis' => 'LinkElement',
    'walls' => 'LinkElement',
    'walls_and_gridlines2_d' => 'boolean',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'auto_scaling' => 'AutoScaling',
    'back_wall' => 'BackWall',
    'category_axis' => 'CategoryAxis',
    'chart_area' => 'ChartArea',
    'chart_data_table' => 'ChartDataTable',
    'chart_object' => 'ChartObject',
    'depth_percent' => 'DepthPercent',
    'elevation' => 'Elevation',
    'first_slice_angle' => 'FirstSliceAngle',
    'floor' => 'Floor',
    'gap_depth' => 'GapDepth',
    'gap_width' => 'GapWidth',
    'height_percent' => 'HeightPercent',
    'hide_pivot_field_buttons' => 'HidePivotFieldButtons',
    'is3_d' => 'Is3D',
    'is_rectangular_cornered' => 'IsRectangularCornered',
    'legend' => 'Legend',
    'name' => 'Name',
    'n_series' => 'NSeries',
    'page_setup' => 'PageSetup',
    'perspective' => 'Perspective',
    'pivot_source' => 'PivotSource',
    'placement' => 'Placement',
    'plot_area' => 'PlotArea',
    'plot_empty_cells_type' => 'PlotEmptyCellsType',
    'plot_visible_cells' => 'PlotVisibleCells',
    'print_size' => 'PrintSize',
    'right_angle_axes' => 'RightAngleAxes',
    'rotation_angle' => 'RotationAngle',
    'second_category_axis' => 'SecondCategoryAxis',
    'second_value_axis' => 'SecondValueAxis',
    'series_axis' => 'SeriesAxis',
    'shapes' => 'Shapes',
    'show_data_table' => 'ShowDataTable',
    'show_legend' => 'ShowLegend',
    'side_wall' => 'SideWall',
    'size_with_window' => 'SizeWithWindow',
    'style' => 'Style',
    'title' => 'Title',
    'type' => 'Type',
    'value_axis' => 'ValueAxis',
    'walls' => 'Walls',
    'walls_and_gridlines2_d' => 'WallsAndGridlines2D',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;