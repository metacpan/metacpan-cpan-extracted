# **Spreadsheet Cloud API: postWorksheetTextSearch**

Search for text in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/findText
```
### **Function Description**
PageTitle: Search for text in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for searching for text in the worksheet, a process known for its intricacy.HeadTitle: Search for text in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for searching for text in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports searching for text in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetTextSearch** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|text|String|Query|Text to search.|
|folder|String|Query|Original workbook folder.|
|storageName|String|Query|Storage name.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostWorksheetTextSearch) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
