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

package AsposeCellsCloud::Object::Worksheet;

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


__PACKAGE__->class_documentation({description => '           Encapsulates the object that represents a single worksheet.           ',
                                  class => 'Worksheet',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'links' => {
     	datatype => 'ARRAY[Link]',
     	base_name => 'Links',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'display_right_to_left' => {
     	datatype => 'boolean',
     	base_name => 'DisplayRightToLeft',
     	description => 'Indicates if the specified worksheet is displayed from right to left instead of from left to right.            Default is false. ',
     	format => '',
     	read_only => '',
     		},
     'display_zeros' => {
     	datatype => 'boolean',
     	base_name => 'DisplayZeros',
     	description => 'True if zero values are displayed. ',
     	format => '',
     	read_only => '',
     		},
     'first_visible_column' => {
     	datatype => 'int',
     	base_name => 'FirstVisibleColumn',
     	description => 'Represents first visible column index. ',
     	format => '',
     	read_only => '',
     		},
     'first_visible_row' => {
     	datatype => 'int',
     	base_name => 'FirstVisibleRow',
     	description => 'Represents first visible row index. ',
     	format => '',
     	read_only => '',
     		},
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Gets or sets the name of the worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'index' => {
     	datatype => 'int',
     	base_name => 'Index',
     	description => 'Gets the index of sheet in the worksheet collection. ',
     	format => '',
     	read_only => '',
     		},
     'is_gridlines_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsGridlinesVisible',
     	description => 'Gets or sets a value indicating whether the gridlines are visible.Default is true. ',
     	format => '',
     	read_only => '',
     		},
     'is_outline_shown' => {
     	datatype => 'boolean',
     	base_name => 'IsOutlineShown',
     	description => 'Indicates whether to show outline. ',
     	format => '',
     	read_only => '',
     		},
     'is_page_break_preview' => {
     	datatype => 'boolean',
     	base_name => 'IsPageBreakPreview',
     	description => 'Indicates whether the specified worksheet is shown in normal view or page break preview. ',
     	format => '',
     	read_only => '',
     		},
     'is_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVisible',
     	description => 'Represents if the worksheet is visible. ',
     	format => '',
     	read_only => '',
     		},
     'is_protected' => {
     	datatype => 'boolean',
     	base_name => 'IsProtected',
     	description => 'Indicates if the worksheet is protected. ',
     	format => '',
     	read_only => '',
     		},
     'is_row_column_headers_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsRowColumnHeadersVisible',
     	description => 'Gets or sets a value indicating whether the worksheet will display row and column headers.            Default is true. ',
     	format => '',
     	read_only => '',
     		},
     'is_ruler_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsRulerVisible',
     	description => 'Indicates whether the ruler is visible. This property is only applied for page break preview. ',
     	format => '',
     	read_only => '',
     		},
     'is_selected' => {
     	datatype => 'boolean',
     	base_name => 'IsSelected',
     	description => 'Indicates whether this worksheet is selected when the workbook is opened. ',
     	format => '',
     	read_only => '',
     		},
     'tab_color' => {
     	datatype => 'Color',
     	base_name => 'TabColor',
     	description => 'Represents worksheet tab color. ',
     	format => '',
     	read_only => '',
     		},
     'transition_entry' => {
     	datatype => 'boolean',
     	base_name => 'TransitionEntry',
     	description => 'Indicates whether the Transition Formula Entry (Lotus compatibility) option is enabled. ',
     	format => '',
     	read_only => '',
     		},
     'transition_evaluation' => {
     	datatype => 'boolean',
     	base_name => 'TransitionEvaluation',
     	description => 'Indicates whether the Transition Formula Evaluation (Lotus compatibility) option is enabled. ',
     	format => '',
     	read_only => '',
     		},
     'type' => {
     	datatype => 'string',
     	base_name => 'Type',
     	description => 'Represents worksheet type. ',
     	format => '',
     	read_only => '',
     		},
     'view_type' => {
     	datatype => 'string',
     	base_name => 'ViewType',
     	description => 'Gets and sets the view type. ',
     	format => '',
     	read_only => '',
     		},
     'visibility_type' => {
     	datatype => 'string',
     	base_name => 'VisibilityType',
     	description => 'Indicates the visible state for this sheet. ',
     	format => '',
     	read_only => '',
     		},
     'zoom' => {
     	datatype => 'int',
     	base_name => 'Zoom',
     	description => 'Represents the scaling factor in percentage. It should be between 10 and 400. ',
     	format => '',
     	read_only => '',
     		},
     'cells' => {
     	datatype => 'LinkElement',
     	base_name => 'Cells',
     	description => 'Gets the  collection. ',
     	format => '',
     	read_only => '',
     		},
     'charts' => {
     	datatype => 'LinkElement',
     	base_name => 'Charts',
     	description => 'Gets a  collection ',
     	format => '',
     	read_only => '',
     		},
     'auto_shapes' => {
     	datatype => 'LinkElement',
     	base_name => 'AutoShapes',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'ole_objects' => {
     	datatype => 'LinkElement',
     	base_name => 'OleObjects',
     	description => 'Represents a collection of  in a worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'comments' => {
     	datatype => 'LinkElement',
     	base_name => 'Comments',
     	description => 'Gets the  collection. ',
     	format => '',
     	read_only => '',
     		},
     'pictures' => {
     	datatype => 'LinkElement',
     	base_name => 'Pictures',
     	description => 'Gets a  collection. ',
     	format => '',
     	read_only => '',
     		},
     'merged_cells' => {
     	datatype => 'LinkElement',
     	base_name => 'MergedCells',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'validations' => {
     	datatype => 'LinkElement',
     	base_name => 'Validations',
     	description => 'Gets the data validation setting collection in the worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'conditional_formattings' => {
     	datatype => 'LinkElement',
     	base_name => 'ConditionalFormattings',
     	description => 'Gets the ConditionalFormattings in the worksheet. ',
     	format => '',
     	read_only => '',
     		},
     'hyperlinks' => {
     	datatype => 'LinkElement',
     	base_name => 'Hyperlinks',
     	description => 'Gets the  collection. ',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'links' => 'ARRAY[Link]',
    'display_right_to_left' => 'boolean',
    'display_zeros' => 'boolean',
    'first_visible_column' => 'int',
    'first_visible_row' => 'int',
    'name' => 'string',
    'index' => 'int',
    'is_gridlines_visible' => 'boolean',
    'is_outline_shown' => 'boolean',
    'is_page_break_preview' => 'boolean',
    'is_visible' => 'boolean',
    'is_protected' => 'boolean',
    'is_row_column_headers_visible' => 'boolean',
    'is_ruler_visible' => 'boolean',
    'is_selected' => 'boolean',
    'tab_color' => 'Color',
    'transition_entry' => 'boolean',
    'transition_evaluation' => 'boolean',
    'type' => 'string',
    'view_type' => 'string',
    'visibility_type' => 'string',
    'zoom' => 'int',
    'cells' => 'LinkElement',
    'charts' => 'LinkElement',
    'auto_shapes' => 'LinkElement',
    'ole_objects' => 'LinkElement',
    'comments' => 'LinkElement',
    'pictures' => 'LinkElement',
    'merged_cells' => 'LinkElement',
    'validations' => 'LinkElement',
    'conditional_formattings' => 'LinkElement',
    'hyperlinks' => 'LinkElement' 
} );

__PACKAGE__->attribute_map( {
    'links' => 'Links',
    'display_right_to_left' => 'DisplayRightToLeft',
    'display_zeros' => 'DisplayZeros',
    'first_visible_column' => 'FirstVisibleColumn',
    'first_visible_row' => 'FirstVisibleRow',
    'name' => 'Name',
    'index' => 'Index',
    'is_gridlines_visible' => 'IsGridlinesVisible',
    'is_outline_shown' => 'IsOutlineShown',
    'is_page_break_preview' => 'IsPageBreakPreview',
    'is_visible' => 'IsVisible',
    'is_protected' => 'IsProtected',
    'is_row_column_headers_visible' => 'IsRowColumnHeadersVisible',
    'is_ruler_visible' => 'IsRulerVisible',
    'is_selected' => 'IsSelected',
    'tab_color' => 'TabColor',
    'transition_entry' => 'TransitionEntry',
    'transition_evaluation' => 'TransitionEvaluation',
    'type' => 'Type',
    'view_type' => 'ViewType',
    'visibility_type' => 'VisibilityType',
    'zoom' => 'Zoom',
    'cells' => 'Cells',
    'charts' => 'Charts',
    'auto_shapes' => 'AutoShapes',
    'ole_objects' => 'OleObjects',
    'comments' => 'Comments',
    'pictures' => 'Pictures',
    'merged_cells' => 'MergedCells',
    'validations' => 'Validations',
    'conditional_formattings' => 'ConditionalFormattings',
    'hyperlinks' => 'Hyperlinks' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;