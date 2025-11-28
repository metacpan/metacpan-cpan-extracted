# **Spreadsheet Cloud API: removeSpreadsheetBlankWorksheets**

Delete all blank rows that do not contain any data or other objects. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/remove/blank-worksheets
```
### **Function Description**
This method removes rows from a spreadsheet that are completely empty, containing no data or objects. It scans through all sheets and identifies rows where every cell is empty. The operation is performed directly on the spreadsheet, ensuring that only rows with no content are deleted. This helps in cleaning up the spreadsheet and removing unnecessary blank rows, making the data more organized and easier to manage. Users should ensure that the spreadsheet is backed up before performing this operation, as deleted rows cannot be recovered. ## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Blank Worksheet Identification**: This function identifies and deletes worksheets that do not contain any data or objects, ensuring a clean workbook.- **Workbook Optimization**: By removing empty worksheets, it optimizes the workbook, reducing file size and improving performance.- **Efficiency**:  Enhances the organization and manageability of spreadsheets by eliminating unnecessary sheets.- **Usage scenarios**: Ideal for cleaning up workbooks where unused worksheets may clutter the file and affect usability.

### The request parameters of **removeSpreadsheetBlankWorksheets** API are: 

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TransformController/RemoveSpreadsheetBlankWorksheets) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
