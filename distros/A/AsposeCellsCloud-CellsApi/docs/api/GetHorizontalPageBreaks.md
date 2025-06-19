# **Spreadsheet Cloud API: getHorizontalPageBreaks**

Retrieve descriptions of horizontal page breaks in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/horizontalpagebreaks
```
### **Function Description**
PageTitle: Retrieve descriptions of horizontal page breaks in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of horizontal page breaks in the worksheet, a process known for its intricacy.HeadTitle: Retrieve descriptions of horizontal page breaks in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of horizontal page breaks in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of horizontal page breaks in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getHorizontalPageBreaks** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "HorizontalPageBreaksResponse",
  "Description": [
    "Represents the HorizontalPageBreaks Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "HorizontalPageBreaks",
      "Description": [
        "The property \"HorizontalPageBreaks\" allows getting and setting horizontal page breaks for the class."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "HorizontalPageBreaks",
        "Name": "class:horizontalpagebreaks"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageBreaksController/GetHorizontalPageBreaks) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
