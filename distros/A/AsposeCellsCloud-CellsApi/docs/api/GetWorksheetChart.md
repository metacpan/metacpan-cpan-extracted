# **Spreadsheet Cloud API: getWorksheetChart**

Retrieve the chart in a specified format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/charts/{chartNumber}
```
### **Function Description**
PageTitle: Retrieve the chart in a specified format.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the chart in a specified format, a process known for its intricacy.HeadTitle: Retrieve the chart in a specified format.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the chart in a specified format, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the chart in a specified format and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetChart** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|chartNumber|Integer|Path|The chart number.|
|format|String|Query|Chart conversion format.(PNG/TIFF/JPEG/GIF/EMF/BMP)|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ChartsController/GetWorksheetChart) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
