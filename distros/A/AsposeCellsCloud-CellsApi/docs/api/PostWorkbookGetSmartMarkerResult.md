# **Spreadsheet Cloud API: postWorkbookGetSmartMarkerResult**

Smart marker processing. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/smartmarker
```
### **Function Description**
PageTitle:  Smart marker processing.PageDescription: Aspose.Cells Cloud provides robust support for smart marker processing in the workbook, a process known for its intricacy.HeadTitle:   Smart marker processing.HeadSummary: Aspose.Cells Cloud provides robust support for smart marker processing in the workbook, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports smart marker processing in the workbook and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookGetSmartMarkerResult** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|xmlFile|String|Query|The xml file full path, if empty the data is read from request body.|
|folder|String|Query|The folder where the file is situated.|
|outPath|String|Query|The path to save result|
|storageName|String|Query|The storage name where the file is situated.|
|outStorageName|String|Query|The storage name where the result file is situated.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/WorkbookController/PostWorkbookGetSmartMarkerResult) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
