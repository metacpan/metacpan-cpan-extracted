# **Spreadsheet Cloud API: deleteHorizontalPageBreak**

Delete a horizontal page break in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
DELETE http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/horizontalpagebreaks/{index}
```
### **Function Description**
PageTitle: Delete a horizontal page break in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for deleting a horizontal page break in the worksheet, a process known for its intricacy.HeadTitle: Delete a horizontal page break in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for deleting a horizontal page break in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports deleting a horizontal page break in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **deleteHorizontalPageBreak** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|index|Integer|Path|Removes the horizontal page break element at a specified name. Element index, zero based.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageBreaksController/DeleteHorizontalPageBreak) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
