# **Spreadsheet Cloud API: putWorksheetFormatConditionCondition**

Add a condition for the format condition in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index}/condition
```
### **Function Description**
PageTitle: Add a condition for the format condition in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a condition for the format condition in the worksheet, a process known for its intricacy.HeadTitle: Add a condition for the format condition in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a condition for the format condition in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a condition for the format condition in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetFormatConditionCondition** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|index|Integer|Path|Gets the Conditional Formatting element at the specified index.|
|type|String|Query|Format condition type(CellValue/Expression/ColorScale/DataBar/IconSet/Top10/UniqueValues/DuplicateValues/ContainsText/NotContainsText/BeginsWith/EndsWith/ContainsBlanks/NotContainsBlanks/ContainsErrors/NotContainsErrors/TimePeriod/AboveAverage).|
|operatorType|String|Query|Represents the operator type of conditional format and data validation(Between/Equal/GreaterThan/GreaterOrEqual/LessThan/None/NotBetween/NotEqual).|
|formula1|String|Query|The value or expression associated with conditional formatting.|
|formula2|String|Query|The value or expression associated with conditional formatting.|
|folder|String|Query|The folder where the file is situated.|
|storageName|String|Query|The storage name where the file is situated.|

### **Response Description**
```json
{
  "Name": "CellsCloudResponse",
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Code",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Integer",
        "Name": "integer"
      }
    },
    {
      "Name": "Status",
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    }
  ]
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConditionalFormattingsController/PutWorksheetFormatConditionCondition) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
