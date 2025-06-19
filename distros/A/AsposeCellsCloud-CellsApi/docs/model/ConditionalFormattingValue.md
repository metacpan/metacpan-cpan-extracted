# AsposeCellsCloud::Object::ConditionalFormattingValue 

## Load the model package
```perl
use AsposeCellsCloud::Object::ConditionalFormattingValue;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**IsGTE** | **boolean** | Get or set the Greater Than Or Equal flag.             Use only for icon sets, determines whether this threshold value uses             the greater than or equal to operator.             'false' indicates 'greater than' is used instead of 'greater than or equal to'.            Default value is true.  |
**Type** | **string** | Get or set the type of this conditional formatting value object.            Setting the type to FormatConditionValueType.Min or FormatConditionValueType.Max             will auto set "Value" to null.  |
**Value** | **string** | Get or set the value of this conditional formatting value object.            It should be used in conjunction with Type.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

