# **Spreadsheet Cloud API: splitTable**

Split an Excel worksheet into multiple sheets by column value. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/split/table
```
### **Function Description**

### The request parameters of **splitTable** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|Worksheet containing the table.|
|tableName|String|Query|Data table that needs to be split.|
|splitColumnName|String|Query|Column name to split by.|
|saveSplitColumn|Boolean|Query|Whether to keep the data in the split column.|
|toNewWorkbook|Boolean|Query|Export destination control: true - Creates new workbook files containing the split data; false - Adds a new worksheet to the current workbook.|
|toMultipleFiles|Boolean|Query|true - Exports table data as **multiple separate files** (returned as ZIP archive);false - Stores all data in a **single file** with multiple sheets. Default: false.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|fontsLocation|String|Query|Use Custom fonts.|
|region|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/SplitTable) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
