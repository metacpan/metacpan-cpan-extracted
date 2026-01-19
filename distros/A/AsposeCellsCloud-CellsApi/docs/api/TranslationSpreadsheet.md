# **Spreadsheet Cloud API: translationSpreadsheet**

Translates the entire spreadsheet to the specified target language. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/ai/translate/spreadsheet
```
### **Function Description**
This method reads all text content from the spreadsheet workbook, translates it to the target language using AI translation services,and returns the translated spreadsheet file. The translation process preserves the original spreadsheet structure and formatting.## **Error Handling**- **400 Bad Request**: Invalid target language parameter.- **401 Unauthorized**: Authentication failed for translation service.- **500 Server Error**: Translation service unavailable or spreadsheet processing error.## **Key Features and Benefits**- **AI-Powered Translation**: Uses advanced AI for accurate translations.- **Structure Preservation**: Maintains original spreadsheet layout and formulas.- **Multi-Sheet Support**: Translates content across all worksheets automatically.

### The request parameters of **translationSpreadsheet** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|targetLanguage|String|Query|The target language code for translation (e.g., "es", "fr", "de").|
|region|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

### **Response Description**
```json
{
File
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AIController/TranslationSpreadsheet) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
