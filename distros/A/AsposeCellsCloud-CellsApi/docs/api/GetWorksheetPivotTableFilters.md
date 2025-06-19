# **Spreadsheet Cloud API: getWorksheetPivotTableFilters**

Gets PivotTable filters in worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters
```
### **Function Description**
PageTitle: Retrieve descriptions of pivot fields in the PivotTable.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of pivot fields in the PivotTable, a process known for its intricacy.HeadTitle: Retrieve descriptions of pivot fields in the PivotTable.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of pivot fields in the PivotTable, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of pivot fields in the PivotTable and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetPivotTableFilters** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|pivotTableIndex|Integer|Path|The PivotTable index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "PivotFiltersResponse",
  "Description": [
    "Represents the PivotFilters Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "PivotFilters",
      "Description": [
        "Property summary: Contains a list of PivotFilter objects."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "PivotFilter",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "PivotFilter",
          "Name": "class:pivotfilter"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PivotTablesController/GetWorksheetPivotTableFilters) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
