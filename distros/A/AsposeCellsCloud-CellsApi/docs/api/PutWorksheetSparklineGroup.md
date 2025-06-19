# **Spreadsheet Cloud API: putWorksheetSparklineGroup**

Add a sparkline group in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/sparklineGroups
```
### **Function Description**
PageTitle: Add a sparkline group in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a sparkline group in a worksheet, a process known for its intricacy.HeadTitle: Add a sparkline group in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a sparkline group in a worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a sparkline group in a worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetSparklineGroup** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|type|String|Query|Represents the sparkline types(Line/Column/Stacked).|
|dataRange|String|Query|Specifies the data range of the sparkline group.|
|isVertical|Boolean|Query|Specifies whether to plot the sparklines from the data range by row or by column.|
|locationRange|String|Query|Specifies where the sparklines to be placed.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SparklineGroupsController/PutWorksheetSparklineGroup) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
