# **Spreadsheet Cloud API: getWorksheetCellStyle**

Retrieve cell style descriptions in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/{cellName}/style
```
### **Function Description**
PageTitle: Retrieve cell style descriptions in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for getting cell style descriptions in the worksheet, a process known for its intricacy.HeadTitle: Retrieve cell style descriptions in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for getting cell style descriptions in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports getting cell style descriptions in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetCellStyle** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|cellName|String|Path|Cell's name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "StyleResponse",
  "Description": [
    "Represents the Style Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Style",
      "Description": [
        "A property named \"Style\" of type \"Style\" is defined with both getter and setter methods."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Style",
        "Name": "class:style"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/GetWorksheetCellStyle) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
