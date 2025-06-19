# **Spreadsheet Cloud API: postWorksheetCalculateFormula**

Calculate formula in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/calculateformula
```
### **Function Description**
PageTitle: Calculate formula in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for calculating formula in the worksheet, a process known for its intricacy.HeadTitle: Calculate formula in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for calculating formula in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports calculating formula in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetCalculateFormula** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|Worksheet name.|
|formula|String|Query|The formula.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "SingleValueResponse",
  "Description": [
    "Represents the SingleValue Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Value",
      "Description": [
        "A property named \"Value\" of type \"SingleValue\" that can be accessed and modified is declared in the class."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "SingleValue",
        "Name": "class:singlevalue"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostWorksheetCalculateFormula) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
