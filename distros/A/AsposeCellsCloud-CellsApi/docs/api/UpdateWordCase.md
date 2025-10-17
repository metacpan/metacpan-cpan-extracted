# **Spreadsheet Cloud API: updateWordCase**

Specify changing the text case in a spreadsheet to switch between uppercase, lowercase, capitalizing the first letter of each word, or capitalizing the first letter of a sentence, and adjust the text according to specific needs. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/wordcase
```
### **Function Description**
ChangeTextCase converts the text values inside the specified range to the requested case (upper / lower / proper / sentence) while leaving formulas, formatting and data-validation intact.- Only string-type cells are processed; numbers, booleans, errors and blanks are skipped.- Returns the number of cells updated and the modified workbook stream.- UpperCase: Converts all characters to uppercase.- LowerCase: Converts all characters to lowercase.- ProperCase: Converts the first letter of each word to uppercase and the rest to lowercase.- SentenceCase: Converts the first letter of each sentence to uppercase and the rest to lowercase.

### The request parameters of **updateWordCase** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|wordCaseType|String|Query|Specify text case: Upper Case, Lower Case, Proper Case, Sentence Case.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/UpdateWordCase) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
