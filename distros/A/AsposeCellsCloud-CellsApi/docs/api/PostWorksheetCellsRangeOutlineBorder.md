# **Spreadsheet Cloud API: postWorksheetCellsRangeOutlineBorder**

Apply an outline border around a range of cells. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/ranges/outlineBorder
```
### **Function Description**
PageTitle: Apply an outline border around a range of cellsPageDescription: Aspose.Cells Cloud provides robust support for applying an outline border around a range of cells in the worksheet, a process known for its intricacy.HeadTitle: Apply an outline border around a range of cellsHeadSummary: Aspose.Cells Cloud provides robust support for applying an outline border around a range of cells in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports applying an outline border around a range of cells in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetCellsRangeOutlineBorder** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|rangeOperate|Class|Body|RangeSetOutlineBorderRequest Range Set OutlineBorder Request.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/RangesController/PostWorksheetCellsRangeOutlineBorder) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
