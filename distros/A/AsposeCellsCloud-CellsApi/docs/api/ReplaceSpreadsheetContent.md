# **Spreadsheet Cloud API: replaceSpreadsheetContent**

Replace text in the local spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/replace/content
```
### **Function Description**
This method replaces specified text within a local spreadsheet file. It supports replacing occurrences of the target text across all sheets and cells of the workbook. The operation is performed cloudly, requiring no cloud storage. Ensure that you have the necessary permissions to read from and write to the source file. If the source file cannot be accessed, if writing to the file fails, or if an error occurs during the replacement process (such as an unsupported file format), an appropriate exception will be thrown. Depending on the implementation, the method may return the number of replacements made or the locations of the replaced texts (e.g., sheet name, cell coordinates). Users should specify the exact text to replace and its replacement to ensure accurate modifications.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Local Spreadsheet Text Replacement**: Replaces specified text within a local spreadsheet file.- **Comprehensive Replacement**: Supports replacing occurrences of the target text across all sheets and cells of the workbook.- **Cloud-Based Processing**: Performs the replacement operation in the cloud, without requiring cloud storage.

### The request parameters of **replaceSpreadsheetContent** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|searchText|String|Query|Specify the search content.|
|replaceText|String|Query|Specify the replace content.|
|worksheet|String|Query|Specify the worksheet for the replace.|
|cellArea|String|Query|Specify the cell area for the replace.|
|region|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchController/ReplaceSpreadsheetContent) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
