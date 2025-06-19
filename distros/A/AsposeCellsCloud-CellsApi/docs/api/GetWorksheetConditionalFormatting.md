# **Spreadsheet Cloud API: getWorksheetConditionalFormatting**

Retrieve conditional formatting descriptions in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index}
```
### **Function Description**
PageTitle:  Retrieve conditional formatting descriptions from a worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining conditional formatting descriptions in a worksheet, a process known for its intricacy.HeadTitle: Retrieve conditional formatting descriptions from a worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining conditional formatting descriptions in a worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining conditional formatting descriptions in a worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetConditionalFormatting** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|index|Integer|Path|The conditional formatting index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "ConditionalFormattingResponse",
  "Description": [
    "Represents the ConditionalFormatting Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "ConditionalFormatting",
      "Description": [
        "This class has a property named ConditionalFormatting of type ConditionalFormatting that can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "ConditionalFormatting",
        "Name": "class:conditionalformatting"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConditionalFormattingsController/GetWorksheetConditionalFormatting) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
