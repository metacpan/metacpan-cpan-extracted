# **Spreadsheet Cloud API: getWorksheetMergedCells**

Get worksheet merged cells. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/mergedCells
```
### **Function Description**
PageTitle: Retrieve descriptions of merged cells in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of merged cells in the worksheet, a process known for its intricacy.HeadTitle: Retrieve descriptions of merged cells in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of merged cells in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of merged cells in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetMergedCells** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The workseet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "MergedCellsResponse",
  "Description": [
    "Represents the MergedCells Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "MergedCells",
      "Description": [
        "Property Summary: Contains information about merged cells within a spreadsheet."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "MergedCells",
        "Name": "class:mergedcells"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/GetWorksheetMergedCells) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
