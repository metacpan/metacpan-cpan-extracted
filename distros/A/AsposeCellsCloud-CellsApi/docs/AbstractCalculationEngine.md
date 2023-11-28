# AsposeCellsCloud::Object::AbstractCalculationEngine 

## Load the model package
```perl
use AsposeCellsCloud::Object::AbstractCalculationEngine;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**IsParamLiteralRequired** | **boolean** | Indicates whether this engine needs the literal text of parameter while doing calculation. Default value is false.  |
**IsParamArrayModeRequired** | **boolean** | Indicates whether this engine needs the parameter to be calculated in array mode. Default value is false.            If  is required when calculating custom            functions, this property needs to be set as true.  |
**ProcessBuiltInFunctions** | **boolean** | Whether built-in functions that have been supported by the built-in engine            should be checked and processed by this implementation.            Default is false.            If user needs to change the calculation logic of some built-in functions, this property should be set as true.            Otherwise please leave this property as false for performance consideration.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

