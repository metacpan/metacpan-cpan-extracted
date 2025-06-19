# **Spreadsheet Cloud API: postWorksheetListColumn**

Update list column in list object. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex}/listcolumns/{columnIndex}
```
### **Function Description**
PageTitle: Update list column in list object.PageDescription: Aspose.Cells Cloud provides robust support for updating list column in list object, a process known for its intricacy.HeadTitle: Update list column in list object.HeadSummary: Aspose.Cells Cloud provides robust support for updating list column in list object, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports updating list column in list object and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetListColumn** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|listObjectIndex|Integer|Path|The list object index.|
|columnIndex|Integer|Path|Represents table column index.|
|listColumn|Class|Body|Represents table column description.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ListObjectsController/PostWorksheetListColumn) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
