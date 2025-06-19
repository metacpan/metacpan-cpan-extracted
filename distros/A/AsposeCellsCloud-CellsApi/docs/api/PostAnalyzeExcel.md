# **Spreadsheet Cloud API: postAnalyzeExcel**

Perform business analysis of data in Excel files. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v3.0/cells/analyze
```
### **Function Description**
PageTitle:  Perform business analysis of data in Excel files.PageDescription: Aspose.Cells Cloud provides robust support for Excel data analysis, making it capable of parsing tables and range data for chart and pivot table output. This process is known for its intricacy.HeadTitle: Perform business analysis of data in Excel files.HeadSummary: Aspose.Cells Cloud provides robust support for Excel data analysis, making it capable of parsing tables and range data for chart and pivot table output.HeadContent: Aspose.Cells Cloud provides REST API which supports Excel data analysis and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.kwords: Data Analyze, Excel, Spreadsheet, Data Conversionhowto:fqa: [ {"Question":"Why data anlysis in C# using REST API?" ,"Answer"}

### The request parameters of **postAnalyzeExcel** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|analyzeExcelRequest|Class|Body|Excel files and analysis output requirements|

### **Response Description**
```json
[
{
  "Name": "AnalyzedResult",
  "Description": [
    "Represents results of analyzed data."
  ],
  "Type": "Class",
  "IsAbstract": false,
  "Properties": [
    {
      "Name": "Filename",
      "Description": [
        "Represents the file name of data file."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "Description",
      "Description": [
        "Represents summary about results of analyzed data."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "String",
        "Name": "string"
      }
    },
    {
      "Name": "BasicStatistics",
      "Description": [
        "Represents Excel data statistics."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Class",
        "Reference": "ExcelDataStatistics",
        "Name": "class:exceldatastatistics"
      }
    },
    {
      "Name": "Results",
      "Description": [
        "Represents analyzed table description."
      ],
      "Nullable": true,
      "ReadOnly": false,
      "IsInherit": false,
      "DataType": {
        "Identifier": "Container",
        "Reference": "AnalyzedTableDescription",
        "ElementDataType": {
          "Identifier": "Class",
          "Reference": "AnalyzedTableDescription",
          "Name": "class:analyzedtabledescription"
        },
        "Name": "container"
      }
    },
    {
      "Name": "SuggestedFile",
      "Description": [
        "base64String Excel file"
      ],
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
]
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AnalyseController/PostAnalyzeExcel) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
