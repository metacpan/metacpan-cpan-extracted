# **Spreadsheet Cloud API: importXMLDataIntoSpreadsheet**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/import/data/xml
```
### **Function Description**

### The request parameters of **importXMLDataIntoSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|datafile|File|FormData|Upload data file.|
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query||
|startcell|String|Query||
|insert|Boolean|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/ImportXMLDataIntoSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
