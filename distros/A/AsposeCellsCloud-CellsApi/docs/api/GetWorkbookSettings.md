# **Spreadsheet Cloud API: getWorkbookSettings**

Retrieve descriptions of workbook settings. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/settings
```
### **Function Description**
PageTitle: Retrieve descriptions of workbook settings.PageDescription: Aspose.Cells Cloud provides robust support for obtaining descriptions of workbook settings in the workbook, a process known for its intricacy.HeadTitle: Retrieve descriptions of workbook settings.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining descriptions of workbook settings in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining descriptions of workbook settings in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorkbookSettings** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "WorkbookSettingsResponse",
  "Description": [
    "Represents the WorkbookSettings Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "settings",
      "Description": [
        "The class has a public property called \"settings\" of type WorkbookSettings that can be accessed and modified."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "WorkbookSettings",
        "Name": "class:workbooksettings"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/GetWorkbookSettings) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
