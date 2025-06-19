# **Spreadsheet Cloud API: postWorksheetCellsRangeColumnWidth**

Set the column width of the specified range. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/ranges/columnWidth
```
### **Function Description**
PageTitle: Set the column width of the specified range.PageDescription: Aspose.Cells Cloud provides robust support for setting the column width of the specified range in the worksheet, a process known for its intricacy.HeadTitle: Set the column width of the specified range.HeadSummary: Aspose.Cells Cloud provides robust support for setting the column width of the specified range in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports setting the column width of the specified range in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetCellsRangeColumnWidth** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|range|Class|Body|Range The range object.|
|value|Floating|Query|Sets the column width of this range.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/RangesController/PostWorksheetCellsRangeColumnWidth) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
