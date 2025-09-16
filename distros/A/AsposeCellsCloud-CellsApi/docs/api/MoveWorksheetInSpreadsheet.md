# **Spreadsheet Cloud API: moveWorksheetInSpreadsheet**

The Web API endpoint allows users to move a specified worksheet within a workbook. This function provides a straightforward way to move a worksheet, enhancing workbook organization. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/spreadsheet/move/worksheet
```
### **Function Description**
By using the MoveWorksheet API, you can dynamically manage the structure of your workbook by moving a specified worksheet to a new position. This feature enhances your ability to organize and optimize your workbook efficiently. Whether you need to rearrange worksheets for better readability or to group related data together, this API provides the flexibility to do so with ease.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Dynamic Worksheet Movement**: Allows users to move a specified worksheet to a new position within the workbook.

### The request parameters of **moveWorksheetInSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|The current name of the worksheet to be moved.|
|position|Integer|Query|Move the worksheet to the position|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ManagementController/MoveWorksheetInSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
