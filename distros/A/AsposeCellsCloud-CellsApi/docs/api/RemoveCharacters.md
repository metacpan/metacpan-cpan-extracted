# **Spreadsheet Cloud API: removeCharacters**

Deletes user-defined characters, predefined symbol sets, or any substring from every cell in the chosen range while preserving formulas, formatting and data-validation. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/remove/characters
```
### **Function Description**
RemoveCustomText performs precise, position-based or pattern-based deletion inside the supplied range while preserving formulas, formatting and data-validation.            **Removal modes**  - `CustomChars` – delete each character supplied in `customCharacters` (case-insensitive by default)  - `CharacterSet` – pick a built-in set:    - `NonPrinting` – ASCII 0-31 + 127,129,141,143,144,157 (line-breaks, etc.)    - `Text` – all letters A-Z / a-z    - `Numeric` – all digits 0-9    - `Symbols` – math, geometric, technical, currency, letter-like symbols (?, ™, 1, …)    - `Punctuation` – any punctuation mark  - `Substring` – remove the entire substring specified in `substring` (case-sensitive option available)              **Options**  - `caseSensitive` – affects `Substring` mode and `CustomChars` when enabled  - Empty result is allowed; if every character is removed the cell becomes blank(empty string). - Numbers, booleans, errors are skipped; only string-type cell values are touched.- Returns the count of modified cells and the updated workbook stream.

### The request parameters of **removeCharacters** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|removeTextMethod|String|Query|Specify the removal of text method type.|
|characterSets|String|Query|Specify the character sets.|
|removeCustomValue|String|Query|Specify the remove custom value.|
|caseSensitive|Boolean|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/RemoveCharacters) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
