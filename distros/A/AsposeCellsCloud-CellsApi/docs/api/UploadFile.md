# **Spreadsheet Cloud API: uploadFile**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/storage/file/{path}
```
### **Function Description**

### The request parameters of **uploadFile** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|UploadFiles|File|FormData|Upload files to cloud storage.|
|path|String|Path||
|storageName|String|Query||

### **Response Description**
```json
{
  "Name": "FilesUploadResult",
  "Description": [
    "File upload result"
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Uploaded",
      "Description": [
        "List of uploaded file names"
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "String",
        "ElementDataType": {
          "Identifier": "String",
          "Name": "string"
        },
        "Name": "container"
      }
    },
    {
      "Name": "Errors",
      "Description": [
        "List of errors."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "Error",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "Error",
          "Name": "class:error"
        },
        "Name": "container"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/FileController/UploadFile) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
