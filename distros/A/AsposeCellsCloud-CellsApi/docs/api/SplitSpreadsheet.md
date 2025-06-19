# **Spreadsheet Cloud API: splitSpreadsheet**

Split a local spreadsheet into the specified format, multi-file. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/split/spreadsheet
```
### **Function Description**
This method splits a single local spreadsheet file into multiple output files in the specified format (e.g., XLSX, CSV, PDF).Each split file may represent different sheets, sections, or segments of the original document based on user-defined criteria.The operation is performed cloudly, requiring no cloud storage.Ensure that you have the necessary permissions to read the source file and write the resulting files.If the source file cannot be accessed or if an error occurs during the splitting process, an appropriate exception will be thrown.Supported formats for output depend on the available libraries and their capabilities.Users should specify clear criteria for how the input file should be divided to ensure accurate results.

### The request parameters of **splitSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|from|Integer|Query|Begin worksheet index.|
|to|Integer|Query|End worksheet index.|
|outFormat|String|Query|The out file format.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|fontsLocation|String|Query|Use Custom fonts.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/SplitSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
