# **Spreadsheet Cloud API: compressSpreadsheet**

The Web API endpoint allows users to compress a spreadsheet to reduce its file size. This function provides a straightforward way to optimize the storage and performance of spreadsheets by applying a specified compression level. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/spreadsheet/compress
```
### **Function Description**
By using the CompressSpreadsheet API, you can dynamically manage the storage and performance of your spreadsheets, applying specified compression levels to reduce file sizes and optimize storage usage. This feature enhances your ability to manage and optimize your spreadsheets efficiently, ensuring minimal storage usage and enhanced performance.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Dynamic Compression**: Allows users to compress a spreadsheet to reduce its file size.- **Specified Compression Levels**: Provides the ability to apply different levels of compression based on user requirements.

### The request parameters of **compressSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|level|Integer|Query|Specifies the compression level to be applied to the spreadsheet. The level should be within a valid range (e.g., 0-9 for most compression algorithms, where 0 is no compression and 9 is maximum compression).|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ManagementController/CompressSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
