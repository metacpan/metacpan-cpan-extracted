# **Spreadsheet Cloud API: getWorkbook**

Retrieve workbooks in various formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}
```
### **Function Description**
PageTitle: Retrieve workbooks in various formats.PageDescription: Aspose.Cells Cloud provides robust support for Excel file format conversion, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadTitle: Get files in various formats from Excel.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file format conversion, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides  REST API which supports getting the workbook in various formats from an Excel file and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorkbook** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|format|String|Query|The conversion format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).|
|password|String|Query|The password needed to open an Excel file.|
|isAutoFit|Boolean|Query|Specifies whether set workbook rows to be autofit.|
|onlySaveTable|Boolean|Query|Specifies whether only save table data.Only use pdf to excel.|
|folder|String|Query|The folder where the file is situated.|
|outPath|String|Query|Path to save the result. If it's a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.|
|storageName|String|Query|The storage name where the file is situated.|
|outStorageName|String|Query|The storage name where the output file is situated.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|
|pageWideFitOnPerSheet|Boolean|Query|The page wide fit on worksheet.|
|pageTallFitOnPerSheet|Boolean|Query|The page tall fit on worksheet.|
|onePagePerSheet|Boolean|Query|When converting to PDF format, one page per sheet.|
|onlyAutofitTable|Boolean|Query||
|FontsLocation|String|Query|Use Custom fonts.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/GetWorkbook) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
