# **Spreadsheet Cloud API: searchContentInRemoteRange**

Search text in the range of remoted spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/worksheets/{worksheet}/ranges/{cellArea}/search/content
```
### **Function Description**
This method searches for specified text within a range of spreadsheet file stored in remote cloud storage.It supports searching through all sheets and cells of the workbook, identifying occurrences of the search term directly within the cloud environment.The operation is performed remotely, eliminating the need to download the file to the local machine.Ensure that you have valid cloud storage credentials and accessible file paths or identifiers for the target spreadsheet.If the source file cannot be accessed, permissions are insufficient, or if an error occurs during the search process (such as an unsupported file format), an appropriate exception will be thrown.Depending on the implementation, the method may return the locations of the matches (e.g., sheet name, cell coordinates).Users should specify the exact search criteria, including case sensitivity and whole word matching options, to refine search results.

### The request parameters of **searchContentInRemoteRange** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path||
|worksheet|String|Path||
|cellArea|String|Path||
|searchText|String|Query||
|ignoringCase|Boolean|Query||
|folder|String|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/SearchContentInRemoteRange) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
