# AsposeCellsCloud::Object::IconSet 

## Load the model package
```perl
use AsposeCellsCloud::Object::IconSet;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**CfIcons** | **ARRAY[ConditionalFormattingIcon]** | Get the from the collection  |
**Cfvos** | **ARRAY[ConditionalFormattingValue]** | Get the CFValueObjects instance.  |
**IsCustom** | **boolean** | Indicates whether the icon set is custom.            Default value is false.  |
**Reverse** | **boolean** | Get or set the flag indicating whether to reverses the default order of the icons in this icon set.            Default value is false.  |
**ShowValue** | **boolean** | Get or set the flag indicating whether to show the values of the cells on which this icon set is applied.            Default value is true.  |
**IconSetType** | **string** | Get or Set the icon set type to display.  Setting the type will auto check   if the current Cfvos's count is accord with the new type. If not accord,   old Cfvos will be cleaned and default Cfvos will be added.             |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

