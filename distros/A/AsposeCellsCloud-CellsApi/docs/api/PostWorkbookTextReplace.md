# **Spreadsheet Cloud API: postWorkbookTextReplace**

Replace text in the workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/replaceText
```
### **Function Description**
PageTitle: Replace text in the workbook.PageDescription: Aspose.Cells Cloud provides robust support for replacing text in the workbook, a process known for its intricacy.HeadTitle:  Replace text in the workbook.HeadSummary: Aspose.Cells Cloud provides robust support for replacing text in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports replacing text in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookTextReplace** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|oldValue|String|Query|The old value.|
|newValue|String|Query|The new value.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "WorkbookReplaceResponse",
  "Description": [
    "Represents the WorkbookReplace Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Matches",
      "Description": [
        "Property summary: An integer property named \"Matches\" with an XmlElement attribute."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Workbook",
      "Description": [
        ""
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "LinkElement",
        "Name": "class:linkelement"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostWorkbookTextReplace) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
