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
use AsposeCellsCloud::Object::FormulaSettings;
use AsposeCellsCloud::Object::GlobalizationSettings;
use AsposeCellsCloud::Object::WriteProtection; 


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
     	description => 'Specifies a boolean value that indicates the application automatically compressed pictures in the workbook. ',
     	format => '',
     	read_only => '',
     		},
     'auto_recover' => {
     	datatype => 'boolean',
     	base_name => 'AutoRecover',
     	description => 'Indicates whether the file is mark for auto-recovery. ',
     	format => '',
     	read_only => '',
     		},
     'build_version' => {
     	datatype => 'string',
     	base_name => 'BuildVersion',
     	description => 'Specifies the incremental public release of the application. ',
     	format => '',
     	read_only => '',
     		},
     'calc_mode' => {
     	datatype => 'string',
     	base_name => 'CalcMode',
     	description => 'It specifies whether to calculate formulas manually,            automatically or automatically except for multiple table operations. ',
     	format => '',
     	read_only => '',
     		},
     'calc_stack_size' => {
     	datatype => 'int',
     	base_name => 'CalcStackSize',
     	description => 'Specifies the stack size for calculating cells recursively.            The large value for this size will give better performance when there are lots of cells need to be calculated recursively.            On the other hand, larger value will raise the risk of StackOverflowException.            If user gets StackOverflowException when calculating formulas, this value should be decreased. ',
     	format => '',
     	read_only => '',
     		},
     'calculation_id' => {
     	datatype => 'string',
     	base_name => 'CalculationId',
     	description => 'Specifies the version of the calculation engine used to calculate values in the workbook. ',
     	format => '',
     	read_only => '',
     		},
     'check_comptiliblity' => {
     	datatype => 'boolean',
     	base_name => 'CheckComptiliblity',
     	description => 'Indicates whether check comptiliblity when saving workbook.                         Remarks: The default value is true.             ',
     	format => '',
     	read_only => '',
     		},
     'check_excel_restriction' => {
     	datatype => 'boolean',
     	base_name => 'CheckExcelRestriction',
     	description => 'Whether check restriction of excel file when user modify cells related objects.            For example, excel does not allow inputting string value longer than 32K.            When you input a value longer than 32K such as by Cell.PutValue(string), if this property is true, you will get an Exception.            If this property is false, we will accept your input string value as the cell`s value so that later            you can output the complete string value for other file formats such as CSV.            However, if you have set such kind of value that is invalid for excel file format,            you should not save the workbook as excel file format later. Otherwise there may be unexpected error for the generated excel file. ',
     	format => '',
     	read_only => '',
     		},
     'crash_save' => {
     	datatype => 'boolean',
     	base_name => 'CrashSave',
     	description => 'indicates whether the application last saved the workbook file after a crash. ',
     	format => '',
     	read_only => '',
     		},
     'create_calc_chain' => {
     	datatype => 'boolean',
     	base_name => 'CreateCalcChain',
     	description => 'Whether creates calculated formulas chain. Default is false. ',
     	format => '',
     	read_only => '',
     		},
     'data_extract_load' => {
     	datatype => 'boolean',
     	base_name => 'DataExtractLoad',
     	description => 'indicates whether the application last opened the workbook for data recovery. ',
     	format => '',
     	read_only => '',
     		},
     'date1904' => {
     	datatype => 'boolean',
     	base_name => 'Date1904',
     	description => 'Gets or sets a value which represents if the workbook uses the 1904 date system. ',
     	format => '',
     	read_only => '',
     		},
     'display_drawing_objects' => {
     	datatype => 'string',
     	base_name => 'DisplayDrawingObjects',
     	description => 'Indicates whether and how to show objects in the workbook. ',
     	format => '',
     	read_only => '',
     		},
     'enable_macros' => {
     	datatype => 'boolean',
     	base_name => 'EnableMacros',
     	description => 'Enable macros; ',
     	format => '',
     	read_only => '',
     		},
     'first_visible_tab' => {
     	datatype => 'int',
     	base_name => 'FirstVisibleTab',
     	description => 'Gets or sets the first visible worksheet tab. ',
     	format => '',
     	read_only => '',
     		},
     'hide_pivot_field_list' => {
     	datatype => 'boolean',
     	base_name => 'HidePivotFieldList',
     	description => 'Gets and sets whether hide the field list for the PivotTable. ',
     	format => '',
     	read_only => '',
     		},
     'is_default_encrypted' => {
     	datatype => 'boolean',
     	base_name => 'IsDefaultEncrypted',
     	description => 'Indicates whether encrypting the workbook with default password if Structure and Windows of the workbook are locked. ',
     	format => '',
     	read_only => '',
     		},
     'is_hidden' => {
     	datatype => 'boolean',
     	base_name => 'IsHidden',
     	description => 'Indicates whether this workbook is hidden. ',
     	format => '',
     	read_only => '',
     		},
     'is_h_scroll_bar_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsHScrollBarVisible',
     	description => 'Gets or sets a value indicating whether the generated spreadsheet will contain a horizontal scroll bar. ',
     	format => '',
     	read_only => '',
     		},
     'is_minimized' => {
     	datatype => 'boolean',
     	base_name => 'IsMinimized',
     	description => 'Represents whether the generated spreadsheet will be opened Minimized. ',
     	format => '',
     	read_only => '',
     		},
     'is_v_scroll_bar_visible' => {
     	datatype => 'boolean',
     	base_name => 'IsVScrollBarVisible',
     	description => 'Gets or sets a value indicating whether the generated spreadsheet will contain a vertical scroll bar. ',
     	format => '',
     	read_only => '',
     		},
     'iteration' => {
     	datatype => 'boolean',
     	base_name => 'Iteration',
     	description => 'Indicates whether enable iterative calculation to resolve circular references. ',
     	format => '',
     	read_only => '',
     		},
     'language_code' => {
     	datatype => 'string',
     	base_name => 'LanguageCode',
     	description => 'Gets or sets the user interface language of the Workbook version based on CountryCode that has saved the file. ',
     	format => '',
     	read_only => '',
     		},
     'max_change' => {
     	datatype => 'double',
     	base_name => 'MaxChange',
     	description => 'Returns or sets the maximum number of change to resolve a circular reference. ',
     	format => '',
     	read_only => '',
     		},
     'max_iteration' => {
     	datatype => 'int',
     	base_name => 'MaxIteration',
     	description => 'Returns or sets the maximum number of iterations to resolve a circular reference. ',
     	format => '',
     	read_only => '',
     		},
     'memory_setting' => {
     	datatype => 'string',
     	base_name => 'MemorySetting',
     	description => 'Gets or sets the memory usage options. The new option will be taken as the default option for newly created worksheets but does not take effect for existing worksheets. ',
     	format => '',
     	read_only => '',
     		},
     'number_decimal_separator' => {
     	datatype => 'string',
     	base_name => 'NumberDecimalSeparator',
     	description => 'Gets or sets the decimal separator for formatting/parsing numeric values. Default is the decimal separator of current Region. ',
     	format => '',
     	read_only => '',
     		},
     'number_group_separator' => {
     	datatype => 'string',
     	base_name => 'NumberGroupSeparator',
     	description => 'Gets or sets the character that separates groups of digits to the left of the decimal in numeric values. Default is the group separator of current Region. ',
     	format => '',
     	read_only => '',
     		},
     'parsing_formula_on_open' => {
     	datatype => 'boolean',
     	base_name => 'ParsingFormulaOnOpen',
     	description => 'Indicates whether parsing the formula when reading the file. ',
     	format => '',
     	read_only => '',
     		},
     'precision_as_displayed' => {
     	datatype => 'boolean',
     	base_name => 'PrecisionAsDisplayed',
     	description => 'True if calculations in this workbook will be done using only the precision of the numbers as they`re displayed ',
     	format => '',
     	read_only => '',
     		},
     'recalculate_before_save' => {
     	datatype => 'boolean',
     	base_name => 'RecalculateBeforeSave',
     	description => 'Indicates whether to recalculate before saving the document. ',
     	format => '',
     	read_only => '',
     		},
     're_calculate_on_open' => {
     	datatype => 'boolean',
     	base_name => 'ReCalculateOnOpen',
     	description => 'Indicates whether re-calculate all formulas on opening file. ',
     	format => '',
     	read_only => '',
     		},
     'recommend_read_only' => {
     	datatype => 'boolean',
     	base_name => 'RecommendReadOnly',
     	description => 'Indicates if the Read Only Recommended option is selected.            ',
     	format => '',
     	read_only => '',
     		},
     'region' => {
     	datatype => 'string',
     	base_name => 'Region',
     	description => 'Gets or sets the regional settings for workbook. ',
     	format => '',
     	read_only => '',
     		},
     'remove_personal_information' => {
     	datatype => 'boolean',
     	base_name => 'RemovePersonalInformation',
     	description => 'True if personal information can be removed from the specified workbook. ',
     	format => '',
     	read_only => '',
     		},
     'repair_load' => {
     	datatype => 'boolean',
     	base_name => 'RepairLoad',
     	description => 'Indicates whether the application last opened the workbook in safe or repair mode. ',
     	format => '',
     	read_only => '',
     		},
     'shared' => {
     	datatype => 'boolean',
     	base_name => 'Shared',
     	description => 'Gets or sets a value that indicates whether the Workbook is shared. ',
     	format => '',
     	read_only => '',
     		},
     'sheet_tab_bar_width' => {
     	datatype => 'int',
     	base_name => 'SheetTabBarWidth',
     	description => 'Width of worksheet tab bar (in 1/1000 of window width). ',
     	format => '',
     	read_only => '',
     		},
     'show_tabs' => {
     	datatype => 'boolean',
     	base_name => 'ShowTabs',
     	description => 'Get or sets a value whether the Workbook tabs are displayed. ',
     	format => '',
     	read_only => '',
     		},
     'update_adjacent_cells_border' => {
     	datatype => 'boolean',
     	base_name => 'UpdateAdjacentCellsBorder',
     	description => 'Indicates whether update adjacent cells` border. ',
     	format => '',
     	read_only => '',
     		},
     'update_links_type' => {
     	datatype => 'string',
     	base_name => 'UpdateLinksType',
     	description => 'Gets and sets how updates external links when the workbook is opened. ',
     	format => '',
     	read_only => '',
     		},
     'window_height' => {
     	datatype => 'double',
     	base_name => 'WindowHeight',
     	description => 'The height of the window, in unit of point. ',
     	format => '',
     	read_only => '',
     		},
     'window_left' => {
     	datatype => 'double',
     	base_name => 'WindowLeft',
     	description => 'The distance from the left edge of the client area to the left edge of the window, in unit of point. ',
     	format => '',
     	read_only => '',
     		},
     'window_top' => {
     	datatype => 'double',
     	base_name => 'WindowTop',
     	description => 'The distance from the top edge of the client area to the top edge of the window, in unit of point. ',
     	format => '',
     	read_only => '',
     		},
     'window_width' => {
     	datatype => 'double',
     	base_name => 'WindowWidth',
     	description => 'The width of the window, in unit of point. ',
     	format => '',
     	read_only => '',
     		},
     'author' => {
     	datatype => 'string',
     	base_name => 'Author',
     	description => 'Gets and sets the author of the file. ',
     	format => '',
     	read_only => '',
     		},
     'check_custom_number_format' => {
     	datatype => 'boolean',
     	base_name => 'CheckCustomNumberFormat',
     	description => 'Indicates whether checking custom number format when setting Style.Custom. ',
     	format => '',
     	read_only => '',
     		},
     'protection_type' => {
     	datatype => 'string',
     	base_name => 'ProtectionType',
     	description => 'Gets the protection type of the workbook. ',
     	format => '',
     	read_only => '',
     		},
     'globalization_settings' => {
     	datatype => 'GlobalizationSettings',
     	base_name => 'GlobalizationSettings',
     	description => 'Gets and sets the globalization settings. ',
     	format => '',
     	read_only => '',
     		},
     'password' => {
     	datatype => 'string',
     	base_name => 'Password',
     	description => 'Represents Workbook file encryption password. ',
     	format => '',
     	read_only => '',
     		},
     'write_protection' => {
     	datatype => 'WriteProtection',
     	base_name => 'WriteProtection',
     	description => 'Provides access to the workbook write protection options. ',
     	format => '',
     	read_only => '',
     		},
     'is_encrypted' => {
     	datatype => 'boolean',
     	base_name => 'IsEncrypted',
     	description => 'Gets a value that indicates whether a password is required to open this workbook. ',
     	format => '',
     	read_only => '',
     		},
     'is_protected' => {
     	datatype => 'boolean',
     	base_name => 'IsProtected',
     	description => 'Gets a value that indicates whether the structure or window of the Workbook is protected. ',
     	format => '',
     	read_only => '',
     		},
     'max_row' => {
     	datatype => 'int',
     	base_name => 'MaxRow',
     	description => 'Gets the max row index, zero-based. ',
     	format => '',
     	read_only => '',
     		},
     'max_column' => {
     	datatype => 'int',
     	base_name => 'MaxColumn',
     	description => 'Gets the max column index, zero-based. ',
     	format => '',
     	read_only => '',
     		},
     'significant_digits' => {
     	datatype => 'int',
     	base_name => 'SignificantDigits',
     	description => 'Gets and sets the number of significant digits.            The default value is . ',
     	format => '',
     	read_only => '',
     		},
     'check_compatibility' => {
     	datatype => 'boolean',
     	base_name => 'CheckCompatibility',
     	description => 'Indicates whether check compatibility with earlier versions when saving workbook. ',
     	format => '',
     	read_only => '',
     		},
     'paper_size' => {
     	datatype => 'string',
     	base_name => 'PaperSize',
     	description => 'Gets and sets the default print paper size. ',
     	format => '',
     	read_only => '',
     		},
     'max_rows_of_shared_formula' => {
     	datatype => 'int',
     	base_name => 'MaxRowsOfSharedFormula',
     	description => 'Gets and sets the max row number of shared formula. ',
     	format => '',
     	read_only => '',
     		},
     'compliance' => {
     	datatype => 'string',
     	base_name => 'Compliance',
     	description => 'Specifies the OOXML version for the output document. The default value is Ecma376_2006. ',
     	format => '',
     	read_only => '',
     		},
     'quote_prefix_to_style' => {
     	datatype => 'boolean',
     	base_name => 'QuotePrefixToStyle',
     	description => 'Indicates whether setting  property when entering the string value(which starts  with single quote mark ) to the cell ',
     	format => '',
     	read_only => '',
     		},
     'formula_settings' => {
     	datatype => 'FormulaSettings',
     	base_name => 'FormulaSettings',
     	description => 'Gets the settings for formula-related features. ',
     	format => '',
     	read_only => '',
     		},
     'force_full_calculate' => {
     	datatype => 'boolean',
     	base_name => 'ForceFullCalculate',
     	description => 'Fully calculates every time when a calculation is triggered. ',
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
    'window_width' => 'double',
    'author' => 'string',
    'check_custom_number_format' => 'boolean',
    'protection_type' => 'string',
    'globalization_settings' => 'GlobalizationSettings',
    'password' => 'string',
    'write_protection' => 'WriteProtection',
    'is_encrypted' => 'boolean',
    'is_protected' => 'boolean',
    'max_row' => 'int',
    'max_column' => 'int',
    'significant_digits' => 'int',
    'check_compatibility' => 'boolean',
    'paper_size' => 'string',
    'max_rows_of_shared_formula' => 'int',
    'compliance' => 'string',
    'quote_prefix_to_style' => 'boolean',
    'formula_settings' => 'FormulaSettings',
    'force_full_calculate' => 'boolean' 
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
    'window_width' => 'WindowWidth',
    'author' => 'Author',
    'check_custom_number_format' => 'CheckCustomNumberFormat',
    'protection_type' => 'ProtectionType',
    'globalization_settings' => 'GlobalizationSettings',
    'password' => 'Password',
    'write_protection' => 'WriteProtection',
    'is_encrypted' => 'IsEncrypted',
    'is_protected' => 'IsProtected',
    'max_row' => 'MaxRow',
    'max_column' => 'MaxColumn',
    'significant_digits' => 'SignificantDigits',
    'check_compatibility' => 'CheckCompatibility',
    'paper_size' => 'PaperSize',
    'max_rows_of_shared_formula' => 'MaxRowsOfSharedFormula',
    'compliance' => 'Compliance',
    'quote_prefix_to_style' => 'QuotePrefixToStyle',
    'formula_settings' => 'FormulaSettings',
    'force_full_calculate' => 'ForceFullCalculate' 
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;