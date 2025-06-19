# **Spreadsheet Cloud API: postWorksheetTextReplace**

Replace old text with new text in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/replaceText
```
### **Function Description**
PageTitle: Replace old text with new text in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for replacing old text with new text in the worksheet, a process known for its intricacy.HeadTitle: Replace old text with new text in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for replacing old text with new text in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports replacing old text with new text in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorksheetTextReplace** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|Worksheet name.|
|oldValue|String|Query|The old text to replace.|
|newValue|String|Query|The new text to replace by.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "WorksheetReplaceResponse",
  "Description": [
    "Represents the WorksheetReplace Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Matches",
      "Description": [
        "\"An integer property named Matches decorated with the XmlElement attribute.\""
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
      "Name": "Worksheet",
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostWorksheetTextReplace) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
