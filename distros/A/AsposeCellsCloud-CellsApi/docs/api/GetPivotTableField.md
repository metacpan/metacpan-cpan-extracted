# **Spreadsheet Cloud API: getPivotTableField**

Retrieve descriptions of pivot fields in the PivotTable. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField
```
### **Function Description**
PageTitle: Retrieve descriptions of pivot fields in the PivotTable.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of pivot fields in the PivotTable, a process known for its intricacy.HeadTitle: Retrieve descriptions of pivot fields in the PivotTable.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of pivot fields in the PivotTable, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of pivot fields in the PivotTable and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getPivotTableField** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|pivotTableIndex|Integer|Path|The PivotTable index.|
|pivotFieldIndex|Integer|Query|The pivot field index of PivotTable.|
|pivotFieldType|String|Query|The field area type(column/row).|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "PivotFieldResponse",
  "Description": [
    "Represents the PivotField Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "PivotField",
      "Description": [
        "This class has a property named \"PivotField\" of type PivotField which can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "PivotField",
        "Name": "class:pivotfield"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PivotTablesController/GetPivotTableField) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
