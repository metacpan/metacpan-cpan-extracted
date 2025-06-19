# **Spreadsheet Cloud API: exportChartAsFormat**

Converts a chart of spreadsheet in cloud storage to the specified format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v4.0/cells/{name}/worksheets/{worksheet}/charts/{chartIndex}
```
### **Function Description**
This method processes a chart of spreadsheet directly in cloud storage, converting it to the requested output format (PDF, or Image format) without requiring the file to be downloaded to the local machine.The operation relies on valid cloud storage credentials and an accessible file path or identifier.The conversion is performed remotely, reducing data transfer and improving performance for large files.If the source file is not found, access is denied, or an error occurs during conversion, an appropriate exception will be thrown.Supported output formats are determined by the capabilities of the underlying cloud conversion service.

### The request parameters of **exportChartAsFormat** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|(Required) The name of the workbook file to be retrieved.|
|worksheet|String|Path||
|chartIndex|Integer|Path||
|format|String|Query|(Required) The desired pdf or image format  (e.g., "png", "Pdf", "svg").|
|folder|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/ExportChartAsFormat) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
