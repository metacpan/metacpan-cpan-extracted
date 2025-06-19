# **Spreadsheet Cloud API: splitRemoteSpreadsheet**

Split a spreadsheet in cloud storage into the specified format, multi-file. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/split/spreadsheet
```
### **Function Description**
This method splits a single spreadsheet file stored in cloud storage into multiple output files in the specified format (e.g., XLSX, CSV, PDF).Each split file may represent different sheets, sections, or segments of the original document based on user-defined criteria.The operation is performed remotely within the cloud environment, eliminating the need to download the files to the local machine.Ensure that you have valid cloud storage credentials and accessible file paths or identifiers for all input files.If the source file cannot be accessed, permissions are insufficient, or if an error occurs during the splitting process, an appropriate exception will be thrown.Supported formats for output depend on the capabilities of the underlying cloud processing service. Users should specify clear criteria for how the input file should be divided to ensure accurate results.

### The request parameters of **splitRemoteSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The name of the workbook file to be split.|
|folder|String|Query|The folder path where the workbook is stored.|
|from|Integer|Query|Begin worksheet index.|
|to|Integer|Query|End worksheet index.|
|outFormat|String|Query|The desired output format (e.g., "Xlsx", "Pdf", "Csv").|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/SplitRemoteSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
