# **Spreadsheet Cloud API: postEncryptWorkbook**

Excel Encryption. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/encryption
```
### **Function Description**
PageTitle: Excel file encryption.PageDescription: Aspose.Cells Cloud provides robust support for Excel file encryption, a process that is an important part of your Excel file protection and information protection strategy.HeadTitle: Excel file encryption.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file encryption, a process that is  an important part of your Excel file protection and information protection strategy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides  REST API which supports Excel file encryption and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postEncryptWorkbook** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|encryption|Class|Body|WorkbookEncryptionRequestEncryption parameters.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ProtectionController/PostEncryptWorkbook) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
