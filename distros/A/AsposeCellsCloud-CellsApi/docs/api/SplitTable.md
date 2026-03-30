# **Spreadsheet Cloud API: splitTable**

Split an Excel worksheet tale into multiple sheets by column value. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/split/table
```
### **Function Description**
This method performs a split operation on the source table by grouping rows according to the distinct values in the specified .Each group of data (for each unique split value) is then processed as a separate data unit.The export destination is controlled by two key boolean parameters:-  Determines the workbook structure. If `true`, each split unit is saved into a separate workbook file. If `false`, each unit becomes a new worksheet within the current workbook.- Determines the output packaging. When set to `true` and combined with `toNewWorkbook` = `true`, the method generates multiple individual files and returns them as a ZIP archive. When `false`, all data is consolidated into a single file (either a multi-sheet workbook or a single file as per other settings).## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Local File Splitting**: Splits a single local spreadsheet file into multiple output files in the specified format (e.g., XLSX, CSV, PDF).- **Cloud-Based Processing**: Performs the splitting operation in the cloud, without requiring cloud storage.- **Enhanced Performance**: Processes the file in the cloud, reducing the need for local processing and improving performance.

### The request parameters of **splitTable** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|Worksheet containing the table.|
|tableName|String|Query|Data table that needs to be split.|
|splitColumnName|String|Query|Column name to split by.|
|saveSplitColumn|Boolean|Query|Whether to keep the data in the split column.|
|splitRowNumber|Integer|Query||
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

[[Back to API list]](../DeveloperGuide.md#api-reference)  
[[Back to README]](../../README.md)