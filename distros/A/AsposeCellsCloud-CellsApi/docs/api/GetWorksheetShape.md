# **Spreadsheet Cloud API: getWorksheetShape**

Retrieve description of shape in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/shapes/{shapeindex}
```
### **Function Description**
PageTitle:  Retrieve description of shape in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining description of shape in the worksheet, a process known for its intricacy.HeadTitle: Retrieve description of shape in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining description of shape in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining description of shape in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetShape** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|shapeindex|Integer|Path|shape index in worksheet shapes.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "ShapeResponse",
  "Description": [
    "Represents the Shape Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Shape",
      "Description": [
        "A public property Shape of type ArcShape that can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Shape",
        "Name": "class:shape"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ShapesController/GetWorksheetShape) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
