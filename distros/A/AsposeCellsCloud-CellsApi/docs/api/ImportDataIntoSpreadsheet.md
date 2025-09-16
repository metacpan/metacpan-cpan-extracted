# **Spreadsheet Cloud API: importDataIntoSpreadsheet**

Import data into a spreadsheet from a supported data file format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/import/data
```
### **Function Description**
This API allows you to import data into a spreadsheet from a supported data file format (CSV, JSON, XML). It takes two main inputs: the target spreadsheet and the data file containing the data to be imported. The data file must be in one of the supported formats (CSV, JSON, XML) and should be accessible to the API. The import process is handled efficiently, ensuring that the data is correctly parsed and inserted into the specified spreadsheet. If the data file is not accessible, the format is unsupported, or an error occurs during the import process, an appropriate exception will be thrown. Users should ensure that the data file is correctly formatted and that the spreadsheet is accessible to avoid errors.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Multiple Data Formats**: Supports importing data from CSV, JSON, and XML file formats.- **Direct Spreadsheet Integration**: Imports data directly into the specified spreadsheet.- **Efficient Data Handling**: Processes data efficiently, ensuring accurate parsing and insertion.

### The request parameters of **importDataIntoSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|datafile|File|FormData|Upload data file.|
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|Specify the worksheet for importing data|
|startcell|String|Query|Specify the starting position for importing data|
|insert|Boolean|Query|The specified import data is for insertion and overwrite.|
|convertNumericData|Boolean|Query|Specify whether to convert numerical data|
|splitter|String|Query|Specify the delimiter for the CSV format.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/ImportDataIntoSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
