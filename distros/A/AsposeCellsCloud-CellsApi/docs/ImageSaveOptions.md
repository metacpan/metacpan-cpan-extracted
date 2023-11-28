# AsposeCellsCloud::Object::ImageSaveOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::ImageSaveOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ChartImageType** | **string** | Indicate the chart imagetype when converting. |
**EmbededImageNameInSvg** | **string** | Indicate the filename of embeded image in svg. This should be full path with directory like "c:\\xpsEmbeded" |
**HorizontalResolution** | **int** | Gets or sets the horizontal resolution for generated images, in dots per inch.                 Applies generating image method except Emf format images.               The default value is 96. |
**ImageFormat** | **string** | Gets or sets the format of the generated images.  Don't apply the method that returns a Bitmap object.             The default value is ImageFormat.Bmp.  Don't apply the method that returns a Bitmap object. |
**IsCellAutoFit** | **boolean** | Indicates whether the width and height of the cells is automatically fitted by cell value. The default value is false. |
**OnePagePerSheet** | **boolean** | If OnePagePerSheet is true , all content of one sheet will output to only                one page in result. The paper size of pagesetup will be invalid, and the                other settings of pagesetup will still take effect. |
**OnlyArea** | **boolean** | If this property is true , onle Area will be output, and no scale will take effect. |
**PrintingPage** | **string** | Indicates which pages will not be printed. |
**PrintWithStatusDialog** | **boolean** | If PrintWithStatusDialog = true , there will be a dialog that shows current print status.  else no such dialog will show. |
**Quality** | **int** | Gets or sets a value determining the quality of the generated images to apply only when saving pages to the Jpeg format.            Has effect only when saving to JPEG.  The value must be between 0 and 100. The default value is 100. |
**TiffCompression** | **string** | Gets or sets the type of compression to apply only when saving pages to the Tiff format.            Has effect only when saving to TIFF.  The default value is Lzw. |
**VerticalResolution** | **int** | Gets or sets the vertical resolution for generated images, in dots per inch.            Applies generating image method except Emf format image.            The default value is 96. |
**SaveFormat** | **string** |  |
**CachedFileFolder** | **string** |  |
**ClearData** | **boolean** |  |
**CreateDirectory** | **boolean** |  |
**EnableHTTPCompression** | **boolean** |  |
**RefreshChartCache** | **boolean** |  |
**SortNames** | **boolean** |  |
**ValidateMergedAreas** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

