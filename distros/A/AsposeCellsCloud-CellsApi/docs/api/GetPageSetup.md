# **Spreadsheet Cloud API: getPageSetup**

Retrieve page setup description in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pagesetup
```
### **Function Description**
PageTitle: Retrieve page setup description in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining page setup description in the worksheet, a process known for its intricacy.HeadTitle: Retrieve page setup description in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining page setup description in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining page setup description in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getPageSetup** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "PageSetupResponse",
  "Description": [
    "Represents the PageSetup Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "PageSetup",
      "Description": [
        "Property Summary: The class has a public property named PageSetup of type PageSetup that can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "PageSetup",
        "Name": "class:pagesetup"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageSetupController/GetPageSetup) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
