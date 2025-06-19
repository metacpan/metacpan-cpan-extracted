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
This method replaces specified text within a local spreadsheet file. It supports replacing occurrences of the target text across all sheets and cells of the workbook.The operation is performed cloudly, requiring no cloud storage.Ensure that you have the necessary permissions to read from and write to the source file.If the source file cannot be accessed, if writing to the file fails, or if an error occurs during the replacement process (such as an unsupported file format), an appropriate exception will be thrown.Depending on the implementation, the method may return the number of replacements made or the locations of the replaced texts (e.g., sheet name, cell coordinates).Users should specify the exact text to replace and its replacement to ensure accurate modifications.

### The request parameters of **replaceSpreadsheetContent** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|searchText|String|Query|The searched text.|
|replaceText|String|Query|The replaced text.|
|worksheet|String|Query|Specify the worksheet for the replace.|
|cellArea|String|Query|Specify the cell area for the replace.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/ReplaceSpreadsheetContent) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
