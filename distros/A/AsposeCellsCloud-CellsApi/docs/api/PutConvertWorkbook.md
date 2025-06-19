# **Spreadsheet Cloud API: putConvertWorkbook**

Convert the workbook from the requested content into files in different formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/convert
```
### **Function Description**
PageTitle: Convert Excel files to other formats.PageDescription: Aspose.Cells Cloud provides robust support for Excel file format conversion, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadTitle:Convert Excel files to other formats.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file format conversion, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports converting Excel files to various format and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on. .

### The request parameters of **putConvertWorkbook** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|format|String|Query|The format to convert(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).|
|password|String|Query|The password needed to open an Excel file.|
|outPath|String|Query|Path to save the result. If it's a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.|
|storageName|String|Query|The storage name where the file is situated.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|streamFormat|String|Query|The format of the input file stream. |
|region|String|Query|The regional settings for workbook.|
|pageWideFitOnPerSheet|Boolean|Query|The page wide fit on worksheet.|
|pageTallFitOnPerSheet|Boolean|Query|The page tall fit on worksheet.|
|sheetName|String|Query|Convert the specified worksheet. |
|pageIndex|Integer|Query|Convert the specified page  of worksheet, sheetName is required. |
|onePagePerSheet|Boolean|Query|When converting to PDF format, one page per sheet. |
|AutoRowsFit|Boolean|Query|Auto-fits all rows in this workbook.|
|AutoColumnsFit|Boolean|Query|Auto-fits the columns width in this workbook.|
|FontsLocation|String|Query|Use Custom fonts.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/PutConvertWorkbook) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
