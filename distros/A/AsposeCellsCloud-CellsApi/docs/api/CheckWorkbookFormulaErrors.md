# **Spreadsheet Cloud API: checkWorkbookFormulaErrors**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/checkformulaerrors
```
### **Function Description**

### The request parameters of **checkWorkbookFormulaErrors** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|formulaErrorOptions|Class|Body||

### **Response Description**
```json
{
  "Name": "CheckedFormulaErrorsResponse",
  "Description": [
    ""
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "IsFormulasErrors",
      "Description": [
        ""
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
      "Name": "FormulasErrors",
      "Description": [
        ""
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataCheckingController/CheckWorkbookFormulaErrors) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
