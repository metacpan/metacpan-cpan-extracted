# **Spreadsheet Cloud API: getWorksheetCell**

Retrieve cell data using either cell reference or method name in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/cells/{cellOrMethodName}
```
### **Function Description**
PageTitle: Retrieve cell data using either cell reference or method name in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for getting cell data using either cell reference or method name in the worksheet, a process known for its intricacy.HeadTitle: Retrieve cell data using either cell reference or method name in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for getting cell data using either cell reference or method name in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports getting cell data using either cell reference or method name in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetCell** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|cellOrMethodName|String|Path|The cell's or method name. (Method name like firstcell, endcell etc.)|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
String
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsController/GetWorksheetCell) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
