# **Spreadsheet Cloud API: addText**

Specify appending text to multiple cells at once, allowing you to add prefixes, suffixes, labels, or any specific characters. You can choose the exact position of the text—in the beginning, at the end, or before or after certain characters in the cell. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/add/text
```
### **Function Description**
Bulk-inserts the supplied string into every cell of the chosen range at the exact position you specify(prefix, suffix, before/after a given substring, or offset).  - **position** enum: None, AtTheBeginning, AtTheEnd, BeforeText, AfterText.  - **selectText**: when `BeforeText` or `AfterText` is used, this field supplies the anchor substring; if the anchor is not found the cell is left unchanged.- **skipEmptyCells**: `true` → only non-blank cells are processed; `false` → empty cells receive the new text directly.- **Numeric / boolean / formula cells** are converted to string before insertion; formulas are **dropped** to avoid corruption.- Returns the **count of touched cells** and the updated workbook stream.

### The request parameters of **addText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|text|String|Query|Specify the added text content.|
|position|String|Query|Indicates the specific location for adding text content.None, AtTheBeginning, AtTheEnd, BeforeText, AfterText.  |
|selectText|String|Query|Indicates selecting the specific position to add text based on the content of the text.|
|skipEmptyCells|Boolean|Query|Indicates skip empty cells.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/AddText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
