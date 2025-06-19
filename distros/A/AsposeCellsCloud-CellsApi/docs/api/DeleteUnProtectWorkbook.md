# **Spreadsheet Cloud API: deleteUnProtectWorkbook**

Excel unprotection. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/protection
```
### **Function Description**
PageTitle: Excel file unprotection.PageDescription: Aspose.Cells Cloud provides robust support for Excel file unprotection.HeadTitle: Excel file unprotection.HeadSummary: Aspose.Cells Cloud provides robust support for Excel file unprotectionHeadContent: Aspose.Cells Cloud provides  REST API which supports Excel file unprotection and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteUnProtectWorkbook** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|password|String|Query|Protection settings, only password can be specified.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ProtectionController/DeleteUnProtectWorkbook) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
