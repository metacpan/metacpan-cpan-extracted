# **Spreadsheet Cloud API: postSearch**

Search for specified text within Excel files. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/search
```
### **Function Description**
PageTitle: Search for specified text within Excel files.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for searching specified text within Excel files.HeadTitle:  Search for specified text within Excel files.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for searching specified text within Excel files.HeadContent: Aspose.Cells Cloud provides REST API which supports searching specified text within Excel files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postSearch** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|text|String|Query|Find content|
|password|String|Query|The password needed to open an Excel file.|
|sheetname|String|Query|The worksheet name. Locate the specified text content in the worksheet.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|

### **Response Description**
```json
[
{
  "Name": "TextItem",
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Filename",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Worksheet",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Position",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Content",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
]
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/PostSearch) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
