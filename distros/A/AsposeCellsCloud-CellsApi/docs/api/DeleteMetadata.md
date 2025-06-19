# **Spreadsheet Cloud API: deleteMetadata**

Delete cells document properties in Excel file, and save them is various formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/metadata/delete
```
### **Function Description**
PageTitle: Delete cells document properties in Excel file, and save them is various formats.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for deleting cells document properties in Excel file and save them is various formats.HeadTitle:  Delete cells document properties in Excel file, and save them is various formats.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for deleting cells document properties in Excel file and save them is various formats.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting cells document properties in Excel file and save them is various formats and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteMetadata** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|type|String|Query|Cells document property name.|
|outFormat|String|Query|The output data file format.(CSV/XLS/HTML/MHTML/ODS/PDF/XML/TXT/TIFF/XLSB/XLSM/XLSX/XLTM/XLTX/XPS/PNG/JPG/JPEG/GIF/EMF/BMP/MD[Markdown]/Numbers)|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/DeleteMetadata) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
