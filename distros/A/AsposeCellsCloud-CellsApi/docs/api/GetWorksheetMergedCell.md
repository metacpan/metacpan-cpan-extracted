# **Spreadsheet Cloud API: getWorksheetMergedCell**

Retrieve description of a merged cell by its index in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/mergedCells/{mergedCellIndex}
```
### **Function Description**
PageTitle: Retrieve descriptions of merged cells in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of merged cells in the worksheet, a process known for its intricacy.HeadTitle: Retrieve descriptions of merged cells in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of merged cells in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of merged cells in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetMergedCell** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|Worksheet name.|
|mergedCellIndex|Integer|Path|Merged cell index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "MergedCellResponse",
  "Description": [
    "Represents the MergedCell Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "MergedCell",
      "Description": [
        "A property named \"MergedCell\" of type \"MergedCell\" which allows getting and setting its value."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "MergedCell",
        "Name": "class:mergedcell"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/GetWorksheetMergedCell) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
