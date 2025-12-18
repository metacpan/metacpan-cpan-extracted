# **Spreadsheet Cloud API: removeDuplicateSubstrings**

Finds and removes repeated substrings inside every cell of the chosen range, using user-defined or preset delimiters, while preserving formulas, formatting and data-validation. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/remove/duplicate-substrings
```
### **Function Description**
**How duplicates are detected**  1. Each cell value is split into substrings by the chosen delimiter(s).  2. The tool compares substrings **within the same cell** and keeps only the **first occurrence** of each duplicate.  3. Cleaned substrings are re-joined with the same delimiter(s) and written back to the cell.            **Delimiter options**  - Preset list: comma, semicolon, space, tab, line-break  - `Custom` – enter any character(s); multiple characters are treated as one composite delimiter  - `TreatConsecutiveDelimitersAsOne` – collapse adjacent delimiters into a single separator              Only string-type cells are processed; numbers, booleans and formulas are converted to string before splitting (formulas are dropped).  Returns the count of cleaned cells and the updated workbook stream.  

### The request parameters of **removeDuplicateSubstrings** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|delimiters|String|Query|comma, semicolon, space, tab, line-break |
|treatConsecutiveDelimitersAsOne|Boolean|Query|collapse adjacent delimiters into a single separator.|
|caseSensitive|Boolean|Query||
|worksheet|String|Query||
|range|String|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/RemoveDuplicateSubstrings) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
