# **Spreadsheet Cloud API: putDocumentProperty**

Set or add an Excel property. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/documentproperties
```
### **Function Description**
PageTitle: Set or add an Excel property.PageDescription: Aspose.Cells Cloud provides robust support for setting or adding an Excel property, a process known for its intricacy.HeadTitle: Set or add an Excel property.HeadSummary: Aspose.Cells Cloud provides robust support for setting or adding an Excel property, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports setting or adding an Excel property and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putDocumentProperty** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|property|Class|Body|Get or set the value of the property.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PropertiesController/PutDocumentProperty) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
