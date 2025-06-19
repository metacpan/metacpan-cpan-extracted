# **Spreadsheet Cloud API: postSetCellRangeValue**

Set the value of the range in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells
```
### **Function Description**
PageTitle: Set the value of the range in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for setting the value of the rang in the worksheet, a process known for its intricacy.HeadTitle: Set the value of the range in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for setting the value of the rang in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports setting the value of the rang in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postSetCellRangeValue** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|cellarea|String|Query|Cell area (like "A1:C2")|
|value|String|Query|Range value|
|type|String|Query|Value data type (like "int")|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/PostSetCellRangeValue) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
