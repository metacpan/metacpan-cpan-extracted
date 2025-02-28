# AsposeCellsCloud::Object::CopyOptions 

## Load the model package
```perl
use AsposeCellsCloud::Object::CopyOptions;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ColumnCharacterWidth** | **boolean** | Indicates whether copying column width in unit of characters.  |
**CopyInvalidFormulasAsValues** | **boolean** | If the formula is not valid for the dest destination, only copy values.  |
**CopyNames** | **boolean** | Indicates whether copying the names.  |
**ExtendToAdjacentRange** | **boolean** | Indicates whether extend ranges when copying the range to adjacent range.  |
**ReferToDestinationSheet** | **boolean** | When copying the range in the same file and the chart refers to the source sheet,            False means the copied chart's data source will not be changed.            True means the copied chart's data source refers to the destination sheet.  |
**ReferToSheetWithSameName** | **boolean** | In ms excel, when copying formulas which refer to other worksheets while copying a worksheet to another one,            the copied formulas should refer to source workbook.            However, for some situations user may need the copied formulas refer to worksheets with the same name            in the same workbook, such as when those worksheets have been copied before this copy operation,            then this property should be kept as true.  |
**CopyTheme** | **boolean** |  |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

