# **Spreadsheet Cloud API: postDigitalSignature**

Excel file digital signature. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/digitalsignature
```
### **Function Description**
PageTitle: Excel file digital signature.PageDescription: Aspose.Cells Cloud provides robust support for Excel file digital signature, a process that is an electronic, encrypted, stamp of authentication on Excel files.HeadTitle: Excel file digital signature.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file digital signature, a process  that is an electronic, encrypted, stamp of authentication on Excel files. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides  REST API which supports Excel file digital signature and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postDigitalSignature** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|digitalsignaturefile|String|Query|The digital signature file path should include both the folder and the file name, along with the extension.|
|password|String|Query|The password needed to open an Excel file.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "CellsCloudResponse",
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ProtectionController/PostDigitalSignature) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
