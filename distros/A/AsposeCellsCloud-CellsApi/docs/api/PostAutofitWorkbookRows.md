# **Spreadsheet Cloud API: postAutofitWorkbookRows**

Autofit rows in the workbook. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/autofitrows
```
### **Function Description**
PageTitle:  Autofit rows in the workbook.PageDescription: Aspose.Cells Cloud provides robust support for autofitting rows in the workbook, a process known for its intricacy.HeadTitle: Autofit rows in the workbook.HeadSummary: Aspose.Cells Cloud provides robust support for autofitting rows in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports autofitting rows in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postAutofitWorkbookRows** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|startRow|Integer|Query|Start row.|
|endRow|Integer|Query|End row.|
|onlyAuto|Boolean|Query|Only auto.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|firstColumn|Integer|Query|First column index.|
|lastColumn|Integer|Query|Last column index.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostAutofitWorkbookRows) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
