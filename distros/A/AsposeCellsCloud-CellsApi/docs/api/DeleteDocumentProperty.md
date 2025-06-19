# **Spreadsheet Cloud API: deleteDocumentProperty**

Delete an Excel property. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/documentproperties/{propertyName}
```
### **Function Description**
PageTitle: Delete an Excel property.PageDescription: Aspose.Cells Cloud provides robust support for deleting an Excel property by name, a process known for its intricacy.HeadTitle:  Delete an Excel property.HeadSummary: Aspose.Cells Cloud provides robust support for deleting an Excel property by name, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting an Excel property by name and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteDocumentProperty** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|propertyName|String|Path|The property name.|
|type|String|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PropertiesController/DeleteDocumentProperty) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
