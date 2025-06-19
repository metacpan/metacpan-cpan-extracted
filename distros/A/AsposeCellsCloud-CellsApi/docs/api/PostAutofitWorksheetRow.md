# **Spreadsheet Cloud API: postAutofitWorksheetRow**

Autofit a row in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autofitrow
```
### **Function Description**
PageTitle: Autofit a row in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for autofitting a row in the worksheet, a process known for its intricacy.HeadTitle: Autofit a row in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for sautofitting a row in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports autofitting a row in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postAutofitWorksheetRow** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|rowIndex|Integer|Query|The row index.|
|firstColumn|Integer|Query|The first column index.|
|lastColumn|Integer|Query|The last column index.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|rowCount|Integer|Query||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostAutofitWorksheetRow) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
