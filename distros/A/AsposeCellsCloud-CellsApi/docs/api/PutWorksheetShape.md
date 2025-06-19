# **Spreadsheet Cloud API: putWorksheetShape**

Add a shape in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/shapes
```
### **Function Description**
PageTitle: Add a shape in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a shape in the worksheet, a process known for its intricacy.HeadTitle: Add a shape in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a shape in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a shape in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetShape** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|shapeDTO|Class|Body||
|DrawingType|String|Query|Shape object type|
|upperLeftRow|Integer|Query|Upper left row index.|
|upperLeftColumn|Integer|Query|Upper left column index.|
|top|Integer|Query|Represents the vertical offset of Spinner from its left row, in unit of pixel.|
|left|Integer|Query|Represents the horizontal offset of Spinner from its left column, in unit of pixel.|
|width|Integer|Query|Represents the height of Spinner, in unit of pixel.|
|height|Integer|Query|Represents the width of Spinner, in unit of pixel.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "CellsCloudResponse",
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
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
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ShapesController/PutWorksheetShape) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
