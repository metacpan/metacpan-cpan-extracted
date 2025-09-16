# **Spreadsheet Cloud API: trimSpreadsheetContent**

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
Efficiency: The API efficiently trims content within the specified range, ensuring that only the designated cells are processed. This targeted approach saves time and resources by avoiding unnecessary operations on the entire worksheet.Flexibility: Users can define the exact range of cells to be processed, providing flexibility in handling different data sets and requirements.Data Integrity: By removing extra spaces and line breaks, the API helps maintain data integrity and consistency, which is crucial for accurate data analysis and reporting.Ease of Use: The API is easy to integrate into existing workflows and can be used with minimal setup, making it accessible for both developers and end-users

### The request parameters of **trimSpreadsheetContent** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|trimContent|String|Query||
|trimLeading|Boolean|Query||
|trimTrailing|Boolean|Query||
|trimSpaceBetweenWordTo1|Boolean|Query||
|trimNonBreakingSpaces|Boolean|Query||
|removeExtraLineBreaks|Boolean|Query||
|removeAllLineBreaks|Boolean|Query||
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/TrimSpreadsheetContent) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
