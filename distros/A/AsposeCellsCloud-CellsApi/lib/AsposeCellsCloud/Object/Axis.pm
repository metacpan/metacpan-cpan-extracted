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


package AsposeCellsCloud::Object::Axis;

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
use AsposeCellsCloud::Object::Line;
use AsposeCellsCloud::Object::TickLabels;
use AsposeCellsCloud::Object::Title;

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
                                  class => 'Axis',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'area' => {
    	datatype => 'Area',
    	base_name => 'Area',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'axis_between_categories' => {
    	datatype => 'boolean',
    	base_name => 'AxisBetweenCategories',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'axis_line' => {
    	datatype => 'Area',
    	base_name => 'AxisLine',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'base_unit_scale' => {
    	datatype => 'string',
    	base_name => 'BaseUnitScale',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'category_type' => {
    	datatype => 'string',
    	base_name => 'CategoryType',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'cross_at' => {
    	datatype => 'double',
    	base_name => 'CrossAt',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'cross_type' => {
    	datatype => 'string',
    	base_name => 'CrossType',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'display_unit' => {
    	datatype => 'string',
    	base_name => 'DisplayUnit',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'has_multi_level_labels' => {
    	datatype => 'boolean',
    	base_name => 'HasMultiLevelLabels',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_automatic_max_value' => {
    	datatype => 'boolean',
    	base_name => 'IsAutomaticMaxValue',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_automatic_minor_unit' => {
    	datatype => 'boolean',
    	base_name => 'IsAutomaticMinorUnit',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_automatic_min_value' => {
    	datatype => 'boolean',
    	base_name => 'IsAutomaticMinValue',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_display_unit_label_shown' => {
    	datatype => 'boolean',
    	base_name => 'IsDisplayUnitLabelShown',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_automatic_major_unit' => {
    	datatype => 'boolean',
    	base_name => 'IsAutomaticMajorUnit',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_logarithmic' => {
    	datatype => 'boolean',
    	base_name => 'IsLogarithmic',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_plot_order_reversed' => {
    	datatype => 'boolean',
    	base_name => 'IsPlotOrderReversed',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'is_visible' => {
    	datatype => 'boolean',
    	base_name => 'IsVisible',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'log_base' => {
    	datatype => 'double',
    	base_name => 'LogBase',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'major_grid_lines' => {
    	datatype => 'Line',
    	base_name => 'MajorGridLines',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'major_tick_mark' => {
    	datatype => 'string',
    	base_name => 'MajorTickMark',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'major_unit' => {
    	datatype => 'double',
    	base_name => 'MajorUnit',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'major_unit_scale' => {
    	datatype => 'string',
    	base_name => 'MajorUnitScale',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'max_value' => {
    	datatype => 'double',
    	base_name => 'MaxValue',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'minor_grid_lines' => {
    	datatype => 'Line',
    	base_name => 'MinorGridLines',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'minor_tick_mark' => {
    	datatype => 'string',
    	base_name => 'MinorTickMark',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'minor_unit' => {
    	datatype => 'double',
    	base_name => 'MinorUnit',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'minor_unit_scale' => {
    	datatype => 'string',
    	base_name => 'MinorUnitScale',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'min_value' => {
    	datatype => 'double',
    	base_name => 'MinValue',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'tick_label_position' => {
    	datatype => 'string',
    	base_name => 'TickLabelPosition',
    	description => ' ',
    	format => '',
    	read_only => '',
    		},
    'tick_labels' => {
    	datatype => 'TickLabels',
    	base_name => 'TickLabels',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'tick_label_spacing' => {
    	datatype => 'int',
    	base_name => 'TickLabelSpacing',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'tick_mark_spacing' => {
    	datatype => 'int',
    	base_name => 'TickMarkSpacing',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'title' => {
    	datatype => 'Title',
    	base_name => 'Title',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'area' => 'Area',
    'axis_between_categories' => 'boolean',
    'axis_line' => 'Area',
    'base_unit_scale' => 'string',
    'category_type' => 'string',
    'cross_at' => 'double',
    'cross_type' => 'string',
    'display_unit' => 'string',
    'has_multi_level_labels' => 'boolean',
    'is_automatic_max_value' => 'boolean',
    'is_automatic_minor_unit' => 'boolean',
    'is_automatic_min_value' => 'boolean',
    'is_display_unit_label_shown' => 'boolean',
    'is_automatic_major_unit' => 'boolean',
    'is_logarithmic' => 'boolean',
    'is_plot_order_reversed' => 'boolean',
    'is_visible' => 'boolean',
    'log_base' => 'double',
    'major_grid_lines' => 'Line',
    'major_tick_mark' => 'string',
    'major_unit' => 'double',
    'major_unit_scale' => 'string',
    'max_value' => 'double',
    'minor_grid_lines' => 'Line',
    'minor_tick_mark' => 'string',
    'minor_unit' => 'double',
    'minor_unit_scale' => 'string',
    'min_value' => 'double',
    'tick_label_position' => 'string',
    'tick_labels' => 'TickLabels',
    'tick_label_spacing' => 'int',
    'tick_mark_spacing' => 'int',
    'title' => 'Title'
} );

__PACKAGE__->attribute_map( {
    'area' => 'Area',
    'axis_between_categories' => 'AxisBetweenCategories',
    'axis_line' => 'AxisLine',
    'base_unit_scale' => 'BaseUnitScale',
    'category_type' => 'CategoryType',
    'cross_at' => 'CrossAt',
    'cross_type' => 'CrossType',
    'display_unit' => 'DisplayUnit',
    'has_multi_level_labels' => 'HasMultiLevelLabels',
    'is_automatic_max_value' => 'IsAutomaticMaxValue',
    'is_automatic_minor_unit' => 'IsAutomaticMinorUnit',
    'is_automatic_min_value' => 'IsAutomaticMinValue',
    'is_display_unit_label_shown' => 'IsDisplayUnitLabelShown',
    'is_automatic_major_unit' => 'IsAutomaticMajorUnit',
    'is_logarithmic' => 'IsLogarithmic',
    'is_plot_order_reversed' => 'IsPlotOrderReversed',
    'is_visible' => 'IsVisible',
    'log_base' => 'LogBase',
    'major_grid_lines' => 'MajorGridLines',
    'major_tick_mark' => 'MajorTickMark',
    'major_unit' => 'MajorUnit',
    'major_unit_scale' => 'MajorUnitScale',
    'max_value' => 'MaxValue',
    'minor_grid_lines' => 'MinorGridLines',
    'minor_tick_mark' => 'MinorTickMark',
    'minor_unit' => 'MinorUnit',
    'minor_unit_scale' => 'MinorUnitScale',
    'min_value' => 'MinValue',
    'tick_label_position' => 'TickLabelPosition',
    'tick_labels' => 'TickLabels',
    'tick_label_spacing' => 'TickLabelSpacing',
    'tick_mark_spacing' => 'TickMarkSpacing',
    'title' => 'Title'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
