# **Spreadsheet Cloud API: postWorkbookSaveAs**

Save an Excel file in various formats. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/SaveAs
```
### **Function Description**
PageTitle: Save an Excel file in various formats.PageDescription: Aspose.Cells Cloud provides robust support for saving Excel files in various formats, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadTitle:  Save Excel files in various formats.HeadSummary: Aspose.Cells Cloud provides robust support for saving an Excel file in various formats, a process known for its intricacy. Aspose.Cells Cloud supports 30+ file formats, including Excel, Pdf, Markdown, Json, XML, Csv, Html, and so on.HeadContent: Aspose.Cells Cloud provides REST API which supports saving an Excel file in various formats and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postWorkbookSaveAs** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|newfilename|String|Query|newfilename to save the result.The `newfilename` should encompass both the filename and extension.|
|saveOptions|Class|Body||
|isAutoFitRows|Boolean|Query|Indicates if Autofit rows in workbook.|
|isAutoFitColumns|Boolean|Query|Indicates if Autofit columns in workbook.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|outStorageName|String|Query|The storage name where the output file is situated.|
|checkExcelRestriction|Boolean|Query|Whether check restriction of excel file when user modify cells related objects.|
|region|String|Query|The regional settings for workbook.|
|pageWideFitOnPerSheet|Boolean|Query|The page wide fit on worksheet.|
|pageTallFitOnPerSheet|Boolean|Query|The page tall fit on worksheet.|
|onePagePerSheet|Boolean|Query||
|FontsLocation|String|Query|Use Custom fonts.|

### **Response Description**
```json
{
  "Name": "SaveResponse",
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "SaveResult",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "SaveResult",
        "Name": "class:saveresult"
      }
    },
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": true,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/PostWorkbookSaveAs) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
