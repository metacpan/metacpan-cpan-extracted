# **Spreadsheet Cloud API: postPivotTableUpdatePivotFields**

Update pivot fields in the PivotTable. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFields
```
### **Function Description**
PageTitle: Update pivot fields in the PivotTable.PageDescription: Aspose.Cells Cloud provides robust support for updating pivot fields in the PivotTable, a process known for its intricacy.HeadTitle: Update pivot fields in the PivotTable.HeadSummary: Aspose.Cells Cloud provides robust support for updating pivot fields in the PivotTable, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports updating pivot fields in the PivotTable and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postPivotTableUpdatePivotFields** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|pivotTableIndex|Integer|Path|The PivotTable index.|
|pivotFieldType|String|Query|Represents PivotTable field type(Undefined/Row/Column/Page/Data).|
|pivotField|Class|Body|PivotFieldRepresents pivot field.|
|needReCalculate|Boolean|Query|Whether the specific PivotTable calculate(true/false).|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PivotTablesController/PostPivotTableUpdatePivotFields) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
