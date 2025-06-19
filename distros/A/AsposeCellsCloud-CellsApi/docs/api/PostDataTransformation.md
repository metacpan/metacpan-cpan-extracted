# **Spreadsheet Cloud API: postDataTransformation**

Transform spreadsheet data is mainly used to pivot columns, unpivot columns. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/datatransformation
```
### **Function Description**
PageTitle: Data Transform: pivot columns and unpivot columns.PageDescription: Aspose.Cells Cloud provides robust support for transforming data of spreadsheet files, a process known for its intricacy.  Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, ODS, and so on.HeadTitle: Deleting incomplete rows of spreadsheet files.HeadSummary: Aspose.Cells Cloud provides robust support for transforming data of spreadsheet files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, ODS, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports transforming data of spreadsheet files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postDataTransformation** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|dataTransformationRequest|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/PostDataTransformation) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
