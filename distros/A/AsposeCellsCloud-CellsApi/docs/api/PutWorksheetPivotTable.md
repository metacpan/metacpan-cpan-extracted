# **Spreadsheet Cloud API: putWorksheetPivotTable**

Add a PivotTable in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pivottables
```
### **Function Description**
PageTitle: Add a PivotTable in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a PivotTable in the worksheet, a process known for its intricacy.HeadTitle: Add a PivotTable in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a PivotTable in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a PivotTable in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetPivotTable** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|sourceData|String|Query|The data for the new PivotTable cache.|
|destCellName|String|Query|The cell in the upper-left corner of the destination range for the PivotTable report.|
|tableName|String|Query|The name of the new PivotTable.|
|useSameSource|Boolean|Query|Indicates whether using same data source when another existing PivotTable has used this data source. If the property is true, it will save memory.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PivotTablesController/PutWorksheetPivotTable) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
