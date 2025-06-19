# **Spreadsheet Cloud API: getWorksheetWithFormat**

Retrieve the worksheet in a specified format from the workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}
```
### **Function Description**
PageTitle: Retrieve the worksheet in a specified format from the workbook.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the worksheet in a specified format from the workbook, a process known for its intricacy.HeadTitle: Retrieve the worksheet in a specified format from the workbook.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the worksheet in a specified format from the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the worksheet in a specified format from the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetWithFormat** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|format|String|Query|Export format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).|
|verticalResolution|Integer|Query|Image vertical resolution.|
|horizontalResolution|Integer|Query|Image horizontal resolution.|
|area|String|Query|Represents the range to be printed.|
|pageIndex|Integer|Query|Represents the page to be printed|
|onePagePerSheet|Boolean|Query||
|printHeadings|Boolean|Query||
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/GetWorksheetWithFormat) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
