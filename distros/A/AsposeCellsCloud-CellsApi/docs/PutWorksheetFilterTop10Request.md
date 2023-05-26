# AsposeCellsCloud::Request::PutWorksheetFilterTop10 

## Load the model package
```perl
use AsposeCellsCloud::Request::PutWorksheetFilterTop10;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **string** | The workbook name. |
**sheet_name** | **string** | The worksheet name. |
**range** | **string** | Represents the range to which the specified AutoFilter applies. |
**field_index** | **int** | The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0). |
**is_top** | **boolean** | Indicates whether filter from top or bottom |
**is_percent** | **boolean** | Indicates whether the items is percent or count |
**item_count** | **int** | The item count |
**match_blanks** | **boolean** | Match all blank or  not blank cell in the list.(true/false) |
**refresh** | **boolean** | If true, hide the filtered rows. |
**folder** | **string** | Original workbook folder. |
**storage_name** | **string** | Storage name. |  

[[Back to Model list]](../README.md#documentation-for-requests) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

