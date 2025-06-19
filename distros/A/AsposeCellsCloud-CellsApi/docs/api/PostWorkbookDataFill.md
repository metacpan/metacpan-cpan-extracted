# **Spreadsheet Cloud API: postWorkbookDataFill**

Data filling for spreadsheet files is primarily used to fill empty data in tables and ranges. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/datafill
```
### **Function Description**
PageTitle: Data filling of spreadsheet files.PageDescription: Aspose.Cells Cloud provides robust support for data filling of spreadsheet files, a process known for its intricacy.  Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, ODS, and so on.HeadTitle: Data filling of spreadsheet files.HeadSummary: Aspose.Cells Cloud provides robust support for data filling of spreadsheet files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, ODS, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports data filling of spreadsheet files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookDataFill** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path||
|dataFill|Class|Body||
|folder|String|Query||
|storageName|String|Query||
|password|String|Query||
|region|String|Query||
|checkExcelRestriction|Boolean|Query||

### **Response Description**
```json
{
  "Name": "FileInfo",
  "Description": [
    "Represents file information."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Filename",
      "Description": [
        "Represents filename. "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "FileSize",
      "Description": [
        "Represents file size."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Long",
        "Name": "long"
      }
    },
    {
      "Name": "FileContent",
      "Description": [
        "Represents file content,  byte to base64 string."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/PostWorkbookDataFill) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
