# AsposeCellsCloud::Object::WorkbookSettings

## Load the model package
```perl
use AsposeCellsCloud::Object::WorkbookSettings;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**number_group_separator** | **string** |  | [optional] 
**hide_pivot_field_list** | **boolean** |  | [optional] 
**is_minimized** | **boolean** | Represents whether the generated spreadsheet will be opened Minimized.              | [optional] 
**calculation_id** | **string** | Specifies the version of the calculation engine used to calculate values in the workbook.              | [optional] 
**re_calculate_on_open** | **boolean** | Indicates whether re-calculate all formulas on opening file.              | [optional] 
**check_excel_restriction** | **boolean** | Whether check restriction of excel file when user modify cells related objects.  For example, excel does not allow inputting string value longer than 32K.  When you input a value longer than 32K such as by Cell.PutValue(string), if this property is true, you will get an Exception.  If this property is false, we will accept your input string value as the cell&#39;s value so that later you can output the complete string value for other file formats such as CSV.  However, if you have set such kind of value that is invalid for excel file format, you should not save the workbook as excel file format later. Otherwise there may be unexpected error for the generated excel file.              | [optional] 
**is_h_scroll_bar_visible** | **boolean** | Gets or sets a value indicating whether the generated spreadsheet will contain a horizontal scroll bar.                           Remarks: The default value is true.               | [optional] 
**window_height** | **double** | The height of the window, in unit of point.              | [optional] 
**window_left** | **double** | The distance from the left edge of the client area to the left edge of the window, in unit of point.              | [optional] 
**calc_stack_size** | **int** | Specifies the stack size for calculating cells recursively.  The large value for this size will give better performance when there are lots of cells need to be calculated recursively.  On the other hand, larger value will raise the stakes of StackOverflowException.  If use gets StackOverflowException when calculating formulas, this value should be decreased.              | [optional] 
**shared** | **boolean** | Gets or sets a value that indicates whether the Workbook is shared.                           Remarks: The default value is false.               | [optional] 
**remove_personal_information** | **boolean** |  | [optional] 
**language_code** | **string** | Gets or sets the user interface language of the Workbook version based on CountryCode that has saved the file.              | [optional] 
**enable_macros** | **boolean** |  | [optional] 
**is_default_encrypted** | **boolean** |  | [optional] 
**recalculate_before_save** | **boolean** | Indicates whether to recalculate before saving the document.              | [optional] 
**parsing_formula_on_open** | **boolean** | Indicates whether parsing the formula when reading the file.                           Remarks: Only applies for Excel Xlsx,Xltx, Xltm,Xlsm file because the formulas in the files are stored with a string formula.               | [optional] 
**window_top** | **double** | The distance from the top edge of the client area to the top edge of the window, in unit of point.              | [optional] 
**region** | **string** | Gets or sets the system regional settings based on CountryCode at the time the file was saved.                           Remarks: If you do not want to use the region saved in the file, please reset it after reading the file.               | [optional] 
**memory_setting** | **string** |  | [optional] 
**update_adjacent_cells_border** | **boolean** | Indicates whether update adjacent cells&#39; border.                           Remarks: The default value is true.  For example: the bottom border of the cell A1 is update, the top border of the cell A2 should be changed too.               | [optional] 
**crash_save** | **boolean** |  | [optional] 
**show_tabs** | **boolean** | Get or sets a value whether the Workbook tabs are displayed.                           Remarks: The default value is true.               | [optional] 
**precision_as_displayed** | **boolean** | True if calculations in this workbook will be done using only the precision of the numbers as they&#39;re displayed              | [optional] 
**calc_mode** | **string** | It specifies whether to calculate formulas manually, automatically or automatically except for multiple table operations.              | [optional] 
**auto_compress_pictures** | **boolean** |  | [optional] 
**date1904** | **boolean** | Gets or sets a value which represents if the workbook uses the 1904 date system.              | [optional] 
**number_decimal_separator** | **string** |  | [optional] 
**iteration** | **boolean** | Indicates if Aspose.Cells will use iteration to resolve circular references.              | [optional] 
**check_comptiliblity** | **boolean** | Indicates whether check comptiliblity when saving workbook.                           Remarks:  The default value is true.               | [optional] 
**auto_recover** | **boolean** |  | [optional] 
**max_change** | **double** | Returns or sets the maximum number of change that Microsoft Excel can use to resolve a circular reference.              | [optional] 
**data_extract_load** | **boolean** |  | [optional] 
**first_visible_tab** | **int** | Gets or sets the first visible worksheet tab.              | [optional] 
**is_hidden** | **boolean** | Indicates whether this workbook is hidden.              | [optional] 
**recommend_read_only** | **boolean** | Indicates if the Read Only Recommended option is selected.              | [optional] 
**display_drawing_objects** | **string** | Indicates whether and how to show objects in the workbook.              | [optional] 
**build_version** | **string** | Specifies the incremental public release of the application.              | [optional] 
**is_v_scroll_bar_visible** | **boolean** | Gets or sets a value indicating whether the generated spreadsheet will contain a vertical scroll bar.                           Remarks: The default value is true.               | [optional] 
**window_width** | **double** | The width of the window, in unit of point.              | [optional] 
**create_calc_chain** | **boolean** | Indicates whether create calculated formulas chain.              | [optional] 
**max_iteration** | **int** | Returns or sets the maximum number of iterations that Aspose.Cells can use to resolve a circular reference.              | [optional] 
**repair_load** | **boolean** |  | [optional] 
**update_links_type** | **string** |  | [optional] 
**sheet_tab_bar_width** | **int** | Width of worksheet tab bar (in 1/1000 of window width).              | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


