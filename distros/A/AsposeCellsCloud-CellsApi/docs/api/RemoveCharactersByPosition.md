# **Spreadsheet Cloud API: removeCharactersByPosition**

Deletes characters from every cell in the target range by position (first/last N, before/after a substring, or between two delimiters) while preserving formulas, formatting and data-validation. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/remove/characters-by-position
```
### **Function Description**
**Position modes**  - `theFirstNCharacters` – remove N characters from the start  - `LastN` – remove N characters from the end  - `BeforeText` – delete everything before the first occurrence of the supplied substring  - `AfterText` – delete everything after the first occurrence  - `BetweenValues` – strip the substring (and optionally the delimiters themselves) between two user-defined values              **Options**  - `caseSensitive` – affects `BeforeText`, `AfterText` and `BetweenValues` searches  - `includingDelimiters` – when `BetweenValues` is used, controls whether the two boundary values are also removed               

### The request parameters of **removeCharactersByPosition** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|theFirstNCharacters|Integer|Query|Specify removing the first n characters from selected cells.|
|theLastNCharacters|Integer|Query|Specify removing the last n characters from selected cells.|
|allCharactersBeforeText|String|Query|Specify using targeted removal options to delete text that is located before certain characters.|
|allCharactersAfterText|String|Query|Specify using targeted removal options to delete text that is located after certain characters.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/RemoveCharactersByPosition) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
