# **Spreadsheet Cloud API: getMetadata**

Get cells document properties. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/metadata/get
```
### **Function Description**
PageTitle: Get cells document properties.PageDescription: Indeed, Aspose.Cells Cloud offers strong support for getting cells document properties.HeadTitle:  Get cells document properties.HeadSummary: Indeed, Aspose.Cells Cloud offers strong support for getting cells document properties.HeadContent: Aspose.Cells Cloud provides REST API which supports getting cells document properties and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getMetadata** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|type|String|Query|Cells document property name.|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|

### **Response Description**
```json
[
{
  "Name": "CellsDocumentProperty",
  "Description": [
    "Cells document property."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Name",
      "Description": [
        "Returns the name of the property.",
        "            "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Value",
      "Description": [
        "Gets or sets the value of the property."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "IsLinkedToContent",
      "Description": [
        "Indicates whether this property is linked to content"
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Source",
      "Description": [
        "The linked content source."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Type",
      "Description": [
        "Gets the data type of the property.",
        "            "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "IsGeneratedName",
      "Description": [
        "Returns true if this property does not have a name in the OLE2 storage and a ",
        " unique name was generated only for the public API.",
        "            "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
]
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/LightCellsController/GetMetadata) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
