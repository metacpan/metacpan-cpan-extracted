# **Spreadsheet Cloud API: unprotectSpreadsheet**

Removes dual-layer password protection from Excel spreadsheets, supporting both open and modify passwords with encryption. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/unprotection/spreadsheet
```
### **Function Description**
This WEB API removes dual-layer password protection from Excel spreadsheets, supporting both open and modify passwords. Passwords can be encrypted to enhance security.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Dual-Layer Password Removal**: Removes both open and modify passwords from Excel spreadsheets.

### The request parameters of **unprotectSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|password|String|Query|Spreadsheet file encryption password.|
|modifyPassword|String|Query|Sets the protected password to modify the file.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|region|String|Query|The spreadsheet region setting.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ProtectionController/UnprotectSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
