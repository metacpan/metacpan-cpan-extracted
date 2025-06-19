# **Spreadsheet Cloud API: postMetadata**

Update document properties in Excel file, and save them is various formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/metadata/update
```
### **Function Description**
PageTitle: Update document properties in Excel file, and save them is various formats.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for updating document properties in Excel file and saving them is various formats.HeadTitle:  Update document properties in Excel file, and save them is various formats.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for updating document properties in Excel file and saving them is various formats.HeadContent: Aspose.Cells Cloud provides REST API which supports updating document properties in Excel file and saving them is various formats and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postMetadata** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|cellsDocuments|Container|Body|document properties|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|outFormat|String|Query|The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/PostMetadata) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
