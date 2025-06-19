# **Spreadsheet Cloud API: postWorkbookImportXML**

Import an XML data file into an Excel file. The XML data file can either be a cloud file or data from an HTTP URI. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/importxml
```
### **Function Description**
PageTitle: Import XML data into an Excel file.PageDescription: Aspose.Cells Cloud provides robust support for importing XML data into an Excel file, a process known for its intricacy.HeadTitle: Import Json data into an Excel file.HeadSummary: Aspose.Cells Cloud provides robust support for importing XML data into an Excel file, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports importing XML data into an Excel file and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookImportXML** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|importXMLRequest|Class|Body|Import XML request.|
|password|String|Query|The password needed to open an Excel file.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|outPath|String|Query|Path to save the result. If it's a single file, the `outPath` should encompass both the filename and extension. In the case of multiple files, the `outPath` should only include the folder.|
|outStorageName|String|Query|The storage name where the output file is situated.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/PostWorkbookImportXML) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
