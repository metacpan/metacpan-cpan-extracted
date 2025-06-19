# AsposeCellsCloud::Object::AnalyzedTableDescription 

## Load the model package
```perl
use AsposeCellsCloud::Object::AnalyzedTableDescription;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Name** | **string** | Represents table name. |
**SheetName** | **string** | Represents worksheet name which is where the table is located. |
**Columns** | **ARRAY[AnalyzedColumnDescription]** | Represents analyzed description about table columns. |
**DateColumns** | **ARRAY[int?]** | Represents date columns list. |
**NumberColumns** | **ARRAY[int?]** | Represents number columns list. |
**TextColumns** | **ARRAY[int?]** | Represents string columns list. |
**ExceptionColumns** | **ARRAY[int?]** | Represents exception columns list. |
**HasTableHeaderRow** | **boolean** | Represents there is a table header in the table. |
**HasTableTotalRow** | **boolean** | Represents there is a total row in the table. |
**StartDataColumnIndex** | **int** | Represents the column index as the start data column. |
**EndDataColumnIndex** | **int** | Represents the column index as the end data column. |
**StartDataRowIndex** | **int** | Represents the row index as the start data row. |
**EndDataRowIndex** | **int** | Represents the row index as the end data row. |
**Thumbnail** | **string** | Represents table thumbnail. Base64String |
**DiscoverCharts** | **ARRAY[DiscoverChart]** | Represents a collection of charts, which is a collection of charts created based on data analysis of a table. |
**DiscoverPivotTables** | **ARRAY[DiscoverPivotTable]** | Represents a collection of pivot tables, which is a collection of pivot tables created based on data analysis of a table. |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

