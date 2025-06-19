# **Spreadsheet Cloud API: postWorkbooksMerge**

Merge a workbook into the existing workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/merge
```
### **Function Description**
PageTitle: Merge a workbook into the existing workbook.PageDescription: Aspose.Cells Cloud provides robust support for merging a workbook into the existing workbook, a process known for its intricacy.HeadTitle:  Merge a workbook into the existing workbook.HeadSummary: Aspose.Cells Cloud provides robust support for merging a workbook into the existing workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports merging a workbook into the existing workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbooksMerge** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|mergeWith|String|Query|The workbook to merge with.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|mergedStorageName|String|Query|Storage name.|

### **Response Description**
```json
{
  "Name": "WorkbookResponse",
  "Description": [
    "Represents the Workbook Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Workbook",
      "Description": [
        "Workbook property of the class allows access to and modification of a Workbook object."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "Workbook",
        "Name": "class:workbook"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostWorkbooksMerge) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
