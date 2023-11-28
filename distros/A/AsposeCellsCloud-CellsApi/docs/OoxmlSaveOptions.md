# AsposeCellsCloud::Object::OoxmlSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::OoxmlSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ExportCellName** | **boolean** | Indicates if export cell name to Excel2007 .xlsx (.xlsm, .xltx, .xltm) file.               If the output file may be accessed by SQL Server DTS, this value must be               true.  Setting the value to false will highly increase the performance and               reduce the file size when creating large file.  Default value is false. |
**UpdateZoom** | **boolean** | Indicates whether update scaling factor before saving the file if the PageSetup.FitToPagesWide and PageSetup.FitToPagesTall properties control how the worksheet is scaled. |
**EnableZip64** | **boolean** | Always use ZIP64 extensions when writing zip archives, even when unnecessary. |
**EmbedOoxmlAsOleObject** | **boolean** | Indicates whether embedding Ooxml files of OleObject as ole object. |
**CompressionType** | **string** | Gets and sets the compression type for ooxml file. |
**SaveFormat** | **string** |  |
**CachedFileFolder** | **string** |  |
**ClearData** | **boolean** |  |
**CreateDirectory** | **boolean** |  |
**EnableHTTPCompression** | **boolean** |  |
**RefreshChartCache** | **boolean** |  |
**SortNames** | **boolean** |  |
**ValidateMergedAreas** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

