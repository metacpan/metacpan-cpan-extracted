# AsposeCellsCloud::Object::PdfSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::PdfSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**DisplayDocTitle** | **boolean** | Indicates whether the window's title bar should display the document title. |
**ExportDocumentStructure** | **boolean** | Indicates whether to export document structure. |
**EmfRenderSetting** | **string** | Setting for rendering Emf metafile. |
**CustomPropertiesExport** | **string** | Specifies the way CustomDocumentPropertyCollection are exported to PDF file. |
**OptimizationType** | **string** | Gets and sets pdf optimization type. |
**Producer** | **string** | Gets and sets producer of generated pdf document. |
**PdfCompression** | **string** | Indicate the compression algorithm. |
**FontEncoding** | **string** | Gets or sets embedded font encoding in pdf. |
**Watermark** | **RenderingWatermark** | Gets or sets watermark to output. |
**CalculateFormula** | **boolean** | Indicates whether calculate formulas before saving pdf file.The default value is false. |
**CheckFontCompatibility** | **boolean** | Indicates whether check font compatibility for every character in text.                The default value is true.  Disable this property may give better performance.                 But when the default or specified font of text/character cannot be used                to render it, unreadable characters(such as block) maybe occur in the generated                pdf.  For such situation user should keep this property as true so that alternative                font can be searched and used to render the text instead; |
**Compliance** | **string** | Workbook converts to pdf will according to PdfCompliance in this property. |
**DefaultFont** | **string** | When characters in the Excel are unicode and not be set with correct font in cell style,              They may appear as block in pdf,image.  Set the DefaultFont such as MingLiu or MS Gothic to show these characters.               If this property is not set, Aspose.Cells will use system default font to show these unicode characters. |
**OnePagePerSheet** | **boolean** | If OnePagePerSheet is true , all content of one sheet will output to only            one page in result. The paper size of pagesetup will be invalid, and the               other settings of pagesetup will still take effect. |
**PrintingPageType** | **string** | Indicates which pages will not be printed. |
**SecurityOptions** | **PdfSecurityOptions** | Set this options, when security is need in xls2pdf result. |
**desiredPPI** | **int** | Set desired PPI(pixels per inch) of resample images and jpeg quality  All images will be converted to JPEG with the specified quality setting, and images that are greater than the specified PPI (pixels per inch) will be resampled.              Desired pixels per inch. 220 high quality. 150 screen quality. 96 email quality. |
**jpegQuality** | **int** | Set desired PPI(pixels per inch) of resample images and jpeg quality  All images will be converted to JPEG with the specified quality setting, and images that are greater than the specified PPI (pixels per inch) will be resampled.              0 - 100% JPEG quality. |
**ImageType** | **string** | Represents the image type when converting the chart and shape . |
**SaveFormat** | **string** |  |
**CachedFileFolder** | **string** |  |
**ClearData** | **boolean** |  |
**CreateDirectory** | **boolean** |  |
**EnableHTTPCompression** | **boolean** |  |
**RefreshChartCache** | **boolean** |  |
**SortNames** | **boolean** |  |
**ValidateMergedAreas** | **boolean** |  |
**MergeAreas** | **boolean** |  |
**SortExternalNames** | **boolean** |  |
**CheckExcelRestriction** | **boolean** |  |
**UpdateSmartArt** | **boolean** |  |
**EncryptDocumentProperties** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

