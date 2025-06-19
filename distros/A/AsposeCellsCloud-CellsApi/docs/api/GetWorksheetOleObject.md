# **Spreadsheet Cloud API: getWorksheetOleObject**

Retrieve the OLE object in a specified format in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/oleobjects/{objectNumber}
```
### **Function Description**
PageTitle: Retrieve the OLE object in a specified format in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining the OLE object in a specified format in the worksheet, a process known for its intricacy.HeadTitle: Retrieve the OLE object in a specified format in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining the OLE object in a specified format in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining the OLE object in a specified format in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getWorksheetOleObject** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|objectNumber|Integer|Path|The object number.|
|format|String|Query|Object conversion format(PNG/TIFF/JPEG/GIF/EMF/BMP).|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/OleObjectsController/GetWorksheetOleObject) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
