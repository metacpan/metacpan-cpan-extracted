# AsposeCellsCloud::Object::CalculationOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::CalculationOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**CalcStackSize** | **int** | Specifies the stack size for calculating cells recursively.  |
**IgnoreError** | **boolean** | Indicates whether errors encountered while calculating formulas should be ignored.            The error may be unsupported function, external links, etc.            The default value is true.  |
**PrecisionStrategy** | **string** | Specifies the strategy for processing precision of calculation.  |
**Recursive** | **boolean** | Indicates whether calculate the dependent cells recursively when calculating one cell and it depends on other cells.            The default value is true.  |
**CustomEngine** | **AbstractCalculationEngine** | The custom formula calculation engine to extend the default calculation engine of Aspose.Cells.  |
**CalculationMonitor** | **AbstractCalculationMonitor** | The monitor for user to track the progress of formula calculation.  |
**LinkedDataSources** | **ARRAY[Workbook]** | Specifies the data sources for external links used in formulas.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

