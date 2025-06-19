# **Spreadsheet Cloud API: postClearObjects**

Clear internal elements in Excel files and generate output files in various formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/clearobjects
```
### **Function Description**
PageTitle: Clear internal elements in Excel files and generate output files in various formats.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for clearing internal elements in Excel files and generating output files in various formats.HeadTitle:  Clear internal elements in Excel files and generate output files in various formats.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for clearing internal elements in Excel files and generating output files in various formats.HeadContent: Aspose.Cells Cloud provides REST API which supports clearing internal elements in Excel files and generating output files in various formats and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postClearObjects** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|objecttype|String|Query|chart/comment/picture/shape/listobject/hyperlink/oleobject/pivottable/validation/Background|
|sheetname|String|Query|The worksheet name, specify the scope of the deletion.|
|outFormat|String|Query|The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/PostClearObjects) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
