# **Spreadsheet Cloud API: deleteWorksheetFreezePanes**

Unfreeze panes in worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/freezepanes
```
### **Function Description**
PageTitle: Unfreeze panes in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for unfreezing panes in the worksheet, a process known for its intricacy.HeadTitle: Unfreeze panes in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for unfreezing panes in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports unfreezing panes in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteWorksheetFreezePanes** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|row|Integer|Query|Row index.|
|column|Integer|Query|Column index.|
|freezedRows|Integer|Query|Number of visible rows in top pane, no more than row index.|
|freezedColumns|Integer|Query|Number of visible columns in left pane, no more than column index.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/DeleteWorksheetFreezePanes) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
