# **Spreadsheet Cloud API: getWorkbookNameValue**

Retrieve the value of a named range in the workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/names/{nameName}/value
```
### **Function Description**
PageTitle: Update a named range in the workbook.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the value of a named range in the workbook, a process known for its intricacy.HeadTitle:  Update a named range in the workbook.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the value of a named range in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the value of a named range in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorkbookNameValue** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|nameName|String|Path|the Aspose.Cells.Name element name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "RangeValueResponse",
  "Description": [
    "Represents the RangeValue Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "CellsList",
      "Description": [
        "Property Summary: Contains a list of elements labeled as \"Cell\"."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "Cell",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "Cell",
          "Name": "class:cell"
        },
        "Name": "container"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/GetWorkbookNameValue) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
