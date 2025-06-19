# **Spreadsheet Cloud API: getPublicKey**

Get an asymmetric public key. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/publickey
```
### **Function Description**
Retrieves the public key portion of an asymmetric encryption algorithm.Asymmetric encryption algorithms (such as RSA, ECC, etc.) use a pair of keys: a public key and a private key.The public key is used for encrypting data or verifying signatures, while the private key is used for decrypting data or generating signatures.The primary purpose of the GetPublicKey method is to extract and return the public key portion for use when needed.

### The request parameters of **getPublicKey** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 

### **Response Description**
```json
{
  "Name": "CellsCloudPublicKeyResponse",
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "CellsCloudPublicKey",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "CellsCloudPublicKey",
        "Name": "class:cellscloudpublickey"
      }
    },
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/KeyController/GetPublicKey) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
