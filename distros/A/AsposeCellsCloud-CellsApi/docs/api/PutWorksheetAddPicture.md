# **Spreadsheet Cloud API: putWorksheetAddPicture**

Add a new picture in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/pictures
```
### **Function Description**
PageTitle: Add a new picture in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a picture in the worksheet, a process known for its intricacy.HeadTitle: Add a new picture in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a picture in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a picture in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetAddPicture** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worsheet name.|
|picture|Class|Body|Pictute object|
|upperLeftRow|Integer|Query|The image upper left row.|
|upperLeftColumn|Integer|Query|The image upper left column.|
|lowerRightRow|Integer|Query|The image low right row.|
|lowerRightColumn|Integer|Query|The image low right column.|
|picturePath|String|Query|The picture path, if not provided the picture data is inspected in the request body.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/PicturesController/PutWorksheetAddPicture) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
