# AsposeCellsCloud::Object::FormulaSettings 

## Load the model package
```perl
use AsposeCellsCloud::Object::FormulaSettings;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**CalculateOnOpen** | **boolean** | Indicates whether the application is required to perform a full calculation when the workbook is opened.  |
**CalculateOnSave** | **boolean** | Indicates whether recalculate the workbook before saving the document, when in manual calculation mode.  |
**ForceFullCalculation** | **boolean** | Indicates whether calculates all formulas every time when a calculation is triggered.  |
**CalculationMode** | **string** | Gets or sets the mode for workbook calculation in ms excel.  |
**CalculationId** | **string** | Specifies the version of the calculation engine used to calculate values in the workbook.  |
**EnableIterativeCalculation** | **boolean** | Indicates whether enable iterative calculation to resolve circular references.  |
**MaxIteration** | **int** | The maximum iterations to resolve a circular reference.  |
**MaxChange** | **double** | The maximum change to resolve a circular reference.  |
**PrecisionAsDisplayed** | **boolean** | Whether the precision of calculated result be set as they are displayed while calculating formulas  |
**EnableCalculationChain** | **boolean** | Whether enable calculation chain for formulas. Default is false.  |
**PreservePaddingSpaces** | **boolean** | Indicates whether preserve those spaces and line breaks that are padded between formula tokens            while getting and setting formulas.            Default value is false.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

