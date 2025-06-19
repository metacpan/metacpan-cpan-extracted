# **Spreadsheet Cloud API: getVerticalPageBreaks**

Retrieve descriptions of vertical page breaks in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/verticalpagebreaks
```
### **Function Description**
PageTitle: Retrieve descriptions of vertical page breaks in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of vertical page breaks in the worksheet, a process known for its intricacy.HeadTitle: Retrieve descriptions of vertical page breaks in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of vertical page breaks in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of vertical page breaks in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getVerticalPageBreaks** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "VerticalPageBreaksResponse",
  "Description": [
    "Represents the VerticalPageBreaks Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "VerticalPageBreaks",
      "Description": [
        "This class has a property named VerticalPageBreaks of type VerticalPageBreaks that can be both read from and written to."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "VerticalPageBreaks",
        "Name": "class:verticalpagebreaks"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageBreaksController/GetVerticalPageBreaks) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
