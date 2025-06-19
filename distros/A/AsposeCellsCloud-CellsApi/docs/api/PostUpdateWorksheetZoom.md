# **Spreadsheet Cloud API: postUpdateWorksheetZoom**

Update the scaling percentage in the worksheet. It should be between 10 and 400. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/zoom
```
### **Function Description**
PageTitle: Update the scaling percentage in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for updating  the scaling percentage in the worksheet, a process known for its intricacy.HeadTitle: Update the scaling percentage in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for updating the scaling percentage in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports updating the scaling percentage in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postUpdateWorksheetZoom** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|value|Integer|Query|Represents the scaling factor in percentage. It should be between 10 and 400.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostUpdateWorksheetZoom) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
