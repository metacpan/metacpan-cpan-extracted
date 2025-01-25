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

package AsposeCellsCloud::Object::PivotTable;

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
use AsposeCellsCloud::Object::CellArea;
use AsposeCellsCloud::Object::Link;
use AsposeCellsCloud::Object::LinkElement;
use AsposeCellsCloud::Object::PivotField;
use AsposeCellsCloud::Object::PivotFilter; 


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


__PACKAGE__->class_documentation({description => 'Summary description for PivotTable.',
                                  class => 'PivotTable',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'alt_text_description' => {
     	datatype => 'string',
     	base_name => 'AltTextDescription',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'alt_text_title' => {
     	datatype => 'string',
     	base_name => 'AltTextTitle',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'auto_format_type' => {
     	datatype => 'string',
     	base_name => 'AutoFormatType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'base_fields' => {
     	datatype => 'ARRAY[PivotField]',
     	base_name => 'BaseFields',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'column_fields' => {
     	datatype => 'ARRAY[PivotField]',
     	base_name => 'ColumnFields',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'column_grand' => {
     	datatype => 'boolean',
     	base_name => 'ColumnGrand',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'column_header_caption' => {
     	datatype => 'string',
     	base_name => 'ColumnHeaderCaption',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'column_range' => {
     	datatype => 'CellArea',
     	base_name => 'ColumnRange',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'custom_list_sort' => {
     	datatype => 'boolean',
     	base_name => 'CustomListSort',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_body_range' => {
     	datatype => 'CellArea',
     	base_name => 'DataBodyRange',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_field' => {
     	datatype => 'PivotField',
     	base_name => 'DataField',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_fields' => {
     	datatype => 'ARRAY[PivotField]',
     	base_name => 'DataFields',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_source' => {
     	datatype => 'ARRAY[string]',
     	base_name => 'DataSource',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'display_error_string' => {
     	datatype => 'boolean',
     	base_name => 'DisplayErrorString',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'display_immediate_items' => {
     	datatype => 'boolean',
     	base_name => 'DisplayImmediateItems',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'display_null_string' => {
     	datatype => 'boolean',
     	base_name => 'DisplayNullString',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_data_value_editing' => {
     	datatype => 'boolean',
     	base_name => 'EnableDataValueEditing',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_drilldown' => {
     	datatype => 'boolean',
     	base_name => 'EnableDrilldown',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_field_dialog' => {
     	datatype => 'boolean',
     	base_name => 'EnableFieldDialog',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_field_list' => {
     	datatype => 'boolean',
     	base_name => 'EnableFieldList',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_wizard' => {
     	datatype => 'boolean',
     	base_name => 'EnableWizard',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'error_string' => {
     	datatype => 'string',
     	base_name => 'ErrorString',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'field_list_sort_ascending' => {
     	datatype => 'boolean',
     	base_name => 'FieldListSortAscending',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'grand_total_name' => {
     	datatype => 'string',
     	base_name => 'GrandTotalName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'has_blank_rows' => {
     	datatype => 'boolean',
     	base_name => 'HasBlankRows',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'indent' => {
     	datatype => 'int',
     	base_name => 'Indent',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_auto_format' => {
     	datatype => 'boolean',
     	base_name => 'IsAutoFormat',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_grid_drop_zones' => {
     	datatype => 'boolean',
     	base_name => 'IsGridDropZones',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_multiple_field_filters' => {
     	datatype => 'boolean',
     	base_name => 'IsMultipleFieldFilters',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_selected' => {
     	datatype => 'boolean',
     	base_name => 'IsSelected',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'item_print_titles' => {
     	datatype => 'boolean',
     	base_name => 'ItemPrintTitles',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'manual_update' => {
     	datatype => 'boolean',
     	base_name => 'ManualUpdate',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'merge_labels' => {
     	datatype => 'boolean',
     	base_name => 'MergeLabels',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'missing_items_limit' => {
     	datatype => 'string',
     	base_name => 'MissingItemsLimit',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'name' => {
     	datatype => 'string',
     	base_name => 'Name',
     	description => 'Represents pivot table name.',
     	format => '',
     	read_only => '',
     		},
     'null_string' => {
     	datatype => 'string',
     	base_name => 'NullString',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_field_order' => {
     	datatype => 'string',
     	base_name => 'PageFieldOrder',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_fields' => {
     	datatype => 'ARRAY[PivotField]',
     	base_name => 'PageFields',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'page_field_wrap_count' => {
     	datatype => 'int',
     	base_name => 'PageFieldWrapCount',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'pivot_filters' => {
     	datatype => 'ARRAY[PivotFilter]',
     	base_name => 'PivotFilters',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'pivot_table_style_name' => {
     	datatype => 'string',
     	base_name => 'PivotTableStyleName',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'pivot_table_style_type' => {
     	datatype => 'string',
     	base_name => 'PivotTableStyleType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'preserve_formatting' => {
     	datatype => 'boolean',
     	base_name => 'PreserveFormatting',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'print_drill' => {
     	datatype => 'boolean',
     	base_name => 'PrintDrill',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'print_titles' => {
     	datatype => 'boolean',
     	base_name => 'PrintTitles',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'refresh_data_flag' => {
     	datatype => 'boolean',
     	base_name => 'RefreshDataFlag',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'refresh_data_on_opening_file' => {
     	datatype => 'boolean',
     	base_name => 'RefreshDataOnOpeningFile',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'row_fields' => {
     	datatype => 'ARRAY[PivotField]',
     	base_name => 'RowFields',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'row_grand' => {
     	datatype => 'boolean',
     	base_name => 'RowGrand',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'row_header_caption' => {
     	datatype => 'string',
     	base_name => 'RowHeaderCaption',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'row_range' => {
     	datatype => 'CellArea',
     	base_name => 'RowRange',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'save_data' => {
     	datatype => 'boolean',
     	base_name => 'SaveData',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_data_tips' => {
     	datatype => 'boolean',
     	base_name => 'ShowDataTips',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_drill' => {
     	datatype => 'boolean',
     	base_name => 'ShowDrill',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_empty_col' => {
     	datatype => 'boolean',
     	base_name => 'ShowEmptyCol',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_empty_row' => {
     	datatype => 'boolean',
     	base_name => 'ShowEmptyRow',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_member_property_tips' => {
     	datatype => 'boolean',
     	base_name => 'ShowMemberPropertyTips',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_pivot_style_column_header' => {
     	datatype => 'boolean',
     	base_name => 'ShowPivotStyleColumnHeader',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_pivot_style_column_stripes' => {
     	datatype => 'boolean',
     	base_name => 'ShowPivotStyleColumnStripes',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_pivot_style_last_column' => {
     	datatype => 'boolean',
     	base_name => 'ShowPivotStyleLastColumn',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_pivot_style_row_header' => {
     	datatype => 'boolean',
     	base_name => 'ShowPivotStyleRowHeader',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_pivot_style_row_stripes' => {
     	datatype => 'boolean',
     	base_name => 'ShowPivotStyleRowStripes',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_row_header_caption' => {
     	datatype => 'boolean',
     	base_name => 'ShowRowHeaderCaption',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_values_row' => {
     	datatype => 'boolean',
     	base_name => 'ShowValuesRow',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'subtotal_hidden_page_items' => {
     	datatype => 'boolean',
     	base_name => 'SubtotalHiddenPageItems',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'table_range1' => {
     	datatype => 'CellArea',
     	base_name => 'TableRange1',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'table_range2' => {
     	datatype => 'CellArea',
     	base_name => 'TableRange2',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'tag' => {
     	datatype => 'string',
     	base_name => 'Tag',
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
    'alt_text_description' => 'string',
    'alt_text_title' => 'string',
    'auto_format_type' => 'string',
    'base_fields' => 'ARRAY[PivotField]',
    'column_fields' => 'ARRAY[PivotField]',
    'column_grand' => 'boolean',
    'column_header_caption' => 'string',
    'column_range' => 'CellArea',
    'custom_list_sort' => 'boolean',
    'data_body_range' => 'CellArea',
    'data_field' => 'PivotField',
    'data_fields' => 'ARRAY[PivotField]',
    'data_source' => 'ARRAY[string]',
    'display_error_string' => 'boolean',
    'display_immediate_items' => 'boolean',
    'display_null_string' => 'boolean',
    'enable_data_value_editing' => 'boolean',
    'enable_drilldown' => 'boolean',
    'enable_field_dialog' => 'boolean',
    'enable_field_list' => 'boolean',
    'enable_wizard' => 'boolean',
    'error_string' => 'string',
    'field_list_sort_ascending' => 'boolean',
    'grand_total_name' => 'string',
    'has_blank_rows' => 'boolean',
    'indent' => 'int',
    'is_auto_format' => 'boolean',
    'is_grid_drop_zones' => 'boolean',
    'is_multiple_field_filters' => 'boolean',
    'is_selected' => 'boolean',
    'item_print_titles' => 'boolean',
    'manual_update' => 'boolean',
    'merge_labels' => 'boolean',
    'missing_items_limit' => 'string',
    'name' => 'string',
    'null_string' => 'string',
    'page_field_order' => 'string',
    'page_fields' => 'ARRAY[PivotField]',
    'page_field_wrap_count' => 'int',
    'pivot_filters' => 'ARRAY[PivotFilter]',
    'pivot_table_style_name' => 'string',
    'pivot_table_style_type' => 'string',
    'preserve_formatting' => 'boolean',
    'print_drill' => 'boolean',
    'print_titles' => 'boolean',
    'refresh_data_flag' => 'boolean',
    'refresh_data_on_opening_file' => 'boolean',
    'row_fields' => 'ARRAY[PivotField]',
    'row_grand' => 'boolean',
    'row_header_caption' => 'string',
    'row_range' => 'CellArea',
    'save_data' => 'boolean',
    'show_data_tips' => 'boolean',
    'show_drill' => 'boolean',
    'show_empty_col' => 'boolean',
    'show_empty_row' => 'boolean',
    'show_member_property_tips' => 'boolean',
    'show_pivot_style_column_header' => 'boolean',
    'show_pivot_style_column_stripes' => 'boolean',
    'show_pivot_style_last_column' => 'boolean',
    'show_pivot_style_row_header' => 'boolean',
    'show_pivot_style_row_stripes' => 'boolean',
    'show_row_header_caption' => 'boolean',
    'show_values_row' => 'boolean',
    'subtotal_hidden_page_items' => 'boolean',
    'table_range1' => 'CellArea',
    'table_range2' => 'CellArea',
    'tag' => 'string',
    'link' => 'Link' 
} );

__PACKAGE__->attribute_map( {
    'alt_text_description' => 'AltTextDescription',
    'alt_text_title' => 'AltTextTitle',
    'auto_format_type' => 'AutoFormatType',
    'base_fields' => 'BaseFields',
    'column_fields' => 'ColumnFields',
    'column_grand' => 'ColumnGrand',
    'column_header_caption' => 'ColumnHeaderCaption',
    'column_range' => 'ColumnRange',
    'custom_list_sort' => 'CustomListSort',
    'data_body_range' => 'DataBodyRange',
    'data_field' => 'DataField',
    'data_fields' => 'DataFields',
    'data_source' => 'DataSource',
    'display_error_string' => 'DisplayErrorString',
    'display_immediate_items' => 'DisplayImmediateItems',
    'display_null_string' => 'DisplayNullString',
    'enable_data_value_editing' => 'EnableDataValueEditing',
    'enable_drilldown' => 'EnableDrilldown',
    'enable_field_dialog' => 'EnableFieldDialog',
    'enable_field_list' => 'EnableFieldList',
    'enable_wizard' => 'EnableWizard',
    'error_string' => 'ErrorString',
    'field_list_sort_ascending' => 'FieldListSortAscending',
    'grand_total_name' => 'GrandTotalName',
    'has_blank_rows' => 'HasBlankRows',
    'indent' => 'Indent',
    'is_auto_format' => 'IsAutoFormat',
    'is_grid_drop_zones' => 'IsGridDropZones',
    'is_multiple_field_filters' => 'IsMultipleFieldFilters',
    'is_selected' => 'IsSelected',
    'item_print_titles' => 'ItemPrintTitles',
    'manual_update' => 'ManualUpdate',
    'merge_labels' => 'MergeLabels',
    'missing_items_limit' => 'MissingItemsLimit',
    'name' => 'Name',
    'null_string' => 'NullString',
    'page_field_order' => 'PageFieldOrder',
    'page_fields' => 'PageFields',
    'page_field_wrap_count' => 'PageFieldWrapCount',
    'pivot_filters' => 'PivotFilters',
    'pivot_table_style_name' => 'PivotTableStyleName',
    'pivot_table_style_type' => 'PivotTableStyleType',
    'preserve_formatting' => 'PreserveFormatting',
    'print_drill' => 'PrintDrill',
    'print_titles' => 'PrintTitles',
    'refresh_data_flag' => 'RefreshDataFlag',
    'refresh_data_on_opening_file' => 'RefreshDataOnOpeningFile',
    'row_fields' => 'RowFields',
    'row_grand' => 'RowGrand',
    'row_header_caption' => 'RowHeaderCaption',
    'row_range' => 'RowRange',
    'save_data' => 'SaveData',
    'show_data_tips' => 'ShowDataTips',
    'show_drill' => 'ShowDrill',
    'show_empty_col' => 'ShowEmptyCol',
    'show_empty_row' => 'ShowEmptyRow',
    'show_member_property_tips' => 'ShowMemberPropertyTips',
    'show_pivot_style_column_header' => 'ShowPivotStyleColumnHeader',
    'show_pivot_style_column_stripes' => 'ShowPivotStyleColumnStripes',
    'show_pivot_style_last_column' => 'ShowPivotStyleLastColumn',
    'show_pivot_style_row_header' => 'ShowPivotStyleRowHeader',
    'show_pivot_style_row_stripes' => 'ShowPivotStyleRowStripes',
    'show_row_header_caption' => 'ShowRowHeaderCaption',
    'show_values_row' => 'ShowValuesRow',
    'subtotal_hidden_page_items' => 'SubtotalHiddenPageItems',
    'table_range1' => 'TableRange1',
    'table_range2' => 'TableRange2',
    'tag' => 'Tag',
    'link' => 'link' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;