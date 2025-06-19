# **Spreadsheet Cloud API: getWorksheetCellsRangeValue**

Retrieve the values of cells within the specified range. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/ranges/value
```
### **Function Description**
PageTitle: Set the style for the specified range.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the values of cells within the specified range in the worksheet, a process known for its intricacy.HeadTitle: Set the style for the specified range.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the values of cells within the specified range in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the values of cells within the specified range in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetCellsRangeValue** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|namerange|String|Query|The range name.|
|firstRow|Integer|Query|Gets the index of the first row of the range.|
|firstColumn|Integer|Query|Gets the index of the first columnn of the range.|
|rowCount|Integer|Query|Gets the count of rows in the range.|
|columnCount|Integer|Query|Gets the count of columns in the range.|
|folder|String|Query|Original workbook folder.|
|storageName|String|Query|Storage name.|

### **Response Description**
```json
{
  "Name": "RangeValueResponse",
  "Description": [
    "Represents the RangeValue Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "CellsList",
      "Description": [
        "Property Summary: Contains a list of elements labeled as \"Cell\"."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "Cell",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "Cell",
          "Name": "class:cell"
        },
        "Name": "container"
      }
    },
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/RangesController/GetWorksheetCellsRangeValue) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
