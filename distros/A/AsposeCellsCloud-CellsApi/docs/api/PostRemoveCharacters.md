# **Spreadsheet Cloud API: postRemoveCharacters**

A comprehensive set of tools for cleaning text content within selected cells. It allows users to remove specific characters, character sets, and substrings, ensuring that the text is standardized and free from unwanted symbols or sequences. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/removecharacters
```
### **Function Description**
- **Remove custom characters** will delete the characters you specify. To delete several symbols, enter each of them into the Remove custom characters field and the add-in will delete all their instances in the selected cells.- **Remove character sets**.There are several sets of symbols you can pick from the dropdown list:- **Non-printing characters**: delete all non-printing characters like line breaks, the first 32 non-printing characters in the 7-bit ASCII code(values 0 through 31), and additional non-printing characters(values 127, 129, 141, 143, 144, and 157).- **Text characters**: remove all letters from your cells.- **Numeric characters**: delete all digits from the range of interest.- **Symbols**: remove from the cells the following symbols: mathematical, geometric, technical and currency symbols, letter-like symbols such as ?, 1, and ™.- **Punctuation marks**: get rid of all punctuation marks in the selected range.- **Remove a substring**. Delete any combination of characters, for example a word, from the selected cells.

### The request parameters of **postRemoveCharacters** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|removeCharactersOptions|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostRemoveCharacters) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
