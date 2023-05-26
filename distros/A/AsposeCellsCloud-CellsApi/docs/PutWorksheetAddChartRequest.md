# AsposeCellsCloud::Request::PutWorksheetAddChart 

## Load the model package
```perl
use AsposeCellsCloud::Request::PutWorksheetAddChart;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **string** | The workbook name. |
**sheet_name** | **string** | The worksheet name. |
**chart_type** | **string** | Chart type, please refer property Type in chart resource. |
**upper_left_row** | **int** | New chart upper left row. |
**upper_left_column** | **int** | New chart upperleft column. |
**lower_right_row** | **int** | New chart lower right row. |
**lower_right_column** | **int** | New chart lower right column. |
**area** | **string** | Specifies values from which to plot the data series.  |
**is_vertical** | **boolean** | Specifies whether to plot the series from a range of cell values by row or by column.  |
**category_data** | **string** | Gets or sets the range of category Axis values. It can be a range of cells (such as, "d1:e10").  |
**is_auto_get_serial_name** | **boolean** | Specifies whether auto update serial name.  |
**title** | **string** | Specifies chart title name. |
**folder** | **string** | Original workbook folder. |
**data_labels** | **boolean** | Represents a specified chart's data label values display behavior. True displays the values. False to hide. |
**data_labels_position** | **string** | Represents data label position(Center/InsideBase/InsideEnd/OutsideEnd/Above/Below/Left/Right/BestFit/Moved). |
**pivot_table_sheet** | **string** | The source is the data of the pivotTable. If PivotSource is not empty ,the chart is PivotChart. |
**pivot_table_name** | **string** | The source is the data of the pivotTable. |
**storage_name** | **string** | Storage name. |  

[[Back to Model list]](../README.md#documentation-for-requests) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

