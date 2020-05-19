# AsposeCellsCloud::Object::Cell

## Load the model package
```perl
use AsposeCellsCloud::Object::Cell;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**link** | [**Link**](Link.md) |  | [optional] 
**style** | [**LinkElement**](LinkElement.md) |  | [optional] 
**html_string** | **string** | Gets and sets the html string which contains data and some formattings in this cell.              | [optional] 
**name** | **string** | Gets the name of the cell.              | [optional] 
**column** | **int** | Gets column number (zero based) of the cell.              | 
**worksheet** | **string** | Gets the parent worksheet. | [optional] 
**is_in_table** | **boolean** | Indicates whethe this cell is part of table formula.              | 
**is_array_header** | **boolean** | Inidicates the cell&#39;s formula is and array formula and it is the first cell of the array. | 
**value** | **string** |  | [optional] 
**is_formula** | **boolean** | Represents if the specified cell contains formula.              | 
**is_style_set** | **boolean** | Indicates if the cell&#39;s style is set. If return false, it means this cell has a default cell format.              | 
**is_in_array** | **boolean** | Indicates whether the cell formula is an array formula. | 
**is_error_value** | **boolean** | Checks if a formula can properly evaluate a result.              | 
**is_merged** | **boolean** | Checks if a cell is part of a merged range or not.              | 
**formula** | **string** | Gets or sets a formula of the Aspose.Cells.Cell. | [optional] 
**type** | **string** | Specifies a cell value type. | [optional] 
**row** | **int** | Gets row number (zero based) of the cell.              | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


