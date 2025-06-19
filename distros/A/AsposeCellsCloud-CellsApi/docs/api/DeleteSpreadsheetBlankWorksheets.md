# **Spreadsheet Cloud API: deleteSpreadsheetBlankWorksheets**

Delete all blank worksheets which do not contain any data or other object. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/delete/blank-worksheets
```
### **Function Description**

### The request parameters of **deleteSpreadsheetBlankWorksheets** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TransformController/DeleteSpreadsheetBlankWorksheets) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
