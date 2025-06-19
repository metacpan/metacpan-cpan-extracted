# **Spreadsheet Cloud API: getChartCategoryAxis**

Retrieve descriptions of chart series axis in the chart. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/categoryaxis
```
### **Function Description**
PageTitle: Retrieve descriptions of chart series axis in the chart.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of chart series axis in the chart, a process known for its intricacy.HeadTitle: Retrieve descriptions of chart series axis in the chart.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of chart series axis in the chart, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of chart series axis in the chart and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getChartCategoryAxis** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|chartIndex|Integer|Path|The chart index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "AxisResponse",
  "Description": [
    "Represents the Axis Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Axis",
      "Description": [
        "A property named \"Axis\" of type \"Axis\" with both getter and setter methods is present in the class."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Axis",
        "Name": "class:axis"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ChartsController/GetChartCategoryAxis) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
