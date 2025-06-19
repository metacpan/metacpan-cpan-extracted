# **Spreadsheet Cloud API: postConvertWorkbookToPptx**

Convert Excel file to Pptx files. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/convert/pptx
```
### **Function Description**
PageTitle: Convert Excel files to Pptx files.PageDescription: Aspose.Cells Cloud provides robust support for converting Excel files to Pptx files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadTitle:Convert Excel files to Pptx files.HeadSummary: Aspose.Cells Cloud provides robust support for converting Excel files to Pptx files, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports converting Excel files to Pptx files and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on. .

### The request parameters of **postConvertWorkbookToPptx** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|File|File|FormData|File to upload|
|password|String|Query|The password needed to open an Excel file.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|
|FontsLocation|String|Query|Use Custom fonts.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/PostConvertWorkbookToPptx) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
