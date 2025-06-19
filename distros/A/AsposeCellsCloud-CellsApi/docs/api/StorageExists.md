# **Spreadsheet Cloud API: storageExists**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/storage/{storageName}/exist
```
### **Function Description**

### The request parameters of **storageExists** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|storageName|String|Path||

### **Response Description**
```json
{
  "Name": "StorageExist",
  "Description": [
    "Storage exists"
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Exists",
      "Description": [
        "Shows that the storage exists.",
        "            "
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/StorageController/StorageExists) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
