# **Spreadsheet Cloud API: getNamedRanges**

Retrieve descriptions of ranges in the worksheets. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/ranges
```
### **Function Description**
PageTitle: Retrieve descriptions of ranges in the worksheets.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of ranges in the worksheets, a process known for its intricacy.HeadTitle: Retrieve descriptions of ranges in the worksheets.HeadSummary: Aspose.Cells Cloud provides robust support for updating descriptions of ranges in the worksheets, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports updating descriptions of ranges in the worksheets and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getNamedRanges** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "RangesResponse",
  "Description": [
    "Represents the Ranges Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Ranges",
      "Description": [
        "This class has a property named \"Ranges\" of type \"Ranges\" that can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Ranges",
        "Name": "class:ranges"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/GetNamedRanges) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
