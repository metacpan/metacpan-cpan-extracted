# **Spreadsheet Cloud API: postWorkbookSplit**

Split the workbook with a specific format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/split
```
### **Function Description**
PageTitle: Split the workbook with a specific format.PageDescription: Aspose.Cells Cloud provides robust support for splitting the workbook with a specific format, a process known for its intricacy.HeadTitle: Split the workbook with a specific format.HeadSummary: Aspose.Cells Cloud provides robust support for splitting the workbook with a specific format, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports splitting the workbook with a specific format and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookSplit** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|format|String|Query|Split format.|
|outFolder|String|Query||
|from|Integer|Query|Start worksheet index.|
|to|Integer|Query|End worksheet index.|
|horizontalResolution|Integer|Query|Image horizontal resolution.|
|verticalResolution|Integer|Query|Image vertical resolution.|
|splitNameRule|String|Query|rule name : sheetname  newguid |
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|outStorageName|String|Query||

### **Response Description**
```json
{
  "Name": "SplitResultResponse",
  "Description": [
    "Represents the SplitResult Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Result",
      "Description": [
        "Gets or sets the splitting result."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "SplitResult",
        "Name": "class:splitresult"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostWorkbookSplit) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
