# **Spreadsheet Cloud API: postImportData**

Import data into the Excel file. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/importdata
```
### **Function Description**
PageTitle: Import data into the Excel file.PageDescription: Aspose.Cells Cloud provides robust support for importing data into the Excel file, a process known for its intricacy. Aspose.Cells Cloud support the import of data in a variety of formats.HeadTitle: Import data into the Excel file.HeadSummary: Aspose.Cells Cloud provides robust support for importing data into the Excel file, a process known for its intricacy. Aspose.Cells Cloud support the import of data in a variety of formats.HeadContent: Aspose.Cells Cloud provides  REST API which supports importing data into the Excel file and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postImportData** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|importOption|Class|Body|Import option. They are include of ImportCSVDataOption, ImportBatchDataOption, ImportPictureOption, ImportStringArrayOption, Import2DimensionStringArrayOption, and so on.  |
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|
|region|String|Query|The regional settings for workbook.|
|FontsLocation|String|Query|Use Custom fonts.|

### **Response Description**
```json
{
  "Name": "CellsCloudResponse",
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/DataProcessingController/PostImportData) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
