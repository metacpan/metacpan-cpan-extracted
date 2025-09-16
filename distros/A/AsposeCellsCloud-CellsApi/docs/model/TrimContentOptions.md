# AsposeCellsCloud::Object::TrimContentOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::TrimContentOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**DataSource** | **DataSource** | Represents data source.  There are three types of data, they are CloudFileSystem, RequestFiles, HttpUri. |
**FileInfo** | **FileInfo** | Represents file information. Include of filename, filesize, and file content(base64String). |
**TrimContent** | **string** | Trim Content |
**TrimLeading** | **boolean** | If the trim leading value is true, the trim content before and after cell values will be deleted. |
**TrimTrailing** | **boolean** | If the trim trailing value is true, the trim content before and after cell values will be deleted. |
**TrimSpaceBetweenWordTo1** | **boolean** | When the trim space between word to 1 parameter is true, it enables the removal of extra spaces between words within a cell, ensuring that only a single space is maintained between words. |
**TrimNonBreakingSpaces** | **boolean** |  |
**RemoveExtraLineBreaks** | **boolean** | When this parameter is enabled (set to True), it deletes extra line breaks within the selected range, ensuring that only necessary line breaks are retained. |
**RemoveAllLineBreaks** | **boolean** | When this parameter is enabled (set to True), it removes all line breaks within the selected range, resulting in a continuous block of text without any line breaks. |
**ScopeOptions** | **ScopeOptions** | Specifies the range of cells within the worksheet where the spreadsheet operations will be performed. This parameter allows users to define the exact area to be processed, ensuring that operations are applied only to the designated cells. |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

