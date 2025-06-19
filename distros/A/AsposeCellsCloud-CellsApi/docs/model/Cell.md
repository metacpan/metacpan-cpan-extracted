# AsposeCellsCloud::Object::Cell 

## Load the model package
```perl
use AsposeCellsCloud::Object::Cell;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Name** | **string** | Gets the name of the cell. |
**Row** | **int** | Gets row number (zero based) of the cell. |
**Column** | **int** | Gets column number (zero based) of the cell. |
**Value** | **string** | Gets the value contained in this cell. |
**Type** | **string** | Represents cell value type. |
**Formula** | **string** | Gets or sets a formula of the . |
**IsFormula** | **boolean** | Represents if the specified cell contains formula. |
**IsMerged** | **boolean** | Checks if a cell is part of a merged range or not. |
**IsArrayHeader** | **boolean** | Indicates the cell's formula is and array formula                         and it is the first cell of the array. |
**IsInArray** | **boolean** | Indicates whether the cell formula is an array formula. |
**IsErrorValue** | **boolean** | Checks if the value of this cell is an error. |
**IsInTable** | **boolean** | Indicates whether this cell is part of table formula. |
**IsStyleSet** | **boolean** | Indicates if the cell's style is set. If return false, it means this cell has a default cell format. |
**HtmlString** | **string** | Gets and sets the html string which contains data and some formats in this cell. |
**Style** | **LinkElement** | This class property represents a style element with the specified XML element name. |
**Worksheet** | **string** | Gets the parent worksheet. |
**link** | **Link** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

