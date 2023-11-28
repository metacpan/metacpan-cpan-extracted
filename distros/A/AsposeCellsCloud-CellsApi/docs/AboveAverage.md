# AsposeCellsCloud::Object::AboveAverage 

## Load the model package
```perl
use AsposeCellsCloud::Object::AboveAverage;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**IsAboveAverage** | **boolean** | Get or set the flag indicating whether the rule is an "above average" rule.             'true' indicates 'above average'.            Default value is true.  |
**IsEqualAverage** | **boolean** | Get or set the flag indicating whether the 'aboveAverage' and 'belowAverage' criteria             is inclusive of the average itself, or exclusive of that value.             'true' indicates to include the average value in the criteria.            Default value is false.  |
**StdDev** | **int** | Get or set the number of standard deviations to include above or below the average in the            conditional formatting rule.             The input value must between 0 and 3 (include 0 and 3).             Setting this value to 0 means stdDev is not set.            The default value is 0.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

