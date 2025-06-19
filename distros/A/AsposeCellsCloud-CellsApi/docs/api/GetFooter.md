# **Spreadsheet Cloud API: getFooter**

Retrieve page footer description in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
GET http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pagesetup/footer
```
### **Function Description**
PageTitle: Retrieve page footer description in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for obtaining page footer description in the worksheet in the worksheet, a process known for its intricacy.HeadTitle: Retrieve page footer description in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for obtaining page footer description in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports obtaining page footer description in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **getFooter** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "PageSectionsResponse",
  "Description": [
    "Represents the PageSections Response."
  ],
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "PageSections",
      "Description": [
        "A property named PageSections of type List PageSection  to store a collection of PageSection objects."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "PageSection",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "PageSection",
          "Name": "class:pagesection"
        },
        "Name": "container"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PageSetupController/GetFooter) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
