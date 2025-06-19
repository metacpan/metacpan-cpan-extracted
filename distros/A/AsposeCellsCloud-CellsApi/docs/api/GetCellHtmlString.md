# **Spreadsheet Cloud API: getCellHtmlString**

Retrieve the HTML string containing data and specific formats in this cell. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/{cellName}/htmlstring
```
### **Function Description**
PageTitle: Retrieve the HTML string containing data and specific formats in this cell.PageDescription: Aspose.Cells Cloud provides robust support for getting the HTML string containing data and specific formats in this cell, a process known for its intricacy.HeadTitle: Retrieve the HTML string containing data and specific formats in this cell.HeadSummary: Aspose.Cells Cloud provides robust support for getting the HTML string containing data and specific formats in this cell, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports getting the HTML string containing data and specific formats in this cell and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getCellHtmlString** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|cellName|String|Path|The cell name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
String
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/GetCellHtmlString) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
