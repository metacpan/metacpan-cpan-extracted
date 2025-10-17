# **Spreadsheet Cloud API: extractText**

Indicates extracting substrings, text characters, and numbers from a spreadsheet cell into another cell without having to use complex FIND, MIN, LEFT, or RIGHT formulas. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/extract/text
```
### **Function Description**
Extracts substrings, numbers, or fixed-length prefixes/suffixes from the selected range and writes the results directly to the target area—no Excel formulas, no helper columns, no manual copy-paste.The engine works cell-by-cell:- **String cells** are scanned for the requested delimiter or position and the matching fragment is returned.- **Numeric or date cells** are implicitly converted to text(using the workbook’s locale) before the rule is applied, so 123.45 can yield 123 (left 3) or 45 (right 2) without pre-formatting.- **Empty cells** remain blank; cells where the delimiter is not found produce an empty string, giving you a predictable, non-error output.Because the operation is executed inside the streaming reader/writer, no temporary objects are created—memory stays flat even on million-row ranges—and the source formatting, formulas and data-validation are left untouched.Result area can be on the same sheet, another sheet, or even another workbook, making it ideal for preparing clean data feeds for pivot tables, charts or downstream ML pipelines.- **Extract first characters**Get the first character or specified number of characters from the left of each selected cell.Make it easy to capture relevant information at the beginning of your data.- **Extract text before, after or between specified characters** Perform precise information retrieval by extracting text before, after, or between the characters or substrings you specify.- **Get text from any position in a string**Enjoy flexibility in data extraction as you retrieve text from any position within a string. Simply indicate where the first character is located and how many characters to pull.- **Extract last characters**Get the last character or a specified number of characters from the end of your cell values. Extract the desired information from the tail of your data, such as the file extensions from a list of file names.- **Extract all numbers from selected cells**Get all numbers from alphanumeric strings making it easier for you to work with quantitative information in your spreadsheets.- **Have the result as value or formula**Tailor the output of your extraction by choosing whether the result appears as a static value or dynamic formula.

### The request parameters of **extractText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|extractTextType|String|Query|Indicates extract text type.|
|beforeText|String|Query|Indicates extracting the text before the specified characters or substrings.|
|afterText|String|Query|Indicates extracting the text after the specified characters or substrings.|
|beforePosition|Integer|Query|Indicates retrieving the first character or a specified number of characters from the left side of the selected cell.|
|afterPosition|Integer|Query|Indicates retrieving the first character or a specified number of characters from the right side of the selected cell.|
|outPositionRange|String|Query|Indicates the output location for the extracted text.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/ExtractText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
