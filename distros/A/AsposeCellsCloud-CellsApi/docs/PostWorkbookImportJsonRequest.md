# AsposeCellsCloud::Request::PostWorkbookImportJson 

## Load the model package
```perl
use AsposeCellsCloud::Request::PostWorkbookImportJson;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **string** | The file name. |
**import_json_request** | **ImportJsonRequest** | Import Json request. |
**password** | **string** | The password needed to open an Excel file. |
**folder** | **string** | The folder where the file is situated. |
**storage_name** | **string** | The storage name where the file is situated. |
**out_path** | **string** | Path to save the result. If it's a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder. |
**out_storage_name** | **string** | The storage name where the output file is situated. |
**check_excel_restriction** | **boolean** | Whether check restriction of excel file when user modify cells related objects. |
**region** | **string** | The regional settings for workbook. |  

[[Back to Model list]](../README.md#documentation-for-requests) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

