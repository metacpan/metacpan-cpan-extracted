# **Spreadsheet Cloud API: postWorksheetListObjectInsertSlicer**

Insert slicer for list object. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex}/InsertSlicer
```
### **Function Description**
PageTitle: Insert slicer for list object.PageDescription: Aspose.Cells Cloud provides robust support for inserting slicer for list object, a process known for its intricacy.HeadTitle: Insert slicer for list object.HeadSummary: Aspose.Cells Cloud provides robust support for inserting slicer for list object, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports inserting slicer for list object and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetListObjectInsertSlicer** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|listObjectIndex|Integer|Path|List object index.|
|columnIndex|Integer|Query|The index of ListColumn in ListObject.ListColumns |
|destCellName|String|Query|The cell in the upper-left corner of the Slicer range. |
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ListObjectsController/PostWorksheetListObjectInsertSlicer) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
