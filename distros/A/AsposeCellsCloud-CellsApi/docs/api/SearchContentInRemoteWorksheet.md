# **Spreadsheet Cloud API: searchContentInRemoteWorksheet**

Search text in the worksheet of remoted spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/worksheets/{worksheet}/search/content
```
### **Function Description**
This method searches for specified text within a worksheet of spreadsheet file stored in remote cloud storage.It supports searching through all sheets and cells of the workbook, identifying occurrences of the search term directly within the cloud environment.The operation is performed remotely, eliminating the need to download the file to the local machine.Ensure that you have valid cloud storage credentials and accessible file paths or identifiers for the target spreadsheet.If the source file cannot be accessed, permissions are insufficient, or if an error occurs during the search process (such as an unsupported file format), an appropriate exception will be thrown.Depending on the implementation, the method may return the locations of the matches (e.g., sheet name, cell coordinates).Users should specify the exact search criteria, including case sensitivity and whole word matching options, to refine search results.

### The request parameters of **searchContentInRemoteWorksheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The name of the workbook file to be search.|
|worksheet|String|Path|The name of worksheet|
|searchText|String|Query|The searched text.|
|ignoringCase|Boolean|Query|Ignore the text of the search.|
|folder|String|Query|The folder path where the workbook is stored.|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
  "Name": "SearchResponse",
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "TextItems",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "TextItem",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "TextItem",
          "Name": "class:textitem"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/SearchContentInRemoteWorksheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
