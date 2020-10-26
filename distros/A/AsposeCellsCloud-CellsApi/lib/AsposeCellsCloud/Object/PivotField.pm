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


package AsposeCellsCloud::Object::PivotField;

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

use AsposeCellsCloud::Object::PivotItem;

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
                                  class => 'PivotField',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'pivot_items' => {
    	datatype => 'ARRAY[PivotItem]',
    	base_name => 'PivotItems',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'display_name' => {
    	datatype => 'string',
    	base_name => 'DisplayName',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'number_format' => {
    	datatype => 'string',
    	base_name => 'NumberFormat',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'drag_to_column' => {
    	datatype => 'boolean',
    	base_name => 'DragToColumn',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_auto_show' => {
    	datatype => 'boolean',
    	base_name => 'IsAutoShow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_repeat_item_labels' => {
    	datatype => 'boolean',
    	base_name => 'IsRepeatItemLabels',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'drag_to_row' => {
    	datatype => 'boolean',
    	base_name => 'DragToRow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_auto_sort' => {
    	datatype => 'boolean',
    	base_name => 'IsAutoSort',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'insert_blank_row' => {
    	datatype => 'boolean',
    	base_name => 'InsertBlankRow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_subtotal_at_top' => {
    	datatype => 'boolean',
    	base_name => 'ShowSubtotalAtTop',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_compact' => {
    	datatype => 'boolean',
    	base_name => 'ShowCompact',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'function' => {
    	datatype => 'string',
    	base_name => 'Function',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_multiple_item_selection_allowed' => {
    	datatype => 'boolean',
    	base_name => 'IsMultipleItemSelectionAllowed',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'data_display_format' => {
    	datatype => 'string',
    	base_name => 'DataDisplayFormat',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'base_item_position' => {
    	datatype => 'string',
    	base_name => 'BaseItemPosition',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_insert_page_breaks_between_items' => {
    	datatype => 'boolean',
    	base_name => 'IsInsertPageBreaksBetweenItems',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'show_all_items' => {
    	datatype => 'boolean',
    	base_name => 'ShowAllItems',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'base_item' => {
    	datatype => 'int',
    	base_name => 'BaseItem',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'item_count' => {
    	datatype => 'int',
    	base_name => 'ItemCount',
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
    'show_in_outline_form' => {
    	datatype => 'boolean',
    	base_name => 'ShowInOutlineForm',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'items' => {
    	datatype => 'ARRAY[string]',
    	base_name => 'Items',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'auto_show_field' => {
    	datatype => 'int',
    	base_name => 'AutoShowField',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_auto_subtotals' => {
    	datatype => 'boolean',
    	base_name => 'IsAutoSubtotals',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_include_new_items_in_filter' => {
    	datatype => 'boolean',
    	base_name => 'IsIncludeNewItemsInFilter',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'current_page_item' => {
    	datatype => 'int',
    	base_name => 'CurrentPageItem',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'position' => {
    	datatype => 'int',
    	base_name => 'Position',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_ascend_sort' => {
    	datatype => 'boolean',
    	base_name => 'IsAscendSort',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_ascend_show' => {
    	datatype => 'boolean',
    	base_name => 'IsAscendShow',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'base_field' => {
    	datatype => 'int',
    	base_name => 'BaseField',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'auto_sort_field' => {
    	datatype => 'int',
    	base_name => 'AutoSortField',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'auto_show_count' => {
    	datatype => 'int',
    	base_name => 'AutoShowCount',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'number' => {
    	datatype => 'int',
    	base_name => 'Number',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'drag_to_page' => {
    	datatype => 'boolean',
    	base_name => 'DragToPage',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'drag_to_data' => {
    	datatype => 'boolean',
    	base_name => 'DragToData',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'base_index' => {
    	datatype => 'int',
    	base_name => 'BaseIndex',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'original_items' => {
    	datatype => 'ARRAY[string]',
    	base_name => 'OriginalItems',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'drag_to_hide' => {
    	datatype => 'boolean',
    	base_name => 'DragToHide',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'is_calculated_field' => {
    	datatype => 'boolean',
    	base_name => 'IsCalculatedField',
    	description => '',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'pivot_items' => 'ARRAY[PivotItem]',
    'display_name' => 'string',
    'number_format' => 'string',
    'drag_to_column' => 'boolean',
    'is_auto_show' => 'boolean',
    'is_repeat_item_labels' => 'boolean',
    'drag_to_row' => 'boolean',
    'is_auto_sort' => 'boolean',
    'insert_blank_row' => 'boolean',
    'show_subtotal_at_top' => 'boolean',
    'show_compact' => 'boolean',
    'function' => 'string',
    'is_multiple_item_selection_allowed' => 'boolean',
    'data_display_format' => 'string',
    'base_item_position' => 'string',
    'is_insert_page_breaks_between_items' => 'boolean',
    'show_all_items' => 'boolean',
    'base_item' => 'int',
    'item_count' => 'int',
    'name' => 'string',
    'show_in_outline_form' => 'boolean',
    'items' => 'ARRAY[string]',
    'auto_show_field' => 'int',
    'is_auto_subtotals' => 'boolean',
    'is_include_new_items_in_filter' => 'boolean',
    'current_page_item' => 'int',
    'position' => 'int',
    'is_ascend_sort' => 'boolean',
    'is_ascend_show' => 'boolean',
    'base_field' => 'int',
    'auto_sort_field' => 'int',
    'auto_show_count' => 'int',
    'number' => 'int',
    'drag_to_page' => 'boolean',
    'drag_to_data' => 'boolean',
    'base_index' => 'int',
    'original_items' => 'ARRAY[string]',
    'drag_to_hide' => 'boolean',
    'is_calculated_field' => 'boolean'
} );

__PACKAGE__->attribute_map( {
    'pivot_items' => 'PivotItems',
    'display_name' => 'DisplayName',
    'number_format' => 'NumberFormat',
    'drag_to_column' => 'DragToColumn',
    'is_auto_show' => 'IsAutoShow',
    'is_repeat_item_labels' => 'IsRepeatItemLabels',
    'drag_to_row' => 'DragToRow',
    'is_auto_sort' => 'IsAutoSort',
    'insert_blank_row' => 'InsertBlankRow',
    'show_subtotal_at_top' => 'ShowSubtotalAtTop',
    'show_compact' => 'ShowCompact',
    'function' => 'Function',
    'is_multiple_item_selection_allowed' => 'IsMultipleItemSelectionAllowed',
    'data_display_format' => 'DataDisplayFormat',
    'base_item_position' => 'BaseItemPosition',
    'is_insert_page_breaks_between_items' => 'IsInsertPageBreaksBetweenItems',
    'show_all_items' => 'ShowAllItems',
    'base_item' => 'BaseItem',
    'item_count' => 'ItemCount',
    'name' => 'Name',
    'show_in_outline_form' => 'ShowInOutlineForm',
    'items' => 'Items',
    'auto_show_field' => 'AutoShowField',
    'is_auto_subtotals' => 'IsAutoSubtotals',
    'is_include_new_items_in_filter' => 'IsIncludeNewItemsInFilter',
    'current_page_item' => 'CurrentPageItem',
    'position' => 'Position',
    'is_ascend_sort' => 'IsAscendSort',
    'is_ascend_show' => 'IsAscendShow',
    'base_field' => 'BaseField',
    'auto_sort_field' => 'AutoSortField',
    'auto_show_count' => 'AutoShowCount',
    'number' => 'Number',
    'drag_to_page' => 'DragToPage',
    'drag_to_data' => 'DragToData',
    'base_index' => 'BaseIndex',
    'original_items' => 'OriginalItems',
    'drag_to_hide' => 'DragToHide',
    'is_calculated_field' => 'IsCalculatedField'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
