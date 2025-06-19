# **Spreadsheet Cloud API: replaceContentInRemoteRange**

Replace text in the range of remoted spreadsheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/worksheets/{worksheet}/ranges/{cellarea}/replace/content
```
### **Function Description**
This method replaces specified text within a range of spreadsheet file stored in remote cloud storage.It supports replacing occurrences of the target text across all sheets and cells of the workbook directly within the cloud environment.The operation is performed remotely, eliminating the need to download the file to the local machine.Ensure that you have valid cloud storage credentials and accessible file paths or identifiers for the target spreadsheet.If the source file cannot be accessed, permissions are insufficient, writing to the file fails, or an error occurs during the replacement process (such as an unsupported file format), an appropriate exception will be thrown.Depending on the implementation, the method may return the number of replacements made or the locations of the replaced texts (e.g., sheet name, cell coordinates).Users should specify the exact text to replace and its replacement to ensure accurate modifications.

### The request parameters of **replaceContentInRemoteRange** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The name of the workbook file to be replace.|
|searchText|String|Query|The searched text.|
|replaceText|String|Query|The replaced text.|
|worksheet|String|Path|The worksheet name.|
|cellArea|String|Path|The cell area for the replace.|
|folder|String|Query|The folder path where the workbook is stored.|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/SearchControllor/ReplaceContentInRemoteRange) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
