# **Spreadsheet Cloud API: deleteDocumentProperties**

Delete all custom document properties and reset built-in ones. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/documentproperties
```
### **Function Description**
PageTitle: Delete all custom document properties and reset built-in ones.PageDescription: Aspose.Cells Cloud provides robust support for deleting all custom document properties and resetting built-in ones, a process known for its intricacy.HeadTitle:  Delete all custom document properties and reset built-in ones.HeadSummary: Aspose.Cells Cloud provides robust support for deleting all custom document properties and resetting built-in ones, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting all custom document properties and resetting built-in ones and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteDocumentProperties** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PropertiesController/DeleteDocumentProperties) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
