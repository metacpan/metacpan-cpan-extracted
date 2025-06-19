# **Spreadsheet Cloud API: getChartAreaFillFormat**

Retrieve chart area fill format description in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/fillFormat
```
### **Function Description**
PageTitle: Retrieve chart fill format description in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining chart fill format description in the worksheet, a process known for its intricacy.HeadTitle: Retrieve chart fill format description in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining chart fill format description in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining chart fill format description in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getChartAreaFillFormat** API are: 

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
  "Name": "FillFormatResponse",
  "Description": [
    "Represents the FillFormat Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "FillFormat",
      "Description": [
        "Property Summary: Allows access to the FillFormat property to get or set fill formatting properties for an object."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "FillFormat",
        "Name": "class:fillformat"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ChartAreaController/GetChartAreaFillFormat) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
