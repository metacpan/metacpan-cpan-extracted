# **Spreadsheet Cloud API: postExtractText**

Effortlessly extract text and numbers from Excel cells with precise options. This API allows extraction of first/last characters, text between delimiters, and numbers from strings, with output as static values or formulas. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/extracttext
```
### **Function Description**
Extract substrings, characters, and digits from Excel cells with options for precise text extraction. This API simplifies complex formula tasks by enabling first character extraction, text retrieval before/after/between specified characters, substring extraction from any position, last character extraction, and number extraction from alphanumeric strings. Choose output as static values or dynamic formulas.- **First Characters**: Extract the first character or a specified number of characters from the left of each cell.- **Text Before/After/Between**: Extract text relative to specified characters or substrings.- **Any Position**: Retrieve text from any position within a string by indicating the start position and length.- **Last Characters**: Extract the last character or a specified number of characters from the end of cell values.- **Numbers Extraction**: Extract all numbers from alphanumeric strings for quantitative analysis.

### The request parameters of **postExtractText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|extractTextOptions|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostExtractText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
