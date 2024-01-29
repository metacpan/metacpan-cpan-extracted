# AsposeCellsCloud::Request::PutWorksheetAddChart 

## Load the model package
```perl
use AsposeCellsCloud::Request::PutWorksheetAddChart;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **string** | The file name. |
**sheet_name** | **string** | The worksheet name. |
**chart_type** | **string** | Chart type, please refer property Type in chart resource. |
**upper_left_row** | **int** | Upper-left row for the new chart. |
**upper_left_column** | **int** | Upper-left column for the new chart. |
**lower_right_row** | **int** | Lower-left row for the new chart. |
**lower_right_column** | **int** | Lower-left column for the new chart. |
**area** | **string** | Specify the values from which to plot the data series. |
**is_vertical** | **boolean** | Specify whether to plot the series from a range of cell values by row or by column.  |
**category_data** | **string** | Get or set the range of category axis values. It can be a range of cells (e.g., "D1:E10"). |
**is_auto_get_serial_name** | **boolean** | Specify whether to auto-update the serial name. |
**title** | **string** | Specify the chart title name. |
**folder** | **string** | The folder where the file is situated. |
**data_labels** | **boolean** | Represents the specified chart's data label values display behavior. True to display the values, False to hide them. |
**data_labels_position** | **string** | Represents data label position (Center/InsideBase/InsideEnd/OutsideEnd/Above/Below/Left/Right/BestFit/Moved). |
**pivot_table_sheet** | **string** | The source is the data of the pivotTable. If PivotSource is not empty, the chart is a PivotChart. |
**pivot_table_name** | **string** | The pivot table name. |
**storage_name** | **string** | The storage name where the file is situated. |  

[[Back to Model list]](../README.md#documentation-for-requests) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

