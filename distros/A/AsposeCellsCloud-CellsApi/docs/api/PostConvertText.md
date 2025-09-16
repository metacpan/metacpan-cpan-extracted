# **Spreadsheet Cloud API: postConvertText**

Enhance Excel data through essential text conversions: convert text to numbers, replace characters and line breaks, and remove accents. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/converttext
```
### **Function Description**
Effortlessly enhance your Excel data by performing essential text conversions. Convert numbers stored as text to the correct numerical format. Replace unwanted characters and line breaks with desired ones. Transform accented characters into their non-accented equivalents.- **Number Conversion**: Automatically converts text representations of numbers into their numerical equivalents, ensuring data consistency and accuracy.- **Character Replacement**: Provides flexibility in replacing specific characters or line breaks, allowing for customized text manipulation.- **Accent Removal**: Converts accented characters to their non-accented counterparts, simplifying text processing and ensuring compatibility with various systems.- **Usage**: This API is particularly useful for data cleaning and preparation tasks, ensuring that your Excel data is standardized and ready for further analysis or processing.It can be integrated into automated workflows to streamline data handling and reduce manual intervention.

### The request parameters of **postConvertText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|convertTextOptions|Class|Body||

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/PostConvertText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
