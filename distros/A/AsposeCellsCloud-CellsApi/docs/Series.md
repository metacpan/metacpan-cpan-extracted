# AsposeCellsCloud::Object::Series 

## Load the model package
```perl
use AsposeCellsCloud::Object::Series;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Area** | **Area** | Represents the background area of Series object. |
**Bar3DShapeType** | **string** | Gets or sets the 3D shape type used with the 3-D bar or column chart. |
**Border** | **Line** | Represents border of Series object. |
**BubbleScale** | **int** | Gets or sets the scale factor for bubbles in the specified chart group.                         It can be an integer value from 0 (zero) to 300,                         corresponding to a percentage of the default size.                        Applies only to bubble charts. |
**BubbleSizes** | **string** | Gets or sets the bubble sizes values of the chart series. |
**CountOfDataValues** | **int** | Gets the number of the data values. |
**DataLabels** | **DataLabels** | Represents the DataLabels object for the specified ASeries. |
**DisplayName** | **string** | Gets the series's name that displays on the chart graph. |
**DoughnutHoleSize** | **int** | Returns or sets the size of the hole in a doughnut chart group.                         The hole size is expressed as a percentage of the chart size, between 10 and 90 percent. |
**DownBars** | **DropBars** | Returns a  object that represents the down bars on a line chart.                        Applies only to line charts. |
**DropLines** | **Line** | Returns a  object that represents the drop lines for a series on the line chart or area chart.                        Applies only to line chart or area charts. |
**Explosion** | **int** | The distance of an open pie slice from the center of the pie chart is expressed as a percentage of the pie diameter. |
**FirstSliceAngle** | **int** | Gets or sets the angle of the first pie-chart or doughnut-chart slice, in degrees (clockwise from vertical).                         Applies only to pie, 3-D pie, and doughnut charts, 0 to 360. |
**GapWidth** | **int** | Returns or sets the space between bar or column clusters, as a percentage of the bar or column width.                        The value of this property must be between 0 and 500. |
**Has3DEffect** | **boolean** | True if the series has a three-dimensional appearance.                         Applies only to bubble charts. |
**HasDropLines** | **boolean** | True if the chart has drop lines.                        Applies only to line chart or area charts. |
**HasHiLoLines** | **boolean** | True if the line chart has high-low lines.                          Applies only to line charts. |
**HasLeaderLines** | **boolean** | True if the series has leader lines. |
**HasRadarAxisLabels** | **boolean** | True if a radar chart has category axis labels. Applies only to radar charts. |
**HasSeriesLines** | **boolean** | True if a stacked column chart or bar chart has series lines or                        if a Pie of Pie chart or Bar of Pie chart has connector lines between the two sections.                         Applies only to stacked column charts, bar charts, Pie of Pie charts, or Bar of Pie charts. |
**HasUpDownBars** | **boolean** | True if a line chart has up and down bars.                        Applies only to line charts. |
**HiLoLines** | **Line** | Returns a HiLoLines object that represents the high-low lines for a series on a line chart.                         Applies only to line charts. |
**IsAutoSplit** | **boolean** | Indicates whether the threshold value is automatic. |
**IsColorVaried** | **boolean** | Represents if the color of points is varied.                         The chart must contain only one series. |
**LeaderLines** | **Line** | Represents leader lines on a chart. Leader lines connect data labels to data points.                         This object isn’t a collection; there’s no object that represents a single leader line. |
**LegendEntry** | **LegendEntry** | Gets the legend entry according to this series. |
**Marker** | **Marker** | Gets the marker. |
**Name** | **string** | Gets or sets the name of the data series. |
**Overlap** | **int** | Specifies how bars and columns are positioned.                        Can be a value between – 100 and 100.                         Applies only to 2-D bar and 2-D column charts. |
**PlotOnSecondAxis** | **boolean** | Indicates if this series is plotted on second value axis. |
**Points** | **LinkElement** | Gets the collection of points in a series in a chart. |
**SecondPlotSize** | **int** | Returns or sets the size of the secondary section of either a pie of pie chart or a bar of pie chart,                         as a percentage of the size of the primary pie.                        Can be a value from 5 to 200. |
**SeriesLines** | **Line** | Returns a SeriesLines object that represents the series lines for a stacked bar chart or a stacked column chart.                        Applies only to stacked bar and stacked column charts. |
**Shadow** | **boolean** | True if the series has a shadow. |
**ShowNegativeBubbles** | **boolean** | True if negative bubbles are shown for the chart group. Valid only for bubble charts. |
**SizeRepresents** | **string** | Gets or sets what the bubble size represents on a bubble chart. |
**Smooth** | **boolean** | Represents curve smoothing.                         True if curve smoothing is turned on for the line chart or scatter chart.                        Applies only to line and scatter connected by lines charts. |
**SplitType** | **string** | Returns or sets a value that how to determine which data points are in the second pie or bar on a pie of pie or bar of                        pie chart. |
**SplitValue** | **double** | Returns or sets a value that shall be used to determine which data points are in the second pie or bar on                        a pie of pie or bar of pie chart. |
**TrendLines** | **Trendlines** | Returns an object that represents a collection of all the trendlines for the series. |
**Type** | **string** | Gets or sets a data series' type. |
**UpBars** | **DropBars** | Returns an DropBars object that represents the up bars on a line chart.                        Applies only to line charts. |
**Values** | **string** | Represents the data of the chart series. |
**XErrorBar** | **ErrorBar** | Represents X direction error bar of the series. |
**XValues** | **string** | Represents the x values of the chart series. |
**YErrorBar** | **ErrorBar** | Represents Y direction error bar of the series. |
**link** | **Link** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

