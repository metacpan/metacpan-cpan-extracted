# **Spreadsheet Cloud API: postUpdateWordCase**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/updatewordcase
```
### **Function Description**

### The request parameters of **postUpdateWordCase** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|wordCaseOptions|Class|Body||

### **Response Description**
```json
{
  "Name": "FileInfo",
  "Description": [
    "Represents file information."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Filename",
      "Description": [
        "Represents filename. "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "FileSize",
      "Description": [
        "Represents file size."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Long",
        "Name": "long"
      }
    },
    {
      "Name": "FileContent",
      "Description": [
        "Represents file content,  byte to base64 string."
      ],
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostUpdateWordCase) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
