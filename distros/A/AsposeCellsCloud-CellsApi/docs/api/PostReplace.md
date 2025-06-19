# **Spreadsheet Cloud API: postReplace**

Replace specified text with new text in Excel files. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/replace
```
### **Function Description**
PageTitle: Replace specified text with new text in Excel files.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for replacing specified text with new text in Excel files.HeadTitle:  Replace specified text with new text in Excel files.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for replacing specified text with new text in Excel files.HeadContent: Aspose.Cells Cloud provides REST API which supports replacing specified text with new text in Excel files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postReplace** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|text|String|Query|Find content|
|newtext|String|Query|Replace content|
|password|String|Query|The password needed to open an Excel file.|
|sheetname|String|Query|The worksheet name. Locate the specified text content in the worksheet.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/PostReplace) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
