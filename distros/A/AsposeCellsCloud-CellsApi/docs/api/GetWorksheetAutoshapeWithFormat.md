# **Spreadsheet Cloud API: getWorksheetAutoshapeWithFormat**

Get autoshape description in some format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autoshapes/{autoshapeNumber}
```
### **Function Description**

### The request parameters of **getWorksheetAutoshapeWithFormat** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|Worksheet name.|
|autoshapeNumber|Integer|Path|The autoshape number.|
|format|String|Query|Autoshape conversion format.|
|folder|String|Query|The document folder.|
|storageName|String|Query|Storage name.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AutoshapesController/GetWorksheetAutoshapeWithFormat) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
