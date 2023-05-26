# AsposeCellsCloud::Object::Chart

## Load the model package
```perl
use AsposeCellsCloud::Object::Chart;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**link** | [**Link**](Link.md) |  | [optional] 
**first_slice_angle** | **int** | Gets or sets the angle of the first pie-chart or doughnut-chart slice, in degrees (clockwise from vertical). Applies only to pie, 3-D pie, and doughnut charts, 0 to 360. | [optional] 
**floor** | [**LinkElement**](LinkElement.md) | Returns a Floor object that represents the walls of a 3-D chart.              | [optional] 
**plot_empty_cells_type** | **string** | Gets and sets how to plot the empty cells. | [optional] 
**auto_scaling** | **boolean** | True if Microsoft Excel scales a 3-D chart so that it&#39;s closer in size to the equivalent 2-D chart. The RightAngleAxes property must be True. | [optional] 
**style** | **int** | Gets and sets the builtin style. | [optional] 
**series_axis** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s series axis. | [optional] 
**value_axis** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s Y axis. | [optional] 
**show_data_table** | **boolean** | Gets or sets a value indicating whether the chart displays a data table. | [optional] 
**is3_d** | **boolean** | Indicates whether the chart is a 3d chart. | [optional] 
**chart_area** | [**LinkElement**](LinkElement.md) | Gets the chart area in the worksheet | [optional] 
**elevation** | **int** | Represents the elevation of the 3-D chart view, in degrees. | [optional] 
**side_wall** | [**LinkElement**](LinkElement.md) |  | [optional] 
**type** | **string** | Gets or sets a chart&#39;s type. | [optional] 
**title** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s title. | [optional] 
**walls** | [**LinkElement**](LinkElement.md) | Returns a Walls object that represents the walls of a 3-D chart. | [optional] 
**back_wall** | [**LinkElement**](LinkElement.md) |  | [optional] 
**chart_data_table** | [**LinkElement**](LinkElement.md) | Represents the chart data table. | [optional] 
**height_percent** | **int** | Returns or sets the height of a 3-D chart as a percentage of the chart width (between 5 and 500 percent). | [optional] 
**gap_width** | **int** | Returns or sets the space between bar or column clusters, as a percentage of the bar or column width. The value of this property must be between 0 and 500.              | [optional] 
**legend** | [**LinkElement**](LinkElement.md) | Gets the chart legend. | [optional] 
**chart_object** | [**LinkElement**](LinkElement.md) | Represents the chartShape; | [optional] 
**is_rectangular_cornered** | **boolean** | Gets or sets a value indicating whether the chart displays a data table. | [optional] 
**second_category_axis** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s second X axis. | [optional] 
**second_value_axis** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s second Y axis. | [optional] 
**placement** | **string** | Represents the way the chart is attached to the cells below it. | [optional] 
**name** | **string** | Gets and sets the name of the chart. | [optional] 
**size_with_window** | **boolean** | True if Microsoft Excel resizes the chart to match the size of the chart sheet window. | [optional] 
**right_angle_axes** | **boolean** | True if the chart axes are at right angles.Applies only for 3-D charts(except Column3D and 3-D Pie Charts). | [optional] 
**plot_visible_cells** | **boolean** | Indicates whether only plot visible cells. | [optional] 
**show_legend** | **boolean** | Gets or sets a value indicating whether the chart legend will be displayed. Default is true. | [optional] 
**pivot_source** | **string** | The source is the data of the pivotTable.If PivotSource is not empty ,the chart is PivotChart. | [optional] 
**depth_percent** | **int** | Represents the depth of a 3-D chart as a percentage of the chart width (between 20 and 2000 percent). | [optional] 
**print_size** | **string** | Gets and sets the printed chart size. | [optional] 
**gap_depth** | **int** | Gets or sets the distance between the data series in a 3-D chart, as a percentage of the marker width.The value of this property must be between 0 and 500. | [optional] 
**shapes** | [**LinkElement**](LinkElement.md) | Returns all drawing shapes in this chart. | [optional] 
**walls_and_gridlines2_d** | **boolean** | True if gridlines are drawn two-dimensionally on a 3-D chart. | [optional] 
**n_series** | [**LinkElement**](LinkElement.md) | Gets a SeriesCollection collection representing the data series in the chart. | [optional] 
**rotation_angle** | **int** | Represents the rotation of the 3-D chart view (the rotation of the plot area around the z-axis, in degrees). | [optional] 
**plot_area** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s plot area which includes axis tick lables. | [optional] 
**category_axis** | [**LinkElement**](LinkElement.md) | Gets the chart&#39;s X axis. The property is read only | [optional] 
**perspective** | **int** | Returns or sets the perspective for the 3-D chart view. Must be between 0 and 100.This property is ignored if the RightAngleAxes property is True. | [optional] 
**hide_pivot_field_buttons** | **boolean** | Indicates whether hide the pivot chart field buttons only when the chart is PivotChart | [optional] 
**page_setup** | [**LinkElement**](LinkElement.md) | Represents the page setup description in this chart. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


