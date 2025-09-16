# **Spreadsheet Cloud API: postAddTextContent**

Adds text content to a specified location within a document. It requires an object that defines the text to be added and the insertion location. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/addtext
```
### **Function Description**
This method safely appends new text to specified content, supporting multiple insertion modes and format handling.Supports multiple insertion modes:- Add text to the beginning of selected cells:   Prepend text to all selected cells, ensuring consistency in your data entry.This option is perfect for adding common identifiers or labels to a column of data, such as product codes, categories, or prefixes.- Insert characters before or after specific text: Tailor your data presentation by placing characters before or after specified text in the selected cells. This allows you to create structured and organized content with ease.- Append same text to the end of every selected cell: Add the same text to the end of multiple cells in one go. This simplifies data entry and ensures a uniform appearance throughout your document.- Insert text before or after a specified number of characters: Precision meets convenience as you add certain text after a specified number of characters from the beginning or from the end of every cell in the target range.Typical use cases include:

### The request parameters of **postAddTextContent** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|addTextOptions|Class|Body|that specifies the text content and the position where the text should be added.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostAddTextContent) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
