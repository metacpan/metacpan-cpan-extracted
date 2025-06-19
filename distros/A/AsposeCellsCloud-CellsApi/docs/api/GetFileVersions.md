# **Spreadsheet Cloud API: getFileVersions**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/storage/version/{path}
```
### **Function Description**

### The request parameters of **getFileVersions** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|path|String|Path||
|storageName|String|Query||

### **Response Description**
```json
{
  "Name": "FileVersions",
  "Description": [
    "File versions FileVersion."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Value",
      "Description": [
        "File versions FileVersion."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "FileVersion",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "FileVersion",
          "Name": "class:fileversion"
        },
        "Name": "container"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/StorageController/GetFileVersions) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
