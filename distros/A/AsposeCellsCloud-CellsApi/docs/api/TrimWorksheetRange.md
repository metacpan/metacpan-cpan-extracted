# **Spreadsheet Cloud API: trimWorksheetRange**

 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/trim/worksheet
```
### **Function Description**

### The request parameters of **trimWorksheetRange** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query||
|range|String|Query||
|trimContent|String|Query||
|trimLeading|Boolean|Query||
|trimTrailing|Boolean|Query||
|trimSpaceBetweenWordTo1|Boolean|Query||
|trimNonBreakingSpaces|Boolean|Query||
|removeExtraLineBreaks|Boolean|Query||
|removeAllLineBreaks|Boolean|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/TrimWorksheetRange) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
