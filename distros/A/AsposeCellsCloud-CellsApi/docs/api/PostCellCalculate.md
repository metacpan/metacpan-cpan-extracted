# **Spreadsheet Cloud API: postCellCalculate**

Calculate cell formula in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/{cellName}/calculate
```
### **Function Description**
PageTitle: Calculate cell formula in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for calculating cell formula in the worksheet, a process known for its intricacy.HeadTitle: Calculate cell formula in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for calculating cell formula in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports calculating cell formula in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postCellCalculate** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|cellName|String|Path|The cell name.|
|options|Class|Body|Calculation Options|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/PostCellCalculate) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
