# **Spreadsheet Cloud API: putWorksheetDateFilter**

Apply a date filter in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autoFilter/dateFilter
```
### **Function Description**
PageTitle:  Apply a date filter in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for applying a date filter in the worksheet, a process known for its intricacy.HeadTitle: Apply a date filter in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for applying a date filter in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports applying a date filter in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetDateFilter** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The file name.|
|sheetName|String|Path|The worksheet name.|
|range|String|Query|Represents the range to which the specified AutoFilter applies.|
|fieldIndex|Integer|Query|The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).|
|dateTimeGroupingType|String|Query|Specifies how to group dateTime values (Day, Hour, Minute, Month, Second, Year).|
|year|Integer|Query|The year.|
|month|Integer|Query|The month.|
|day|Integer|Query|The day.|
|hour|Integer|Query|The hour.|
|minute|Integer|Query|The minute.|
|second|Integer|Query|The second.|
|matchBlanks|Boolean|Query|Match all blank cell in the list.|
|refresh|Boolean|Query|Refresh auto filters to hide or unhide the rows.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AutoFilterController/PutWorksheetDateFilter) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
