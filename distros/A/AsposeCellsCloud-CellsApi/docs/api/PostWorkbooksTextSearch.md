# **Spreadsheet Cloud API: postWorkbooksTextSearch**

Search for text in the workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/findText
```
### **Function Description**
PageTitle: Search for text in the workbook.PageDescription: Aspose.Cells Cloud provides robust support for searching for text in the workbook, a process known for its intricacy.HeadTitle:  Search for text in the workbook.HeadSummary: Aspose.Cells Cloud provides robust support for searching for text in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports searching for text in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbooksTextSearch** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|text|String|Query|Text sample.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "TextItemsResponse",
  "Description": [
    "Represents the TextItems Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "TextItems",
      "Description": [
        "This property allows access to a collection of TextItems."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "TextItems",
        "Name": "class:textitems"
      }
    },
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostWorkbooksTextSearch) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
