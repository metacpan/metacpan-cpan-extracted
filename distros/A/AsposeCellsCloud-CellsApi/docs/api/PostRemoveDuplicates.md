# **Spreadsheet Cloud API: postRemoveDuplicates**

Efficiently remove duplicate substrings from Excel cells. Select a range, specify delimiters, and apply options to eliminate repeated text segments. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/removeduplicates
```
### **Function Description**
- **Range Selection**: Define the range of cells to process for duplicate removal.- **Delimiters**: Specify delimiters to identify substrings within cells.- **Options**: Configure options to customize the removal process.- **Usage**:- Ideal for cleaning large datasets by removing redundant text.- Streamlines data preparation, ensuring cells contain unique substrings.

### The request parameters of **postRemoveDuplicates** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|removeDuplicatesOptions|Class|Body||

### **Response Description**
```json
{
  "Name": "FileInfo",
  "Description": [
    "Represents file information."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Filename",
      "Description": [
        "Represents filename. "
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "FileSize",
      "Description": [
        "Represents file size."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Long",
        "Name": "long"
      }
    },
    {
      "Name": "FileContent",
      "Description": [
        "Represents file content,  byte to base64 string."
      ],
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostRemoveDuplicates) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
