# **Spreadsheet Cloud API: postCopyWorksheetRows**

Copy data and formats from specific entire rows in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/rows/copy
```
### **Function Description**
PageTitle: Copy data and formats from specific entire rows in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for copying data and formats from specific entire rows in the worksheet, a process known for its intricacy.HeadTitle: Copy data and formats from specific entire rows in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for copying data and formats from specific entire rows in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports copying data and formats from specific entire rows in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postCopyWorksheetRows** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|sourceRowIndex|Integer|Query|Source row index|
|destinationRowIndex|Integer|Query|Destination row index|
|rowNumber|Integer|Query|The copied row number|
|worksheet|String|Query|The worksheet name.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/PostCopyWorksheetRows) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
