# **Spreadsheet Cloud API: searchSpreadsheetContent**

Search text in the local spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/search/content
```
### **Function Description**
This method searches for specified text within a local spreadsheet file.It supports searching through all sheets and cells of the workbook, identifying occurrences of the search term.The operation is performed cloudly, requiring no cloud storage. Ensure that you have the necessary permissions to read the source file.If the source file cannot be accessed or if an error occurs during the search process (such as an unsupported file format), an appropriate exception will be thrown.The method may return the locations of the matches (e.g., sheet name, cell coordinates) depending on implementation details.Users should specify the exact search criteria, including case sensitivity and whole word matching options, to refine search results.

### The request parameters of **searchSpreadsheetContent** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|searchText|String|Query|The searched text.|
|ignoringCase|Boolean|Query|Ignore the text of the search.|
|worksheet|String|Query|Specify the worksheet for the lookup.|
|cellArea|String|Query|Specify the cell area for the lookup|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/SearchSpreadsheetContent) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
