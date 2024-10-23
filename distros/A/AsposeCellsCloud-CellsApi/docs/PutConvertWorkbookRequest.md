# AsposeCellsCloud::Request::PutConvertWorkbook 

## Load the model package
```perl
use AsposeCellsCloud::Request::PutConvertWorkbook;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**file** | **string** | File to upload |
**format** | **string** | The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers). |
**password** | **string** | The password needed to open an Excel file. |
**out_path** | **string** | Path to save the result. If it's a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder. |
**storage_name** | **string** | The storage name where the file is situated. |
**check_excel_restriction** | **boolean** | Whether check restriction of excel file when user modify cells related objects. |
**stream_format** | **string** | The format of the input file stream.  |
**region** | **string** | The regional settings for workbook. |
**page_wide_fit_on_per_sheet** | **boolean** | The page wide fit on worksheet. |
**page_tall_fit_on_per_sheet** | **boolean** | The page tall fit on worksheet. |
**sheet_name** | **string** |  |
**page_index** | **int** |  |  

[[Back to Model list]](../README.md#documentation-for-requests) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

