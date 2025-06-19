# **Spreadsheet Cloud API: getDocumentProperties**

Retrieve descriptions of Excel file properties. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/documentproperties
```
### **Function Description**
PageTitle:  Retrieve descriptions of Excel file properties.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of Excel file properties, a process known for its intricacy.HeadTitle: Retrieve descriptions of Excel file properties.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of Excel file properties, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of Excel file properties and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getDocumentProperties** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|type|String|Query|Excel property type.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "CellsDocumentPropertiesResponse",
  "Description": [
    "Represents the CellsDocumentProperties Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "DocumentProperties",
      "Description": [
        "The class has a property that represents the document properties of cells."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "CellsDocumentProperties",
        "Name": "class:cellsdocumentproperties"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PropertiesController/GetDocumentProperties) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
