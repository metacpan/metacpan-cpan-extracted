# **Spreadsheet Cloud API: exportTableAsFormat**

Converts a table of spreadsheet in cloud storage to the specified format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/{name}/worksheets/{worksheet}/tables/{tableName}
```
### **Function Description**
This method processes a table of spreadsheet directly in cloud storage, converting it to the requested output format (PDF, or Image format) without requiring the file to be downloaded to the local machine. The operation relies on valid cloud storage credentials and an accessible file path or identifier. The conversion is performed remotely, reducing data transfer and improving performance for large files. If the source file is not found, access is denied, or an error occurs during conversion, an appropriate exception will be thrown. Supported output formats are determined by the capabilities of the underlying cloud conversion service.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining conversion data.## **Key Features and Benefits**- **Cloud-Native Conversion**: Processes spreadsheets directly in cloud storage, eliminating the need to download files to local machines.- **Format Versatility**: Supports common output formats (XLSX, PDF, CSV) to meet diverse use cases (e.g., editing, sharing, data import).- **Simplified Workflow**: Directly converts cloud-stored spreadsheets to needed formats without intermediate steps.

### The request parameters of **exportTableAsFormat** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|(Required) The name of the workbook file to be retrieved.|
|worksheet|String|Path|worksheet name|
|tableName|String|Path|table name|
|format|String|Query|(Required) The desired format  (e.g., "png", "Pdf", "svg").|
|folder|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/ExportTableAsFormat) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
