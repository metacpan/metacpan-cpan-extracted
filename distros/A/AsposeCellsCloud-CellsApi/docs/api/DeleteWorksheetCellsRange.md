# **Spreadsheet Cloud API: deleteWorksheetCellsRange**

Delete a range of cells and shift existing cells based on the specified shift option. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/ranges
```
### **Function Description**
PageTitle: Delete a range of cells and shift existing cells based on the specified shift option.PageDescription: Aspose.Cells Cloud provides robust support for deleting a range of cells and shift existing cells based on the specified shift option in the worksheet, a process known for its intricacy.HeadTitle: Delete a range of cells and shift existing cells based on the specified shift option.HeadSummary: Aspose.Cells Cloud provides robust support for deleting a range of cells and shift existing cells based on the specified shift option in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting a range of cells and shift existing cells based on the specified shift option in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteWorksheetCellsRange** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|range|String|Query|The range object.|
|shift|String|Query|Represent the shift options when deleting a range of cells(Down/Left/None/Right/Up).|
|folder|String|Query|Original workbook folder.|
|storageName|String|Query|Storage name.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/RangesController/DeleteWorksheetCellsRange) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
