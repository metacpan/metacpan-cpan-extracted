# **Spreadsheet Cloud API: getWorksheetAutoshapes**

Get autoshapes description in worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autoshapes
```
### **Function Description**

### The request parameters of **getWorksheetAutoshapes** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|Document's folder.|
|storageName|String|Query|Storage name.|

### **Response Description**
```json
{
  "Name": "AutoShapesResponse",
  "Description": [
    "Represents the AutoShapes Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "AutoShapes",
      "Description": [
        "The class has a property named \"AutoShapes\" decorated with the XmlElement attribute \"shapes\"."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "AutoShapes",
        "Name": "class:autoshapes"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AutoshapesController/GetWorksheetAutoshapes) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
