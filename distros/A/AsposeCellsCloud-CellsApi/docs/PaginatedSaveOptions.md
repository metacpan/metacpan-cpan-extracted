# AsposeCellsCloud::Object::PaginatedSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::PaginatedSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**DefaultFont** | **string** | When characters in the Excel are Unicode and not be set with correct font in cell style,They may appear as block in pdf,image.Set the DefaultFont such as MingLiu or MS Gothic to show these characters. If this property is not set, Aspose.Cells will use system default font to show these unicode characters. |
**CheckWorkbookDefaultFont** | **boolean** | When characters in the Excel are Unicode and not be set with correct font in cell style,They may appear as block in pdf,image.Set this to true to try to use workbook's default font to show these characters first. |
**CheckFontCompatibility** | **boolean** | Indicates whether to check font compatibility for every character in text. |
**IsFontSubstitutionCharGranularity** | **boolean** | Indicates whether to only substitute the font of character when the cell font is not compatibility for it. |
**OnePagePerSheet** | **boolean** | If OnePagePerSheet is true , all content of one sheet will output to only one page in result.The paper size of pagesetup will be invalid, and the other settings of pagesetup will still take effect. |
**AllColumnsInOnePagePerSheet** | **boolean** | If AllColumnsInOnePagePerSheet is true , all column content of one sheet will output to only one page in result.The width of paper size of pagesetup will be ignored, and the other settings of pagesetup will still take effect. |
**IgnoreError** | **boolean** | Indicates if you need to hide the error while rendering.The error can be error in shape, image, chart rendering, etc. |
**OutputBlankPageWhenNothingToPrint** | **boolean** | Indicates whether to output a blank page when there is nothing to print. |
**PageIndex** | **int** | Gets or sets the 0-based index of the first page to save. |
**PageCount** | **int** | Gets or sets the number of pages to save. |
**PrintingPageType** | **string** | Indicates which pages will not be printed. |
**GridlineType** | **string** | Gets or sets gridline type. |
**TextCrossType** | **string** | Gets or sets displaying text type when the text width is larger than cell width. |
**DefaultEditLanguage** | **string** | Gets or sets default edit language. |
**EmfRenderSetting** | **string** | Setting for rendering Emf metafile. |
**MergeAreas** | **boolean** |  |
**SortExternalNames** | **boolean** |  |
**UpdateSmartArt** | **boolean** |  |
**SaveFormat** | **string** |  |
**CachedFileFolder** | **string** |  |
**ClearData** | **boolean** |  |
**CreateDirectory** | **boolean** |  |
**EnableHTTPCompression** | **boolean** |  |
**RefreshChartCache** | **boolean** |  |
**SortNames** | **boolean** |  |
**ValidateMergedAreas** | **boolean** |  |
**CheckExcelRestriction** | **boolean** |  |
**EncryptDocumentProperties** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

