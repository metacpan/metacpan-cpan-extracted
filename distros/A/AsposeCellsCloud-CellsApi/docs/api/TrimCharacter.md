# **Spreadsheet Cloud API: trimCharacter**

The TrimSpreadsheetContent API is designed to process and trim content within a spreadsheet. This API allows users to remove extra spaces, line breaks, or other unnecessary characters from the content of selected cells. It is particularly useful for cleaning up data entries and ensuring consistency in spreadsheet formatting 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/trim
```
### **Function Description**
Based on the functional description provided, the following is a summary of the data cleansing tool:## **Core Features Overview**The tool focuses on text formatting cleanup and provides a variety of whitespace and newline processing functions to ensure that spreadsheet data is clean, professional and easy to use.## ** Primary Cleaning Capacity**- **Trim the first and last spaces** - Remove extra spaces at the beginning and end of text - Improve data appearance neatness and readability- **Processing of extra spaces between words** - Eliminate extra spaces between words - Solve the format confusion caused by multi-source data- **Special spaces removed** - Specially clear non-breaking spaces - Ensure data accuracy and consistency- **Line break management** - Remove extra or all line breaks. - Keep cell content organized and professional looking## ** Functional Value**Through comprehensive space and line break cleaning, the tool can effectively improve data quality, eliminate data processing obstacles caused by format problems, and provide users with a reliable and clean spreadsheet environment.        

### The request parameters of **trimCharacter** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|trimContent|String|Query|Specify the trim content.|
|trimLeading|Boolean|Query|Specify to trim content from the beginning.|
|trimTrailing|Boolean|Query|Specify to trim content from the end.|
|trimSpaceBetweenWordTo1|Boolean|Query|Remove excess spaces between words within a cell.|
|trimNonBreakingSpaces|Boolean|Query|Remove non-breaking spaces.|
|removeExtraLineBreaks|Boolean|Query|Remove extra line breaks.|
|removeAllLineBreaks|Boolean|Query|Remove all line breaks.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/TrimCharacter) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
