# AsposeCellsCloud::Object::FormatCondition 

## Load the model package
```perl
use AsposeCellsCloud::Object::FormatCondition;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Priority** | **int** | The priority of this conditional formatting rule. This value is used to determine which                        format should be evaluated and rendered. Lower numeric values are higher priority than                        higher numeric values, where '1' is the highest priority. |
**Type** | **string** | Gets and sets whether the conditional format Type. |
**StopIfTrue** | **boolean** | True, no rules with lower priority may be applied over this rule, when this rule evaluates to true.                        Only applies for Excel 2007; |
**AboveAverage** | **AboveAverage** | Get the conditional formatting's "AboveAverage" instance.                        The default instance's rule highlights cells that are                         above the average for all values in the range.                        Valid only for type = AboveAverage. |
**ColorScale** | **ColorScale** | Get the conditional formatting's "ColorScale" instance.                        The default instance is a "green-yellow-red" 3ColorScale .                        Valid only for type = ColorScale. |
**DataBar** | **DataBar** | Get the conditional formatting's "DataBar" instance.                        The default instance's color is blue.                        Valid only for type is DataBar. |
**Formula1** | **string** | Gets and sets the value or expression associated with conditional formatting. |
**Formula2** | **string** | Gets and sets the value or expression associated with conditional formatting. |
**IconSet** | **IconSet** | Get the conditional formatting's "IconSet" instance.                        The default instance's IconSetType is TrafficLights31.                        Valid only for type = IconSet. |
**Operator** | **string** | Gets and sets the conditional format operator type. |
**Style** | **Style** | Gets or setts style of conditional formatted cell ranges. |
**Text** | **string** | The text value in a "text contains" conditional formatting rule.                         Valid only for type = containsText, notContainsText, beginsWith and endsWith.                        The default value is null. |
**TimePeriod** | **string** | The applicable time period in a "date occurring…" conditional formatting rule.                         Valid only for type = timePeriod.                        The default value is TimePeriodType.Today. |
**Top10** | **Top10** | Get the conditional formatting's "Top10" instance.                        The default instance's rule highlights cells whose                        values fall in the top 10 bracket.                        Valid only for type is Top10. |
**link** | **Link** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

