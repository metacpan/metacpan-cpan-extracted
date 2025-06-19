# **Spreadsheet Cloud API: postCopyWorksheet**

Copy contents and formats from another worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/copy
```
### **Function Description**
PageTitle: Copy contents and formats from another worksheet.PageDescription: Aspose.Cells Cloud provides robust support for copying contents and formats from another worksheet, a process known for its intricacy.HeadTitle: Copy contents and formats from another worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for copying contents and formats from another worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports copying contents and formats from another worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postCopyWorksheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|sourceSheet|String|Query|Source worksheet.|
|options|Class|Body|Represents the copy options.|
|sourceWorkbook|String|Query|source Workbook.|
|sourceFolder|String|Query|Original workbook folder.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorksheetsController/PostCopyWorksheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
