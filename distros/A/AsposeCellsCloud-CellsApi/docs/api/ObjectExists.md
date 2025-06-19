# **Spreadsheet Cloud API: objectExists**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/storage/exist/{path}
```
### **Function Description**

### The request parameters of **objectExists** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|path|String|Path||
|storageName|String|Query||
|versionId|String|Query||

### **Response Description**
```json
{
  "Name": "ObjectExist",
  "Description": [
    "Object exists"
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Exists",
      "Description": [
        "Indicates that the file or folder exists."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Boolean",
        "Name": "boolean"
      }
    },
    {
      "Name": "IsFolder",
      "Description": [
        "True if it is a folder, false if it is a file."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Boolean",
        "Name": "boolean"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/StorageController/ObjectExists) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
