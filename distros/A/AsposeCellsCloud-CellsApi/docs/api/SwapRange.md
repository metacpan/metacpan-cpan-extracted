# **Spreadsheet Cloud API: swapRange**

The Swap Ranges for Excel API provides a powerful tool to move any two columns, rows, ranges, or individual cells within an Excel file. This API allows users to re-arrange their tables quickly and efficiently, ensuring that the original data formatting is preserved and all existing formulas continue to function correctly. By leveraging this API, users can streamline their data manipulation tasks and maintain the integrity of their spreadsheets. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/swap/range
```
### **Function Description**
This API is designed to enhance productivity by simplifying the process of re-arranging data in Excel files. Users can easily swap columns, rows, ranges, or individual cells without worrying about losing data formatting or breaking formulas. The API ensures that the re-arranged tables remain functional and visually consistent with the original data. This feature is particularly useful for users who frequently need to manipulate large datasets or perform complex data re-arrangements.## **Error Handling**- **400 Bad Request**: Invalid url.- **401 Unauthorized**:  Authentication has failed, or no credentials were provided.- **404 Not Found**: Source file not accessible.- **500 Server Error** The spreadsheet has encountered an anomaly in obtaining data.## **Key Features and Benefits**- **Flexible Data Manipulation**: Swap columns, rows, ranges, or cells.- **Formatting and Formula Preservation**: Maintains original formatting and formula functionality.- **Efficiency**: Quick and efficient table re-arrangement.

### The request parameters of **swapRange** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|worksheet1|String|Query|Specify the worksheet that is the source of the exchange data area.|
|range1|String|Query|Specify exchange data source.|
|worksheet2|String|Query|Specify the worksheet that is the target of the exchange data area.|
|range2|String|Query|Specify exchange data target.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TransformController/SwapRange) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
