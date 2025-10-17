# **Spreadsheet Cloud API: convertText**

Indicates converting the numbers stored as text into the correct number format, replacing unwanted characters and line breaks with the desired characters, and converting accented characters to their equivalent characters without accents. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/convert/text
```
### **Function Description**
- **Convert numbers stored as text to numbers**Transform numeric data stored as text to numbers, ensuring accurate calculations and proper data representation.- **Replace specific characters**Replace all occurrences of specified characters in all the selected cells at once to standardize your information.- **Convert line breaks to space, comma or semicolon**Improve the readability of your sheets by converting line breaks to space, comma, or semicolon, creating a more organized and visually appealing presentation.- **Replace accented characters**If your data is in different languages, you have the option to swap accented characters like "é" or "ü" with their non-accented counterparts. This enhances consistency and clarity in your text.

### The request parameters of **convertText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|convertTextType|String|Query|Indicates the conversion of text type.|
|sourceCharacters|String|Query|Indicates the source characters.|
|targetCharacters|String|Query|Indicates the target characters.|
|worksheet|String|Query|Specify the worksheet of spreadsheet.|
|range|String|Query|Specify the worksheet range of spreadsheet.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|region|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/ConvertText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
