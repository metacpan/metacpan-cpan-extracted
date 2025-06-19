# **Spreadsheet Cloud API: postHeader**

Update page header in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pagesetup/header
```
### **Function Description**
PageTitle: Update page header in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for updating page header in the worksheet in the worksheet, a process known for its intricacy.HeadTitle: Update page header in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for updating page header in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports updating page header in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **postHeader** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|section|Integer|Query|0:Left Section. 1:Center Section 2:Right Section|
|script|String|Query|Header format script.|
|isFirstPage|Boolean|Query|Is first page(true/false).|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageSetupController/PostHeader) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
