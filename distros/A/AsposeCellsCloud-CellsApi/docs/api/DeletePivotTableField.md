# **Spreadsheet Cloud API: deletePivotTableField**

Delete a pivot field in the PivotTable. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField
```
### **Function Description**
PageTitle: Delete a pivot field in the PivotTable.PageDescription: Aspose.Cells Cloud provides robust support for deleting a pivot field in the PivotTable, a process known for its intricacy.HeadTitle: Delete a pivot field in the PivotTable.HeadSummary: Aspose.Cells Cloud provides robust support for deleting a pivot field in the PivotTable, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting a pivot field in the PivotTable and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deletePivotTableField** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|pivotTableIndex|Integer|Path|Gets the PivotTable report by index.|
|pivotFieldType|String|Query|The fields area type.|
|pivotTableFieldRequest|Class|Body|PivotTableFieldRequest PivotTable field request.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PivotTablesController/DeletePivotTableField) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
