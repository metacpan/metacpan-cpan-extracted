# **Spreadsheet Cloud API: removeCharacters**

Perform operations or delete any custom characters, character sets, and substrings within a selected range for a specific position. 


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
RemoveCustomText performs precise, position-based or pattern-based deletion inside the supplied range while preserving formulas, formatting and data-validation.- Head / tail truncation: theFirstNCharacters and theLastNCharacters are mutually exclusive with text-boundary modes.- Boundary modes: allCharactersBeforeText and allCharactersAfterText delete everything up-to or after the supplied substring (first occurrence).- Character-sets: provide any Unicode run (e.g. "(){}-") or regex class; matching code-points are stripped, order is ignored.- Empty result is allowed; if every character is removed the cell becomes blank(empty string). - Numbers, booleans, errors are skipped; only string-type cell values are touched.- Returns the count of modified cells and the updated workbook stream.

### The request parameters of **removeCharacters** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|theFirstNCharacters|Integer|Query|Specify removing the first n characters from selected cells.|
|theLastNCharacters|Integer|Query|Specify removing the last n characters from selected cells.|
|allCharactersBeforeText|String|Query|Specify using targeted removal options to delete text that is located before certain characters.|
|allCharactersAfterText|String|Query|Specify using targeted removal options to delete text that is located after certain characters.|
|removeTextMethod|String|Query|Specify the removal of text method type.|
|characterSets|String|Query|Specify the character sets.|
|removeCustomValue|String|Query|Specify the remove custom value.|
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
