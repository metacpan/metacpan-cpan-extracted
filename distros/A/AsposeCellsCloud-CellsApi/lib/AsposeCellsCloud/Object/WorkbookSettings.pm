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

package AsposeCellsCloud::Object::WorkbookSettings;

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
                                  class => 'WorkbookSettings',
                                  required => [], # TODO
}                                 );


__PACKAGE__->method_documentation({
     'auto_compress_pictures' => {
     	datatype => 'boolean',
     	base_name => 'AutoCompressPictures',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'auto_recover' => {
     	datatype => 'boolean',
     	base_name => 'AutoRecover',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'build_version' => {
     	datatype => 'string',
     	base_name => 'BuildVersion',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'calc_mode' => {
     	datatype => 'string',
     	base_name => 'CalcMode',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'calc_stack_size' => {
     	datatype => 'int',
     	base_name => 'CalcStackSize',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'calculation_id' => {
     	datatype => 'string',
     	base_name => 'CalculationId',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_comptiliblity' => {
     	datatype => 'boolean',
     	base_name => 'CheckComptiliblity',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'check_excel_restriction' => {
     	datatype => 'boolean',
     	base_name => 'CheckExcelRestriction',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'crash_save' => {
     	datatype => 'boolean',
     	base_name => 'CrashSave',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'create_calc_chain' => {
     	datatype => 'boolean',
     	base_name => 'CreateCalcChain',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'data_extract_load' => {
     	datatype => 'boolean',
     	base_name => 'DataExtractLoad',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'date1904' => {
     	datatype => 'boolean',
     	base_name => 'Date1904',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'display_drawing_objects' => {
     	datatype => 'string',
     	base_name => 'DisplayDrawingObjects',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'enable_macros' => {
     	datatype => 'boolean',
     	base_name => 'EnableMacros',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'first_visible_tab' => {
     	datatype => 'int',
     	base_name => 'FirstVisibleTab',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'hide_pivot_field_list' => {
     	datatype => 'boolean',
     	base_name => 'HidePivotFieldList',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_default_encrypted' => {
     	datatype => 'boolean',
     	base_name => 'IsDefaultEncrypted',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_hidden' => {
     	datatype => 'boolean',
     	base_name => 'IsHidden',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_h_scroll_bar_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsHScrollBarVisible',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_minimized' => {
     	datatype => 'boolean',
     	base_name => 'IsMinimized',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'is_v_scroll_bar_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVScrollBarVisible',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'iteration' => {
     	datatype => 'boolean',
     	base_name => 'Iteration',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'language_code' => {
     	datatype => 'string',
     	base_name => 'LanguageCode',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'max_change' => {
     	datatype => 'double',
     	base_name => 'MaxChange',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'max_iteration' => {
     	datatype => 'int',
     	base_name => 'MaxIteration',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'memory_setting' => {
     	datatype => 'string',
     	base_name => 'MemorySetting',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'number_decimal_separator' => {
     	datatype => 'string',
     	base_name => 'NumberDecimalSeparator',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'number_group_separator' => {
     	datatype => 'string',
     	base_name => 'NumberGroupSeparator',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'parsing_formula_on_open' => {
     	datatype => 'boolean',
     	base_name => 'ParsingFormulaOnOpen',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'precision_as_displayed' => {
     	datatype => 'boolean',
     	base_name => 'PrecisionAsDisplayed',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'recalculate_before_save' => {
     	datatype => 'boolean',
     	base_name => 'RecalculateBeforeSave',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     're_calculate_on_open' => {
     	datatype => 'boolean',
     	base_name => 'ReCalculateOnOpen',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'recommend_read_only' => {
     	datatype => 'boolean',
     	base_name => 'RecommendReadOnly',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'region' => {
     	datatype => 'string',
     	base_name => 'Region',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'remove_personal_information' => {
     	datatype => 'boolean',
     	base_name => 'RemovePersonalInformation',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'repair_load' => {
     	datatype => 'boolean',
     	base_name => 'RepairLoad',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'shared' => {
     	datatype => 'boolean',
     	base_name => 'Shared',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'sheet_tab_bar_width' => {
     	datatype => 'int',
     	base_name => 'SheetTabBarWidth',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'show_tabs' => {
     	datatype => 'boolean',
     	base_name => 'ShowTabs',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'update_adjacent_cells_border' => {
     	datatype => 'boolean',
     	base_name => 'UpdateAdjacentCellsBorder',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'update_links_type' => {
     	datatype => 'string',
     	base_name => 'UpdateLinksType',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'window_height' => {
     	datatype => 'double',
     	base_name => 'WindowHeight',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'window_left' => {
     	datatype => 'double',
     	base_name => 'WindowLeft',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'window_top' => {
     	datatype => 'double',
     	base_name => 'WindowTop',
     	description => '',
     	format => '',
     	read_only => '',
     		},
     'window_width' => {
     	datatype => 'double',
     	base_name => 'WindowWidth',
     	description => '',
     	format => '',
     	read_only => '',
     		},    
});

__PACKAGE__->swagger_types( {
    'auto_compress_pictures' => 'boolean',
    'auto_recover' => 'boolean',
    'build_version' => 'string',
    'calc_mode' => 'string',
    'calc_stack_size' => 'int',
    'calculation_id' => 'string',
    'check_comptiliblity' => 'boolean',
    'check_excel_restriction' => 'boolean',
    'crash_save' => 'boolean',
    'create_calc_chain' => 'boolean',
    'data_extract_load' => 'boolean',
    'date1904' => 'boolean',
    'display_drawing_objects' => 'string',
    'enable_macros' => 'boolean',
    'first_visible_tab' => 'int',
    'hide_pivot_field_list' => 'boolean',
    'is_default_encrypted' => 'boolean',
    'is_hidden' => 'boolean',
    'is_h_scroll_bar_visible' => 'boolean',
    'is_minimized' => 'boolean',
    'is_v_scroll_bar_visible' => 'boolean',
    'iteration' => 'boolean',
    'language_code' => 'string',
    'max_change' => 'double',
    'max_iteration' => 'int',
    'memory_setting' => 'string',
    'number_decimal_separator' => 'string',
    'number_group_separator' => 'string',
    'parsing_formula_on_open' => 'boolean',
    'precision_as_displayed' => 'boolean',
    'recalculate_before_save' => 'boolean',
    're_calculate_on_open' => 'boolean',
    'recommend_read_only' => 'boolean',
    'region' => 'string',
    'remove_personal_information' => 'boolean',
    'repair_load' => 'boolean',
    'shared' => 'boolean',
    'sheet_tab_bar_width' => 'int',
    'show_tabs' => 'boolean',
    'update_adjacent_cells_border' => 'boolean',
    'update_links_type' => 'string',
    'window_height' => 'double',
    'window_left' => 'double',
    'window_top' => 'double',
    'window_width' => 'double' 
} );

__PACKAGE__->attribute_map( {
    'auto_compress_pictures' => 'AutoCompressPictures',
    'auto_recover' => 'AutoRecover',
    'build_version' => 'BuildVersion',
    'calc_mode' => 'CalcMode',
    'calc_stack_size' => 'CalcStackSize',
    'calculation_id' => 'CalculationId',
    'check_comptiliblity' => 'CheckComptiliblity',
    'check_excel_restriction' => 'CheckExcelRestriction',
    'crash_save' => 'CrashSave',
    'create_calc_chain' => 'CreateCalcChain',
    'data_extract_load' => 'DataExtractLoad',
    'date1904' => 'Date1904',
    'display_drawing_objects' => 'DisplayDrawingObjects',
    'enable_macros' => 'EnableMacros',
    'first_visible_tab' => 'FirstVisibleTab',
    'hide_pivot_field_list' => 'HidePivotFieldList',
    'is_default_encrypted' => 'IsDefaultEncrypted',
    'is_hidden' => 'IsHidden',
    'is_h_scroll_bar_visible' => 'IsHScrollBarVisible',
    'is_minimized' => 'IsMinimized',
    'is_v_scroll_bar_visible' => 'IsVScrollBarVisible',
    'iteration' => 'Iteration',
    'language_code' => 'LanguageCode',
    'max_change' => 'MaxChange',
    'max_iteration' => 'MaxIteration',
    'memory_setting' => 'MemorySetting',
    'number_decimal_separator' => 'NumberDecimalSeparator',
    'number_group_separator' => 'NumberGroupSeparator',
    'parsing_formula_on_open' => 'ParsingFormulaOnOpen',
    'precision_as_displayed' => 'PrecisionAsDisplayed',
    'recalculate_before_save' => 'RecalculateBeforeSave',
    're_calculate_on_open' => 'ReCalculateOnOpen',
    'recommend_read_only' => 'RecommendReadOnly',
    'region' => 'Region',
    'remove_personal_information' => 'RemovePersonalInformation',
    'repair_load' => 'RepairLoad',
    'shared' => 'Shared',
    'sheet_tab_bar_width' => 'SheetTabBarWidth',
    'show_tabs' => 'ShowTabs',
    'update_adjacent_cells_border' => 'UpdateAdjacentCellsBorder',
    'update_links_type' => 'UpdateLinksType',
    'window_height' => 'WindowHeight',
    'window_left' => 'WindowLeft',
    'window_top' => 'WindowTop',
    'window_width' => 'WindowWidth' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;