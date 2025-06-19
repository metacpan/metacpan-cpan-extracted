# **Spreadsheet Cloud API: postExport**

Export Excel internal elements or the workbook itself to various format files. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/export
```
### **Function Description**
PageTitle: Export Excel internal elements or the workbook itself to various format files.PageDescription: Aspose.Cells Cloud provides robust support for exporting Excel internal elements or the workbook itself to various format files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadTitle: Export Excel internal elements or the workbook itself to various format files.HeadSummary: Aspose.Cells Cloud provides robust support for exporting Excel internal elements or the workbook itself to various format files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports exporting Excel internal elements or the workbook itself to various format files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postExport** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|objectType|String|Query|Exported object type:workbook/worksheet/chart/comment/picture/shape/listobject/oleobject.|
|format|String|Query|The conversion format(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers).|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|
|FontsLocation|String|Query|Use Custom fonts.|

### **Response Description**
```json
{
  "Name": "FilesResult",
  "Description": [
    "Class features: Weekly lectures, group projects, midterm and final exams, and participation in class discussions."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Files",
      "Description": [
        "A property named **Files** of type **IList FileInfo ** containing a collection of file information objects."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "FileInfo",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "FileInfo",
          "Name": "class:fileinfo"
        },
        "Name": "container"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/PostExport) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
