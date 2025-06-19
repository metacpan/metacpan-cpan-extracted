# **Spreadsheet Cloud API: getDocumentProperty**

Get Excel property by name. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/documentproperties/{propertyName}
```
### **Function Description**
PageTitle: Get Excel property by name.PageDescription: Aspose.Cells Cloud provides robust support for getting Excel property by name, a process known for its intricacy.HeadTitle: Get Excel property by name.HeadSummary: Aspose.Cells Cloud provides robust support for getting Excel property by name, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports getting Excel property by name and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getDocumentProperty** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|propertyName|String|Path|The property name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "CellsDocumentPropertyResponse",
  "Description": [
    "Represents the CellsDocumentProperty Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "DocumentProperty",
      "Description": [
        "A property named DocumentProperty of type CellsDocumentProperty is defined with get and set accessors."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "CellsDocumentProperty",
        "Name": "class:cellsdocumentproperty"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PropertiesController/GetDocumentProperty) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
