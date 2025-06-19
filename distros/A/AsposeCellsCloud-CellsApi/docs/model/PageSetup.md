# AsposeCellsCloud::Object::PageSetup 

## Load the model package
```perl
use AsposeCellsCloud::Object::PageSetup;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**BlackAndWhite** | **boolean** | Represents if elements of the document will be printed in black and white.  |
**BottomMargin** | **double** | Represents the size of the bottom margin, in unit of centimeters.  |
**CenterHorizontally** | **boolean** | Represent if the sheet is printed centered horizontally.  |
**CenterVertically** | **boolean** | Represent if the sheet is printed centered vertically.  |
**FirstPageNumber** | **int** | Represents the first page number that will be used when this sheet is printed.  |
**FitToPagesTall** | **int** | Represents  the number of pages tall the worksheet will be scaled to when it's printed.            The default value is 1.  |
**FitToPagesWide** | **int** | Represents the number of pages wide the worksheet will be scaled to when it's printed.            The default value is 1.  |
**FooterMargin** | **double** | Represents the distance from the bottom of the page to the footer, in unit of centimeters.  |
**HeaderMargin** | **double** | Represents the distance from the top of the page to the header, in unit of centimeters.  |
**IsAutoFirstPageNumber** | **boolean** | Indicates whether the first the page number is automatically assigned.  |
**IsHFAlignMargins** | **boolean** | Indicates whether header and footer margins are aligned with the page margins.            If this property is true, the left header and footer will be aligned with the left margin,            and the right header and footer will be aligned with the right margin.            This option is enabled by default.  |
**IsHFDiffFirst** | **boolean** | True means that the header/footer of the first page is different with other pages.  |
**IsHFDiffOddEven** | **boolean** | True means that the header/footer of the odd pages is different with odd pages.  |
**IsHFScaleWithDoc** | **boolean** | Indicates whether header and footer are scaled with document scaling.            Only applies for Excel 2007.  |
**IsPercentScale** | **boolean** | If this property is False, the FitToPagesWide and FitToPagesTall properties control how the worksheet is scaled.  |
**LeftMargin** | **double** | Represents the size of the left margin, in unit of centimeters.  |
**Order** | **string** | Represents the order that Microsoft Excel uses to number pages when printing a large worksheet.  |
**Orientation** | **string** | Represents page print orientation.  |
**PaperSize** | **string** | Represents the size of the paper.  |
**PrintArea** | **string** | Represents the range to be printed.  |
**PrintComments** | **string** | Represents the way comments are printed with the sheet.  |
**PrintCopies** | **int** | Get and sets number of copies to print.  |
**PrintDraft** | **boolean** | Represents if the sheet will be printed without graphics.  |
**PrintErrors** | **string** | Specifies the type of print error displayed.  |
**PrintGridlines** | **boolean** | Represents if cell gridlines are printed on the page.  |
**PrintHeadings** | **boolean** | Represents if row and column headings are printed with this page.  |
**PrintQuality** | **int** | Represents the print quality.  |
**PrintTitleColumns** | **string** | Represents the columns that contain the cells to be repeated on the left side of each page.  |
**PrintTitleRows** | **string** | Represents the rows that contain the cells to be repeated at the top of each page.  |
**RightMargin** | **double** | Represents the size of the right margin, in unit of centimeters.  |
**TopMargin** | **double** | Represents the size of the top margin, in unit of centimeters.  |
**Zoom** | **int** | Represents the scaling factor in percent. It should be between 10 and 400.  |
**Header** | **ARRAY[PageSection]** | Represents the page header. |
**Footer** | **ARRAY[PageSection]** | Represents the page footor. |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

