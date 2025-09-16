# **Spreadsheet Cloud API: renameWorksheetInSpreadsheet**

The Web API endpoint allows users to rename a specified worksheet within a workbook. This function provides a straightforward way to update worksheet names, enhancing workbook organization and readability. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/spreadsheet/rename/worksheet
```
### **Function Description**
By using the RenameWorksheet API, you can dynamically manage the structure of your workbook, updating worksheet names to maintain a clear and organized spreadsheet environment. This feature enhances your ability to manage and optimize your workbook efficiently.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Worksheet Renaming**: Allows users to rename a specified worksheet within a workbook.- **Simplified Workbook Management**: Provides a straightforward method to update worksheet names, enhancing workbook organization and readability.

### The request parameters of **renameWorksheetInSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|sourceName|String|Query|The current name of the worksheet to be renamed.|
|targetName|String|Query|The new name for the worksheet.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|region|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ManagementController/RenameWorksheetInSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
