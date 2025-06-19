# **Spreadsheet Cloud API: putDocumentProtectFromChanges**

Excel file write protection. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/writeProtection
```
### **Function Description**
PageTitle: Excel file unprotection.PageDescription: Aspose.Cells Cloud provides robust support for Excel file unprotection.HeadTitle: Excel file unprotection.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file unprotectionHeadContent: Aspose.Cells Cloud provides REST API which supports Excel file unprotection and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putDocumentProtectFromChanges** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|password|Class|Body|The password needed to open an Excel file.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ProtectionController/PutDocumentProtectFromChanges) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
