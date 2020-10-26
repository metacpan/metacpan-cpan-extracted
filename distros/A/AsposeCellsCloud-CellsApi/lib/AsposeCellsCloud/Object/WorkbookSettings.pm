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
    'number_group_separator' => {
    	datatype => 'string',
    	base_name => 'NumberGroupSeparator',
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
    'is_minimized' => {
    	datatype => 'boolean',
    	base_name => 'IsMinimized',
    	description => 'Represents whether the generated spreadsheet will be opened Minimized.             ',
    	format => '',
    	read_only => '',
    		},
    'calculation_id' => {
    	datatype => 'string',
    	base_name => 'CalculationId',
    	description => 'Specifies the version of the calculation engine used to calculate values in the workbook.             ',
    	format => '',
    	read_only => '',
    		},
    're_calculate_on_open' => {
    	datatype => 'boolean',
    	base_name => 'ReCalculateOnOpen',
    	description => 'Indicates whether re-calculate all formulas on opening file.             ',
    	format => '',
    	read_only => '',
    		},
    'check_excel_restriction' => {
    	datatype => 'boolean',
    	base_name => 'CheckExcelRestriction',
    	description => 'Whether check restriction of excel file when user modify cells related objects.  For example, excel does not allow inputting string value longer than 32K.  When you input a value longer than 32K such as by Cell.PutValue(string), if this property is true, you will get an Exception.  If this property is false, we will accept your input string value as the cell&#39;s value so that later you can output the complete string value for other file formats such as CSV.  However, if you have set such kind of value that is invalid for excel file format, you should not save the workbook as excel file format later. Otherwise there may be unexpected error for the generated excel file.             ',
    	format => '',
    	read_only => '',
    		},
    'is_h_scroll_bar_visible' => {
    	datatype => 'boolean',
    	base_name => 'IsHScrollBarVisible',
    	description => 'Gets or sets a value indicating whether the generated spreadsheet will contain a horizontal scroll bar.                           Remarks: The default value is true.              ',
    	format => '',
    	read_only => '',
    		},
    'window_height' => {
    	datatype => 'double',
    	base_name => 'WindowHeight',
    	description => 'The height of the window, in unit of point.             ',
    	format => '',
    	read_only => '',
    		},
    'window_left' => {
    	datatype => 'double',
    	base_name => 'WindowLeft',
    	description => 'The distance from the left edge of the client area to the left edge of the window, in unit of point.             ',
    	format => '',
    	read_only => '',
    		},
    'calc_stack_size' => {
    	datatype => 'int',
    	base_name => 'CalcStackSize',
    	description => 'Specifies the stack size for calculating cells recursively.  The large value for this size will give better performance when there are lots of cells need to be calculated recursively.  On the other hand, larger value will raise the stakes of StackOverflowException.  If use gets StackOverflowException when calculating formulas, this value should be decreased.             ',
    	format => '',
    	read_only => '',
    		},
    'shared' => {
    	datatype => 'boolean',
    	base_name => 'Shared',
    	description => 'Gets or sets a value that indicates whether the Workbook is shared.                           Remarks: The default value is false.              ',
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
    'language_code' => {
    	datatype => 'string',
    	base_name => 'LanguageCode',
    	description => 'Gets or sets the user interface language of the Workbook version based on CountryCode that has saved the file.             ',
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
    'is_default_encrypted' => {
    	datatype => 'boolean',
    	base_name => 'IsDefaultEncrypted',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'recalculate_before_save' => {
    	datatype => 'boolean',
    	base_name => 'RecalculateBeforeSave',
    	description => 'Indicates whether to recalculate before saving the document.             ',
    	format => '',
    	read_only => '',
    		},
    'parsing_formula_on_open' => {
    	datatype => 'boolean',
    	base_name => 'ParsingFormulaOnOpen',
    	description => 'Indicates whether parsing the formula when reading the file.                           Remarks: Only applies for Excel Xlsx,Xltx, Xltm,Xlsm file because the formulas in the files are stored with a string formula.              ',
    	format => '',
    	read_only => '',
    		},
    'window_top' => {
    	datatype => 'double',
    	base_name => 'WindowTop',
    	description => 'The distance from the top edge of the client area to the top edge of the window, in unit of point.             ',
    	format => '',
    	read_only => '',
    		},
    'region' => {
    	datatype => 'string',
    	base_name => 'Region',
    	description => 'Gets or sets the system regional settings based on CountryCode at the time the file was saved.                           Remarks: If you do not want to use the region saved in the file, please reset it after reading the file.              ',
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
    'update_adjacent_cells_border' => {
    	datatype => 'boolean',
    	base_name => 'UpdateAdjacentCellsBorder',
    	description => 'Indicates whether update adjacent cells&#39; border.                           Remarks: The default value is true.  For example: the bottom border of the cell A1 is update, the top border of the cell A2 should be changed too.              ',
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
    'show_tabs' => {
    	datatype => 'boolean',
    	base_name => 'ShowTabs',
    	description => 'Get or sets a value whether the Workbook tabs are displayed.                           Remarks: The default value is true.              ',
    	format => '',
    	read_only => '',
    		},
    'precision_as_displayed' => {
    	datatype => 'boolean',
    	base_name => 'PrecisionAsDisplayed',
    	description => 'True if calculations in this workbook will be done using only the precision of the numbers as they&#39;re displayed             ',
    	format => '',
    	read_only => '',
    		},
    'calc_mode' => {
    	datatype => 'string',
    	base_name => 'CalcMode',
    	description => 'It specifies whether to calculate formulas manually, automatically or automatically except for multiple table operations.             ',
    	format => '',
    	read_only => '',
    		},
    'auto_compress_pictures' => {
    	datatype => 'boolean',
    	base_name => 'AutoCompressPictures',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'date1904' => {
    	datatype => 'boolean',
    	base_name => 'Date1904',
    	description => 'Gets or sets a value which represents if the workbook uses the 1904 date system.             ',
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
    'iteration' => {
    	datatype => 'boolean',
    	base_name => 'Iteration',
    	description => 'Indicates if Aspose.Cells will use iteration to resolve circular references.             ',
    	format => '',
    	read_only => '',
    		},
    'check_comptiliblity' => {
    	datatype => 'boolean',
    	base_name => 'CheckComptiliblity',
    	description => 'Indicates whether check comptiliblity when saving workbook.                           Remarks:  The default value is true.              ',
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
    'max_change' => {
    	datatype => 'double',
    	base_name => 'MaxChange',
    	description => 'Returns or sets the maximum number of change that Microsoft Excel can use to resolve a circular reference.             ',
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
    'first_visible_tab' => {
    	datatype => 'int',
    	base_name => 'FirstVisibleTab',
    	description => 'Gets or sets the first visible worksheet tab.             ',
    	format => '',
    	read_only => '',
    		},
    'is_hidden' => {
    	datatype => 'boolean',
    	base_name => 'IsHidden',
    	description => 'Indicates whether this workbook is hidden.             ',
    	format => '',
    	read_only => '',
    		},
    'recommend_read_only' => {
    	datatype => 'boolean',
    	base_name => 'RecommendReadOnly',
    	description => 'Indicates if the Read Only Recommended option is selected.             ',
    	format => '',
    	read_only => '',
    		},
    'display_drawing_objects' => {
    	datatype => 'string',
    	base_name => 'DisplayDrawingObjects',
    	description => 'Indicates whether and how to show objects in the workbook.             ',
    	format => '',
    	read_only => '',
    		},
    'build_version' => {
    	datatype => 'string',
    	base_name => 'BuildVersion',
    	description => 'Specifies the incremental public release of the application.             ',
    	format => '',
    	read_only => '',
    		},
    'is_v_scroll_bar_visible' => {
    	datatype => 'boolean',
    	base_name => 'IsVScrollBarVisible',
    	description => 'Gets or sets a value indicating whether the generated spreadsheet will contain a vertical scroll bar.                           Remarks: The default value is true.              ',
    	format => '',
    	read_only => '',
    		},
    'window_width' => {
    	datatype => 'double',
    	base_name => 'WindowWidth',
    	description => 'The width of the window, in unit of point.             ',
    	format => '',
    	read_only => '',
    		},
    'create_calc_chain' => {
    	datatype => 'boolean',
    	base_name => 'CreateCalcChain',
    	description => 'Indicates whether create calculated formulas chain.             ',
    	format => '',
    	read_only => '',
    		},
    'max_iteration' => {
    	datatype => 'int',
    	base_name => 'MaxIteration',
    	description => 'Returns or sets the maximum number of iterations that Aspose.Cells can use to resolve a circular reference.             ',
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
    'update_links_type' => {
    	datatype => 'string',
    	base_name => 'UpdateLinksType',
    	description => '',
    	format => '',
    	read_only => '',
    		},
    'sheet_tab_bar_width' => {
    	datatype => 'int',
    	base_name => 'SheetTabBarWidth',
    	description => 'Width of worksheet tab bar (in 1/1000 of window width).             ',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'number_group_separator' => 'string',
    'hide_pivot_field_list' => 'boolean',
    'is_minimized' => 'boolean',
    'calculation_id' => 'string',
    're_calculate_on_open' => 'boolean',
    'check_excel_restriction' => 'boolean',
    'is_h_scroll_bar_visible' => 'boolean',
    'window_height' => 'double',
    'window_left' => 'double',
    'calc_stack_size' => 'int',
    'shared' => 'boolean',
    'remove_personal_information' => 'boolean',
    'language_code' => 'string',
    'enable_macros' => 'boolean',
    'is_default_encrypted' => 'boolean',
    'recalculate_before_save' => 'boolean',
    'parsing_formula_on_open' => 'boolean',
    'window_top' => 'double',
    'region' => 'string',
    'memory_setting' => 'string',
    'update_adjacent_cells_border' => 'boolean',
    'crash_save' => 'boolean',
    'show_tabs' => 'boolean',
    'precision_as_displayed' => 'boolean',
    'calc_mode' => 'string',
    'auto_compress_pictures' => 'boolean',
    'date1904' => 'boolean',
    'number_decimal_separator' => 'string',
    'iteration' => 'boolean',
    'check_comptiliblity' => 'boolean',
    'auto_recover' => 'boolean',
    'max_change' => 'double',
    'data_extract_load' => 'boolean',
    'first_visible_tab' => 'int',
    'is_hidden' => 'boolean',
    'recommend_read_only' => 'boolean',
    'display_drawing_objects' => 'string',
    'build_version' => 'string',
    'is_v_scroll_bar_visible' => 'boolean',
    'window_width' => 'double',
    'create_calc_chain' => 'boolean',
    'max_iteration' => 'int',
    'repair_load' => 'boolean',
    'update_links_type' => 'string',
    'sheet_tab_bar_width' => 'int'
} );

__PACKAGE__->attribute_map( {
    'number_group_separator' => 'NumberGroupSeparator',
    'hide_pivot_field_list' => 'HidePivotFieldList',
    'is_minimized' => 'IsMinimized',
    'calculation_id' => 'CalculationId',
    're_calculate_on_open' => 'ReCalculateOnOpen',
    'check_excel_restriction' => 'CheckExcelRestriction',
    'is_h_scroll_bar_visible' => 'IsHScrollBarVisible',
    'window_height' => 'WindowHeight',
    'window_left' => 'WindowLeft',
    'calc_stack_size' => 'CalcStackSize',
    'shared' => 'Shared',
    'remove_personal_information' => 'RemovePersonalInformation',
    'language_code' => 'LanguageCode',
    'enable_macros' => 'EnableMacros',
    'is_default_encrypted' => 'IsDefaultEncrypted',
    'recalculate_before_save' => 'RecalculateBeforeSave',
    'parsing_formula_on_open' => 'ParsingFormulaOnOpen',
    'window_top' => 'WindowTop',
    'region' => 'Region',
    'memory_setting' => 'MemorySetting',
    'update_adjacent_cells_border' => 'UpdateAdjacentCellsBorder',
    'crash_save' => 'CrashSave',
    'show_tabs' => 'ShowTabs',
    'precision_as_displayed' => 'PrecisionAsDisplayed',
    'calc_mode' => 'CalcMode',
    'auto_compress_pictures' => 'AutoCompressPictures',
    'date1904' => 'Date1904',
    'number_decimal_separator' => 'NumberDecimalSeparator',
    'iteration' => 'Iteration',
    'check_comptiliblity' => 'CheckComptiliblity',
    'auto_recover' => 'AutoRecover',
    'max_change' => 'MaxChange',
    'data_extract_load' => 'DataExtractLoad',
    'first_visible_tab' => 'FirstVisibleTab',
    'is_hidden' => 'IsHidden',
    'recommend_read_only' => 'RecommendReadOnly',
    'display_drawing_objects' => 'DisplayDrawingObjects',
    'build_version' => 'BuildVersion',
    'is_v_scroll_bar_visible' => 'IsVScrollBarVisible',
    'window_width' => 'WindowWidth',
    'create_calc_chain' => 'CreateCalcChain',
    'max_iteration' => 'MaxIteration',
    'repair_load' => 'RepairLoad',
    'update_links_type' => 'UpdateLinksType',
    'sheet_tab_bar_width' => 'SheetTabBarWidth'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
