# AsposeCellsCloud::Object::Chart 

## Load the model package
```perl
use AsposeCellsCloud::Object::Chart;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**AutoScaling** | **boolean** | True if Microsoft Excel scales a 3-D chart so that it's closer in size to the equivalent 2-D chart.                         The RightAngleAxes property must be True. |
**BackWall** | **Walls** | Returns a  object that represents the back wall of a 3-D chart. |
**CategoryAxis** | **Axis** | Gets the chart's X axis. |
**ChartArea** | **ChartArea** | Gets the chart area in the worksheet. |
**ChartDataTable** | **ChartDataTable** | Represents the chart data table. |
**ChartObject** | **LinkElement** | Represents the chartShape; |
**DepthPercent** | **int** | Represents the depth of a 3-D chart as a percentage of the chart width (between 20 and 2000 percent). |
**Elevation** | **int** | Represents the elevation of the 3-D chart view, in degrees. |
**FirstSliceAngle** | **int** | Gets or sets the angle of the first pie-chart or doughnut-chart slice, in degrees (clockwise from vertical).                         Applies only to pie, 3-D pie, and doughnut charts, 0 to 360. |
**Floor** | **Floor** | Returns a  object that represents the walls of a 3-D chart. |
**GapDepth** | **int** | Gets or sets the distance between the data series in a 3-D chart, as a percentage of the marker width.                        The value of this property must be between 0 and 500. |
**GapWidth** | **int** | Returns or sets the space between bar or column clusters, as a percentage of the bar or column width.                        The value of this property must be between 0 and 500. |
**HeightPercent** | **int** | Returns or sets the height of a 3-D chart as a percentage of the chart width (between 5 and 500 percent). |
**HidePivotFieldButtons** | **boolean** | Indicates whether hide the pivot chart field buttons only when the chart is PivotChart. |
**Is3D** | **boolean** | Indicates whether the chart is a 3d chart. |
**IsRectangularCornered** | **boolean** | Gets or sets a value indicating whether the chart area is rectangular cornered.                        Default is true. |
**Legend** | **Legend** | Gets the chart legend. |
**Name** | **string** | Represents chart name. |
**NSeries** | **SeriesItems** | Gets a  collection representing the data series in the chart. |
**PageSetup** | **LinkElement** | Represents the page setup description in this chart. |
**Perspective** | **int** | Returns or sets the perspective for the 3-D chart view. Must be between 0 and 100.                        This property is ignored if the RightAngleAxes property is True. |
**PivotSource** | **string** | The source is the data of the pivotTable.                        If PivotSource is not empty ,the chart is PivotChart. |
**Placement** | **string** | Represents the way the chart is attached to the cells below it. |
**PlotArea** | **PlotArea** | Gets the chart's plot area which includes axis tick labels. |
**PlotEmptyCellsType** | **string** | Gets and sets  how to plot the empty cells. |
**PlotVisibleCells** | **boolean** | Indicates whether only plot visible cells. |
**PrintSize** | **string** | Gets and sets the printed chart size. |
**RightAngleAxes** | **boolean** | True if the chart axes are at right angles. Applies only for 3-D charts(except Column3D and 3-D Pie Charts). |
**RotationAngle** | **int** | Represents the rotation of the 3-D chart view (the rotation of the plot area around the z-axis, in degrees). |
**SecondCategoryAxis** | **LinkElement** | Gets the chart's second X axis. |
**SecondValueAxis** | **LinkElement** | Gets the chart's second Y axis. |
**SeriesAxis** | **LinkElement** | Gets the chart's series axis. |
**Shapes** | **LinkElement** | Returns all drawing shapes in this chart. |
**ShowDataTable** | **boolean** | Gets or sets a value indicating whether the chart displays a data table. |
**ShowLegend** | **boolean** | Gets or sets a value indicating whether the chart legend will be displayed. Default is true. |
**SideWall** | **LinkElement** | Returns a  object that represents the side wall of a 3-D chart. |
**SizeWithWindow** | **boolean** | True if Microsoft Excel resizes the chart to match the size of the chart sheet window. |
**Style** | **int** | Gets and sets the builtin style. |
**Title** | **LinkElement** | Represents chart title. |
**Type** | **string** | Represents chart type. |
**ValueAxis** | **Axis** | Gets the chart's Y axis. |
**Walls** | **LinkElement** | Returns a  object that represents the walls of a 3-D chart. |
**WallsAndGridlines2D** | **boolean** | True if gridlines are drawn two-dimensionally on a 3-D chart. |
**link** | **Link** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

