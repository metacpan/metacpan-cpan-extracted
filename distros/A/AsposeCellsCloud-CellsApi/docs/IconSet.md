# AsposeCellsCloud::Object::IconSet

## Load the model package
```perl
use AsposeCellsCloud::Object::IconSet;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**reverse** | **boolean** | Get or set the flag indicating whether to reverses the default order of the   icons in this icon set.  Default value is false.              | [optional] 
**cf_icons** | [**ARRAY[ConditionalFormattingIcon]**](ConditionalFormattingIcon.md) | Get theAspose.Cells.ConditionalFormattingIcon from the collection | [optional] 
**cfvos** | [**ARRAY[ConditionalFormattingValue]**](ConditionalFormattingValue.md) | Get the CFValueObjects instance. | [optional] 
**icon_set_type** | **string** | Get or Set the icon set type to display.  Setting the type will auto check    if the current Cfvos&#39;s count is accord with the new type. If not accord,    old Cfvos will be cleaned and default Cfvos will be added.              | [optional] 
**is_custom** | **boolean** | Indicates whether the icon set is custom.  Default value is false. | [optional] 
**show_value** | **boolean** | Get or set the flag indicating whether to show the values of the cells on    which this icon set is applied.  Default value is true.              | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


