# **Spreadsheet Cloud API: putWorksheetColorFilter**

Add a color filter in the worksheet. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v3.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v3.0/cells/{name}/worksheets/{sheetName}/autoFilter/colorFilter
```
### **Function Description**
PageTitle:Add a color filter in the worksheet.PageDescription: Aspose.Cells Cloud provides robust support for adding a color filter in the worksheet, a process known for its intricacy.HeadTitle: Add a color filter in the worksheet.HeadSummary: Aspose.Cells Cloud provides robust support for adding a color filter in the worksheet, a process known for its intricacy.HeadContent: Aspose.Cells Cloud provides REST API which supports adding a color filter in the worksheet and offers SDKs for multiple programming languages. These programming languages are include of Net, Java, Go, NodeJS, Python, and so on.

### The request parameters of **putWorksheetColorFilter** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|The workbook name.|
|sheetName|String|Path|The worksheet name.|
|range|String|Query|Represents the range to which the specified AutoFilter applies.|
|fieldIndex|Integer|Query|The integer offset of the field on which you want to base the filter (from the left of the list; the leftmost field is field 0).|
|colorFilter|Class|Body|color filter request.|
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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/AutoFilterController/PutWorksheetColorFilter) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
