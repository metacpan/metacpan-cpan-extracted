# **Spreadsheet Cloud API: mergeSpreadsheets**

Merge local spreadsheet files into a specified format file. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/merge/spreadsheet
```
### **Function Description**
This method combines multiple spreadsheet files from the local file system into a single output file in the specified format (e.g., XLSX, CSV, PDF). All input files must be accessible and in a supported format for the merge operation to succeed. The merged content is processed cloudly, without requiring cloud storage. Ensure proper file permissions are granted for reading the source files and writing the output file. If any of the files cannot be accessed or an error occurs during the merging process, an appropriate exception will be thrown. The final output format can be configured based on available conversion and export capabilities.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Local File Merge:**: Combines multiple local spreadsheet files into a single output file in the specified format (e.g., XLSX, CSV, PDF).- **Efficient Data Handling**: Processes the merge operation in the cloud without requiring cloud storage.Merges multiple files into a single output file efficiently, leveraging cloud processing capabilities.- **Format Flexibility**: Supports a range of output formats based on the available conversion and export capabilities.

### The request parameters of **mergeSpreadsheets** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|outFormat|String|Query|The out file format.|
|mergeInOneSheet|Boolean|Query|Whether to combine all data into a single worksheet.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/MergeSpreadsheets) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
