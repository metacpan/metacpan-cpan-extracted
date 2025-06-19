# **Spreadsheet Cloud API: getWorksheetConditionalFormattings**

Retrieve descriptions of conditional formattings in a worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/conditionalFormattings
```
### **Function Description**
PageTitle:  Retrieve descriptions of conditional formattings in a worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of conditional formattings in a worksheet, a process known for its intricacy.HeadTitle: Retrieve descriptions of conditional formattings in a worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of conditional formattings in a worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of conditional formattings in a worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetConditionalFormattings** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "ConditionalFormattingsResponse",
  "Description": [
    "Represents the ConditionalFormattings Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "ConditionalFormattings",
      "Description": [
        "A property named ConditionalFormattings of type ConditionalFormattings is defined with both getter and setter methods in the class."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "ConditionalFormattings",
        "Name": "class:conditionalformattings"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConditionalFormattingsController/GetWorksheetConditionalFormattings) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
