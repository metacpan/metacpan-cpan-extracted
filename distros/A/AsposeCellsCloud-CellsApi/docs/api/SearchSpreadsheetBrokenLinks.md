# **Spreadsheet Cloud API: searchSpreadsheetBrokenLinks**

Search broken links in the local spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/search/broken-links
```
### **Function Description**
This method searches for broken links within a local spreadsheet file.It scans through all sheets and cells to identify any hyperlinks that no longer point to valid destinations, such as dead URLs or missing references.The operation is performed cloudly, requiring no cloud storage.Ensure you have the necessary permissions to read the source file.If the source file cannot be accessed, contains unsupported formats, or if an error occurs during the search process, an appropriate exception will be thrown.Depending on the implementation, the method may return a list of broken links with details such as sheet name, cell coordinates, and the problematic URL.Users should review the results carefully to update or remove invalid links.

### The request parameters of **searchSpreadsheetBrokenLinks** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet|String|Query|Specify the worksheet for the replace.|
|cellArea|String|Query|Specify the cell area for the replace.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
  "Name": "BrokenLinksReponse",
  "Type": "Class",
  "ParentName": "CellsCloudResponse",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "BrokenLinks",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "BrokenLink",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "BrokenLink",
          "Name": "class:brokenlink"
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/SearchSpreadsheetBrokenLinks) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
