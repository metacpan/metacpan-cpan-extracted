# **Spreadsheet Cloud API: postSplitText**

Efficiently divides Excel cell content into columns or rows based on specified delimiters or patterns. Supports Character-based splitting, Custom string splitting, Mask and wildcard splitting for pattern-based division, Line break division, Column or row splitting, Delimiter removal or retention. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/splittext
```
### **Function Description**
This API simplifies data extraction, making it easier to work with text and numbers in spreadsheets.- **First Characters**: Extract the first character or a specified number of characters from the left of each cell.- **Text Before/After/Between**: Extract text relative to specified characters or substrings.- **Any Position**: Retrieve text from any position within a string by indicating the start position and length.- **Last Characters**: Extract the last character or a specified number of characters from the end of cell values.- **Numbers Extraction**: Extract all numbers from alphanumeric strings for quantitative analysis.

### The request parameters of **postSplitText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|splitTextOptions|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostSplitText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
