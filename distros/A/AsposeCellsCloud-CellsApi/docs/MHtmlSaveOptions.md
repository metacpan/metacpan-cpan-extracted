# AsposeCellsCloud::Object::MHtmlSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::MHtmlSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**AttachedFilesDirectory** | **string** | The directory that the attached files will be saved to.  Only for saving to html stream. |
**AttachedFilesUrlPrefix** | **string** | Specify the Url prefix of attached files such as image in the html file. Only for saving to html stream. |
**Encoding** | **string** | If not set,use Encoding.UTF8 as default enconding type. |
**ExportActiveWorksheetOnly** | **boolean** | Indicates if exporting the whole workbook to html file. |
**ExportChartImageFormat** | **string** | Get or set the format of chart image before exporting |
**ExportImagesAsBase64** | **boolean** | Specifies whether images are saved in Base64 format to HTML, MHTML or EPUB. |
**HiddenColDisplayType** | **string** | Hidden column(the width of this column is 0) in excel,before save this into                html format, if HtmlHiddenColDisplayType is "Remove",the hidden column would               ont been output, if the value is "Hidden", the column would been output,but was hidden,the default value is "Hidden" |
**HiddenRowDisplayType** | **string** | Hidden row(the height of this row is 0) in excel,before save this into html                format, if HtmlHiddenRowDisplayType is "Remove",the hidden row would ont               been output, if the value is "Hidden", the row would been output,but was               hidden,the default value is "Hidden" |
**HtmlCrossStringType** | **string** | Indicates if a cross-cell string will be displayed in the same way as MS               Excel when saving an Excel file in html format.  By default the value is               Default, so, for cross-cell strings, there is little difference between the               html files created by Aspose.Cells and MS Excel. But the performance for               creating large html files,setting the value to Cross would be several times               faster than setting it to Default or Fit2Cell. |
**IsExpImageToTempDir** | **boolean** | Indicates if export image files to temp directory.  Only for saving to html  stream. |
**PageTitle** | **string** | The title of the html page.  Only for saving to html stream. |
**ParseHtmlTagInCell** | **boolean** | Parse html tag in cell,like ,as cell value,or as html tag,default is true |
**SaveFormat** | **string** |  |
**CachedFileFolder** | **string** |  |
**ClearData** | **boolean** |  |
**CreateDirectory** | **boolean** |  |
**EnableHTTPCompression** | **boolean** |  |
**RefreshChartCache** | **boolean** |  |
**SortNames** | **boolean** |  |
**ValidateMergedAreas** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

