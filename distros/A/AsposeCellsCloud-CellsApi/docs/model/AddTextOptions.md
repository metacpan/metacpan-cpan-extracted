# AsposeCellsCloud::Object::AddTextOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::AddTextOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Name** | **string** | The class has a public property named "Name" with a getter and setter method. |
**DataSource** | **DataSource** | Represents data source.  There are three types of data, they are CloudFileSystem, RequestFiles, HttpUri. |
**FileInfo** | **FileInfo** | Represents file information. Include of filename, filesize, and file content(base64String). |
**ScopeOptions** | **ScopeOptions** | Specifies the range of cells within the worksheet where the spreadsheet operations will be performed. This parameter allows users to define the exact area to be processed, ensuring that operations are applied only to the designated cells. |
**Text** | **string** | Add text content. |
**SelectPoistion** | **string** | Represents where text should be inserted or selected in the spreadsheet. |
**SelectText** | **string** | Selected text of cell where text should be inserted or selected in the spreadsheet. |
**SkipEmptyCells** | **boolean** | Indicates whether empty cells should be skipped during processing. |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

