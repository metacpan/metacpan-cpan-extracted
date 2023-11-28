# AsposeCellsCloud::Object::HtmlSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::HtmlSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ExportPageHeaders** | **boolean** |  |
**ExportPageFooters** | **boolean** |  |
**ExportRowColumnHeadings** | **boolean** |  |
**ShowAllSheets** | **boolean** |  |
**ImageOptions** | **ImageOrPrintOptions** |  |
**SaveAsSingleFile** | **boolean** | Indicates whether save the html as single file. The default value is false. |
**ExportHiddenWorksheet** | **boolean** | Indicates whether save the html as single file. The default value is false. |
**ExportGridLines** | **boolean** | Indicating whether exporting the gridlines.The default value is false. |
**PresentationPreference** | **boolean** | Indicating if html or mht file is presentation preference.The default value is             false.if you want to get more beautiful presentation,please set the value to                true. |
**CellCssPrefix** | **string** | Gets and sets the prefix of the css name,the default value is "". |
**TableCssId** | **string** | Gets and sets the prefix of the type css name such as tr,col,td and so on, they                are contained in the table element which has the specific TableCssId attribute.                The default value is "". |
**IsFullPathLink** | **boolean** | Indicating whether using full path link in sheet00x.htm,filelist.xml and tabstrip.htm.                The default value is false. |
**ExportWorksheetCSSSeparately** | **boolean** | Indicating whether export the worksheet css separately.The default value is false. |
**ExportSimilarBorderStyle** | **boolean** |  |
**MergeEmptyTdForcely** | **boolean** | Indicates whether merging empty TD element forcely when exporting file to html.                The size of html file will be reduced significantly after setting value to true.                The default value is false. If you want to import the html file to excel or export                perfect grid lines when saving file to html, please keep the default value. |
**ExportCellCoordinate** | **boolean** | Indicates whether exporting excel coordinate of nonblank cells when saving file                to html. The default value is false. If you want to import the output html to                excel, please keep the default value. |
**ExportExtraHeadings** | **boolean** | Indicates whether exporting extra headings when the length of text is longer                than max display column. The default value is false. If you want to import the                html file to excel, please keep the default value. |
**ExportHeadings** | **boolean** | Indicates whether exporting headings when saving file to html.The default value                is false. If you want to import the html file to excel, please keep the default                value. |
**ExportFormula** | **boolean** | Indicates whether exporting formula when saving file to html. The default value                is true. If you want to import the output html to excel, please keep the default                value |
**AddTooltipText** | **boolean** | Indicates whether adding tooltip text when the data can't be fully displayed. |
**ExportBogusRowData** | **boolean** | Indicating whether exporting bogus bottom row data. The default value is true.If you want to import the html or mht file to excel, please keep the default value. |
**ExcludeUnusedStyles** | **boolean** | Indicating whether excluding unused styles.The default value is false.If you  want to import the html or mht file to excel, please keep the default value. |
**ExportDocumentProperties** | **boolean** | Indicating whether exporting document properties.The default value is true.If  you want to import the html or mht file to excel, please keep the default value. |
**ExportWorksheetProperties** | **boolean** | Indicating whether exporting worksheet properties.The default value is true.If  you want to import the html or mht file to excel, please keep the default value. |
**ExportWorkbookProperties** | **boolean** | Indicating whether exporting workbook properties.The default value is true.If  you want to import the html or mht file to excel, please keep the default value. |
**ExportFrameScriptsAndProperties** | **boolean** | Indicating whether exporting frame scripts and document properties. The default  value is true.If you want to import the html or mht file to excel, please keep the default value. |
**AttachedFilesDirectory** | **string** | The directory that the attached files will be saved to.  Only for saving to html stream. |
**AttachedFilesUrlPrefix** | **string** | Specify the Url prefix of attached files such as image in the html file. Only for saving to html stream. |
**Encoding** | **string** |  |
**ExportActiveWorksheetOnly** | **boolean** | Indicates if exporting the whole workbook to html file. |
**ExportChartImageFormat** | **string** | Get or set the format of chart image before exporting |
**ExportImagesAsBase64** | **boolean** |  |
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

