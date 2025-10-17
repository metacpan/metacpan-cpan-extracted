# **Spreadsheet Cloud API: removeSpreadsheetBlankColumns**

Delete all blank rows that do not contain any data or other objects. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/remove/blank-columns
```
### **Function Description**
This method is designed to clean up Excel spreadsheets by removing rows that are completely empty, containing no data or objects. It scans through all sheets and identifies rows where every cell is empty. The operation is performed directly on the Excel file, ensuring that only rows with no content are deleted. This helps in organizing the data and removing unnecessary blank rows, making the spreadsheet more manageable. Users should ensure that the Excel file is backed up before performing this operation, as deleted rows cannot be recovered.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Blank Column Identification**: This function identifies columns that do not contain any data or objects, ensuring thorough removal of unnecessary blank columns.- **Data Integrity**: By removing only truly empty columns, it maintains the integrity of your dataset, preventing accidental data loss.- **Efficiency**: Enhances the readability and usability of spreadsheets by eliminating extraneous blank columns.- **Usage scenarios**: Ideal for cleaning large datasets where blank columns may interfere with data analysis or processing.

### The request parameters of **removeSpreadsheetBlankColumns** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TransformController/RemoveSpreadsheetBlankColumns) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
