# **Spreadsheet Cloud API: saveSpreadsheetAs**

Converts a spreadsheet in cloud storage to the specified format. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
- **Example** 

## **Interface Details**

### **Endpoint** 

```
PUT http://api.aspose.cloud/v4.0/cells/{name}/saveas
```
### **Function Description**
This method accesses a spreadsheet file directly from cloud storage, converts it into the desired output format (e.g., XLSX, PDF, CSV), and returns the converted result without downloading the file to the local system.Ensure that the cloud storage configuration (such as access credentials and file path) is correctly set up.The conversion process happens entirely within the cloud environment, minimizing data transfer overhead and enhancing security by keeping sensitive data within the cloud infrastructure.If the source file does not exist, or if an error occurs during the conversion process, an appropriate exception will be thrown.Supported output formats depend on the underlying conversion service capabilities.

### The request parameters of **saveSpreadsheetAs** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 
|name|String|Path|(Required) The name of the workbook file to be converted.|
|format|String|Query|(Required) The desired output format (e.g., "Xlsx", "Pdf", "Csv").|
|saveOptionsData|Class|Body|(Optional) Save options data. The default is null.|
|folder|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|storageName|String|Query|(Optional) The name of the storage if using custom cloud storage. Use default storage if omitted.|
|outPath|String|Query|(Optional) The folder path where the workbook is stored. The default is null.|
|outStorageName|String|Query|Output file Storage Name.|
|fontsLocation|String|Query|Use Custom fonts.|
|regoin|String|Query|The spreadsheet region setting.|
|password|String|Query|The password for opening spreadsheet file.|

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

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/ConversionController/SaveSpreadsheetAs) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
