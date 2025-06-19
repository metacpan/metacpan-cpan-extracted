# **Spreadsheet Cloud API: searchBrokenLinksInRemoteSpreadsheet**

Search broken links in the remoted spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/search/broken-links
```
### **Function Description**
This method searches for broken links within a spreadsheet file stored in remote cloud storage.It scans all sheets and cells to identify hyperlinks that no longer point to valid destinations, such as dead URLs or missing external references.The operation is performed remotely within the cloud environment, without requiring the file to be downloaded to the local machine.Ensure that you have valid cloud storage credentials and proper access permissions to the target file.If the source file cannot be accessed, if it contains unsupported formats, or if an error occurs during the scanning process, an appropriate exception will be thrown.Depending on the implementation, the method may return a list of broken links with details such as sheet name, cell coordinates, and the invalid URL.Users should carefully review the results to update or remove outdated links in the spreadsheet.

### The request parameters of **searchBrokenLinksInRemoteSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The name of the workbook file to be search.|
|worksheet|String|Query|Specify the worksheet for the lookup.|
|cellArea|String|Query|Specify the cell area for the lookup|
|folder|String|Query|The folder path where the workbook is stored.|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/SearchBrokenLinksInRemoteSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
