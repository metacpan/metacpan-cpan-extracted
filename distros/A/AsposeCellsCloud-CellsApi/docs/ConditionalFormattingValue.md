# AsposeCellsCloud::Object::ConditionalFormattingValue

## Load the model package
```perl
use AsposeCellsCloud::Object::ConditionalFormattingValue;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**is_gte** | **boolean** | Get or set the Greater Than Or Equal flag. Use only for icon sets, determines    whether this threshold value uses the greater than or equal to operator.    &#39;false&#39; indicates &#39;greater than&#39; is used instead of &#39;greater than or equal    to&#39;.  Default value is true.              | [optional] 
**type** | **string** | Get or set the type of this conditional formatting value object.  Setting      the type to FormatConditionValueType.Min or FormatConditionValueType.Max      will auto set \&quot;Value\&quot; to null.   | [optional] 
**value** | **string** | Get or set the value of this conditional formatting value object.  It should     be used in conjunction with Type. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


