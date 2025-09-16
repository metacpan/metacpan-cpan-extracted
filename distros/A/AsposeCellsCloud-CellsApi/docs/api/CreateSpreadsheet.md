# **Spreadsheet Cloud API: createSpreadsheet**

The Web API allows users to create a new spreadsheet with a specified name. Optionally, a template can be provided to initialize the spreadsheet with predefined content or formatting. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/spreadsheet/create
```
### **Function Description**
By using the CreateSpreadsheet function, you can quickly set up new spreadsheets with or without templates, streamlining your workflow and enhancing productivity.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Spreadsheet Creation**: Allows users to create a new spreadsheet with a specified name.- **Template Support**: Optionally, users can provide a template to initialize the spreadsheet with predefined content or formatting.- **Enhanced Productivity**: Quickly set up new spreadsheets, streamlining your workflow.

### The request parameters of **createSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|format|String|Query|Specifies the name of the new spreadsheet. This name will be used to identify the spreadsheet in the system.|
|template|String|Query|template: Optional.If provided, the new spreadsheet will be created based on the specified template.This can be useful for applying predefined layouts and styles.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ManagementController/CreateSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
