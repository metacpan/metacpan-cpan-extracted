# **Spreadsheet Cloud API: postUpdateWordCase**

Managing inconsistent text case in spreadsheets (Excel, Google Sheets, CSV) can be frustrating, especially with large datasets. The PostUpdateWordCase WEB API solves this by automating text case conversions, ensuring clean and standardized data. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/updatewordcase
```
### **Function Description**
This method applies case conversion to text based on the specified formatting rule (e.g., uppercase, lowercase, title case, or sentence case). It ensures consistent text formatting for use cases such as:- Standardizing product SKUs, invoice IDs, or codes(e.g. "inv_123" -&gt; "INV_123").- Preparing user input(e.g., emails, names) for database storage or CRM imports.- Formatting document titles, report headers, or display text.Note:- For sentence case, ensure proper sentence boundary detection (e.g., punctuation handling).- For title case, consider locale-specific rules (e.g., handling minor words like "and," "the").- Trimming whitespace before processing is recommended for clean output.

### The request parameters of **postUpdateWordCase** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|wordCaseOptions|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostUpdateWordCase) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
