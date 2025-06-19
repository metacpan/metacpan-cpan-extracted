# AsposeCellsCloud::Object::WorkbookSettings 

## Load the model package
```perl
use AsposeCellsCloud::Object::WorkbookSettings;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**AutoCompressPictures** | **boolean** | Specifies a boolean value that indicates the application automatically compressed pictures in the workbook.  |
**AutoRecover** | **boolean** | Indicates whether the file is mark for auto-recovery.  |
**BuildVersion** | **string** | Specifies the incremental public release of the application.  |
**CalcMode** | **string** | It specifies whether to calculate formulas manually,            automatically or automatically except for multiple table operations.  |
**CalculationId** | **string** | Specifies the version of the calculation engine used to calculate values in the workbook.  |
**CheckComptiliblity** | **boolean** | Indicates whether check comptiliblity when saving workbook.                         Remarks: The default value is true.              |
**CheckExcelRestriction** | **boolean** | Whether check restriction of excel file when user modify cells related objects.            For example, excel does not allow inputting string value longer than 32K.            When you input a value longer than 32K such as by Cell.PutValue(string), if this property is true, you will get an Exception.            If this property is false, we will accept your input string value as the cell's value so that later            you can output the complete string value for other file formats such as CSV.            However, if you have set such kind of value that is invalid for excel file format,            you should not save the workbook as excel file format later. Otherwise there may be unexpected error for the generated excel file.  |
**CrashSave** | **boolean** | indicates whether the application last saved the workbook file after a crash.  |
**CreateCalcChain** | **boolean** | Whether creates calculated formulas chain. Default is false.  |
**DataExtractLoad** | **boolean** | indicates whether the application last opened the workbook for data recovery.  |
**Date1904** | **boolean** | Gets or sets a value which represents if the workbook uses the 1904 date system.  |
**DisplayDrawingObjects** | **string** | Indicates whether and how to show objects in the workbook.  |
**EnableMacros** | **boolean** | Enable macros;  |
**FirstVisibleTab** | **int** | Gets or sets the first visible worksheet tab.  |
**HidePivotFieldList** | **boolean** | Gets and sets whether hide the field list for the PivotTable.  |
**IsDefaultEncrypted** | **boolean** | Indicates whether encrypting the workbook with default password if Structure and Windows of the workbook are locked.  |
**IsHidden** | **boolean** | Indicates whether this workbook is hidden.  |
**IsHScrollBarVisible** | **boolean** | Gets or sets a value indicating whether the generated spreadsheet will contain a horizontal scroll bar.  |
**IsMinimized** | **boolean** | Represents whether the generated spreadsheet will be opened Minimized.  |
**IsVScrollBarVisible** | **boolean** | Gets or sets a value indicating whether the generated spreadsheet will contain a vertical scroll bar.  |
**Iteration** | **boolean** | Indicates whether enable iterative calculation to resolve circular references.  |
**LanguageCode** | **string** | Gets or sets the user interface language of the Workbook version based on CountryCode that has saved the file.  |
**MaxChange** | **double** | Returns or sets the maximum number of change to resolve a circular reference.  |
**MaxIteration** | **int** | Returns or sets the maximum number of iterations to resolve a circular reference.  |
**MemorySetting** | **string** | Gets or sets the memory usage options. The new option will be taken as the default option for newly created worksheets but does not take effect for existing worksheets.  |
**NumberDecimalSeparator** | **string** | Gets or sets the decimal separator for formatting/parsing numeric values. Default is the decimal separator of current Region.  |
**NumberGroupSeparator** | **string** | Gets or sets the character that separates groups of digits to the left of the decimal in numeric values. Default is the group separator of current Region.  |
**ParsingFormulaOnOpen** | **boolean** | Indicates whether parsing the formula when reading the file.  |
**PrecisionAsDisplayed** | **boolean** | True if calculations in this workbook will be done using only the precision of the numbers as they're displayed  |
**RecalculateBeforeSave** | **boolean** | Indicates whether to recalculate before saving the document.  |
**ReCalculateOnOpen** | **boolean** | Indicates whether re-calculate all formulas on opening file.  |
**RecommendReadOnly** | **boolean** | Indicates if the Read Only Recommended option is selected.             |
**Region** | **string** | Gets or sets the regional settings for workbook.  |
**RemovePersonalInformation** | **boolean** | True if personal information can be removed from the specified workbook.  |
**RepairLoad** | **boolean** | Indicates whether the application last opened the workbook in safe or repair mode.  |
**Shared** | **boolean** | Gets or sets a value that indicates whether the Workbook is shared.  |
**SheetTabBarWidth** | **int** | Width of worksheet tab bar (in 1/1000 of window width).  |
**ShowTabs** | **boolean** | Get or sets a value whether the Workbook tabs are displayed.  |
**UpdateAdjacentCellsBorder** | **boolean** | Indicates whether update adjacent cells' border.  |
**UpdateLinksType** | **string** | Gets and sets how updates external links when the workbook is opened.  |
**WindowHeight** | **double** | The height of the window, in unit of point.  |
**WindowLeft** | **double** | The distance from the left edge of the client area to the left edge of the window, in unit of point.  |
**WindowTop** | **double** | The distance from the top edge of the client area to the top edge of the window, in unit of point.  |
**WindowWidth** | **double** | The width of the window, in unit of point.  |
**Author** | **string** | Gets and sets the author of the file.  |
**CheckCustomNumberFormat** | **boolean** | Indicates whether checking custom number format when setting Style.Custom.  |
**ProtectionType** | **string** | Gets the protection type of the workbook.  |
**GlobalizationSettings** | **GlobalizationSettings** | Gets and sets the globalization settings.  |
**Password** | **string** | Represents Workbook file encryption password.  |
**WriteProtection** | **WriteProtection** | Provides access to the workbook write protection options.  |
**IsEncrypted** | **boolean** | Gets a value that indicates whether a password is required to open this workbook.  |
**IsProtected** | **boolean** | Gets a value that indicates whether the structure or window of the Workbook is protected.  |
**MaxRow** | **int** | Gets the max row index, zero-based.  |
**MaxColumn** | **int** | Gets the max column index, zero-based.  |
**SignificantDigits** | **int** | Gets and sets the number of significant digits.            The default value is .  |
**CheckCompatibility** | **boolean** | Indicates whether check compatibility with earlier versions when saving workbook.  |
**PaperSize** | **string** | Gets and sets the default print paper size.  |
**MaxRowsOfSharedFormula** | **int** | Gets and sets the max row number of shared formula.  |
**Compliance** | **string** | Specifies the OOXML version for the output document. The default value is Ecma376_2006.  |
**QuotePrefixToStyle** | **boolean** | Indicates whether setting  property when entering the string value(which starts  with single quote mark ) to the cell  |
**FormulaSettings** | **FormulaSettings** | Gets the settings for formula-related features.  |
**ForceFullCalculate** | **boolean** | Fully calculates every time when a calculation is triggered.  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

