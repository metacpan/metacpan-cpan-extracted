# **Spreadsheet Cloud API: getWorksheets**

Retrieve the description of worksheets from a workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets
```
### **Function Description**
PageTitle: Retrieve the description of worksheets from a workbook.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the description of worksheets from a workbook, a process known for its intricacy.HeadTitle: Retrieve the description of worksheets from a workbook.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the description of worksheets from a workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the description of worksheets from a workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheets** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "WorksheetsResponse",
  "Description": [
    "Represents the Worksheets Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Worksheets",
      "Description": [
        "Property `Worksheets` of type `Worksheets` with the XML element name \"worksheets\" is defined in the class."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Worksheets",
        "Name": "class:worksheets"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/GetWorksheets) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
