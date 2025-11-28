# **Spreadsheet Cloud API: splitText**

Indicates performing text segmentation on the specified area according to the segmentation method, and outputting to the designated interval. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/content/split/text
```
### **Function Description**
## **Primary Split Capability**- **Split by specific characters** - supports the use of any character as a separator(such as comma, space, semicolon, etc.)- **Split by string combination** - any combination of characters can be used as a separation criterion- **Split by Pattern Mask** - text segmentation based on a specific pattern through wildcards, providing more flexibility- **Split by line break** - divide the cell contents according to line breaks to improve the organization of the table.## **Output Configuration Options**- **Direction Selection**: Free choice to split cells into columns or rows- **Separator handling**: remove the separator or keep it at the beginning and end of the result cell## **Functional advantages**Through a variety of segmentation methods and flexible configuration options, the tool provides users with a comprehensive and powerful text segmentation solution that can meet a variety of complex data processing needs.

### The request parameters of **splitText** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|Spreadsheet|File|FormData|Upload spreadsheet file.|
|delimiters|String|Query|Indicates the custom delimiter.|
|keepDelimitersInResultingCells|Boolean|Query|Indicates keep delimiters in resulting cells.|
|keepDelimitersPosition|String|Query|Indicates keep delimiters position.|
|HowToSplit|String|Query|Indicates|
|outPositionRange|String|Query|Indicates split delimiters type.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/TextProcessingController/SplitText) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
