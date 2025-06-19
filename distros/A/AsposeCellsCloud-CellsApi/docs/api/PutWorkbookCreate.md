# **Spreadsheet Cloud API: putWorkbookCreate**

Create a new workbook using different methods. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}
```
### **Function Description**
PageTitle:  Create a new workbook using different methods.PageDescription: Aspose.Cells Cloud provides robust support for creating a new workbook using different methods, a process known for its intricacy.HeadTitle: Create a new workbook using different methods.HeadSummary: Aspose.Cells Cloud provides robust support for creating a new workbook using different methods, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports creating a new workbook using different methods and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorkbookCreate** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The new document name.|
|templateFile|String|Query|The template file, if the data not provided default workbook is created.|
|dataFile|String|Query|Smart marker data file, if the data not provided the request content is checked for the data.|
|isWriteOver|Boolean|Query|Specifies whether to write over targer file.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|checkExcelRestriction|Boolean|Query||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PutWorkbookCreate) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
