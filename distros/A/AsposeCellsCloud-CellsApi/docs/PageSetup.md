# AsposeCellsCloud::Object::PageSetup

## Load the model package
```perl
use AsposeCellsCloud::Object::PageSetup;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**link** | [**Link**](Link.md) |  | [optional] 
**is_hf_diff_first** | **boolean** | True means that the header/footer of the first page is different with other pages. | [optional] 
**fit_to_pages_wide** | **int** | Represents the number of pages wide the worksheet will be scaled to when it&#39;s printed. | [optional] 
**print_quality** | **int** | Represents the print quality. | [optional] 
**print_draft** | **boolean** | Represents if the sheet will be printed without graphics. | [optional] 
**first_page_number** | **int** | Represents the first page number that will be used when this sheet is printed. | [optional] 
**paper_size** | **string** | Represents the size of the paper. | [optional] 
**print_comments** | **string** | Represents the way comments are printed with the sheet. | [optional] 
**print_errors** | **string** | Specifies the type of print error displayed. | [optional] 
**center_vertically** | **boolean** | Represent if the sheet is printed centered vertically. | [optional] 
**is_percent_scale** | **boolean** | If this property is False, the FitToPagesWide and FitToPagesTall properties control how the worksheet is scaled. | [optional] 
**black_and_white** | **boolean** | Represents if elements of the document will be printed in black and white. True/False | [optional] 
**print_title_columns** | **string** | Represents the columns that contain the cells to be repeated on the left side of each page. | [optional] 
**is_hf_align_margins** | **boolean** | Indicates whether header and footer margins are aligned with the page margins.Only applies for Excel 2007. | [optional] 
**print_area** | **string** | Represents the range to be printed. | [optional] 
**footer_margin** | **double** | Represents the distance from the bottom of the page to the footer, in unit of centimeters. | [optional] 
**left_margin** | **double** | Represents the size of the left margin, in unit of centimeters. | [optional] 
**center_horizontally** | **boolean** | Represent if the sheet is printed centered horizontally. | [optional] 
**header_margin** | **double** | Represents the distance from the top of the page to the header, in unit of centimeters. | [optional] 
**top_margin** | **double** | Represents the size of the top margin, in unit of centimeters. | [optional] 
**footer** | [**ARRAY[PageSection]**](PageSection.md) | Represents the page footor. | [optional] 
**fit_to_pages_tall** | **int** | Represents the number of pages tall the worksheet will be scaled to when it&#39;s printed. | [optional] 
**is_hf_scale_with_doc** | **boolean** | Indicates whether header and footer are scaled with document scaling.Only applies for Excel 2007.  | [optional] 
**print_headings** | **boolean** | Represents if row and column headings are printed with this page. | [optional] 
**zoom** | **int** | Represents the scaling factor in percent. It should be between 10 and 400. | [optional] 
**print_title_rows** | **string** | Represents the rows that contain the cells to be repeated at the top of each page. | [optional] 
**order** | **string** | Represents the order that Microsoft Excel uses to number pages when printing a large worksheet. | [optional] 
**print_copies** | **int** | Get and sets number of copies to print. | [optional] 
**orientation** | **string** | Represents page print orientation. | [optional] 
**right_margin** | **double** | Represents the size of the right margin, in unit of centimeters. | [optional] 
**print_gridlines** | **boolean** | Represents if cell gridlines are printed on the page. | [optional] 
**is_auto_first_page_number** | **boolean** | Indicates whether the first the page number is automatically assigned. | [optional] 
**header** | [**ARRAY[PageSection]**](PageSection.md) | Represents the page header. | [optional] 
**is_hf_diff_odd_even** | **boolean** | True means that the header/footer of the odd pages is different with odd pages. | [optional] 
**bottom_margin** | **double** | Represents the size of the bottom margin, in unit of centimeters. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


