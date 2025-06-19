# **Spreadsheet Cloud API: postWorksheetCellsRangeValue**

Assign a value to the range; if necessary, the value will be converted to another data type, and the cell's number format will be reset. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/ranges/value
```
### **Function Description**
PageTitle: Assign a value to the range; if necessary, the value will be converted to another data type, and the cell's number format will be reset.PageDescription: Aspose.Cells Cloud provides robust support for assigning a value to the range in the worksheet, a process known for its intricacy.HeadTitle: Assign a value to the range; if necessary, the value will be converted to another data type, and the cell's number format will be reset.HeadSummary: Aspose.Cells Cloud provides robust support for assigning a value to the range in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports assigning a value to the range in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetCellsRangeValue** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|range|Class|Body|The range in worksheet. |
|Value|String|Query|Input value.|
|isConverted|Boolean|Query|True: converted to other data type if appropriate.|
|setStyle|Boolean|Query|True: set the number format to cell's style when converting to other data type.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/RangesController/PostWorksheetCellsRangeValue) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
