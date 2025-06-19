# **Spreadsheet Cloud API: getWorksheetAutoFilter**

Retrieve the description of auto filters from a worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autoFilter
```
### **Function Description**
PageTitle:  Retrieve the description of auto filters from a worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the description of auto filters from a worksheet, a process known for its intricacy.HeadTitle: Retrieve the description of auto filters from a worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the description of auto filters from a worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the description of auto filters from a worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetAutoFilter** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "AutoFilterResponse",
  "Description": [
    "Represents the AutoFilter Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "AutoFilter",
      "Description": [
        "A property named \"AutoFilter\" with a type of \"AutoFilter\" that can be read from and written to."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "AutoFilter",
        "Name": "class:autofilter"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AutoFilterController/GetWorksheetAutoFilter) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
