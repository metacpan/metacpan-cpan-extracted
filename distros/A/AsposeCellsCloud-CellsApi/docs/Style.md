# AsposeCellsCloud::Object::Style 

## Load the model package
```perl
use AsposeCellsCloud::Object::Style;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Font** | **Font** | Gets a  object.  |
**Name** | **string** | Gets or sets the name of the style.  |
**CultureCustom** | **string** | Gets and sets the culture-dependent pattern string for number format.            If no number format has been set for this object, null will be returned.            If number format is builtin, the pattern string corresponding to the builtin number will be returned.  |
**Custom** | **string** | Represents the custom number format string of this style object.            If the custom number format is not set(For example, the number format is builtin), "" will be returned.  |
**BackgroundColor** | **Color** | Gets or sets a style's background color.  |
**ForegroundColor** | **Color** | Gets or sets a style's foreground color.  |
**IsFormulaHidden** | **boolean** | Represents if the formula will be hidden when the worksheet is protected.  |
**IsDateTime** | **boolean** | Indicates whether the number format is a date format.  |
**IsTextWrapped** | **boolean** | Gets or sets a value indicating whether the text within a cell is wrapped.  |
**IsGradient** | **boolean** | Indicates whether the cell shading is a gradient pattern.  |
**IsLocked** | **boolean** | Gets or sets a value indicating whether a cell can be modified or not.  |
**IsPercent** | **boolean** | Indicates whether the number format is a percent format.  |
**ShrinkToFit** | **boolean** | Represents if text automatically shrinks to fit in the available column width.  |
**IndentLevel** | **int** | Represents the indent level for the cell or range. Can only be an integer from 0 to 250.  |
**Number** | **int** | Gets or sets the display format of numbers and dates. The formatting patterns are different for different regions.  |
**RotationAngle** | **int** | Represents text rotation angle.  |
**Pattern** | **string** | Gets or sets the cell background pattern type.  |
**TextDirection** | **string** | Represents text reading order.  |
**VerticalAlignment** | **string** | Gets or sets the vertical alignment type of the text in a cell.  |
**HorizontalAlignment** | **string** | Gets or sets the horizontal alignment type of the text in a cell.  |
**BorderCollection** | **ARRAY[Border]** | A public property named `BorderCollection` that is a list of `Border` objects. |
**BackgroundThemeColor** | **ThemeColor** | Gets and sets the background theme color.  |
**ForegroundThemeColor** | **ThemeColor** | Gets and sets the foreground theme color.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

