# **Spreadsheet Cloud API: getWorksheetColumn**

Retrieve worksheet column data by column index. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}
```
### **Function Description**
PageTitle: Retrieve worksheet column data by column index.PageDescription: Aspose.Cells Cloud provides robust support for obtaining worksheet column data by column index in the worksheet, a process known for its intricacy.HeadTitle: Retrieve worksheet column data by column index.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining worksheet column data by column index in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining worksheet column data by column index in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetColumn** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|columnIndex|Integer|Path|The column index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "ColumnResponse",
  "Description": [
    "Represents the Column Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Column",
      "Description": [
        "This class has a public property called \"Column\" of type \"Column\" with both getter and setter methods."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Column",
        "Name": "class:column"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/GetWorksheetColumn) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
