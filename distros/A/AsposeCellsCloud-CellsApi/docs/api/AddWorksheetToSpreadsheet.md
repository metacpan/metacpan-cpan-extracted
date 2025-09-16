# **Spreadsheet Cloud API: addWorksheetToSpreadsheet**

The Web API enables users to add a new worksheet to a workbook, specifying the worksheet's type, position, and name. This function provides flexibility in managing workbook structure by allowing detailed control over worksheet addition. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/spreadsheet/add/worksheet
```
### **Function Description**
By using the AddWorksheet API, you can dynamically manage the structure of your workbook, adding new worksheets with specific types, positions, and names, thereby enhancing your productivity and control over spreadsheet management.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Spreadsheet Creation**: Allows users to create a new spreadsheet with a specified name.- **Template Support**: Optionally, users can provide a template to initialize the spreadsheet with predefined content or formatting.- **Flexibility in Workbook Management**: Provides detailed control over the addition of new worksheets, enhancing flexibility in managing workbook structure.

### The request parameters of **addWorksheetToSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|sheetType|String|Query|Specifies the name of the new worksheet.If not provided, a default name will be assigned.|
|position|Integer|Query|Specifies the position at which the new worksheet should be inserted.If not provided, the worksheet will be added at the end of the workbook.|
|sheetName|String|Query|Specifies the type of worksheet to be added.If not provided, a default worksheet type will be used.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ManagementController/AddWorksheetToSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
