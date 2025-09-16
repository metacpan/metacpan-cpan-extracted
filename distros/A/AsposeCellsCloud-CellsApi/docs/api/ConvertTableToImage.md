# **Spreadsheet Cloud API: convertTableToImage**

Converts a table of spreadsheet on a local drive to the image file. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/convert/table/image
```
### **Function Description**
This method reads a spreadsheet file from the local file system, converts it's table to the desired image file, and returns the converted result. The source file path and target format must be specified correctly. Ensure that the necessary permissions are in place to read the source file and write the converted file if applicable. The conversion process occurs entirely on the cloud server, eliminating the need for any cloud storage or external downloads. If the source file does not exist, is inaccessible, or if an error occurs during the conversion process, an appropriate exception will be thrown. Supported formats for conversion depend on the available libraries and their capabilities.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining conversion data.## **Key Features and Benefits**- **Cloud-Native Conversion**: Conversion of local files directly in the cloud, eliminating the need to store them there.- **Reduced Cloud Resource Burden**: No need to upload files to the cloud, saving cloud storage space.- **Format Versatility**: Supports common output image formats (png, svg, tiff and so on).- **Simplified Workflow**: Convert local spreadsheets to the desired format directly through cloud services, without intermediate steps.

### The request parameters of **convertTableToImage** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|worksheet name of spreadsheet.|
|tableName|String|Query|table name|
|format|String|Query|file format.  |
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/ConvertTableToImage) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
