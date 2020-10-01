# AsposeCellsCloud::CellsApi

## Load the API package
```perl
use AsposeCellsCloud::Object::CellsApi;
```

All URIs are relative to *https://api.aspose.cloud/v3.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cells_auto_filter_delete_worksheet_date_filter**](CellsApi.md#cells_auto_filter_delete_worksheet_date_filter) | **DELETE** /cells/{name}/worksheets/{sheetName}/autoFilter/dateFilter | Removes a date filter.             
[**cells_auto_filter_delete_worksheet_filter**](CellsApi.md#cells_auto_filter_delete_worksheet_filter) | **DELETE** /cells/{name}/worksheets/{sheetName}/autoFilter/filter | Delete a filter for a filter column.             
[**cells_auto_filter_get_worksheet_auto_filter**](CellsApi.md#cells_auto_filter_get_worksheet_auto_filter) | **GET** /cells/{name}/worksheets/{sheetName}/autoFilter | Get Auto filter Description
[**cells_auto_filter_post_worksheet_auto_filter_refresh**](CellsApi.md#cells_auto_filter_post_worksheet_auto_filter_refresh) | **POST** /cells/{name}/worksheets/{sheetName}/autoFilter/refresh | 
[**cells_auto_filter_post_worksheet_match_blanks**](CellsApi.md#cells_auto_filter_post_worksheet_match_blanks) | **POST** /cells/{name}/worksheets/{sheetName}/autoFilter/matchBlanks | Match all blank cell in the list.
[**cells_auto_filter_post_worksheet_match_non_blanks**](CellsApi.md#cells_auto_filter_post_worksheet_match_non_blanks) | **POST** /cells/{name}/worksheets/{sheetName}/autoFilter/matchNonBlanks | Match all not blank cell in the list.             
[**cells_auto_filter_put_worksheet_color_filter**](CellsApi.md#cells_auto_filter_put_worksheet_color_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/colorFilter | 
[**cells_auto_filter_put_worksheet_custom_filter**](CellsApi.md#cells_auto_filter_put_worksheet_custom_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/custom | Filters a list with a custom criteria.             
[**cells_auto_filter_put_worksheet_date_filter**](CellsApi.md#cells_auto_filter_put_worksheet_date_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/dateFilter | add date filter in worksheet 
[**cells_auto_filter_put_worksheet_dynamic_filter**](CellsApi.md#cells_auto_filter_put_worksheet_dynamic_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/dynamicFilter | 
[**cells_auto_filter_put_worksheet_filter**](CellsApi.md#cells_auto_filter_put_worksheet_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/filter | Adds a filter for a filter column.             
[**cells_auto_filter_put_worksheet_filter_top10**](CellsApi.md#cells_auto_filter_put_worksheet_filter_top10) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/filterTop10 | Filter the top 10 item in the list
[**cells_auto_filter_put_worksheet_icon_filter**](CellsApi.md#cells_auto_filter_put_worksheet_icon_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/autoFilter/iconFilter | Adds an icon filter.
[**cells_autoshapes_get_worksheet_autoshape**](CellsApi.md#cells_autoshapes_get_worksheet_autoshape) | **GET** /cells/{name}/worksheets/{sheetName}/autoshapes/{autoshapeNumber} | Get autoshape info.
[**cells_autoshapes_get_worksheet_autoshapes**](CellsApi.md#cells_autoshapes_get_worksheet_autoshapes) | **GET** /cells/{name}/worksheets/{sheetName}/autoshapes | Get worksheet autoshapes info.
[**cells_chart_area_get_chart_area**](CellsApi.md#cells_chart_area_get_chart_area) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea | Get chart area info.
[**cells_chart_area_get_chart_area_border**](CellsApi.md#cells_chart_area_get_chart_area_border) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/border | Get chart area border info.
[**cells_chart_area_get_chart_area_fill_format**](CellsApi.md#cells_chart_area_get_chart_area_fill_format) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/chartArea/fillFormat | Get chart area fill format info.
[**cells_charts_delete_worksheet_chart_legend**](CellsApi.md#cells_charts_delete_worksheet_chart_legend) | **DELETE** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend | Hide legend in chart
[**cells_charts_delete_worksheet_chart_title**](CellsApi.md#cells_charts_delete_worksheet_chart_title) | **DELETE** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title | Hide title in chart
[**cells_charts_delete_worksheet_clear_charts**](CellsApi.md#cells_charts_delete_worksheet_clear_charts) | **DELETE** /cells/{name}/worksheets/{sheetName}/charts | Clear the charts.
[**cells_charts_delete_worksheet_delete_chart**](CellsApi.md#cells_charts_delete_worksheet_delete_chart) | **DELETE** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex} | Delete worksheet chart by index.
[**cells_charts_get_worksheet_chart**](CellsApi.md#cells_charts_get_worksheet_chart) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartNumber} | Get chart info.
[**cells_charts_get_worksheet_chart_legend**](CellsApi.md#cells_charts_get_worksheet_chart_legend) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend | Get chart legend
[**cells_charts_get_worksheet_chart_title**](CellsApi.md#cells_charts_get_worksheet_chart_title) | **GET** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title | Get chart title
[**cells_charts_get_worksheet_charts**](CellsApi.md#cells_charts_get_worksheet_charts) | **GET** /cells/{name}/worksheets/{sheetName}/charts | Get worksheet charts info.
[**cells_charts_post_worksheet_chart**](CellsApi.md#cells_charts_post_worksheet_chart) | **POST** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex} | Update chart propreties
[**cells_charts_post_worksheet_chart_legend**](CellsApi.md#cells_charts_post_worksheet_chart_legend) | **POST** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend | Update chart legend
[**cells_charts_post_worksheet_chart_title**](CellsApi.md#cells_charts_post_worksheet_chart_title) | **POST** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title | Update chart title
[**cells_charts_put_worksheet_add_chart**](CellsApi.md#cells_charts_put_worksheet_add_chart) | **PUT** /cells/{name}/worksheets/{sheetName}/charts | Add new chart to worksheet.
[**cells_charts_put_worksheet_chart_legend**](CellsApi.md#cells_charts_put_worksheet_chart_legend) | **PUT** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/legend | Show legend in chart
[**cells_charts_put_worksheet_chart_title**](CellsApi.md#cells_charts_put_worksheet_chart_title) | **PUT** /cells/{name}/worksheets/{sheetName}/charts/{chartIndex}/title | Add chart title / Set chart title visible
[**cells_conditional_formattings_delete_worksheet_conditional_formatting**](CellsApi.md#cells_conditional_formattings_delete_worksheet_conditional_formatting) | **DELETE** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index} | Remove conditional formatting
[**cells_conditional_formattings_delete_worksheet_conditional_formatting_area**](CellsApi.md#cells_conditional_formattings_delete_worksheet_conditional_formatting_area) | **DELETE** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/area | Remove cell area from conditional formatting.
[**cells_conditional_formattings_delete_worksheet_conditional_formattings**](CellsApi.md#cells_conditional_formattings_delete_worksheet_conditional_formattings) | **DELETE** /cells/{name}/worksheets/{sheetName}/conditionalFormattings | Clear all condition formattings
[**cells_conditional_formattings_get_worksheet_conditional_formatting**](CellsApi.md#cells_conditional_formattings_get_worksheet_conditional_formatting) | **GET** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index} | Get conditional formatting
[**cells_conditional_formattings_get_worksheet_conditional_formattings**](CellsApi.md#cells_conditional_formattings_get_worksheet_conditional_formattings) | **GET** /cells/{name}/worksheets/{sheetName}/conditionalFormattings | Get conditional formattings 
[**cells_conditional_formattings_put_worksheet_conditional_formatting**](CellsApi.md#cells_conditional_formattings_put_worksheet_conditional_formatting) | **PUT** /cells/{name}/worksheets/{sheetName}/conditionalFormattings | Add a condition formatting.
[**cells_conditional_formattings_put_worksheet_format_condition**](CellsApi.md#cells_conditional_formattings_put_worksheet_format_condition) | **PUT** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index} | Add a format condition.
[**cells_conditional_formattings_put_worksheet_format_condition_area**](CellsApi.md#cells_conditional_formattings_put_worksheet_format_condition_area) | **PUT** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index}/area | add a cell area for format condition             
[**cells_conditional_formattings_put_worksheet_format_condition_condition**](CellsApi.md#cells_conditional_formattings_put_worksheet_format_condition_condition) | **PUT** /cells/{name}/worksheets/{sheetName}/conditionalFormattings/{index}/condition | Add a condition for format condition.
[**cells_delete_worksheet_columns**](CellsApi.md#cells_delete_worksheet_columns) | **DELETE** /cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex} | Delete worksheet columns.
[**cells_delete_worksheet_row**](CellsApi.md#cells_delete_worksheet_row) | **DELETE** /cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex} | Delete worksheet row.
[**cells_delete_worksheet_rows**](CellsApi.md#cells_delete_worksheet_rows) | **DELETE** /cells/{name}/worksheets/{sheetName}/cells/rows | Delete several worksheet rows.
[**cells_get_cell_html_string**](CellsApi.md#cells_get_cell_html_string) | **GET** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/htmlstring | Read cell data by cell&#39;s name.
[**cells_get_worksheet_cell**](CellsApi.md#cells_get_worksheet_cell) | **GET** /cells/{name}/worksheets/{sheetName}/cells/{cellOrMethodName} | Read cell data by cell&#39;s name.
[**cells_get_worksheet_cell_style**](CellsApi.md#cells_get_worksheet_cell_style) | **GET** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/style | Read cell&#39;s style info.
[**cells_get_worksheet_cells**](CellsApi.md#cells_get_worksheet_cells) | **GET** /cells/{name}/worksheets/{sheetName}/cells | Get cells info.
[**cells_get_worksheet_column**](CellsApi.md#cells_get_worksheet_column) | **GET** /cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex} | Read worksheet column data by column&#39;s index.
[**cells_get_worksheet_columns**](CellsApi.md#cells_get_worksheet_columns) | **GET** /cells/{name}/worksheets/{sheetName}/cells/columns | Read worksheet columns info.
[**cells_get_worksheet_row**](CellsApi.md#cells_get_worksheet_row) | **GET** /cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex} | Read worksheet row data by row&#39;s index.
[**cells_get_worksheet_rows**](CellsApi.md#cells_get_worksheet_rows) | **GET** /cells/{name}/worksheets/{sheetName}/cells/rows | Read worksheet rows info.
[**cells_hypelinks_delete_worksheet_hyperlink**](CellsApi.md#cells_hypelinks_delete_worksheet_hyperlink) | **DELETE** /cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex} | Delete worksheet hyperlink by index.
[**cells_hypelinks_delete_worksheet_hyperlinks**](CellsApi.md#cells_hypelinks_delete_worksheet_hyperlinks) | **DELETE** /cells/{name}/worksheets/{sheetName}/hyperlinks | Delete all hyperlinks in worksheet.
[**cells_hypelinks_get_worksheet_hyperlink**](CellsApi.md#cells_hypelinks_get_worksheet_hyperlink) | **GET** /cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex} | Get worksheet hyperlink by index.
[**cells_hypelinks_get_worksheet_hyperlinks**](CellsApi.md#cells_hypelinks_get_worksheet_hyperlinks) | **GET** /cells/{name}/worksheets/{sheetName}/hyperlinks | Get worksheet hyperlinks.
[**cells_hypelinks_post_worksheet_hyperlink**](CellsApi.md#cells_hypelinks_post_worksheet_hyperlink) | **POST** /cells/{name}/worksheets/{sheetName}/hyperlinks/{hyperlinkIndex} | Update worksheet hyperlink by index.
[**cells_hypelinks_put_worksheet_hyperlink**](CellsApi.md#cells_hypelinks_put_worksheet_hyperlink) | **PUT** /cells/{name}/worksheets/{sheetName}/hyperlinks | Add worksheet hyperlink.
[**cells_list_objects_delete_worksheet_list_object**](CellsApi.md#cells_list_objects_delete_worksheet_list_object) | **DELETE** /cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex} | Delete worksheet list object by index
[**cells_list_objects_delete_worksheet_list_objects**](CellsApi.md#cells_list_objects_delete_worksheet_list_objects) | **DELETE** /cells/{name}/worksheets/{sheetName}/listobjects | Delete worksheet list objects
[**cells_list_objects_get_worksheet_list_object**](CellsApi.md#cells_list_objects_get_worksheet_list_object) | **GET** /cells/{name}/worksheets/{sheetName}/listobjects/{listobjectindex} | Get worksheet list object info by index.
[**cells_list_objects_get_worksheet_list_objects**](CellsApi.md#cells_list_objects_get_worksheet_list_objects) | **GET** /cells/{name}/worksheets/{sheetName}/listobjects | Get worksheet listobjects info.
[**cells_list_objects_post_worksheet_list_object**](CellsApi.md#cells_list_objects_post_worksheet_list_object) | **POST** /cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex} | Update  list object 
[**cells_list_objects_post_worksheet_list_object_convert_to_range**](CellsApi.md#cells_list_objects_post_worksheet_list_object_convert_to_range) | **POST** /cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex}/ConvertToRange | 
[**cells_list_objects_post_worksheet_list_object_sort_table**](CellsApi.md#cells_list_objects_post_worksheet_list_object_sort_table) | **POST** /cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex}/sort | 
[**cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table**](CellsApi.md#cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table) | **POST** /cells/{name}/worksheets/{sheetName}/listobjects/{listObjectIndex}/SummarizeWithPivotTable | 
[**cells_list_objects_put_worksheet_list_object**](CellsApi.md#cells_list_objects_put_worksheet_list_object) | **PUT** /cells/{name}/worksheets/{sheetName}/listobjects | Add a list object into worksheet.
[**cells_ole_objects_delete_worksheet_ole_object**](CellsApi.md#cells_ole_objects_delete_worksheet_ole_object) | **DELETE** /cells/{name}/worksheets/{sheetName}/oleobjects/{oleObjectIndex} | Delete OLE object.
[**cells_ole_objects_delete_worksheet_ole_objects**](CellsApi.md#cells_ole_objects_delete_worksheet_ole_objects) | **DELETE** /cells/{name}/worksheets/{sheetName}/oleobjects | Delete all OLE objects.
[**cells_ole_objects_get_worksheet_ole_object**](CellsApi.md#cells_ole_objects_get_worksheet_ole_object) | **GET** /cells/{name}/worksheets/{sheetName}/oleobjects/{objectNumber} | Get OLE object info.
[**cells_ole_objects_get_worksheet_ole_objects**](CellsApi.md#cells_ole_objects_get_worksheet_ole_objects) | **GET** /cells/{name}/worksheets/{sheetName}/oleobjects | Get worksheet OLE objects info.
[**cells_ole_objects_post_update_worksheet_ole_object**](CellsApi.md#cells_ole_objects_post_update_worksheet_ole_object) | **POST** /cells/{name}/worksheets/{sheetName}/oleobjects/{oleObjectIndex} | Update OLE object.
[**cells_ole_objects_put_worksheet_ole_object**](CellsApi.md#cells_ole_objects_put_worksheet_ole_object) | **PUT** /cells/{name}/worksheets/{sheetName}/oleobjects | Add OLE object
[**cells_page_breaks_delete_horizontal_page_break**](CellsApi.md#cells_page_breaks_delete_horizontal_page_break) | **DELETE** /cells/{name}/worksheets/{sheetName}/horizontalpagebreaks/{index} | 
[**cells_page_breaks_delete_horizontal_page_breaks**](CellsApi.md#cells_page_breaks_delete_horizontal_page_breaks) | **DELETE** /cells/{name}/worksheets/{sheetName}/horizontalpagebreaks | 
[**cells_page_breaks_delete_vertical_page_break**](CellsApi.md#cells_page_breaks_delete_vertical_page_break) | **DELETE** /cells/{name}/worksheets/{sheetName}/verticalpagebreaks/{index} | 
[**cells_page_breaks_delete_vertical_page_breaks**](CellsApi.md#cells_page_breaks_delete_vertical_page_breaks) | **DELETE** /cells/{name}/worksheets/{sheetName}/verticalpagebreaks | 
[**cells_page_breaks_get_horizontal_page_break**](CellsApi.md#cells_page_breaks_get_horizontal_page_break) | **GET** /cells/{name}/worksheets/{sheetName}/horizontalpagebreaks/{index} | 
[**cells_page_breaks_get_horizontal_page_breaks**](CellsApi.md#cells_page_breaks_get_horizontal_page_breaks) | **GET** /cells/{name}/worksheets/{sheetName}/horizontalpagebreaks | 
[**cells_page_breaks_get_vertical_page_break**](CellsApi.md#cells_page_breaks_get_vertical_page_break) | **GET** /cells/{name}/worksheets/{sheetName}/verticalpagebreaks/{index} | 
[**cells_page_breaks_get_vertical_page_breaks**](CellsApi.md#cells_page_breaks_get_vertical_page_breaks) | **GET** /cells/{name}/worksheets/{sheetName}/verticalpagebreaks | 
[**cells_page_breaks_put_horizontal_page_break**](CellsApi.md#cells_page_breaks_put_horizontal_page_break) | **PUT** /cells/{name}/worksheets/{sheetName}/horizontalpagebreaks | 
[**cells_page_breaks_put_vertical_page_break**](CellsApi.md#cells_page_breaks_put_vertical_page_break) | **PUT** /cells/{name}/worksheets/{sheetName}/verticalpagebreaks | 
[**cells_page_setup_delete_header_footer**](CellsApi.md#cells_page_setup_delete_header_footer) | **DELETE** /cells/{name}/worksheets/{sheetName}/pagesetup/clearheaderfooter | clear header footer
[**cells_page_setup_get_footer**](CellsApi.md#cells_page_setup_get_footer) | **GET** /cells/{name}/worksheets/{sheetName}/pagesetup/footer | get page footer information
[**cells_page_setup_get_header**](CellsApi.md#cells_page_setup_get_header) | **GET** /cells/{name}/worksheets/{sheetName}/pagesetup/header | get page header information
[**cells_page_setup_get_page_setup**](CellsApi.md#cells_page_setup_get_page_setup) | **GET** /cells/{name}/worksheets/{sheetName}/pagesetup | Get Page Setup information.             
[**cells_page_setup_post_footer**](CellsApi.md#cells_page_setup_post_footer) | **POST** /cells/{name}/worksheets/{sheetName}/pagesetup/footer | update  page footer information 
[**cells_page_setup_post_header**](CellsApi.md#cells_page_setup_post_header) | **POST** /cells/{name}/worksheets/{sheetName}/pagesetup/header | update  page header information 
[**cells_page_setup_post_page_setup**](CellsApi.md#cells_page_setup_post_page_setup) | **POST** /cells/{name}/worksheets/{sheetName}/pagesetup | Update Page Setup information.
[**cells_pictures_delete_worksheet_picture**](CellsApi.md#cells_pictures_delete_worksheet_picture) | **DELETE** /cells/{name}/worksheets/{sheetName}/pictures/{pictureIndex} | Delete a picture object in worksheet
[**cells_pictures_delete_worksheet_pictures**](CellsApi.md#cells_pictures_delete_worksheet_pictures) | **DELETE** /cells/{name}/worksheets/{sheetName}/pictures | Delete all pictures in worksheet.
[**cells_pictures_get_worksheet_picture**](CellsApi.md#cells_pictures_get_worksheet_picture) | **GET** /cells/{name}/worksheets/{sheetName}/pictures/{pictureIndex} | GRead worksheet picture by number.
[**cells_pictures_get_worksheet_pictures**](CellsApi.md#cells_pictures_get_worksheet_pictures) | **GET** /cells/{name}/worksheets/{sheetName}/pictures | Read worksheet pictures.
[**cells_pictures_post_worksheet_picture**](CellsApi.md#cells_pictures_post_worksheet_picture) | **POST** /cells/{name}/worksheets/{sheetName}/pictures/{pictureIndex} | Update worksheet picture by index.
[**cells_pictures_put_worksheet_add_picture**](CellsApi.md#cells_pictures_put_worksheet_add_picture) | **PUT** /cells/{name}/worksheets/{sheetName}/pictures | Add a new worksheet picture.
[**cells_pivot_tables_delete_pivot_table_field**](CellsApi.md#cells_pivot_tables_delete_pivot_table_field) | **DELETE** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField | Delete pivot field into into pivot table
[**cells_pivot_tables_delete_worksheet_pivot_table**](CellsApi.md#cells_pivot_tables_delete_worksheet_pivot_table) | **DELETE** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex} | Delete worksheet pivot table by index
[**cells_pivot_tables_delete_worksheet_pivot_table_filter**](CellsApi.md#cells_pivot_tables_delete_worksheet_pivot_table_filter) | **DELETE** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters/{fieldIndex} | delete  pivot filter for piovt table             
[**cells_pivot_tables_delete_worksheet_pivot_table_filters**](CellsApi.md#cells_pivot_tables_delete_worksheet_pivot_table_filters) | **DELETE** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters | delete all pivot filters for piovt table
[**cells_pivot_tables_delete_worksheet_pivot_tables**](CellsApi.md#cells_pivot_tables_delete_worksheet_pivot_tables) | **DELETE** /cells/{name}/worksheets/{sheetName}/pivottables | Delete worksheet pivot tables
[**cells_pivot_tables_get_pivot_table_field**](CellsApi.md#cells_pivot_tables_get_pivot_table_field) | **GET** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField | Get pivot field into into pivot table
[**cells_pivot_tables_get_worksheet_pivot_table**](CellsApi.md#cells_pivot_tables_get_worksheet_pivot_table) | **GET** /cells/{name}/worksheets/{sheetName}/pivottables/{pivottableIndex} | Get worksheet pivottable info by index.
[**cells_pivot_tables_get_worksheet_pivot_table_filter**](CellsApi.md#cells_pivot_tables_get_worksheet_pivot_table_filter) | **GET** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters/{filterIndex} | 
[**cells_pivot_tables_get_worksheet_pivot_table_filters**](CellsApi.md#cells_pivot_tables_get_worksheet_pivot_table_filters) | **GET** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters | 
[**cells_pivot_tables_get_worksheet_pivot_tables**](CellsApi.md#cells_pivot_tables_get_worksheet_pivot_tables) | **GET** /cells/{name}/worksheets/{sheetName}/pivottables | Get worksheet pivottables info.
[**cells_pivot_tables_post_pivot_table_cell_style**](CellsApi.md#cells_pivot_tables_post_pivot_table_cell_style) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/Format | Update cell style for pivot table
[**cells_pivot_tables_post_pivot_table_field_hide_item**](CellsApi.md#cells_pivot_tables_post_pivot_table_field_hide_item) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/Hide | 
[**cells_pivot_tables_post_pivot_table_field_move_to**](CellsApi.md#cells_pivot_tables_post_pivot_table_field_move_to) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField/Move | 
[**cells_pivot_tables_post_pivot_table_style**](CellsApi.md#cells_pivot_tables_post_pivot_table_style) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/FormatAll | Update style for pivot table
[**cells_pivot_tables_post_pivot_table_update_pivot_field**](CellsApi.md#cells_pivot_tables_post_pivot_table_update_pivot_field) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFields/{pivotFieldIndex} | 
[**cells_pivot_tables_post_pivot_table_update_pivot_fields**](CellsApi.md#cells_pivot_tables_post_pivot_table_update_pivot_fields) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFields | 
[**cells_pivot_tables_post_worksheet_pivot_table_calculate**](CellsApi.md#cells_pivot_tables_post_worksheet_pivot_table_calculate) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/Calculate | Calculates pivottable&#39;s data to cells.
[**cells_pivot_tables_post_worksheet_pivot_table_move**](CellsApi.md#cells_pivot_tables_post_worksheet_pivot_table_move) | **POST** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/Move | 
[**cells_pivot_tables_put_pivot_table_field**](CellsApi.md#cells_pivot_tables_put_pivot_table_field) | **PUT** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotField | Add pivot field into into pivot table
[**cells_pivot_tables_put_worksheet_pivot_table**](CellsApi.md#cells_pivot_tables_put_worksheet_pivot_table) | **PUT** /cells/{name}/worksheets/{sheetName}/pivottables | Add a pivot table into worksheet.
[**cells_pivot_tables_put_worksheet_pivot_table_filter**](CellsApi.md#cells_pivot_tables_put_worksheet_pivot_table_filter) | **PUT** /cells/{name}/worksheets/{sheetName}/pivottables/{pivotTableIndex}/PivotFilters | Add pivot filter for piovt table index
[**cells_post_cell_calculate**](CellsApi.md#cells_post_cell_calculate) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/calculate | Cell calculate formula
[**cells_post_cell_characters**](CellsApi.md#cells_post_cell_characters) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/characters | Set cell characters 
[**cells_post_clear_contents**](CellsApi.md#cells_post_clear_contents) | **POST** /cells/{name}/worksheets/{sheetName}/cells/clearcontents | Clear cells contents.
[**cells_post_clear_formats**](CellsApi.md#cells_post_clear_formats) | **POST** /cells/{name}/worksheets/{sheetName}/cells/clearformats | Clear cells contents.
[**cells_post_column_style**](CellsApi.md#cells_post_column_style) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex}/style | Set column style
[**cells_post_copy_cell_into_cell**](CellsApi.md#cells_post_copy_cell_into_cell) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{destCellName}/copy | Copy cell into cell
[**cells_post_copy_worksheet_columns**](CellsApi.md#cells_post_copy_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/copy | Copy worksheet columns.
[**cells_post_copy_worksheet_rows**](CellsApi.md#cells_post_copy_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/copy | Copy worksheet rows.
[**cells_post_group_worksheet_columns**](CellsApi.md#cells_post_group_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/group | Group worksheet columns.
[**cells_post_group_worksheet_rows**](CellsApi.md#cells_post_group_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/group | Group worksheet rows.
[**cells_post_hide_worksheet_columns**](CellsApi.md#cells_post_hide_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/hide | Hide worksheet columns.
[**cells_post_hide_worksheet_rows**](CellsApi.md#cells_post_hide_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/hide | Hide worksheet rows.
[**cells_post_row_style**](CellsApi.md#cells_post_row_style) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex}/style | Set row style.
[**cells_post_set_cell_html_string**](CellsApi.md#cells_post_set_cell_html_string) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/htmlstring | Set htmlstring value into cell
[**cells_post_set_cell_range_value**](CellsApi.md#cells_post_set_cell_range_value) | **POST** /cells/{name}/worksheets/{sheetName}/cells | Set cell range value 
[**cells_post_set_worksheet_column_width**](CellsApi.md#cells_post_set_worksheet_column_width) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex} | Set worksheet column width.
[**cells_post_ungroup_worksheet_columns**](CellsApi.md#cells_post_ungroup_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/ungroup | Ungroup worksheet columns.
[**cells_post_ungroup_worksheet_rows**](CellsApi.md#cells_post_ungroup_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/ungroup | Ungroup worksheet rows.
[**cells_post_unhide_worksheet_columns**](CellsApi.md#cells_post_unhide_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/cells/columns/unhide | Unhide worksheet columns.
[**cells_post_unhide_worksheet_rows**](CellsApi.md#cells_post_unhide_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/unhide | Unhide worksheet rows.
[**cells_post_update_worksheet_cell_style**](CellsApi.md#cells_post_update_worksheet_cell_style) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{cellName}/style | Update cell&#39;s style.
[**cells_post_update_worksheet_range_style**](CellsApi.md#cells_post_update_worksheet_range_style) | **POST** /cells/{name}/worksheets/{sheetName}/cells/style | Update cell&#39;s range style.
[**cells_post_update_worksheet_row**](CellsApi.md#cells_post_update_worksheet_row) | **POST** /cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex} | Update worksheet row.
[**cells_post_worksheet_cell_set_value**](CellsApi.md#cells_post_worksheet_cell_set_value) | **POST** /cells/{name}/worksheets/{sheetName}/cells/{cellName} | Set cell value.
[**cells_post_worksheet_merge**](CellsApi.md#cells_post_worksheet_merge) | **POST** /cells/{name}/worksheets/{sheetName}/cells/merge | Merge cells.
[**cells_post_worksheet_unmerge**](CellsApi.md#cells_post_worksheet_unmerge) | **POST** /cells/{name}/worksheets/{sheetName}/cells/unmerge | Unmerge cells.
[**cells_properties_delete_document_properties**](CellsApi.md#cells_properties_delete_document_properties) | **DELETE** /cells/{name}/documentproperties | Delete all custom document properties and clean built-in ones.
[**cells_properties_delete_document_property**](CellsApi.md#cells_properties_delete_document_property) | **DELETE** /cells/{name}/documentproperties/{propertyName} | Delete document property.
[**cells_properties_get_document_properties**](CellsApi.md#cells_properties_get_document_properties) | **GET** /cells/{name}/documentproperties | Read document properties.
[**cells_properties_get_document_property**](CellsApi.md#cells_properties_get_document_property) | **GET** /cells/{name}/documentproperties/{propertyName} | Read document property by name.
[**cells_properties_put_document_property**](CellsApi.md#cells_properties_put_document_property) | **PUT** /cells/{name}/documentproperties/{propertyName} | Set/create document property.
[**cells_put_insert_worksheet_columns**](CellsApi.md#cells_put_insert_worksheet_columns) | **PUT** /cells/{name}/worksheets/{sheetName}/cells/columns/{columnIndex} | Insert worksheet columns.
[**cells_put_insert_worksheet_row**](CellsApi.md#cells_put_insert_worksheet_row) | **PUT** /cells/{name}/worksheets/{sheetName}/cells/rows/{rowIndex} | Insert new worksheet row.
[**cells_put_insert_worksheet_rows**](CellsApi.md#cells_put_insert_worksheet_rows) | **PUT** /cells/{name}/worksheets/{sheetName}/cells/rows | Insert several new worksheet rows.
[**cells_ranges_get_worksheet_cells_range_value**](CellsApi.md#cells_ranges_get_worksheet_cells_range_value) | **GET** /cells/{name}/worksheets/{sheetName}/ranges/value | Get cells list in a range by range name or row column indexes  
[**cells_ranges_post_worksheet_cells_range_column_width**](CellsApi.md#cells_ranges_post_worksheet_cells_range_column_width) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/columnWidth | Set column width of range
[**cells_ranges_post_worksheet_cells_range_merge**](CellsApi.md#cells_ranges_post_worksheet_cells_range_merge) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/merge | Combines a range of cells into a single cell.              
[**cells_ranges_post_worksheet_cells_range_move_to**](CellsApi.md#cells_ranges_post_worksheet_cells_range_move_to) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/moveto | Move the current range to the dest range.             
[**cells_ranges_post_worksheet_cells_range_outline_border**](CellsApi.md#cells_ranges_post_worksheet_cells_range_outline_border) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/outlineBorder | Sets outline border around a range of cells.
[**cells_ranges_post_worksheet_cells_range_row_height**](CellsApi.md#cells_ranges_post_worksheet_cells_range_row_height) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/rowHeight | set row height of range
[**cells_ranges_post_worksheet_cells_range_style**](CellsApi.md#cells_ranges_post_worksheet_cells_range_style) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/style | Sets the style of the range.             
[**cells_ranges_post_worksheet_cells_range_unmerge**](CellsApi.md#cells_ranges_post_worksheet_cells_range_unmerge) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/unmerge | Unmerges merged cells of this range.             
[**cells_ranges_post_worksheet_cells_range_value**](CellsApi.md#cells_ranges_post_worksheet_cells_range_value) | **POST** /cells/{name}/worksheets/{sheetName}/ranges/value | Puts a value into the range, if appropriate the value will be converted to other data type and cell&#39;s number format will be reset.             
[**cells_ranges_post_worksheet_cells_ranges**](CellsApi.md#cells_ranges_post_worksheet_cells_ranges) | **POST** /cells/{name}/worksheets/{sheetName}/ranges | copy range in the worksheet
[**cells_save_as_post_document_save_as**](CellsApi.md#cells_save_as_post_document_save_as) | **POST** /cells/{name}/SaveAs | Convert document and save result to storage.
[**cells_shapes_delete_worksheet_shape**](CellsApi.md#cells_shapes_delete_worksheet_shape) | **DELETE** /cells/{name}/worksheets/{sheetName}/shapes/{shapeindex} | Delete a shape in worksheet
[**cells_shapes_delete_worksheet_shapes**](CellsApi.md#cells_shapes_delete_worksheet_shapes) | **DELETE** /cells/{name}/worksheets/{sheetName}/shapes | delete all shapes in worksheet
[**cells_shapes_get_worksheet_shape**](CellsApi.md#cells_shapes_get_worksheet_shape) | **GET** /cells/{name}/worksheets/{sheetName}/shapes/{shapeindex} | Get worksheet shape
[**cells_shapes_get_worksheet_shapes**](CellsApi.md#cells_shapes_get_worksheet_shapes) | **GET** /cells/{name}/worksheets/{sheetName}/shapes | Get worksheet shapes 
[**cells_shapes_post_worksheet_shape**](CellsApi.md#cells_shapes_post_worksheet_shape) | **POST** /cells/{name}/worksheets/{sheetName}/shapes/{shapeindex} | Update a shape in worksheet
[**cells_shapes_put_worksheet_shape**](CellsApi.md#cells_shapes_put_worksheet_shape) | **PUT** /cells/{name}/worksheets/{sheetName}/shapes | Add shape in worksheet
[**cells_sparkline_groups_delete_worksheet_sparkline_group**](CellsApi.md#cells_sparkline_groups_delete_worksheet_sparkline_group) | **DELETE** /cells/{name}/worksheets/{sheetName}/sparklinegroups/{sparklineIndex} | 
[**cells_sparkline_groups_delete_worksheet_sparkline_groups**](CellsApi.md#cells_sparkline_groups_delete_worksheet_sparkline_groups) | **DELETE** /cells/{name}/worksheets/{sheetName}/sparklinegroups | 
[**cells_sparkline_groups_get_worksheet_sparkline_group**](CellsApi.md#cells_sparkline_groups_get_worksheet_sparkline_group) | **GET** /cells/{name}/worksheets/{sheetName}/sparklinegroups/{sparklineIndex} | 
[**cells_sparkline_groups_get_worksheet_sparkline_groups**](CellsApi.md#cells_sparkline_groups_get_worksheet_sparkline_groups) | **GET** /cells/{name}/worksheets/{sheetName}/sparklinegroups | Get worksheet charts description.
[**cells_sparkline_groups_post_worksheet_sparkline_group**](CellsApi.md#cells_sparkline_groups_post_worksheet_sparkline_group) | **POST** /cells/{name}/worksheets/{sheetName}/sparklinegroups/{sparklineIndex} | 
[**cells_sparkline_groups_put_worksheet_sparkline_group**](CellsApi.md#cells_sparkline_groups_put_worksheet_sparkline_group) | **PUT** /cells/{name}/worksheets/{sheetName}/sparklinegroups | 
[**cells_task_post_run_task**](CellsApi.md#cells_task_post_run_task) | **POST** /cells/task/runtask | Run tasks  
[**cells_workbook_delete_decrypt_document**](CellsApi.md#cells_workbook_delete_decrypt_document) | **DELETE** /cells/{name}/encryption | Decrypt document.
[**cells_workbook_delete_document_unprotect_from_changes**](CellsApi.md#cells_workbook_delete_document_unprotect_from_changes) | **DELETE** /cells/{name}/writeProtection | Unprotect document from changes.
[**cells_workbook_delete_unprotect_document**](CellsApi.md#cells_workbook_delete_unprotect_document) | **DELETE** /cells/{name}/protection | Unprotect document.
[**cells_workbook_delete_workbook_background**](CellsApi.md#cells_workbook_delete_workbook_background) | **DELETE** /cells/{name}/background | Set worksheet background image.
[**cells_workbook_delete_workbook_name**](CellsApi.md#cells_workbook_delete_workbook_name) | **DELETE** /cells/{name}/names/{nameName} | Clean workbook&#39;s names.
[**cells_workbook_delete_workbook_names**](CellsApi.md#cells_workbook_delete_workbook_names) | **DELETE** /cells/{name}/names | Clean workbook&#39;s names.
[**cells_workbook_get_workbook**](CellsApi.md#cells_workbook_get_workbook) | **GET** /cells/{name} | Read workbook info or export.
[**cells_workbook_get_workbook_default_style**](CellsApi.md#cells_workbook_get_workbook_default_style) | **GET** /cells/{name}/defaultstyle | Read workbook default style info.
[**cells_workbook_get_workbook_name**](CellsApi.md#cells_workbook_get_workbook_name) | **GET** /cells/{name}/names/{nameName} | Read workbook&#39;s name.
[**cells_workbook_get_workbook_name_value**](CellsApi.md#cells_workbook_get_workbook_name_value) | **GET** /cells/{name}/names/{nameName}/value | Get workbook&#39;s name value.
[**cells_workbook_get_workbook_names**](CellsApi.md#cells_workbook_get_workbook_names) | **GET** /cells/{name}/names | Read workbook&#39;s names.
[**cells_workbook_get_workbook_settings**](CellsApi.md#cells_workbook_get_workbook_settings) | **GET** /cells/{name}/settings | Get Workbook Settings DTO
[**cells_workbook_get_workbook_text_items**](CellsApi.md#cells_workbook_get_workbook_text_items) | **GET** /cells/{name}/textItems | Read workbook&#39;s text items.
[**cells_workbook_post_autofit_workbook_rows**](CellsApi.md#cells_workbook_post_autofit_workbook_rows) | **POST** /cells/{name}/autofitrows | Autofit workbook rows.
[**cells_workbook_post_encrypt_document**](CellsApi.md#cells_workbook_post_encrypt_document) | **POST** /cells/{name}/encryption | Encript document.
[**cells_workbook_post_import_data**](CellsApi.md#cells_workbook_post_import_data) | **POST** /cells/{name}/importdata | 
[**cells_workbook_post_protect_document**](CellsApi.md#cells_workbook_post_protect_document) | **POST** /cells/{name}/protection | Protect document.
[**cells_workbook_post_workbook_calculate_formula**](CellsApi.md#cells_workbook_post_workbook_calculate_formula) | **POST** /cells/{name}/calculateformula | Calculate all formulas in workbook.
[**cells_workbook_post_workbook_get_smart_marker_result**](CellsApi.md#cells_workbook_post_workbook_get_smart_marker_result) | **POST** /cells/{name}/smartmarker | Smart marker processing result.
[**cells_workbook_post_workbook_settings**](CellsApi.md#cells_workbook_post_workbook_settings) | **POST** /cells/{name}/settings | Update Workbook setting 
[**cells_workbook_post_workbook_split**](CellsApi.md#cells_workbook_post_workbook_split) | **POST** /cells/{name}/split | Split workbook.
[**cells_workbook_post_workbooks_merge**](CellsApi.md#cells_workbook_post_workbooks_merge) | **POST** /cells/{name}/merge | Merge workbooks.
[**cells_workbook_post_workbooks_text_replace**](CellsApi.md#cells_workbook_post_workbooks_text_replace) | **POST** /cells/{name}/replaceText | Replace text.
[**cells_workbook_post_workbooks_text_search**](CellsApi.md#cells_workbook_post_workbooks_text_search) | **POST** /cells/{name}/findText | Search text.
[**cells_workbook_put_convert_workbook**](CellsApi.md#cells_workbook_put_convert_workbook) | **PUT** /cells/convert | Convert workbook from request content to some format.
[**cells_workbook_put_document_protect_from_changes**](CellsApi.md#cells_workbook_put_document_protect_from_changes) | **PUT** /cells/{name}/writeProtection | Protect document from changes.
[**cells_workbook_put_workbook_background**](CellsApi.md#cells_workbook_put_workbook_background) | **PUT** /cells/{name}/background | Set workbook background image.
[**cells_workbook_put_workbook_create**](CellsApi.md#cells_workbook_put_workbook_create) | **PUT** /cells/{name} | Create new workbook using deferent methods.
[**cells_workbook_put_workbook_water_marker**](CellsApi.md#cells_workbook_put_workbook_water_marker) | **PUT** /cells/{name}/watermarker | Set workbook background image.
[**cells_worksheet_validations_delete_worksheet_validation**](CellsApi.md#cells_worksheet_validations_delete_worksheet_validation) | **DELETE** /cells/{name}/worksheets/{sheetName}/validations/{validationIndex} | Delete worksheet validation by index.
[**cells_worksheet_validations_delete_worksheet_validations**](CellsApi.md#cells_worksheet_validations_delete_worksheet_validations) | **DELETE** /cells/{name}/worksheets/{sheetName}/validations | Clear all validation in worksheet.
[**cells_worksheet_validations_get_worksheet_validation**](CellsApi.md#cells_worksheet_validations_get_worksheet_validation) | **GET** /cells/{name}/worksheets/{sheetName}/validations/{validationIndex} | Get worksheet validation by index.
[**cells_worksheet_validations_get_worksheet_validations**](CellsApi.md#cells_worksheet_validations_get_worksheet_validations) | **GET** /cells/{name}/worksheets/{sheetName}/validations | Get worksheet validations.
[**cells_worksheet_validations_post_worksheet_validation**](CellsApi.md#cells_worksheet_validations_post_worksheet_validation) | **POST** /cells/{name}/worksheets/{sheetName}/validations/{validationIndex} | Update worksheet validation by index.
[**cells_worksheet_validations_put_worksheet_validation**](CellsApi.md#cells_worksheet_validations_put_worksheet_validation) | **PUT** /cells/{name}/worksheets/{sheetName}/validations | Add worksheet validation at index.
[**cells_worksheets_delete_unprotect_worksheet**](CellsApi.md#cells_worksheets_delete_unprotect_worksheet) | **DELETE** /cells/{name}/worksheets/{sheetName}/protection | Unprotect worksheet.
[**cells_worksheets_delete_worksheet**](CellsApi.md#cells_worksheets_delete_worksheet) | **DELETE** /cells/{name}/worksheets/{sheetName} | Delete worksheet.
[**cells_worksheets_delete_worksheet_background**](CellsApi.md#cells_worksheets_delete_worksheet_background) | **DELETE** /cells/{name}/worksheets/{sheetName}/background | Set worksheet background image.
[**cells_worksheets_delete_worksheet_comment**](CellsApi.md#cells_worksheets_delete_worksheet_comment) | **DELETE** /cells/{name}/worksheets/{sheetName}/comments/{cellName} | Delete worksheet&#39;s cell comment.
[**cells_worksheets_delete_worksheet_comments**](CellsApi.md#cells_worksheets_delete_worksheet_comments) | **DELETE** /cells/{name}/worksheets/{sheetName}/comments | Delete all comments for worksheet.
[**cells_worksheets_delete_worksheet_freeze_panes**](CellsApi.md#cells_worksheets_delete_worksheet_freeze_panes) | **DELETE** /cells/{name}/worksheets/{sheetName}/freezepanes | Unfreeze panes
[**cells_worksheets_get_named_ranges**](CellsApi.md#cells_worksheets_get_named_ranges) | **GET** /cells/{name}/worksheets/ranges | Read worksheets ranges info.
[**cells_worksheets_get_worksheet**](CellsApi.md#cells_worksheets_get_worksheet) | **GET** /cells/{name}/worksheets/{sheetName} | Read worksheet info or export.
[**cells_worksheets_get_worksheet_calculate_formula**](CellsApi.md#cells_worksheets_get_worksheet_calculate_formula) | **GET** /cells/{name}/worksheets/{sheetName}/formulaResult | Calculate formula value.
[**cells_worksheets_get_worksheet_comment**](CellsApi.md#cells_worksheets_get_worksheet_comment) | **GET** /cells/{name}/worksheets/{sheetName}/comments/{cellName} | Get worksheet comment by cell name.
[**cells_worksheets_get_worksheet_comments**](CellsApi.md#cells_worksheets_get_worksheet_comments) | **GET** /cells/{name}/worksheets/{sheetName}/comments | Get worksheet comments.
[**cells_worksheets_get_worksheet_merged_cell**](CellsApi.md#cells_worksheets_get_worksheet_merged_cell) | **GET** /cells/{name}/worksheets/{sheetName}/mergedCells/{mergedCellIndex} | Get worksheet merged cell by its index.
[**cells_worksheets_get_worksheet_merged_cells**](CellsApi.md#cells_worksheets_get_worksheet_merged_cells) | **GET** /cells/{name}/worksheets/{sheetName}/mergedCells | Get worksheet merged cells.
[**cells_worksheets_get_worksheet_text_items**](CellsApi.md#cells_worksheets_get_worksheet_text_items) | **GET** /cells/{name}/worksheets/{sheetName}/textItems | Get worksheet text items.
[**cells_worksheets_get_worksheets**](CellsApi.md#cells_worksheets_get_worksheets) | **GET** /cells/{name}/worksheets | Read worksheets info.
[**cells_worksheets_post_autofit_worksheet_columns**](CellsApi.md#cells_worksheets_post_autofit_worksheet_columns) | **POST** /cells/{name}/worksheets/{sheetName}/autofitcolumns | 
[**cells_worksheets_post_autofit_worksheet_row**](CellsApi.md#cells_worksheets_post_autofit_worksheet_row) | **POST** /cells/{name}/worksheets/{sheetName}/autofitrow | 
[**cells_worksheets_post_autofit_worksheet_rows**](CellsApi.md#cells_worksheets_post_autofit_worksheet_rows) | **POST** /cells/{name}/worksheets/{sheetName}/autofitrows | Autofit worksheet rows.
[**cells_worksheets_post_copy_worksheet**](CellsApi.md#cells_worksheets_post_copy_worksheet) | **POST** /cells/{name}/worksheets/{sheetName}/copy | 
[**cells_worksheets_post_move_worksheet**](CellsApi.md#cells_worksheets_post_move_worksheet) | **POST** /cells/{name}/worksheets/{sheetName}/position | Move worksheet.
[**cells_worksheets_post_rename_worksheet**](CellsApi.md#cells_worksheets_post_rename_worksheet) | **POST** /cells/{name}/worksheets/{sheetName}/rename | Rename worksheet
[**cells_worksheets_post_update_worksheet_property**](CellsApi.md#cells_worksheets_post_update_worksheet_property) | **POST** /cells/{name}/worksheets/{sheetName} | Update worksheet property
[**cells_worksheets_post_update_worksheet_zoom**](CellsApi.md#cells_worksheets_post_update_worksheet_zoom) | **POST** /cells/{name}/worksheets/{sheetName}/zoom | 
[**cells_worksheets_post_worksheet_comment**](CellsApi.md#cells_worksheets_post_worksheet_comment) | **POST** /cells/{name}/worksheets/{sheetName}/comments/{cellName} | Update worksheet&#39;s cell comment.
[**cells_worksheets_post_worksheet_range_sort**](CellsApi.md#cells_worksheets_post_worksheet_range_sort) | **POST** /cells/{name}/worksheets/{sheetName}/sort | Sort worksheet range.
[**cells_worksheets_post_worksheet_text_search**](CellsApi.md#cells_worksheets_post_worksheet_text_search) | **POST** /cells/{name}/worksheets/{sheetName}/findText | Search text.
[**cells_worksheets_post_worsheet_text_replace**](CellsApi.md#cells_worksheets_post_worsheet_text_replace) | **POST** /cells/{name}/worksheets/{sheetName}/replaceText | Replace text.
[**cells_worksheets_put_add_new_worksheet**](CellsApi.md#cells_worksheets_put_add_new_worksheet) | **PUT** /cells/{name}/worksheets/{sheetName} | Add new worksheet.
[**cells_worksheets_put_change_visibility_worksheet**](CellsApi.md#cells_worksheets_put_change_visibility_worksheet) | **PUT** /cells/{name}/worksheets/{sheetName}/visible | Change worksheet visibility.
[**cells_worksheets_put_protect_worksheet**](CellsApi.md#cells_worksheets_put_protect_worksheet) | **PUT** /cells/{name}/worksheets/{sheetName}/protection | Protect worksheet.
[**cells_worksheets_put_worksheet_background**](CellsApi.md#cells_worksheets_put_worksheet_background) | **PUT** /cells/{name}/worksheets/{sheetName}/background | Set worksheet background image.
[**cells_worksheets_put_worksheet_comment**](CellsApi.md#cells_worksheets_put_worksheet_comment) | **PUT** /cells/{name}/worksheets/{sheetName}/comments/{cellName} | Add worksheet&#39;s cell comment.
[**cells_worksheets_put_worksheet_freeze_panes**](CellsApi.md#cells_worksheets_put_worksheet_freeze_panes) | **PUT** /cells/{name}/worksheets/{sheetName}/freezepanes | Set freeze panes
[**copy_file**](CellsApi.md#copy_file) | **PUT** /cells/storage/file/copy/{srcPath} | Copy file
[**copy_folder**](CellsApi.md#copy_folder) | **PUT** /cells/storage/folder/copy/{srcPath} | Copy folder
[**create_folder**](CellsApi.md#create_folder) | **PUT** /cells/storage/folder/{path} | Create the folder
[**delete_file**](CellsApi.md#delete_file) | **DELETE** /cells/storage/file/{path} | Delete file
[**delete_folder**](CellsApi.md#delete_folder) | **DELETE** /cells/storage/folder/{path} | Delete folder
[**download_file**](CellsApi.md#download_file) | **GET** /cells/storage/file/{path} | Download file
[**get_disc_usage**](CellsApi.md#get_disc_usage) | **GET** /cells/storage/disc | Get disc usage
[**get_file_versions**](CellsApi.md#get_file_versions) | **GET** /cells/storage/version/{path} | Get file versions
[**get_files_list**](CellsApi.md#get_files_list) | **GET** /cells/storage/folder/{path} | Get all files and folders within a folder
[**move_file**](CellsApi.md#move_file) | **PUT** /cells/storage/file/move/{srcPath} | Move file
[**move_folder**](CellsApi.md#move_folder) | **PUT** /cells/storage/folder/move/{srcPath} | Move folder
[**o_auth_post**](CellsApi.md#o_auth_post) | **POST** /connect/token | Get Access token
[**object_exists**](CellsApi.md#object_exists) | **GET** /cells/storage/exist/{path} | Check if file or folder exists
[**storage_exists**](CellsApi.md#storage_exists) | **GET** /cells/storage/{storageName}/exist | Check if storage exists
[**upload_file**](CellsApi.md#upload_file) | **PUT** /cells/storage/file/{path} | Upload file


# **cells_auto_filter_delete_worksheet_date_filter**
> CellsCloudResponse cells_auto_filter_delete_worksheet_date_filter(name => $name, sheet_name => $sheet_name, field_index => $field_index, date_time_grouping_type => $date_time_grouping_type, year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second, folder => $folder, storage_name => $storage_name)

Removes a date filter.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $field_index = 56; # int | 
my $date_time_grouping_type = 'date_time_grouping_type_example'; # string | 
my $year = 56; # int | 
my $month = 56; # int | 
my $day = 56; # int | 
my $hour = 56; # int | 
my $minute = 56; # int | 
my $second = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_delete_worksheet_date_filter(name => $name, sheet_name => $sheet_name, field_index => $field_index, date_time_grouping_type => $date_time_grouping_type, year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_delete_worksheet_date_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **field_index** | **int**|  | 
 **date_time_grouping_type** | **string**|  | 
 **year** | **int**|  | [optional] [default to 0]
 **month** | **int**|  | [optional] [default to 0]
 **day** | **int**|  | [optional] [default to 0]
 **hour** | **int**|  | [optional] [default to 0]
 **minute** | **int**|  | [optional] [default to 0]
 **second** | **int**|  | [optional] [default to 0]
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_delete_worksheet_filter**
> CellsCloudResponse cells_auto_filter_delete_worksheet_filter(name => $name, sheet_name => $sheet_name, field_index => $field_index, criteria => $criteria, folder => $folder, storage_name => $storage_name)

Delete a filter for a filter column.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $field_index = 56; # int | 
my $criteria = 'criteria_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_delete_worksheet_filter(name => $name, sheet_name => $sheet_name, field_index => $field_index, criteria => $criteria, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_delete_worksheet_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **field_index** | **int**|  | 
 **criteria** | **string**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_get_worksheet_auto_filter**
> AutoFilterResponse cells_auto_filter_get_worksheet_auto_filter(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get Auto filter Description

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_get_worksheet_auto_filter(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_get_worksheet_auto_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**AutoFilterResponse**](AutoFilterResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_post_worksheet_auto_filter_refresh**
> CellsCloudResponse cells_auto_filter_post_worksheet_auto_filter_refresh(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_post_worksheet_auto_filter_refresh(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_post_worksheet_auto_filter_refresh: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_post_worksheet_match_blanks**
> CellsCloudResponse cells_auto_filter_post_worksheet_match_blanks(name => $name, sheet_name => $sheet_name, field_index => $field_index, folder => $folder, storage_name => $storage_name)

Match all blank cell in the list.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $field_index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_post_worksheet_match_blanks(name => $name, sheet_name => $sheet_name, field_index => $field_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_post_worksheet_match_blanks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **field_index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_post_worksheet_match_non_blanks**
> CellsCloudResponse cells_auto_filter_post_worksheet_match_non_blanks(name => $name, sheet_name => $sheet_name, field_index => $field_index, folder => $folder, storage_name => $storage_name)

Match all not blank cell in the list.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $field_index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_post_worksheet_match_non_blanks(name => $name, sheet_name => $sheet_name, field_index => $field_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_post_worksheet_match_non_blanks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **field_index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_color_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_color_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, color_filter => $color_filter, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $color_filter = AsposeCellsCloud::Object::ColorFilterRequest->new(); # ColorFilterRequest | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_color_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, color_filter => $color_filter, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_color_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **color_filter** | [**ColorFilterRequest**](ColorFilterRequest.md)|  | [optional] 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_custom_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_custom_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, operator_type1 => $operator_type1, criteria1 => $criteria1, is_and => $is_and, operator_type2 => $operator_type2, criteria2 => $criteria2, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)

Filters a list with a custom criteria.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $operator_type1 = 'operator_type1_example'; # string | 
my $criteria1 = 'criteria1_example'; # string | 
my $is_and = 1; # boolean | 
my $operator_type2 = 'operator_type2_example'; # string | 
my $criteria2 = 'criteria2_example'; # string | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_custom_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, operator_type1 => $operator_type1, criteria1 => $criteria1, is_and => $is_and, operator_type2 => $operator_type2, criteria2 => $criteria2, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_custom_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **operator_type1** | **string**|  | 
 **criteria1** | **string**|  | 
 **is_and** | **boolean**|  | [optional] 
 **operator_type2** | **string**|  | [optional] 
 **criteria2** | **string**|  | [optional] 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_date_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_date_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, date_time_grouping_type => $date_time_grouping_type, year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)

add date filter in worksheet 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $date_time_grouping_type = 'date_time_grouping_type_example'; # string | 
my $year = 56; # int | 
my $month = 56; # int | 
my $day = 56; # int | 
my $hour = 56; # int | 
my $minute = 56; # int | 
my $second = 56; # int | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_date_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, date_time_grouping_type => $date_time_grouping_type, year => $year, month => $month, day => $day, hour => $hour, minute => $minute, second => $second, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_date_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **date_time_grouping_type** | **string**|  | 
 **year** | **int**|  | [optional] [default to 0]
 **month** | **int**|  | [optional] [default to 0]
 **day** | **int**|  | [optional] [default to 0]
 **hour** | **int**|  | [optional] [default to 0]
 **minute** | **int**|  | [optional] [default to 0]
 **second** | **int**|  | [optional] [default to 0]
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_dynamic_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_dynamic_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, dynamic_filter_type => $dynamic_filter_type, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $dynamic_filter_type = 'dynamic_filter_type_example'; # string | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_dynamic_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, dynamic_filter_type => $dynamic_filter_type, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_dynamic_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **dynamic_filter_type** | **string**|  | 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, criteria => $criteria, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)

Adds a filter for a filter column.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $criteria = 'criteria_example'; # string | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, criteria => $criteria, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **criteria** | **string**|  | 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_filter_top10**
> CellsCloudResponse cells_auto_filter_put_worksheet_filter_top10(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, is_top => $is_top, is_percent => $is_percent, item_count => $item_count, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)

Filter the top 10 item in the list

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $is_top = 1; # boolean | 
my $is_percent = 1; # boolean | 
my $item_count = 56; # int | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_filter_top10(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, is_top => $is_top, is_percent => $is_percent, item_count => $item_count, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_filter_top10: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **is_top** | **boolean**|  | 
 **is_percent** | **boolean**|  | 
 **item_count** | **int**|  | 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_auto_filter_put_worksheet_icon_filter**
> CellsCloudResponse cells_auto_filter_put_worksheet_icon_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, icon_set_type => $icon_set_type, icon_id => $icon_id, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name)

Adds an icon filter.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $range = 'range_example'; # string | 
my $field_index = 56; # int | 
my $icon_set_type = 'icon_set_type_example'; # string | 
my $icon_id = 56; # int | 
my $match_blanks = 1; # boolean | 
my $refresh = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_auto_filter_put_worksheet_icon_filter(name => $name, sheet_name => $sheet_name, range => $range, field_index => $field_index, icon_set_type => $icon_set_type, icon_id => $icon_id, match_blanks => $match_blanks, refresh => $refresh, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_auto_filter_put_worksheet_icon_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **range** | **string**|  | 
 **field_index** | **int**|  | 
 **icon_set_type** | **string**|  | 
 **icon_id** | **int**|  | 
 **match_blanks** | **boolean**|  | [optional] 
 **refresh** | **boolean**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_autoshapes_get_worksheet_autoshape**
> string cells_autoshapes_get_worksheet_autoshape(name => $name, sheet_name => $sheet_name, autoshape_number => $autoshape_number, format => $format, folder => $folder, storage_name => $storage_name)

Get autoshape info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $autoshape_number = 56; # int | The autoshape number.
my $format = 'format_example'; # string | Exported format.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_autoshapes_get_worksheet_autoshape(name => $name, sheet_name => $sheet_name, autoshape_number => $autoshape_number, format => $format, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_autoshapes_get_worksheet_autoshape: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **autoshape_number** | **int**| The autoshape number. | 
 **format** | **string**| Exported format. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_autoshapes_get_worksheet_autoshapes**
> AutoShapesResponse cells_autoshapes_get_worksheet_autoshapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet autoshapes info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_autoshapes_get_worksheet_autoshapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_autoshapes_get_worksheet_autoshapes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**AutoShapesResponse**](AutoShapesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_chart_area_get_chart_area**
> ChartAreaResponse cells_chart_area_get_chart_area(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Get chart area info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_chart_area_get_chart_area(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_chart_area_get_chart_area: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ChartAreaResponse**](ChartAreaResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_chart_area_get_chart_area_border**
> LineResponse cells_chart_area_get_chart_area_border(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Get chart area border info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_chart_area_get_chart_area_border(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_chart_area_get_chart_area_border: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**LineResponse**](LineResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_chart_area_get_chart_area_fill_format**
> FillFormatResponse cells_chart_area_get_chart_area_fill_format(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Get chart area fill format info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_chart_area_get_chart_area_fill_format(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_chart_area_get_chart_area_fill_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**FillFormatResponse**](FillFormatResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_delete_worksheet_chart_legend**
> CellsCloudResponse cells_charts_delete_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Hide legend in chart

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_delete_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_delete_worksheet_chart_legend: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_delete_worksheet_chart_title**
> CellsCloudResponse cells_charts_delete_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Hide title in chart

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_delete_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_delete_worksheet_chart_title: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_delete_worksheet_clear_charts**
> CellsCloudResponse cells_charts_delete_worksheet_clear_charts(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Clear the charts.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_delete_worksheet_clear_charts(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_delete_worksheet_clear_charts: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_delete_worksheet_delete_chart**
> ChartsResponse cells_charts_delete_worksheet_delete_chart(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Delete worksheet chart by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_delete_worksheet_delete_chart(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_delete_worksheet_delete_chart: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ChartsResponse**](ChartsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_get_worksheet_chart**
> string cells_charts_get_worksheet_chart(name => $name, sheet_name => $sheet_name, chart_number => $chart_number, format => $format, folder => $folder, storage_name => $storage_name)

Get chart info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_number = 56; # int | The chart number.
my $format = 'format_example'; # string | The exported file format.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_get_worksheet_chart(name => $name, sheet_name => $sheet_name, chart_number => $chart_number, format => $format, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_get_worksheet_chart: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_number** | **int**| The chart number. | 
 **format** | **string**| The exported file format. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_get_worksheet_chart_legend**
> LegendResponse cells_charts_get_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Get chart legend

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_get_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_get_worksheet_chart_legend: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**LegendResponse**](LegendResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_get_worksheet_chart_title**
> TitleResponse cells_charts_get_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Get chart title

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_get_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_get_worksheet_chart_title: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TitleResponse**](TitleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_get_worksheet_charts**
> ChartsResponse cells_charts_get_worksheet_charts(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet charts info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_get_worksheet_charts(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_get_worksheet_charts: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ChartsResponse**](ChartsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_post_worksheet_chart**
> CellsCloudResponse cells_charts_post_worksheet_chart(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, chart => $chart, folder => $folder, storage_name => $storage_name)

Update chart propreties

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $chart_index = 56; # int | 
my $chart = AsposeCellsCloud::Object::Chart->new(); # Chart | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_post_worksheet_chart(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, chart => $chart, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_post_worksheet_chart: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **chart_index** | **int**|  | 
 **chart** | [**Chart**](Chart.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_post_worksheet_chart_legend**
> LegendResponse cells_charts_post_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, legend => $legend, folder => $folder, storage_name => $storage_name)

Update chart legend

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $legend = AsposeCellsCloud::Object::Legend->new(); # Legend | 
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_post_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, legend => $legend, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_post_worksheet_chart_legend: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **legend** | [**Legend**](Legend.md)|  | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**LegendResponse**](LegendResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_post_worksheet_chart_title**
> TitleResponse cells_charts_post_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, title => $title, folder => $folder, storage_name => $storage_name)

Update chart title

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $title = AsposeCellsCloud::Object::Title->new(); # Title | Chart title
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_post_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, title => $title, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_post_worksheet_chart_title: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **title** | [**Title**](Title.md)| Chart title | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TitleResponse**](TitleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_put_worksheet_add_chart**
> ChartsResponse cells_charts_put_worksheet_add_chart(name => $name, sheet_name => $sheet_name, chart_type => $chart_type, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, lower_right_row => $lower_right_row, lower_right_column => $lower_right_column, area => $area, is_vertical => $is_vertical, category_data => $category_data, is_auto_get_serial_name => $is_auto_get_serial_name, title => $title, folder => $folder, storage_name => $storage_name, data_labels => $data_labels, data_labels_position => $data_labels_position, pivot_table_sheet => $pivot_table_sheet, pivot_table_name => $pivot_table_name)

Add new chart to worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $chart_type = 'chart_type_example'; # string | Chart type, please refer property Type in chart resource.
my $upper_left_row = 56; # int | New chart upper left row.
my $upper_left_column = 56; # int | New chart upperleft column.
my $lower_right_row = 56; # int | New chart lower right row.
my $lower_right_column = 56; # int | New chart lower right column.
my $area = 'area_example'; # string | Specifies values from which to plot the data series. 
my $is_vertical = 1; # boolean | Specifies whether to plot the series from a range of cell values by row or by column. 
my $category_data = 'category_data_example'; # string | Gets or sets the range of category Axis values. It can be a range of cells (such as, \"d1:e10\"). 
my $is_auto_get_serial_name = 1; # boolean | Specifies whether auto update serial name. 
my $title = 'title_example'; # string | Specifies chart title name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.
my $data_labels = 1; # boolean | 
my $data_labels_position = 'data_labels_position_example'; # string | 
my $pivot_table_sheet = 'pivot_table_sheet_example'; # string | 
my $pivot_table_name = 'pivot_table_name_example'; # string | 

eval { 
    my $result = $api_instance->cells_charts_put_worksheet_add_chart(name => $name, sheet_name => $sheet_name, chart_type => $chart_type, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, lower_right_row => $lower_right_row, lower_right_column => $lower_right_column, area => $area, is_vertical => $is_vertical, category_data => $category_data, is_auto_get_serial_name => $is_auto_get_serial_name, title => $title, folder => $folder, storage_name => $storage_name, data_labels => $data_labels, data_labels_position => $data_labels_position, pivot_table_sheet => $pivot_table_sheet, pivot_table_name => $pivot_table_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_put_worksheet_add_chart: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **chart_type** | **string**| Chart type, please refer property Type in chart resource. | 
 **upper_left_row** | **int**| New chart upper left row. | [optional] [default to 0]
 **upper_left_column** | **int**| New chart upperleft column. | [optional] [default to 0]
 **lower_right_row** | **int**| New chart lower right row. | [optional] [default to 0]
 **lower_right_column** | **int**| New chart lower right column. | [optional] [default to 0]
 **area** | **string**| Specifies values from which to plot the data series.  | [optional] 
 **is_vertical** | **boolean**| Specifies whether to plot the series from a range of cell values by row or by column.  | [optional] [default to true]
 **category_data** | **string**| Gets or sets the range of category Axis values. It can be a range of cells (such as, \&quot;d1:e10\&quot;).  | [optional] 
 **is_auto_get_serial_name** | **boolean**| Specifies whether auto update serial name.  | [optional] [default to true]
 **title** | **string**| Specifies chart title name. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **data_labels** | **boolean**|  | [optional] [default to true]
 **data_labels_position** | **string**|  | [optional] [default to Above]
 **pivot_table_sheet** | **string**|  | [optional] 
 **pivot_table_name** | **string**|  | [optional] 

### Return type

[**ChartsResponse**](ChartsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_put_worksheet_chart_legend**
> CellsCloudResponse cells_charts_put_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name)

Show legend in chart

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_put_worksheet_chart_legend(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_put_worksheet_chart_legend: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_charts_put_worksheet_chart_title**
> TitleResponse cells_charts_put_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, title => $title, folder => $folder, storage_name => $storage_name)

Add chart title / Set chart title visible

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $chart_index = 56; # int | The chart index.
my $title = AsposeCellsCloud::Object::Title->new(); # Title | Chart title.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_charts_put_worksheet_chart_title(name => $name, sheet_name => $sheet_name, chart_index => $chart_index, title => $title, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_charts_put_worksheet_chart_title: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **chart_index** | **int**| The chart index. | 
 **title** | [**Title**](Title.md)| Chart title. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TitleResponse**](TitleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_delete_worksheet_conditional_formatting**
> CellsCloudResponse cells_conditional_formattings_delete_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)

Remove conditional formatting

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_delete_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_delete_worksheet_conditional_formatting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_delete_worksheet_conditional_formatting_area**
> CellsCloudResponse cells_conditional_formattings_delete_worksheet_conditional_formatting_area(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name)

Remove cell area from conditional formatting.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $start_row = 56; # int | 
my $start_column = 56; # int | 
my $total_rows = 56; # int | 
my $total_columns = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_delete_worksheet_conditional_formatting_area(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_delete_worksheet_conditional_formatting_area: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **start_row** | **int**|  | 
 **start_column** | **int**|  | 
 **total_rows** | **int**|  | 
 **total_columns** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_delete_worksheet_conditional_formattings**
> CellsCloudResponse cells_conditional_formattings_delete_worksheet_conditional_formattings(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Clear all condition formattings

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_delete_worksheet_conditional_formattings(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_delete_worksheet_conditional_formattings: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_get_worksheet_conditional_formatting**
> ConditionalFormattingResponse cells_conditional_formattings_get_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)

Get conditional formatting

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_get_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_get_worksheet_conditional_formatting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ConditionalFormattingResponse**](ConditionalFormattingResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_get_worksheet_conditional_formattings**
> ConditionalFormattingsResponse cells_conditional_formattings_get_worksheet_conditional_formattings(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get conditional formattings 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_get_worksheet_conditional_formattings(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_get_worksheet_conditional_formattings: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ConditionalFormattingsResponse**](ConditionalFormattingsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_put_worksheet_conditional_formatting**
> CellsCloudResponse cells_conditional_formattings_put_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, cell_area => $cell_area, formatcondition => $formatcondition, folder => $folder, storage_name => $storage_name)

Add a condition formatting.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $cell_area = 'cell_area_example'; # string | 
my $formatcondition = AsposeCellsCloud::Object::FormatCondition->new(); # FormatCondition | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_put_worksheet_conditional_formatting(name => $name, sheet_name => $sheet_name, cell_area => $cell_area, formatcondition => $formatcondition, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_put_worksheet_conditional_formatting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **cell_area** | **string**|  | 
 **formatcondition** | [**FormatCondition**](FormatCondition.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_put_worksheet_format_condition**
> CellsCloudResponse cells_conditional_formattings_put_worksheet_format_condition(name => $name, sheet_name => $sheet_name, index => $index, cell_area => $cell_area, type => $type, operator_type => $operator_type, formula1 => $formula1, formula2 => $formula2, folder => $folder, storage_name => $storage_name)

Add a format condition.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $cell_area = 'cell_area_example'; # string | 
my $type = 'type_example'; # string | 
my $operator_type = 'operator_type_example'; # string | 
my $formula1 = 'formula1_example'; # string | 
my $formula2 = 'formula2_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_put_worksheet_format_condition(name => $name, sheet_name => $sheet_name, index => $index, cell_area => $cell_area, type => $type, operator_type => $operator_type, formula1 => $formula1, formula2 => $formula2, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_put_worksheet_format_condition: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **cell_area** | **string**|  | 
 **type** | **string**|  | 
 **operator_type** | **string**|  | 
 **formula1** | **string**|  | 
 **formula2** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_put_worksheet_format_condition_area**
> CellsCloudResponse cells_conditional_formattings_put_worksheet_format_condition_area(name => $name, sheet_name => $sheet_name, index => $index, cell_area => $cell_area, folder => $folder, storage_name => $storage_name)

add a cell area for format condition             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $cell_area = 'cell_area_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_put_worksheet_format_condition_area(name => $name, sheet_name => $sheet_name, index => $index, cell_area => $cell_area, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_put_worksheet_format_condition_area: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **cell_area** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_conditional_formattings_put_worksheet_format_condition_condition**
> CellsCloudResponse cells_conditional_formattings_put_worksheet_format_condition_condition(name => $name, sheet_name => $sheet_name, index => $index, type => $type, operator_type => $operator_type, formula1 => $formula1, formula2 => $formula2, folder => $folder, storage_name => $storage_name)

Add a condition for format condition.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $type = 'type_example'; # string | 
my $operator_type = 'operator_type_example'; # string | 
my $formula1 = 'formula1_example'; # string | 
my $formula2 = 'formula2_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_conditional_formattings_put_worksheet_format_condition_condition(name => $name, sheet_name => $sheet_name, index => $index, type => $type, operator_type => $operator_type, formula1 => $formula1, formula2 => $formula2, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_conditional_formattings_put_worksheet_format_condition_condition: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **type** | **string**|  | 
 **operator_type** | **string**|  | 
 **formula1** | **string**|  | 
 **formula2** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_delete_worksheet_columns**
> ColumnsResponse cells_delete_worksheet_columns(name => $name, sheet_name => $sheet_name, column_index => $column_index, columns => $columns, update_reference => $update_reference, folder => $folder, storage_name => $storage_name)

Delete worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $column_index = 56; # int | The column index.
my $columns = 56; # int | The columns.
my $update_reference = 1; # boolean | The update reference.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_delete_worksheet_columns(name => $name, sheet_name => $sheet_name, column_index => $column_index, columns => $columns, update_reference => $update_reference, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_delete_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **column_index** | **int**| The column index. | 
 **columns** | **int**| The columns. | 
 **update_reference** | **boolean**| The update reference. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ColumnsResponse**](ColumnsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_delete_worksheet_row**
> CellsCloudResponse cells_delete_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name)

Delete worksheet row.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet bame.
my $row_index = 56; # int | The row index.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_delete_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_delete_worksheet_row: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet bame. | 
 **row_index** | **int**| The row index. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_delete_worksheet_rows**
> CellsCloudResponse cells_delete_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, update_reference => $update_reference, folder => $folder, storage_name => $storage_name)

Delete several worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet bame.
my $startrow = 56; # int | The begin row index to be operated.
my $total_rows = 56; # int | Number of rows to be operated.
my $update_reference = 1; # boolean | Indicates if update references in other worksheets.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_delete_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, update_reference => $update_reference, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_delete_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet bame. | 
 **startrow** | **int**| The begin row index to be operated. | 
 **total_rows** | **int**| Number of rows to be operated. | [optional] [default to 1]
 **update_reference** | **boolean**| Indicates if update references in other worksheets. | [optional] [default to true]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_cell_html_string**
> object cells_get_cell_html_string(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name)

Read cell data by cell's name.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell's  name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_cell_html_string(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_cell_html_string: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cell_name** | **string**| The cell&#39;s  name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_cell**
> object cells_get_worksheet_cell(name => $name, sheet_name => $sheet_name, cell_or_method_name => $cell_or_method_name, folder => $folder, storage_name => $storage_name)

Read cell data by cell's name.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cell_or_method_name = 'cell_or_method_name_example'; # string | The cell's or method name. (Method name like firstcell, endcell etc.)
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_cell(name => $name, sheet_name => $sheet_name, cell_or_method_name => $cell_or_method_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_cell: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cell_or_method_name** | **string**| The cell&#39;s or method name. (Method name like firstcell, endcell etc.) | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_cell_style**
> StyleResponse cells_get_worksheet_cell_style(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name)

Read cell's style info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cell_name = 'cell_name_example'; # string | Cell's name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_cell_style(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_cell_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cell_name** | **string**| Cell&#39;s name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**StyleResponse**](StyleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_cells**
> CellsResponse cells_get_worksheet_cells(name => $name, sheet_name => $sheet_name, offest => $offest, count => $count, folder => $folder, storage_name => $storage_name)

Get cells info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $offest = 56; # int | Begginig offset.
my $count = 56; # int | Maximum amount of cells in the response.
my $folder = 'folder_example'; # string | Document's folder name.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_cells(name => $name, sheet_name => $sheet_name, offest => $offest, count => $count, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_cells: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **offest** | **int**| Begginig offset. | [optional] [default to 0]
 **count** | **int**| Maximum amount of cells in the response. | [optional] [default to 0]
 **folder** | **string**| Document&#39;s folder name. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsResponse**](CellsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_column**
> ColumnResponse cells_get_worksheet_column(name => $name, sheet_name => $sheet_name, column_index => $column_index, folder => $folder, storage_name => $storage_name)

Read worksheet column data by column's index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $column_index = 56; # int | The column index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_column(name => $name, sheet_name => $sheet_name, column_index => $column_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_column: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **column_index** | **int**| The column index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ColumnResponse**](ColumnResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_columns**
> ColumnsResponse cells_get_worksheet_columns(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Read worksheet columns info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | The workdook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_columns(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| The workdook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ColumnsResponse**](ColumnsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_row**
> RowResponse cells_get_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name)

Read worksheet row data by row's index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $row_index = 56; # int | The row index.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_row: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **row_index** | **int**| The row index. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RowResponse**](RowResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_get_worksheet_rows**
> RowsResponse cells_get_worksheet_rows(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Read worksheet rows info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | The workdook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_get_worksheet_rows(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_get_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| The workdook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RowsResponse**](RowsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_delete_worksheet_hyperlink**
> CellsCloudResponse cells_hypelinks_delete_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, folder => $folder, storage_name => $storage_name)

Delete worksheet hyperlink by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $hyperlink_index = 56; # int | The hyperlink's index.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_delete_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_delete_worksheet_hyperlink: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **hyperlink_index** | **int**| The hyperlink&#39;s index. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_delete_worksheet_hyperlinks**
> CellsCloudResponse cells_hypelinks_delete_worksheet_hyperlinks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete all hyperlinks in worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_delete_worksheet_hyperlinks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_delete_worksheet_hyperlinks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_get_worksheet_hyperlink**
> HyperlinkResponse cells_hypelinks_get_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, folder => $folder, storage_name => $storage_name)

Get worksheet hyperlink by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $hyperlink_index = 56; # int | The hyperlink's index.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_get_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_get_worksheet_hyperlink: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **hyperlink_index** | **int**| The hyperlink&#39;s index. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HyperlinkResponse**](HyperlinkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_get_worksheet_hyperlinks**
> HyperlinksResponse cells_hypelinks_get_worksheet_hyperlinks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet hyperlinks.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_get_worksheet_hyperlinks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_get_worksheet_hyperlinks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HyperlinksResponse**](HyperlinksResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_post_worksheet_hyperlink**
> HyperlinkResponse cells_hypelinks_post_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, hyperlink => $hyperlink, folder => $folder, storage_name => $storage_name)

Update worksheet hyperlink by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $hyperlink_index = 56; # int | The hyperlink's index.
my $hyperlink = AsposeCellsCloud::Object::Hyperlink->new(); # Hyperlink | Hyperlink object
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_post_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, hyperlink_index => $hyperlink_index, hyperlink => $hyperlink, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_post_worksheet_hyperlink: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **hyperlink_index** | **int**| The hyperlink&#39;s index. | 
 **hyperlink** | [**Hyperlink**](Hyperlink.md)| Hyperlink object | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HyperlinkResponse**](HyperlinkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_hypelinks_put_worksheet_hyperlink**
> HyperlinkResponse cells_hypelinks_put_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, first_row => $first_row, first_column => $first_column, total_rows => $total_rows, total_columns => $total_columns, address => $address, folder => $folder, storage_name => $storage_name)

Add worksheet hyperlink.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $first_row = 56; # int | 
my $first_column = 56; # int | 
my $total_rows = 56; # int | 
my $total_columns = 56; # int | 
my $address = 'address_example'; # string | 
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_hypelinks_put_worksheet_hyperlink(name => $name, sheet_name => $sheet_name, first_row => $first_row, first_column => $first_column, total_rows => $total_rows, total_columns => $total_columns, address => $address, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_hypelinks_put_worksheet_hyperlink: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **first_row** | **int**|  | 
 **first_column** | **int**|  | 
 **total_rows** | **int**|  | 
 **total_columns** | **int**|  | 
 **address** | **string**|  | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HyperlinkResponse**](HyperlinkResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_delete_worksheet_list_object**
> CellsCloudResponse cells_list_objects_delete_worksheet_list_object(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, folder => $folder, storage_name => $storage_name)

Delete worksheet list object by index

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $list_object_index = 56; # int | List object index
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_delete_worksheet_list_object(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_delete_worksheet_list_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **list_object_index** | **int**| List object index | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_delete_worksheet_list_objects**
> CellsCloudResponse cells_list_objects_delete_worksheet_list_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete worksheet list objects

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_delete_worksheet_list_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_delete_worksheet_list_objects: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_get_worksheet_list_object**
> ListObjectResponse cells_list_objects_get_worksheet_list_object(name => $name, sheet_name => $sheet_name, listobjectindex => $listobjectindex, folder => $folder, storage_name => $storage_name)

Get worksheet list object info by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $listobjectindex = 56; # int | list object index.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_get_worksheet_list_object(name => $name, sheet_name => $sheet_name, listobjectindex => $listobjectindex, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_get_worksheet_list_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **listobjectindex** | **int**| list object index. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ListObjectResponse**](ListObjectResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_get_worksheet_list_objects**
> ListObjectsResponse cells_list_objects_get_worksheet_list_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet listobjects info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_get_worksheet_list_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_get_worksheet_list_objects: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ListObjectsResponse**](ListObjectsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_post_worksheet_list_object**
> CellsCloudResponse cells_list_objects_post_worksheet_list_object(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, list_object => $list_object, folder => $folder, storage_name => $storage_name)

Update  list object 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $list_object_index = 56; # int | list Object index
my $list_object = AsposeCellsCloud::Object::ListObject->new(); # ListObject | listObject dto in request body.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_post_worksheet_list_object(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, list_object => $list_object, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_post_worksheet_list_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **list_object_index** | **int**| list Object index | 
 **list_object** | [**ListObject**](ListObject.md)| listObject dto in request body. | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_post_worksheet_list_object_convert_to_range**
> CellsCloudResponse cells_list_objects_post_worksheet_list_object_convert_to_range(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $list_object_index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_post_worksheet_list_object_convert_to_range(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_post_worksheet_list_object_convert_to_range: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **list_object_index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_post_worksheet_list_object_sort_table**
> CellsCloudResponse cells_list_objects_post_worksheet_list_object_sort_table(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, data_sorter => $data_sorter, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $list_object_index = 56; # int | 
my $data_sorter = AsposeCellsCloud::Object::DataSorter->new(); # DataSorter | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_post_worksheet_list_object_sort_table(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, data_sorter => $data_sorter, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_post_worksheet_list_object_sort_table: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **list_object_index** | **int**|  | 
 **data_sorter** | [**DataSorter**](DataSorter.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table**
> CellsCloudResponse cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, destsheet_name => $destsheet_name, request => $request, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $list_object_index = 56; # int | 
my $destsheet_name = 'destsheet_name_example'; # string | 
my $request = AsposeCellsCloud::Object::CreatePivotTableRequest->new(); # CreatePivotTableRequest | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table(name => $name, sheet_name => $sheet_name, list_object_index => $list_object_index, destsheet_name => $destsheet_name, request => $request, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_post_worksheet_list_object_summarize_with_pivot_table: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **list_object_index** | **int**|  | 
 **destsheet_name** | **string**|  | 
 **request** | [**CreatePivotTableRequest**](CreatePivotTableRequest.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_list_objects_put_worksheet_list_object**
> ListObjectResponse cells_list_objects_put_worksheet_list_object(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, has_headers => $has_headers, list_object => $list_object, folder => $folder, storage_name => $storage_name, has_headers2 => $has_headers2)

Add a list object into worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $start_row = 56; # int | The start row of the list range.
my $start_column = 56; # int | The start row of the list range.
my $end_row = 56; # int | The start row of the list range.
my $end_column = 56; # int | The start row of the list range.
my $has_headers = 1; # boolean | Whether the range has headers.
my $list_object = AsposeCellsCloud::Object::ListObject->new(); # ListObject | List Object
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.
my $has_headers2 = 1; # boolean | Whether the range has headers.

eval { 
    my $result = $api_instance->cells_list_objects_put_worksheet_list_object(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, has_headers => $has_headers, list_object => $list_object, folder => $folder, storage_name => $storage_name, has_headers2 => $has_headers2);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_list_objects_put_worksheet_list_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **start_row** | **int**| The start row of the list range. | 
 **start_column** | **int**| The start row of the list range. | 
 **end_row** | **int**| The start row of the list range. | 
 **end_column** | **int**| The start row of the list range. | 
 **has_headers** | **boolean**| Whether the range has headers. | [optional] [default to true]
 **list_object** | [**ListObject**](ListObject.md)| List Object | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **has_headers2** | **boolean**| Whether the range has headers. | [optional] [default to true]

### Return type

[**ListObjectResponse**](ListObjectResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_delete_worksheet_ole_object**
> CellsCloudResponse cells_ole_objects_delete_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object_index => $ole_object_index, folder => $folder, storage_name => $storage_name)

Delete OLE object.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $ole_object_index = 56; # int | Ole object index
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_delete_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object_index => $ole_object_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_delete_worksheet_ole_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **ole_object_index** | **int**| Ole object index | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_delete_worksheet_ole_objects**
> CellsCloudResponse cells_ole_objects_delete_worksheet_ole_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete all OLE objects.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_delete_worksheet_ole_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_delete_worksheet_ole_objects: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_get_worksheet_ole_object**
> string cells_ole_objects_get_worksheet_ole_object(name => $name, sheet_name => $sheet_name, object_number => $object_number, format => $format, folder => $folder, storage_name => $storage_name)

Get OLE object info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $object_number = 56; # int | The object number.
my $format = 'format_example'; # string | The exported object format.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_get_worksheet_ole_object(name => $name, sheet_name => $sheet_name, object_number => $object_number, format => $format, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_get_worksheet_ole_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **object_number** | **int**| The object number. | 
 **format** | **string**| The exported object format. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_get_worksheet_ole_objects**
> OleObjectsResponse cells_ole_objects_get_worksheet_ole_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet OLE objects info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_get_worksheet_ole_objects(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_get_worksheet_ole_objects: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**OleObjectsResponse**](OleObjectsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_post_update_worksheet_ole_object**
> CellsCloudResponse cells_ole_objects_post_update_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object_index => $ole_object_index, ole => $ole, folder => $folder, storage_name => $storage_name)

Update OLE object.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $ole_object_index = 56; # int | Ole object index
my $ole = AsposeCellsCloud::Object::OleObject->new(); # OleObject | Ole Object
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_post_update_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object_index => $ole_object_index, ole => $ole, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_post_update_worksheet_ole_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **ole_object_index** | **int**| Ole object index | 
 **ole** | [**OleObject**](OleObject.md)| Ole Object | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ole_objects_put_worksheet_ole_object**
> OleObjectResponse cells_ole_objects_put_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object => $ole_object, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, height => $height, width => $width, ole_file => $ole_file, image_file => $image_file, folder => $folder, storage_name => $storage_name)

Add OLE object

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $ole_object = AsposeCellsCloud::Object::OleObject->new(); # OleObject | Ole Object
my $upper_left_row = 56; # int | Upper left row index
my $upper_left_column = 56; # int | Upper left column index
my $height = 56; # int | Height of oleObject, in unit of pixel
my $width = 56; # int | Width of oleObject, in unit of pixel
my $ole_file = 'ole_file_example'; # string | OLE filename
my $image_file = 'image_file_example'; # string | Image filename
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ole_objects_put_worksheet_ole_object(name => $name, sheet_name => $sheet_name, ole_object => $ole_object, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, height => $height, width => $width, ole_file => $ole_file, image_file => $image_file, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ole_objects_put_worksheet_ole_object: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **ole_object** | [**OleObject**](OleObject.md)| Ole Object | [optional] 
 **upper_left_row** | **int**| Upper left row index | [optional] [default to 0]
 **upper_left_column** | **int**| Upper left column index | [optional] [default to 0]
 **height** | **int**| Height of oleObject, in unit of pixel | [optional] [default to 0]
 **width** | **int**| Width of oleObject, in unit of pixel | [optional] [default to 0]
 **ole_file** | **string**| OLE filename | [optional] 
 **image_file** | **string**| Image filename | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**OleObjectResponse**](OleObjectResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_delete_horizontal_page_break**
> CellsCloudResponse cells_page_breaks_delete_horizontal_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_delete_horizontal_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_delete_horizontal_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_delete_horizontal_page_breaks**
> CellsCloudResponse cells_page_breaks_delete_horizontal_page_breaks(name => $name, sheet_name => $sheet_name, row => $row, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $row = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_delete_horizontal_page_breaks(name => $name, sheet_name => $sheet_name, row => $row, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_delete_horizontal_page_breaks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **row** | **int**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_delete_vertical_page_break**
> CellsCloudResponse cells_page_breaks_delete_vertical_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_delete_vertical_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_delete_vertical_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_delete_vertical_page_breaks**
> CellsCloudResponse cells_page_breaks_delete_vertical_page_breaks(name => $name, sheet_name => $sheet_name, column => $column, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $column = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_delete_vertical_page_breaks(name => $name, sheet_name => $sheet_name, column => $column, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_delete_vertical_page_breaks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **column** | **int**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_get_horizontal_page_break**
> HorizontalPageBreakResponse cells_page_breaks_get_horizontal_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_get_horizontal_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_get_horizontal_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HorizontalPageBreakResponse**](HorizontalPageBreakResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_get_horizontal_page_breaks**
> HorizontalPageBreaksResponse cells_page_breaks_get_horizontal_page_breaks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_get_horizontal_page_breaks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_get_horizontal_page_breaks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**HorizontalPageBreaksResponse**](HorizontalPageBreaksResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_get_vertical_page_break**
> VerticalPageBreakResponse cells_page_breaks_get_vertical_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_get_vertical_page_break(name => $name, sheet_name => $sheet_name, index => $index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_get_vertical_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**VerticalPageBreakResponse**](VerticalPageBreakResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_get_vertical_page_breaks**
> VerticalPageBreaksResponse cells_page_breaks_get_vertical_page_breaks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_get_vertical_page_breaks(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_get_vertical_page_breaks: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**VerticalPageBreaksResponse**](VerticalPageBreaksResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_put_horizontal_page_break**
> CellsCloudResponse cells_page_breaks_put_horizontal_page_break(name => $name, sheet_name => $sheet_name, cellname => $cellname, row => $row, column => $column, start_column => $start_column, end_column => $end_column, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $cellname = 'cellname_example'; # string | 
my $row = 56; # int | 
my $column = 56; # int | 
my $start_column = 56; # int | 
my $end_column = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_put_horizontal_page_break(name => $name, sheet_name => $sheet_name, cellname => $cellname, row => $row, column => $column, start_column => $start_column, end_column => $end_column, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_put_horizontal_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **cellname** | **string**|  | [optional] 
 **row** | **int**|  | [optional] 
 **column** | **int**|  | [optional] 
 **start_column** | **int**|  | [optional] 
 **end_column** | **int**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_breaks_put_vertical_page_break**
> CellsCloudResponse cells_page_breaks_put_vertical_page_break(name => $name, sheet_name => $sheet_name, cellname => $cellname, column => $column, row => $row, start_row => $start_row, end_row => $end_row, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $cellname = 'cellname_example'; # string | 
my $column = 56; # int | 
my $row = 56; # int | 
my $start_row = 56; # int | 
my $end_row = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_breaks_put_vertical_page_break(name => $name, sheet_name => $sheet_name, cellname => $cellname, column => $column, row => $row, start_row => $start_row, end_row => $end_row, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_breaks_put_vertical_page_break: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **cellname** | **string**|  | [optional] 
 **column** | **int**|  | [optional] 
 **row** | **int**|  | [optional] 
 **start_row** | **int**|  | [optional] 
 **end_row** | **int**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_delete_header_footer**
> CellsCloudResponse cells_page_setup_delete_header_footer(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

clear header footer

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_delete_header_footer(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_delete_header_footer: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_get_footer**
> PageSectionsResponse cells_page_setup_get_footer(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

get page footer information

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_get_footer(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_get_footer: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PageSectionsResponse**](PageSectionsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_get_header**
> PageSectionsResponse cells_page_setup_get_header(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

get page header information

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_get_header(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_get_header: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PageSectionsResponse**](PageSectionsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_get_page_setup**
> PageSetupResponse cells_page_setup_get_page_setup(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get Page Setup information.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_get_page_setup(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_get_page_setup: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PageSetupResponse**](PageSetupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_post_footer**
> CellsCloudResponse cells_page_setup_post_footer(name => $name, sheet_name => $sheet_name, section => $section, script => $script, is_first_page => $is_first_page, folder => $folder, storage_name => $storage_name)

update  page footer information 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $section = 56; # int | 
my $script = 'script_example'; # string | 
my $is_first_page = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_post_footer(name => $name, sheet_name => $sheet_name, section => $section, script => $script, is_first_page => $is_first_page, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_post_footer: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **section** | **int**|  | 
 **script** | **string**|  | 
 **is_first_page** | **boolean**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_post_header**
> CellsCloudResponse cells_page_setup_post_header(name => $name, sheet_name => $sheet_name, section => $section, script => $script, is_first_page => $is_first_page, folder => $folder, storage_name => $storage_name)

update  page header information 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $section = 56; # int | 
my $script = 'script_example'; # string | 
my $is_first_page = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_post_header(name => $name, sheet_name => $sheet_name, section => $section, script => $script, is_first_page => $is_first_page, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_post_header: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **section** | **int**|  | 
 **script** | **string**|  | 
 **is_first_page** | **boolean**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_page_setup_post_page_setup**
> CellsCloudResponse cells_page_setup_post_page_setup(name => $name, sheet_name => $sheet_name, page_setup => $page_setup, folder => $folder, storage_name => $storage_name)

Update Page Setup information.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $page_setup = AsposeCellsCloud::Object::PageSetup->new(); # PageSetup | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_page_setup_post_page_setup(name => $name, sheet_name => $sheet_name, page_setup => $page_setup, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_page_setup_post_page_setup: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **page_setup** | [**PageSetup**](PageSetup.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_delete_worksheet_picture**
> CellsCloudResponse cells_pictures_delete_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, folder => $folder, storage_name => $storage_name)

Delete a picture object in worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $picture_index = 56; # int | Picture index
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_delete_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_delete_worksheet_picture: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **picture_index** | **int**| Picture index | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_delete_worksheet_pictures**
> CellsCloudResponse cells_pictures_delete_worksheet_pictures(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete all pictures in worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_delete_worksheet_pictures(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_delete_worksheet_pictures: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_get_worksheet_picture**
> string cells_pictures_get_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, format => $format, folder => $folder, storage_name => $storage_name)

GRead worksheet picture by number.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $picture_index = 56; # int | The picture index.
my $format = 'format_example'; # string | The exported object format.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_get_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, format => $format, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_get_worksheet_picture: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **picture_index** | **int**| The picture index. | 
 **format** | **string**| The exported object format. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_get_worksheet_pictures**
> PicturesResponse cells_pictures_get_worksheet_pictures(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Read worksheet pictures.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_get_worksheet_pictures(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_get_worksheet_pictures: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PicturesResponse**](PicturesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_post_worksheet_picture**
> PictureResponse cells_pictures_post_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, picture => $picture, folder => $folder, storage_name => $storage_name)

Update worksheet picture by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $picture_index = 56; # int | The picture's index.
my $picture = AsposeCellsCloud::Object::Picture->new(); # Picture | Picture object
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_post_worksheet_picture(name => $name, sheet_name => $sheet_name, picture_index => $picture_index, picture => $picture, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_post_worksheet_picture: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **picture_index** | **int**| The picture&#39;s index. | 
 **picture** | [**Picture**](Picture.md)| Picture object | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PictureResponse**](PictureResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pictures_put_worksheet_add_picture**
> PicturesResponse cells_pictures_put_worksheet_add_picture(name => $name, sheet_name => $sheet_name, picture => $picture, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, lower_right_row => $lower_right_row, lower_right_column => $lower_right_column, picture_path => $picture_path, folder => $folder, storage_name => $storage_name)

Add a new worksheet picture.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worsheet name.
my $picture = AsposeCellsCloud::Object::Picture->new(); # Picture | Pictute object
my $upper_left_row = 56; # int | The image upper left row.
my $upper_left_column = 56; # int | The image upper left column.
my $lower_right_row = 56; # int | The image low right row.
my $lower_right_column = 56; # int | The image low right column.
my $picture_path = 'picture_path_example'; # string | The picture path, if not provided the picture data is inspected in the request body.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pictures_put_worksheet_add_picture(name => $name, sheet_name => $sheet_name, picture => $picture, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, lower_right_row => $lower_right_row, lower_right_column => $lower_right_column, picture_path => $picture_path, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pictures_put_worksheet_add_picture: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worsheet name. | 
 **picture** | [**Picture**](Picture.md)| Pictute object | [optional] 
 **upper_left_row** | **int**| The image upper left row. | [optional] [default to 0]
 **upper_left_column** | **int**| The image upper left column. | [optional] [default to 0]
 **lower_right_row** | **int**| The image low right row. | [optional] [default to 0]
 **lower_right_column** | **int**| The image low right column. | [optional] [default to 0]
 **picture_path** | **string**| The picture path, if not provided the picture data is inspected in the request body. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PicturesResponse**](PicturesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_delete_pivot_table_field**
> CellsCloudResponse cells_pivot_tables_delete_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, request => $request, folder => $folder, storage_name => $storage_name)

Delete pivot field into into pivot table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $pivot_field_type = 'pivot_field_type_example'; # string | The fields area type.
my $request = AsposeCellsCloud::Object::PivotTableFieldRequest->new(); # PivotTableFieldRequest | Dto that conrains field indexes
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_delete_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, request => $request, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_delete_pivot_table_field: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **pivot_field_type** | **string**| The fields area type. | 
 **request** | [**PivotTableFieldRequest**](PivotTableFieldRequest.md)| Dto that conrains field indexes | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_delete_worksheet_pivot_table**
> CellsCloudResponse cells_pivot_tables_delete_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name)

Delete worksheet pivot table by index

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_delete_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_delete_worksheet_pivot_table: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_delete_worksheet_pivot_table_filter**
> CellsCloudResponse cells_pivot_tables_delete_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, field_index => $field_index, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

delete  pivot filter for piovt table             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $field_index = 56; # int | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_delete_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, field_index => $field_index, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_delete_worksheet_pivot_table_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **field_index** | **int**|  | 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_delete_worksheet_pivot_table_filters**
> CellsCloudResponse cells_pivot_tables_delete_worksheet_pivot_table_filters(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

delete all pivot filters for piovt table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_delete_worksheet_pivot_table_filters(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_delete_worksheet_pivot_table_filters: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_delete_worksheet_pivot_tables**
> CellsCloudResponse cells_pivot_tables_delete_worksheet_pivot_tables(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete worksheet pivot tables

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_delete_worksheet_pivot_tables(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_delete_worksheet_pivot_tables: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_get_pivot_table_field**
> PivotFieldResponse cells_pivot_tables_get_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_index => $pivot_field_index, pivot_field_type => $pivot_field_type, folder => $folder, storage_name => $storage_name)

Get pivot field into into pivot table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $pivot_field_index = 56; # int | The field index in the base fields.
my $pivot_field_type = 'pivot_field_type_example'; # string | The fields area type.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_get_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_index => $pivot_field_index, pivot_field_type => $pivot_field_type, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_get_pivot_table_field: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **pivot_field_index** | **int**| The field index in the base fields. | 
 **pivot_field_type** | **string**| The fields area type. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PivotFieldResponse**](PivotFieldResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_get_worksheet_pivot_table**
> PivotTableResponse cells_pivot_tables_get_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, pivottable_index => $pivottable_index, folder => $folder, storage_name => $storage_name)

Get worksheet pivottable info by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivottable_index = 56; # int | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_get_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, pivottable_index => $pivottable_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_get_worksheet_pivot_table: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivottable_index** | **int**|  | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PivotTableResponse**](PivotTableResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_get_worksheet_pivot_table_filter**
> PivotFilterResponse cells_pivot_tables_get_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, filter_index => $filter_index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $filter_index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_get_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, filter_index => $filter_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_get_worksheet_pivot_table_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **filter_index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PivotFilterResponse**](PivotFilterResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_get_worksheet_pivot_table_filters**
> PivotFiltersResponse cells_pivot_tables_get_worksheet_pivot_table_filters(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_get_worksheet_pivot_table_filters(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_get_worksheet_pivot_table_filters: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PivotFiltersResponse**](PivotFiltersResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_get_worksheet_pivot_tables**
> PivotTablesResponse cells_pivot_tables_get_worksheet_pivot_tables(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet pivottables info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_get_worksheet_pivot_tables(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_get_worksheet_pivot_tables: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**PivotTablesResponse**](PivotTablesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_cell_style**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_cell_style(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, column => $column, row => $row, style => $style, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

Update cell style for pivot table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $column = 56; # int | 
my $row = 56; # int | 
my $style = AsposeCellsCloud::Object::Style->new(); # Style | Style dto in request body.
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_cell_style(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, column => $column, row => $row, style => $style, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_cell_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **column** | **int**|  | 
 **row** | **int**|  | 
 **style** | [**Style**](Style.md)| Style dto in request body. | [optional] 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_field_hide_item**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_field_hide_item(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, field_index => $field_index, item_index => $item_index, is_hide => $is_hide, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $pivot_field_type = 'pivot_field_type_example'; # string | 
my $field_index = 56; # int | 
my $item_index = 56; # int | 
my $is_hide = 1; # boolean | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_field_hide_item(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, field_index => $field_index, item_index => $item_index, is_hide => $is_hide, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_field_hide_item: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **pivot_field_type** | **string**|  | 
 **field_index** | **int**|  | 
 **item_index** | **int**|  | 
 **is_hide** | **boolean**|  | 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_field_move_to**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_field_move_to(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, field_index => $field_index, from => $from, to => $to, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $field_index = 56; # int | 
my $from = 'from_example'; # string | 
my $to = 'to_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_field_move_to(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, field_index => $field_index, from => $from, to => $to, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_field_move_to: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **field_index** | **int**|  | 
 **from** | **string**|  | 
 **to** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_style**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_style(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, style => $style, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

Update style for pivot table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $style = AsposeCellsCloud::Object::Style->new(); # Style | Style dto in request body.
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_style(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, style => $style, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **style** | [**Style**](Style.md)| Style dto in request body. | [optional] 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_update_pivot_field**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_update_pivot_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_index => $pivot_field_index, pivot_field_type => $pivot_field_type, pivot_field => $pivot_field, need_re_calculate => $need_re_calculate, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $pivot_field_index = 56; # int | 
my $pivot_field_type = 'pivot_field_type_example'; # string | 
my $pivot_field = AsposeCellsCloud::Object::PivotField->new(); # PivotField | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_update_pivot_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_index => $pivot_field_index, pivot_field_type => $pivot_field_type, pivot_field => $pivot_field, need_re_calculate => $need_re_calculate, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_update_pivot_field: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **pivot_field_index** | **int**|  | 
 **pivot_field_type** | **string**|  | 
 **pivot_field** | [**PivotField**](PivotField.md)|  | 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_pivot_table_update_pivot_fields**
> CellsCloudResponse cells_pivot_tables_post_pivot_table_update_pivot_fields(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, pivot_field => $pivot_field, need_re_calculate => $need_re_calculate, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $pivot_field_type = 'pivot_field_type_example'; # string | 
my $pivot_field = AsposeCellsCloud::Object::PivotField->new(); # PivotField | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_pivot_tables_post_pivot_table_update_pivot_fields(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, pivot_field => $pivot_field, need_re_calculate => $need_re_calculate, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_pivot_table_update_pivot_fields: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **pivot_field_type** | **string**|  | 
 **pivot_field** | [**PivotField**](PivotField.md)|  | 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_worksheet_pivot_table_calculate**
> CellsCloudResponse cells_pivot_tables_post_worksheet_pivot_table_calculate(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name)

Calculates pivottable's data to cells.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_worksheet_pivot_table_calculate(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_worksheet_pivot_table_calculate: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_post_worksheet_pivot_table_move**
> CellsCloudResponse cells_pivot_tables_post_worksheet_pivot_table_move(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, row => $row, column => $column, dest_cell_name => $dest_cell_name, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $row = 56; # int | 
my $column = 56; # int | 
my $dest_cell_name = 'dest_cell_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_post_worksheet_pivot_table_move(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, row => $row, column => $column, dest_cell_name => $dest_cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_post_worksheet_pivot_table_move: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **row** | **int**|  | [optional] 
 **column** | **int**|  | [optional] 
 **dest_cell_name** | **string**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_put_pivot_table_field**
> CellsCloudResponse cells_pivot_tables_put_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, request => $request, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

Add pivot field into into pivot table

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $pivot_table_index = 56; # int | Pivot table index
my $pivot_field_type = 'pivot_field_type_example'; # string | The fields area type.
my $request = AsposeCellsCloud::Object::PivotTableFieldRequest->new(); # PivotTableFieldRequest | Dto that conrains field indexes
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_put_pivot_table_field(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, pivot_field_type => $pivot_field_type, request => $request, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_put_pivot_table_field: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **pivot_table_index** | **int**| Pivot table index | 
 **pivot_field_type** | **string**| The fields area type. | 
 **request** | [**PivotTableFieldRequest**](PivotTableFieldRequest.md)| Dto that conrains field indexes | [optional] 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_put_worksheet_pivot_table**
> PivotTableResponse cells_pivot_tables_put_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, request => $request, folder => $folder, storage_name => $storage_name, source_data => $source_data, dest_cell_name => $dest_cell_name, table_name => $table_name, use_same_source => $use_same_source)

Add a pivot table into worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $request = AsposeCellsCloud::Object::CreatePivotTableRequest->new(); # CreatePivotTableRequest | CreatePivotTableRequest dto in request body.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.
my $source_data = 'source_data_example'; # string | The data for the new PivotTable cache.
my $dest_cell_name = 'dest_cell_name_example'; # string | The cell in the upper-left corner of the PivotTable report's destination range.
my $table_name = 'table_name_example'; # string | The name of the new PivotTable report.
my $use_same_source = 1; # boolean | Indicates whether using same data source when another existing pivot table has used this data source. If the property is true, it will save memory.

eval { 
    my $result = $api_instance->cells_pivot_tables_put_worksheet_pivot_table(name => $name, sheet_name => $sheet_name, request => $request, folder => $folder, storage_name => $storage_name, source_data => $source_data, dest_cell_name => $dest_cell_name, table_name => $table_name, use_same_source => $use_same_source);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_put_worksheet_pivot_table: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **request** | [**CreatePivotTableRequest**](CreatePivotTableRequest.md)| CreatePivotTableRequest dto in request body. | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **source_data** | **string**| The data for the new PivotTable cache. | [optional] 
 **dest_cell_name** | **string**| The cell in the upper-left corner of the PivotTable report&#39;s destination range. | [optional] 
 **table_name** | **string**| The name of the new PivotTable report. | [optional] 
 **use_same_source** | **boolean**| Indicates whether using same data source when another existing pivot table has used this data source. If the property is true, it will save memory. | [optional] 

### Return type

[**PivotTableResponse**](PivotTableResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_pivot_tables_put_worksheet_pivot_table_filter**
> CellsCloudResponse cells_pivot_tables_put_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, filter => $filter, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name)

Add pivot filter for piovt table index

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $pivot_table_index = 56; # int | 
my $filter = AsposeCellsCloud::Object::PivotFilter->new(); # PivotFilter | 
my $need_re_calculate = 1; # boolean | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_pivot_tables_put_worksheet_pivot_table_filter(name => $name, sheet_name => $sheet_name, pivot_table_index => $pivot_table_index, filter => $filter, need_re_calculate => $need_re_calculate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_pivot_tables_put_worksheet_pivot_table_filter: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **pivot_table_index** | **int**|  | 
 **filter** | [**PivotFilter**](PivotFilter.md)|  | [optional] 
 **need_re_calculate** | **boolean**|  | [optional] [default to false]
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_cell_calculate**
> CellsCloudResponse cells_post_cell_calculate(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, options => $options, folder => $folder, storage_name => $storage_name)

Cell calculate formula

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $cell_name = 'cell_name_example'; # string | 
my $options = AsposeCellsCloud::Object::CalculationOptions->new(); # CalculationOptions | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_cell_calculate(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, options => $options, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_cell_calculate: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **cell_name** | **string**|  | 
 **options** | [**CalculationOptions**](CalculationOptions.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_cell_characters**
> CellsCloudResponse cells_post_cell_characters(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, options => $options, folder => $folder, storage_name => $storage_name)

Set cell characters 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $cell_name = 'cell_name_example'; # string | 
my $options = [AsposeCellsCloud::Object::ARRAY[FontSetting]->new()]; # ARRAY[FontSetting] | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_cell_characters(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, options => $options, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_cell_characters: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **cell_name** | **string**|  | 
 **options** | [**ARRAY[FontSetting]**](FontSetting.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_clear_contents**
> CellsCloudResponse cells_post_clear_contents(name => $name, sheet_name => $sheet_name, range => $range, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, folder => $folder, storage_name => $storage_name)

Clear cells contents.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $range = 'range_example'; # string | The range.
my $start_row = 56; # int | The start row.
my $start_column = 56; # int | The start column.
my $end_row = 56; # int | The end row.
my $end_column = 56; # int | The end column.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_clear_contents(name => $name, sheet_name => $sheet_name, range => $range, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_clear_contents: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **range** | **string**| The range. | [optional] 
 **start_row** | **int**| The start row. | [optional] 
 **start_column** | **int**| The start column. | [optional] 
 **end_row** | **int**| The end row. | [optional] 
 **end_column** | **int**| The end column. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_clear_formats**
> CellsCloudResponse cells_post_clear_formats(name => $name, sheet_name => $sheet_name, range => $range, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, folder => $folder, storage_name => $storage_name)

Clear cells contents.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $range = 'range_example'; # string | The range.
my $start_row = 56; # int | The start row.
my $start_column = 56; # int | The start column.
my $end_row = 56; # int | The end row.
my $end_column = 56; # int | The end column.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_clear_formats(name => $name, sheet_name => $sheet_name, range => $range, start_row => $start_row, start_column => $start_column, end_row => $end_row, end_column => $end_column, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_clear_formats: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **range** | **string**| The range. | [optional] 
 **start_row** | **int**| The start row. | [optional] 
 **start_column** | **int**| The start column. | [optional] 
 **end_row** | **int**| The end row. | [optional] 
 **end_column** | **int**| The end column. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_column_style**
> CellsCloudResponse cells_post_column_style(name => $name, sheet_name => $sheet_name, column_index => $column_index, style => $style, folder => $folder, storage_name => $storage_name)

Set column style

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $column_index = 56; # int | The column index.
my $style = AsposeCellsCloud::Object::Style->new(); # Style | Style dto
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_column_style(name => $name, sheet_name => $sheet_name, column_index => $column_index, style => $style, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_column_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **column_index** | **int**| The column index. | 
 **style** | [**Style**](Style.md)| Style dto | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_copy_cell_into_cell**
> CellsCloudResponse cells_post_copy_cell_into_cell(name => $name, dest_cell_name => $dest_cell_name, sheet_name => $sheet_name, worksheet => $worksheet, cellname => $cellname, row => $row, column => $column, folder => $folder, storage_name => $storage_name)

Copy cell into cell

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $dest_cell_name = 'dest_cell_name_example'; # string | Destination cell name
my $sheet_name = 'sheet_name_example'; # string | Destination worksheet name.
my $worksheet = 'worksheet_example'; # string | Source worksheet name.
my $cellname = 'cellname_example'; # string | Source cell name
my $row = 56; # int | Source row
my $column = 56; # int | Source column
my $folder = 'folder_example'; # string | Folder name
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_copy_cell_into_cell(name => $name, dest_cell_name => $dest_cell_name, sheet_name => $sheet_name, worksheet => $worksheet, cellname => $cellname, row => $row, column => $column, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_copy_cell_into_cell: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **dest_cell_name** | **string**| Destination cell name | 
 **sheet_name** | **string**| Destination worksheet name. | 
 **worksheet** | **string**| Source worksheet name. | 
 **cellname** | **string**| Source cell name | [optional] 
 **row** | **int**| Source row | [optional] 
 **column** | **int**| Source column | [optional] 
 **folder** | **string**| Folder name | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_copy_worksheet_columns**
> CellsCloudResponse cells_post_copy_worksheet_columns(name => $name, sheet_name => $sheet_name, source_column_index => $source_column_index, destination_column_index => $destination_column_index, column_number => $column_number, worksheet => $worksheet, folder => $folder, storage_name => $storage_name)

Copy worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $source_column_index = 56; # int | Source column index
my $destination_column_index = 56; # int | Destination column index
my $column_number = 56; # int | The copied column number
my $worksheet = 'worksheet_example'; # string | The Worksheet
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_copy_worksheet_columns(name => $name, sheet_name => $sheet_name, source_column_index => $source_column_index, destination_column_index => $destination_column_index, column_number => $column_number, worksheet => $worksheet, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_copy_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **source_column_index** | **int**| Source column index | 
 **destination_column_index** | **int**| Destination column index | 
 **column_number** | **int**| The copied column number | 
 **worksheet** | **string**| The Worksheet | [optional] [default to ]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_copy_worksheet_rows**
> CellsCloudResponse cells_post_copy_worksheet_rows(name => $name, sheet_name => $sheet_name, source_row_index => $source_row_index, destination_row_index => $destination_row_index, row_number => $row_number, worksheet => $worksheet, folder => $folder, storage_name => $storage_name)

Copy worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $source_row_index = 56; # int | Source row index
my $destination_row_index = 56; # int | Destination row index
my $row_number = 56; # int | The copied row number
my $worksheet = 'worksheet_example'; # string | worksheet
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_copy_worksheet_rows(name => $name, sheet_name => $sheet_name, source_row_index => $source_row_index, destination_row_index => $destination_row_index, row_number => $row_number, worksheet => $worksheet, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_copy_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **source_row_index** | **int**| Source row index | 
 **destination_row_index** | **int**| Destination row index | 
 **row_number** | **int**| The copied row number | 
 **worksheet** | **string**| worksheet | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_group_worksheet_columns**
> CellsCloudResponse cells_post_group_worksheet_columns(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, hide => $hide, folder => $folder, storage_name => $storage_name)

Group worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $first_index = 56; # int | The first column index to be operated.
my $last_index = 56; # int | The last column index to be operated.
my $hide = 1; # boolean | columns visible state
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_group_worksheet_columns(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, hide => $hide, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_group_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **first_index** | **int**| The first column index to be operated. | 
 **last_index** | **int**| The last column index to be operated. | 
 **hide** | **boolean**| columns visible state | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_group_worksheet_rows**
> CellsCloudResponse cells_post_group_worksheet_rows(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, hide => $hide, folder => $folder, storage_name => $storage_name)

Group worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $first_index = 56; # int | The first row index to be operated.
my $last_index = 56; # int | The last row index to be operated.
my $hide = 1; # boolean | rows visible state
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_group_worksheet_rows(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, hide => $hide, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_group_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **first_index** | **int**| The first row index to be operated. | 
 **last_index** | **int**| The last row index to be operated. | 
 **hide** | **boolean**| rows visible state | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_hide_worksheet_columns**
> CellsCloudResponse cells_post_hide_worksheet_columns(name => $name, sheet_name => $sheet_name, start_column => $start_column, total_columns => $total_columns, folder => $folder, storage_name => $storage_name)

Hide worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $start_column = 56; # int | The begin column index to be operated.
my $total_columns = 56; # int | Number of columns to be operated.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_hide_worksheet_columns(name => $name, sheet_name => $sheet_name, start_column => $start_column, total_columns => $total_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_hide_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **start_column** | **int**| The begin column index to be operated. | 
 **total_columns** | **int**| Number of columns to be operated. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_hide_worksheet_rows**
> CellsCloudResponse cells_post_hide_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, folder => $folder, storage_name => $storage_name)

Hide worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $startrow = 56; # int | The begin row index to be operated.
my $total_rows = 56; # int | Number of rows to be operated.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_hide_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_hide_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **startrow** | **int**| The begin row index to be operated. | 
 **total_rows** | **int**| Number of rows to be operated. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_row_style**
> CellsCloudResponse cells_post_row_style(name => $name, sheet_name => $sheet_name, row_index => $row_index, style => $style, folder => $folder, storage_name => $storage_name)

Set row style.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $row_index = 56; # int | The row index.
my $style = AsposeCellsCloud::Object::Style->new(); # Style | Style dto
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_row_style(name => $name, sheet_name => $sheet_name, row_index => $row_index, style => $style, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_row_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **row_index** | **int**| The row index. | 
 **style** | [**Style**](Style.md)| Style dto | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_set_cell_html_string**
> CellResponse cells_post_set_cell_html_string(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name)

Set htmlstring value into cell

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_set_cell_html_string(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_set_cell_html_string: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cell_name** | **string**| The cell name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellResponse**](CellResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_set_cell_range_value**
> CellsCloudResponse cells_post_set_cell_range_value(name => $name, sheet_name => $sheet_name, cellarea => $cellarea, value => $value, type => $type, folder => $folder, storage_name => $storage_name)

Set cell range value 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cellarea = 'cellarea_example'; # string | Cell area (like \"A1:C2\")
my $value = 'value_example'; # string | Range value
my $type = 'type_example'; # string | Value data type (like \"int\")
my $folder = 'folder_example'; # string | Folder name
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_set_cell_range_value(name => $name, sheet_name => $sheet_name, cellarea => $cellarea, value => $value, type => $type, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_set_cell_range_value: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cellarea** | **string**| Cell area (like \&quot;A1:C2\&quot;) | 
 **value** | **string**| Range value | 
 **type** | **string**| Value data type (like \&quot;int\&quot;) | 
 **folder** | **string**| Folder name | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_set_worksheet_column_width**
> ColumnResponse cells_post_set_worksheet_column_width(name => $name, sheet_name => $sheet_name, column_index => $column_index, width => $width, folder => $folder, storage_name => $storage_name)

Set worksheet column width.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $column_index = 56; # int | The column index.
my $width = 1.2; # double | The width.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_set_worksheet_column_width(name => $name, sheet_name => $sheet_name, column_index => $column_index, width => $width, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_set_worksheet_column_width: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **column_index** | **int**| The column index. | 
 **width** | **double**| The width. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ColumnResponse**](ColumnResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_ungroup_worksheet_columns**
> CellsCloudResponse cells_post_ungroup_worksheet_columns(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, folder => $folder, storage_name => $storage_name)

Ungroup worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $first_index = 56; # int | The first column index to be operated.
my $last_index = 56; # int | The last column index to be operated.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_ungroup_worksheet_columns(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_ungroup_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **first_index** | **int**| The first column index to be operated. | 
 **last_index** | **int**| The last column index to be operated. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_ungroup_worksheet_rows**
> CellsCloudResponse cells_post_ungroup_worksheet_rows(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, is_all => $is_all, folder => $folder, storage_name => $storage_name)

Ungroup worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $first_index = 56; # int | The first row index to be operated.
my $last_index = 56; # int | The last row index to be operated.
my $is_all = 1; # boolean | Is all row to be operated
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_ungroup_worksheet_rows(name => $name, sheet_name => $sheet_name, first_index => $first_index, last_index => $last_index, is_all => $is_all, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_ungroup_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **first_index** | **int**| The first row index to be operated. | 
 **last_index** | **int**| The last row index to be operated. | 
 **is_all** | **boolean**| Is all row to be operated | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_unhide_worksheet_columns**
> CellsCloudResponse cells_post_unhide_worksheet_columns(name => $name, sheet_name => $sheet_name, startcolumn => $startcolumn, total_columns => $total_columns, width => $width, folder => $folder, storage_name => $storage_name)

Unhide worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $startcolumn = 56; # int | The begin column index to be operated.
my $total_columns = 56; # int | Number of columns to be operated.
my $width = 1.2; # double | The new column width.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_unhide_worksheet_columns(name => $name, sheet_name => $sheet_name, startcolumn => $startcolumn, total_columns => $total_columns, width => $width, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_unhide_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **startcolumn** | **int**| The begin column index to be operated. | 
 **total_columns** | **int**| Number of columns to be operated. | 
 **width** | **double**| The new column width. | [optional] [default to 50.0]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_unhide_worksheet_rows**
> CellsCloudResponse cells_post_unhide_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, height => $height, folder => $folder, storage_name => $storage_name)

Unhide worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $startrow = 56; # int | The begin row index to be operated.
my $total_rows = 56; # int | Number of rows to be operated.
my $height = 1.2; # double | The new row height.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_unhide_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, height => $height, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_unhide_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **startrow** | **int**| The begin row index to be operated. | 
 **total_rows** | **int**| Number of rows to be operated. | 
 **height** | **double**| The new row height. | [optional] [default to 15.0]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_update_worksheet_cell_style**
> StyleResponse cells_post_update_worksheet_cell_style(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, style => $style, folder => $folder, storage_name => $storage_name)

Update cell's style.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name.
my $style = AsposeCellsCloud::Object::Style->new(); # Style | with update style settings.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_update_worksheet_cell_style(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, style => $style, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_update_worksheet_cell_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **cell_name** | **string**| The cell name. | 
 **style** | [**Style**](Style.md)| with update style settings. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**StyleResponse**](StyleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_update_worksheet_range_style**
> CellsCloudResponse cells_post_update_worksheet_range_style(name => $name, sheet_name => $sheet_name, range => $range, style => $style, folder => $folder, storage_name => $storage_name)

Update cell's range style.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $range = 'range_example'; # string | The range.
my $style = AsposeCellsCloud::Object::Style->new(); # Style | with update style settings.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_update_worksheet_range_style(name => $name, sheet_name => $sheet_name, range => $range, style => $style, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_update_worksheet_range_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **range** | **string**| The range. | 
 **style** | [**Style**](Style.md)| with update style settings. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_update_worksheet_row**
> RowResponse cells_post_update_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, height => $height, folder => $folder, storage_name => $storage_name)

Update worksheet row.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $row_index = 56; # int | The row index.
my $height = 1.2; # double | The new row height.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_update_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, height => $height, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_update_worksheet_row: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **row_index** | **int**| The row index. | 
 **height** | **double**| The new row height. | [optional] [default to 0.0]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RowResponse**](RowResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_worksheet_cell_set_value**
> CellResponse cells_post_worksheet_cell_set_value(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, value => $value, type => $type, formula => $formula, folder => $folder, storage_name => $storage_name)

Set cell value.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name.
my $value = 'value_example'; # string | The cell value.
my $type = 'type_example'; # string | The value type.
my $formula = 'formula_example'; # string | Formula for cell
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_worksheet_cell_set_value(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, value => $value, type => $type, formula => $formula, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_worksheet_cell_set_value: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_name** | **string**| The cell name. | 
 **value** | **string**| The cell value. | [optional] 
 **type** | **string**| The value type. | [optional] 
 **formula** | **string**| Formula for cell | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellResponse**](CellResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_worksheet_merge**
> CellsCloudResponse cells_post_worksheet_merge(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name)

Merge cells.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $start_row = 56; # int | The start row.
my $start_column = 56; # int | The start column.
my $total_rows = 56; # int | The total rows
my $total_columns = 56; # int | The total columns.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_worksheet_merge(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_worksheet_merge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **start_row** | **int**| The start row. | 
 **start_column** | **int**| The start column. | 
 **total_rows** | **int**| The total rows | 
 **total_columns** | **int**| The total columns. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_post_worksheet_unmerge**
> CellsCloudResponse cells_post_worksheet_unmerge(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name)

Unmerge cells.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $start_row = 56; # int | The start row.
my $start_column = 56; # int | The start column.
my $total_rows = 56; # int | The total rows
my $total_columns = 56; # int | The total columns.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_post_worksheet_unmerge(name => $name, sheet_name => $sheet_name, start_row => $start_row, start_column => $start_column, total_rows => $total_rows, total_columns => $total_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_post_worksheet_unmerge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **start_row** | **int**| The start row. | 
 **start_column** | **int**| The start column. | 
 **total_rows** | **int**| The total rows | 
 **total_columns** | **int**| The total columns. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_properties_delete_document_properties**
> CellsDocumentPropertiesResponse cells_properties_delete_document_properties(name => $name, folder => $folder, storage_name => $storage_name)

Delete all custom document properties and clean built-in ones.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_properties_delete_document_properties(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_properties_delete_document_properties: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsDocumentPropertiesResponse**](CellsDocumentPropertiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_properties_delete_document_property**
> CellsDocumentPropertiesResponse cells_properties_delete_document_property(name => $name, property_name => $property_name, folder => $folder, storage_name => $storage_name)

Delete document property.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $property_name = 'property_name_example'; # string | The property name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_properties_delete_document_property(name => $name, property_name => $property_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_properties_delete_document_property: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **property_name** | **string**| The property name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsDocumentPropertiesResponse**](CellsDocumentPropertiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_properties_get_document_properties**
> CellsDocumentPropertiesResponse cells_properties_get_document_properties(name => $name, folder => $folder, storage_name => $storage_name)

Read document properties.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_properties_get_document_properties(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_properties_get_document_properties: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsDocumentPropertiesResponse**](CellsDocumentPropertiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_properties_get_document_property**
> CellsDocumentPropertyResponse cells_properties_get_document_property(name => $name, property_name => $property_name, folder => $folder, storage_name => $storage_name)

Read document property by name.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $property_name = 'property_name_example'; # string | The property name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_properties_get_document_property(name => $name, property_name => $property_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_properties_get_document_property: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **property_name** | **string**| The property name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsDocumentPropertyResponse**](CellsDocumentPropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_properties_put_document_property**
> CellsDocumentPropertyResponse cells_properties_put_document_property(name => $name, property_name => $property_name, property => $property, folder => $folder, storage_name => $storage_name)

Set/create document property.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $property_name = 'property_name_example'; # string | The property name.
my $property = AsposeCellsCloud::Object::CellsDocumentProperty->new(); # CellsDocumentProperty | with new property value.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_properties_put_document_property(name => $name, property_name => $property_name, property => $property, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_properties_put_document_property: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **property_name** | **string**| The property name. | 
 **property** | [**CellsDocumentProperty**](CellsDocumentProperty.md)| with new property value. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsDocumentPropertyResponse**](CellsDocumentPropertyResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_put_insert_worksheet_columns**
> ColumnsResponse cells_put_insert_worksheet_columns(name => $name, sheet_name => $sheet_name, column_index => $column_index, columns => $columns, update_reference => $update_reference, folder => $folder, storage_name => $storage_name)

Insert worksheet columns.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $column_index = 56; # int | The column index.
my $columns = 56; # int | The columns.
my $update_reference = 1; # boolean | The update reference.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_put_insert_worksheet_columns(name => $name, sheet_name => $sheet_name, column_index => $column_index, columns => $columns, update_reference => $update_reference, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_put_insert_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **column_index** | **int**| The column index. | 
 **columns** | **int**| The columns. | 
 **update_reference** | **boolean**| The update reference. | [optional] [default to true]
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ColumnsResponse**](ColumnsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_put_insert_worksheet_row**
> RowResponse cells_put_insert_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name)

Insert new worksheet row.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $row_index = 56; # int | The new row index.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_put_insert_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_put_insert_worksheet_row: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **row_index** | **int**| The new row index. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RowResponse**](RowResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_put_insert_worksheet_rows**
> CellsCloudResponse cells_put_insert_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, update_reference => $update_reference, folder => $folder, storage_name => $storage_name)

Insert several new worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $startrow = 56; # int | The begin row index to be operated.
my $total_rows = 56; # int | Number of rows to be operated.
my $update_reference = 1; # boolean | Indicates if update references in other worksheets.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_put_insert_worksheet_rows(name => $name, sheet_name => $sheet_name, startrow => $startrow, total_rows => $total_rows, update_reference => $update_reference, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_put_insert_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **startrow** | **int**| The begin row index to be operated. | 
 **total_rows** | **int**| Number of rows to be operated. | [optional] [default to 1]
 **update_reference** | **boolean**| Indicates if update references in other worksheets. | [optional] [default to true]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_get_worksheet_cells_range_value**
> RangeValueResponse cells_ranges_get_worksheet_cells_range_value(name => $name, sheet_name => $sheet_name, namerange => $namerange, first_row => $first_row, first_column => $first_column, row_count => $row_count, column_count => $column_count, folder => $folder, storage_name => $storage_name)

Get cells list in a range by range name or row column indexes  

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $namerange = 'namerange_example'; # string | range name, for example: 'A1:B2' or 'range_name1'
my $first_row = 56; # int | the first row of the range
my $first_column = 56; # int | the first column of the range
my $row_count = 56; # int | the count of rows in the range
my $column_count = 56; # int | the count of columns in the range
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_get_worksheet_cells_range_value(name => $name, sheet_name => $sheet_name, namerange => $namerange, first_row => $first_row, first_column => $first_column, row_count => $row_count, column_count => $column_count, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_get_worksheet_cells_range_value: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **namerange** | **string**| range name, for example: &#39;A1:B2&#39; or &#39;range_name1&#39; | [optional] 
 **first_row** | **int**| the first row of the range | [optional] 
 **first_column** | **int**| the first column of the range | [optional] 
 **row_count** | **int**| the count of rows in the range | [optional] 
 **column_count** | **int**| the count of columns in the range | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RangeValueResponse**](RangeValueResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_column_width**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_column_width(name => $name, sheet_name => $sheet_name, value => $value, range => $range, folder => $folder, storage_name => $storage_name)

Set column width of range

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $value = 1.2; # double | 
my $range = AsposeCellsCloud::Object::Range->new(); # Range | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_column_width(name => $name, sheet_name => $sheet_name, value => $value, range => $range, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_column_width: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **value** | **double**|  | 
 **range** | [**Range**](Range.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_merge**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_merge(name => $name, sheet_name => $sheet_name, range => $range, folder => $folder, storage_name => $storage_name)

Combines a range of cells into a single cell.              

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $range = AsposeCellsCloud::Object::Range->new(); # Range | range in worksheet 
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_merge(name => $name, sheet_name => $sheet_name, range => $range, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_merge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **range** | [**Range**](Range.md)| range in worksheet  | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_move_to**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_move_to(name => $name, sheet_name => $sheet_name, dest_row => $dest_row, dest_column => $dest_column, range => $range, folder => $folder, storage_name => $storage_name)

Move the current range to the dest range.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $dest_row = 56; # int | The start row of the dest range.
my $dest_column = 56; # int | The start column of the dest range.
my $range = AsposeCellsCloud::Object::Range->new(); # Range | range in worksheet 
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_move_to(name => $name, sheet_name => $sheet_name, dest_row => $dest_row, dest_column => $dest_column, range => $range, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_move_to: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **dest_row** | **int**| The start row of the dest range. | 
 **dest_column** | **int**| The start column of the dest range. | 
 **range** | [**Range**](Range.md)| range in worksheet  | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_outline_border**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_outline_border(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name)

Sets outline border around a range of cells.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $range_operate = AsposeCellsCloud::Object::RangeSetOutlineBorderRequest->new(); # RangeSetOutlineBorderRequest | Range Set OutlineBorder Request 
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_outline_border(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_outline_border: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **range_operate** | [**RangeSetOutlineBorderRequest**](RangeSetOutlineBorderRequest.md)| Range Set OutlineBorder Request  | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_row_height**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_row_height(name => $name, sheet_name => $sheet_name, value => $value, range => $range, folder => $folder, storage_name => $storage_name)

set row height of range

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $value = 1.2; # double | 
my $range = AsposeCellsCloud::Object::Range->new(); # Range | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_row_height(name => $name, sheet_name => $sheet_name, value => $value, range => $range, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_row_height: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **value** | **double**|  | 
 **range** | [**Range**](Range.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_style**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_style(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name)

Sets the style of the range.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $range_operate = AsposeCellsCloud::Object::RangeSetStyleRequest->new(); # RangeSetStyleRequest | Range Set Style Request 
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_style(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **range_operate** | [**RangeSetStyleRequest**](RangeSetStyleRequest.md)| Range Set Style Request  | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_unmerge**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_unmerge(name => $name, sheet_name => $sheet_name, range => $range, folder => $folder, storage_name => $storage_name)

Unmerges merged cells of this range.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $range = AsposeCellsCloud::Object::Range->new(); # Range | range in worksheet 
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_unmerge(name => $name, sheet_name => $sheet_name, range => $range, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_unmerge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **range** | [**Range**](Range.md)| range in worksheet  | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_range_value**
> CellsCloudResponse cells_ranges_post_worksheet_cells_range_value(name => $name, sheet_name => $sheet_name, value => $value, range => $range, is_converted => $is_converted, set_style => $set_style, folder => $folder, storage_name => $storage_name)

Puts a value into the range, if appropriate the value will be converted to other data type and cell's number format will be reset.             

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $value = 'value_example'; # string | Input value
my $range = AsposeCellsCloud::Object::Range->new(); # Range | range in worksheet 
my $is_converted = 1; # boolean | True: converted to other data type if appropriate.
my $set_style = 1; # boolean | True: set the number format to cell's style when converting to other data type
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_range_value(name => $name, sheet_name => $sheet_name, value => $value, range => $range, is_converted => $is_converted, set_style => $set_style, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_range_value: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **value** | **string**| Input value | 
 **range** | [**Range**](Range.md)| range in worksheet  | [optional] 
 **is_converted** | **boolean**| True: converted to other data type if appropriate. | [optional] [default to false]
 **set_style** | **boolean**| True: set the number format to cell&#39;s style when converting to other data type | [optional] [default to false]
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_ranges_post_worksheet_cells_ranges**
> CellsCloudResponse cells_ranges_post_worksheet_cells_ranges(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name)

copy range in the worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | workbook name
my $sheet_name = 'sheet_name_example'; # string | worksheet name
my $range_operate = AsposeCellsCloud::Object::RangeCopyRequest->new(); # RangeCopyRequest | copydata,copystyle,copyto,copyvalue
my $folder = 'folder_example'; # string | Workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_ranges_post_worksheet_cells_ranges(name => $name, sheet_name => $sheet_name, range_operate => $range_operate, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_ranges_post_worksheet_cells_ranges: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| workbook name | 
 **sheet_name** | **string**| worksheet name | 
 **range_operate** | [**RangeCopyRequest**](RangeCopyRequest.md)| copydata,copystyle,copyto,copyvalue | [optional] 
 **folder** | **string**| Workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_save_as_post_document_save_as**
> SaveResponse cells_save_as_post_document_save_as(name => $name, save_options => $save_options, newfilename => $newfilename, is_auto_fit_rows => $is_auto_fit_rows, is_auto_fit_columns => $is_auto_fit_columns, folder => $folder, storage_name => $storage_name)

Convert document and save result to storage.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $save_options = AsposeCellsCloud::Object::SaveOptions->new(); # SaveOptions | Save options.
my $newfilename = 'newfilename_example'; # string | The new file name.
my $is_auto_fit_rows = 1; # boolean | Autofit rows.
my $is_auto_fit_columns = 1; # boolean | Autofit columns.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_save_as_post_document_save_as(name => $name, save_options => $save_options, newfilename => $newfilename, is_auto_fit_rows => $is_auto_fit_rows, is_auto_fit_columns => $is_auto_fit_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_save_as_post_document_save_as: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **save_options** | [**SaveOptions**](SaveOptions.md)| Save options. | [optional] 
 **newfilename** | **string**| The new file name. | [optional] 
 **is_auto_fit_rows** | **boolean**| Autofit rows. | [optional] [default to false]
 **is_auto_fit_columns** | **boolean**| Autofit columns. | [optional] [default to false]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**SaveResponse**](SaveResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_delete_worksheet_shape**
> CellsCloudResponse cells_shapes_delete_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, folder => $folder, storage_name => $storage_name)

Delete a shape in worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $shapeindex = 56; # int | shape index in worksheet shapes.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_delete_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_delete_worksheet_shape: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **shapeindex** | **int**| shape index in worksheet shapes. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_delete_worksheet_shapes**
> CellsCloudResponse cells_shapes_delete_worksheet_shapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

delete all shapes in worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_delete_worksheet_shapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_delete_worksheet_shapes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_get_worksheet_shape**
> ShapeResponse cells_shapes_get_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, folder => $folder, storage_name => $storage_name)

Get worksheet shape

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $shapeindex = 56; # int | shape index in worksheet shapes.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_get_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_get_worksheet_shape: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **shapeindex** | **int**| shape index in worksheet shapes. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ShapeResponse**](ShapeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_get_worksheet_shapes**
> ShapesResponse cells_shapes_get_worksheet_shapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet shapes 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_get_worksheet_shapes(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_get_worksheet_shapes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ShapesResponse**](ShapesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_post_worksheet_shape**
> CellsCloudResponse cells_shapes_post_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, dto => $dto, folder => $folder, storage_name => $storage_name)

Update a shape in worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $shapeindex = 56; # int | shape index in worksheet shapes.
my $dto = AsposeCellsCloud::Object::Shape->new(); # Shape | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_post_worksheet_shape(name => $name, sheet_name => $sheet_name, shapeindex => $shapeindex, dto => $dto, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_post_worksheet_shape: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **shapeindex** | **int**| shape index in worksheet shapes. | 
 **dto** | [**Shape**](Shape.md)|  | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_shapes_put_worksheet_shape**
> ShapeResponse cells_shapes_put_worksheet_shape(name => $name, sheet_name => $sheet_name, shape_dto => $shape_dto, drawing_type => $drawing_type, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, top => $top, left => $left, width => $width, height => $height, folder => $folder, storage_name => $storage_name)

Add shape in worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | document name.
my $sheet_name = 'sheet_name_example'; # string | worksheet name.
my $shape_dto = AsposeCellsCloud::Object::Shape->new(); # Shape | 
my $drawing_type = 'drawing_type_example'; # string | shape object type
my $upper_left_row = 56; # int | Upper left row index.
my $upper_left_column = 56; # int | Upper left column index.
my $top = 56; # int | Represents the vertical offset of Spinner from its left row, in unit of pixel.
my $left = 56; # int | Represents the horizontal offset of Spinner from its left column, in unit of pixel.
my $width = 56; # int | Represents the height of Spinner, in unit of pixel.
my $height = 56; # int | Represents the width of Spinner, in unit of pixel.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_shapes_put_worksheet_shape(name => $name, sheet_name => $sheet_name, shape_dto => $shape_dto, drawing_type => $drawing_type, upper_left_row => $upper_left_row, upper_left_column => $upper_left_column, top => $top, left => $left, width => $width, height => $height, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_shapes_put_worksheet_shape: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| document name. | 
 **sheet_name** | **string**| worksheet name. | 
 **shape_dto** | [**Shape**](Shape.md)|  | [optional] 
 **drawing_type** | **string**| shape object type | [optional] 
 **upper_left_row** | **int**| Upper left row index. | [optional] 
 **upper_left_column** | **int**| Upper left column index. | [optional] 
 **top** | **int**| Represents the vertical offset of Spinner from its left row, in unit of pixel. | [optional] 
 **left** | **int**| Represents the horizontal offset of Spinner from its left column, in unit of pixel. | [optional] 
 **width** | **int**| Represents the height of Spinner, in unit of pixel. | [optional] 
 **height** | **int**| Represents the width of Spinner, in unit of pixel. | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ShapeResponse**](ShapeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_delete_worksheet_sparkline_group**
> CellsCloudResponse cells_sparkline_groups_delete_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_index => $sparkline_index, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $sparkline_index = 56; # int | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_sparkline_groups_delete_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_index => $sparkline_index, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_delete_worksheet_sparkline_group: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **sparkline_index** | **int**|  | 
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_delete_worksheet_sparkline_groups**
> CellsCloudResponse cells_sparkline_groups_delete_worksheet_sparkline_groups(name => $name, sheet_name => $sheet_name, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_sparkline_groups_delete_worksheet_sparkline_groups(name => $name, sheet_name => $sheet_name, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_delete_worksheet_sparkline_groups: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_get_worksheet_sparkline_group**
> SparklineGroupResponse cells_sparkline_groups_get_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_index => $sparkline_index, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $sparkline_index = 56; # int | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_sparkline_groups_get_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_index => $sparkline_index, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_get_worksheet_sparkline_group: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **sparkline_index** | **int**|  | 
 **folder** | **string**|  | [optional] 

### Return type

[**SparklineGroupResponse**](SparklineGroupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_get_worksheet_sparkline_groups**
> SparklineGroupsResponse cells_sparkline_groups_get_worksheet_sparkline_groups(name => $name, sheet_name => $sheet_name, folder => $folder)

Get worksheet charts description.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.

eval { 
    my $result = $api_instance->cells_sparkline_groups_get_worksheet_sparkline_groups(name => $name, sheet_name => $sheet_name, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_get_worksheet_sparkline_groups: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 

### Return type

[**SparklineGroupsResponse**](SparklineGroupsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_post_worksheet_sparkline_group**
> CellsCloudResponse cells_sparkline_groups_post_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_group_index => $sparkline_group_index, sparkline_group => $sparkline_group, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $sparkline_group_index = 56; # int | 
my $sparkline_group = AsposeCellsCloud::Object::SparklineGroup->new(); # SparklineGroup | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_sparkline_groups_post_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, sparkline_group_index => $sparkline_group_index, sparkline_group => $sparkline_group, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_post_worksheet_sparkline_group: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **sparkline_group_index** | **int**|  | 
 **sparkline_group** | [**SparklineGroup**](SparklineGroup.md)|  | 
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_sparkline_groups_put_worksheet_sparkline_group**
> CellsCloudResponse cells_sparkline_groups_put_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, type => $type, data_range => $data_range, is_vertical => $is_vertical, location_range => $location_range, folder => $folder)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $type = 'type_example'; # string | 
my $data_range = 'data_range_example'; # string | 
my $is_vertical = 1; # boolean | 
my $location_range = 'location_range_example'; # string | 
my $folder = 'folder_example'; # string | 

eval { 
    my $result = $api_instance->cells_sparkline_groups_put_worksheet_sparkline_group(name => $name, sheet_name => $sheet_name, type => $type, data_range => $data_range, is_vertical => $is_vertical, location_range => $location_range, folder => $folder);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_sparkline_groups_put_worksheet_sparkline_group: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **type** | **string**|  | 
 **data_range** | **string**|  | 
 **is_vertical** | **boolean**|  | 
 **location_range** | **string**|  | 
 **folder** | **string**|  | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_task_post_run_task**
> object cells_task_post_run_task(task_data => $task_data)

Run tasks  

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $task_data = AsposeCellsCloud::Object::String->new(); # String | 

eval { 
    my $result = $api_instance->cells_task_post_run_task(task_data => $task_data);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_task_post_run_task: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **task_data** | [**String**](String.md)|  | 

### Return type

**object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_decrypt_document**
> CellsCloudResponse cells_workbook_delete_decrypt_document(name => $name, encryption => $encryption, folder => $folder, storage_name => $storage_name)

Decrypt document.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $encryption = AsposeCellsCloud::Object::WorkbookEncryptionRequest->new(); # WorkbookEncryptionRequest | Encryption settings, only password can be specified.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_decrypt_document(name => $name, encryption => $encryption, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_decrypt_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **encryption** | [**WorkbookEncryptionRequest**](WorkbookEncryptionRequest.md)| Encryption settings, only password can be specified. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_document_unprotect_from_changes**
> CellsCloudResponse cells_workbook_delete_document_unprotect_from_changes(name => $name, folder => $folder, storage_name => $storage_name)

Unprotect document from changes.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_document_unprotect_from_changes(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_document_unprotect_from_changes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_unprotect_document**
> CellsCloudResponse cells_workbook_delete_unprotect_document(name => $name, protection => $protection, folder => $folder, storage_name => $storage_name)

Unprotect document.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $protection = AsposeCellsCloud::Object::WorkbookProtectionRequest->new(); # WorkbookProtectionRequest | Protection settings, only password can be specified.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_unprotect_document(name => $name, protection => $protection, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_unprotect_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **protection** | [**WorkbookProtectionRequest**](WorkbookProtectionRequest.md)| Protection settings, only password can be specified. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_workbook_background**
> CellsCloudResponse cells_workbook_delete_workbook_background(name => $name, folder => $folder, storage_name => $storage_name)

Set worksheet background image.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_workbook_background(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_workbook_background: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_workbook_name**
> CellsCloudResponse cells_workbook_delete_workbook_name(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name)

Clean workbook's names.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $name_name = 'name_name_example'; # string | The name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_workbook_name(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_workbook_name: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **name_name** | **string**| The name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_delete_workbook_names**
> CellsCloudResponse cells_workbook_delete_workbook_names(name => $name, folder => $folder, storage_name => $storage_name)

Clean workbook's names.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_delete_workbook_names(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_delete_workbook_names: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook**
> string cells_workbook_get_workbook(name => $name, password => $password, format => $format, is_auto_fit => $is_auto_fit, only_save_table => $only_save_table, folder => $folder, storage_name => $storage_name, out_path => $out_path)

Read workbook info or export.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $password = 'password_example'; # string | The document password.
my $format = 'format_example'; # string | The exported file format.
my $is_auto_fit = 1; # boolean | Set document rows to be autofit.
my $only_save_table = 1; # boolean | Only save table data.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.
my $out_path = 'out_path_example'; # string | The document output folder.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook(name => $name, password => $password, format => $format, is_auto_fit => $is_auto_fit, only_save_table => $only_save_table, folder => $folder, storage_name => $storage_name, out_path => $out_path);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **password** | **string**| The document password. | [optional] 
 **format** | **string**| The exported file format. | [optional] 
 **is_auto_fit** | **boolean**| Set document rows to be autofit. | [optional] [default to false]
 **only_save_table** | **boolean**| Only save table data. | [optional] [default to false]
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **out_path** | **string**| The document output folder. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_default_style**
> StyleResponse cells_workbook_get_workbook_default_style(name => $name, folder => $folder, storage_name => $storage_name)

Read workbook default style info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $folder = 'folder_example'; # string | The document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_default_style(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_default_style: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **folder** | **string**| The document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**StyleResponse**](StyleResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_name**
> NameResponse cells_workbook_get_workbook_name(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name)

Read workbook's name.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $name_name = 'name_name_example'; # string | The name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_name(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_name: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **name_name** | **string**| The name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**NameResponse**](NameResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_name_value**
> RangeValueResponse cells_workbook_get_workbook_name_value(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name)

Get workbook's name value.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $name_name = 'name_name_example'; # string | The name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_name_value(name => $name, name_name => $name_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_name_value: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **name_name** | **string**| The name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RangeValueResponse**](RangeValueResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_names**
> NamesResponse cells_workbook_get_workbook_names(name => $name, folder => $folder, storage_name => $storage_name)

Read workbook's names.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_names(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_names: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**NamesResponse**](NamesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_settings**
> WorkbookSettingsResponse cells_workbook_get_workbook_settings(name => $name, folder => $folder, storage_name => $storage_name)

Get Workbook Settings DTO

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_settings(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_settings: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorkbookSettingsResponse**](WorkbookSettingsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_get_workbook_text_items**
> TextItemsResponse cells_workbook_get_workbook_text_items(name => $name, folder => $folder, storage_name => $storage_name)

Read workbook's text items.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_get_workbook_text_items(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_get_workbook_text_items: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TextItemsResponse**](TextItemsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_autofit_workbook_rows**
> CellsCloudResponse cells_workbook_post_autofit_workbook_rows(name => $name, auto_fitter_options => $auto_fitter_options, start_row => $start_row, end_row => $end_row, only_auto => $only_auto, folder => $folder, storage_name => $storage_name)

Autofit workbook rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $auto_fitter_options = AsposeCellsCloud::Object::AutoFitterOptions->new(); # AutoFitterOptions | Auto Fitter Options.
my $start_row = 56; # int | Start row.
my $end_row = 56; # int | End row.
my $only_auto = 1; # boolean | Only auto.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_autofit_workbook_rows(name => $name, auto_fitter_options => $auto_fitter_options, start_row => $start_row, end_row => $end_row, only_auto => $only_auto, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_autofit_workbook_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **auto_fitter_options** | [**AutoFitterOptions**](AutoFitterOptions.md)| Auto Fitter Options. | [optional] 
 **start_row** | **int**| Start row. | [optional] 
 **end_row** | **int**| End row. | [optional] 
 **only_auto** | **boolean**| Only auto. | [optional] [default to false]
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_encrypt_document**
> CellsCloudResponse cells_workbook_post_encrypt_document(name => $name, encryption => $encryption, folder => $folder, storage_name => $storage_name)

Encript document.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $encryption = AsposeCellsCloud::Object::WorkbookEncryptionRequest->new(); # WorkbookEncryptionRequest | Encryption parameters.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_encrypt_document(name => $name, encryption => $encryption, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_encrypt_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **encryption** | [**WorkbookEncryptionRequest**](WorkbookEncryptionRequest.md)| Encryption parameters. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_import_data**
> CellsCloudResponse cells_workbook_post_import_data(name => $name, importdata => $importdata, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $importdata = AsposeCellsCloud::Object::String->new(); # String | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_import_data(name => $name, importdata => $importdata, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_import_data: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **importdata** | [**String**](String.md)|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_protect_document**
> CellsCloudResponse cells_workbook_post_protect_document(name => $name, protection => $protection, folder => $folder, storage_name => $storage_name)

Protect document.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $protection = AsposeCellsCloud::Object::WorkbookProtectionRequest->new(); # WorkbookProtectionRequest | The protection settings.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_protect_document(name => $name, protection => $protection, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_protect_document: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **protection** | [**WorkbookProtectionRequest**](WorkbookProtectionRequest.md)| The protection settings. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbook_calculate_formula**
> CellsCloudResponse cells_workbook_post_workbook_calculate_formula(name => $name, options => $options, ignore_error => $ignore_error, folder => $folder, storage_name => $storage_name)

Calculate all formulas in workbook.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $options = AsposeCellsCloud::Object::CalculationOptions->new(); # CalculationOptions | Calculation Options.
my $ignore_error = 1; # boolean | ignore Error.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbook_calculate_formula(name => $name, options => $options, ignore_error => $ignore_error, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbook_calculate_formula: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **options** | [**CalculationOptions**](CalculationOptions.md)| Calculation Options. | [optional] 
 **ignore_error** | **boolean**| ignore Error. | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbook_get_smart_marker_result**
> string cells_workbook_post_workbook_get_smart_marker_result(name => $name, xml_file => $xml_file, folder => $folder, storage_name => $storage_name, out_path => $out_path)

Smart marker processing result.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $xml_file = 'xml_file_example'; # string | The xml file full path, if empty the data is read from request body.
my $folder = 'folder_example'; # string | The workbook folder full path.
my $storage_name = 'storage_name_example'; # string | storage name.
my $out_path = 'out_path_example'; # string | Path to save result

eval { 
    my $result = $api_instance->cells_workbook_post_workbook_get_smart_marker_result(name => $name, xml_file => $xml_file, folder => $folder, storage_name => $storage_name, out_path => $out_path);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbook_get_smart_marker_result: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **xml_file** | **string**| The xml file full path, if empty the data is read from request body. | [optional] 
 **folder** | **string**| The workbook folder full path. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **out_path** | **string**| Path to save result | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbook_settings**
> CellsCloudResponse cells_workbook_post_workbook_settings(name => $name, settings => $settings, folder => $folder, storage_name => $storage_name)

Update Workbook setting 

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $settings = AsposeCellsCloud::Object::WorkbookSettings->new(); # WorkbookSettings | Workbook Setting DTO
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbook_settings(name => $name, settings => $settings, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbook_settings: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **settings** | [**WorkbookSettings**](WorkbookSettings.md)| Workbook Setting DTO | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbook_split**
> SplitResultResponse cells_workbook_post_workbook_split(name => $name, format => $format, from => $from, to => $to, horizontal_resolution => $horizontal_resolution, vertical_resolution => $vertical_resolution, folder => $folder, out_folder => $out_folder, storage_name => $storage_name)

Split workbook.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $format = 'format_example'; # string | Split format.
my $from = 56; # int | Start worksheet index.
my $to = 56; # int | End worksheet index.
my $horizontal_resolution = 56; # int | Image horizontal resolution.
my $vertical_resolution = 56; # int | Image vertical resolution.
my $folder = 'folder_example'; # string | The workbook folder.
my $out_folder = 'out_folder_example'; # string | out Folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbook_split(name => $name, format => $format, from => $from, to => $to, horizontal_resolution => $horizontal_resolution, vertical_resolution => $vertical_resolution, folder => $folder, out_folder => $out_folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbook_split: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **format** | **string**| Split format. | [optional] 
 **from** | **int**| Start worksheet index. | [optional] [default to 0]
 **to** | **int**| End worksheet index. | [optional] [default to 0]
 **horizontal_resolution** | **int**| Image horizontal resolution. | [optional] [default to 0]
 **vertical_resolution** | **int**| Image vertical resolution. | [optional] [default to 0]
 **folder** | **string**| The workbook folder. | [optional] 
 **out_folder** | **string**| out Folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**SplitResultResponse**](SplitResultResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbooks_merge**
> WorkbookResponse cells_workbook_post_workbooks_merge(name => $name, merge_with => $merge_with, folder => $folder, storage_name => $storage_name)

Merge workbooks.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $merge_with = 'merge_with_example'; # string | The workbook to merge with.
my $folder = 'folder_example'; # string | Source workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbooks_merge(name => $name, merge_with => $merge_with, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbooks_merge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **merge_with** | **string**| The workbook to merge with. | 
 **folder** | **string**| Source workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorkbookResponse**](WorkbookResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbooks_text_replace**
> WorkbookReplaceResponse cells_workbook_post_workbooks_text_replace(name => $name, old_value => $old_value, new_value => $new_value, folder => $folder, storage_name => $storage_name)

Replace text.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $old_value = 'old_value_example'; # string | The old value.
my $new_value = 'new_value_example'; # string | The new value.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbooks_text_replace(name => $name, old_value => $old_value, new_value => $new_value, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbooks_text_replace: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **old_value** | **string**| The old value. | 
 **new_value** | **string**| The new value. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorkbookReplaceResponse**](WorkbookReplaceResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_post_workbooks_text_search**
> TextItemsResponse cells_workbook_post_workbooks_text_search(name => $name, text => $text, folder => $folder, storage_name => $storage_name)

Search text.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $text = 'text_example'; # string | Text sample.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_post_workbooks_text_search(name => $name, text => $text, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_post_workbooks_text_search: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **text** | **string**| Text sample. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TextItemsResponse**](TextItemsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_put_convert_workbook**
> string cells_workbook_put_convert_workbook(workbook => $workbook, format => $format, password => $password, out_path => $out_path)

Convert workbook from request content to some format.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $workbook = AsposeCellsCloud::Object::string->new(); # string | File to convert
my $format = 'format_example'; # string | The format to convert.
my $password = 'password_example'; # string | The workbook password.
my $out_path = 'out_path_example'; # string | Path to save result

eval { 
    my $result = $api_instance->cells_workbook_put_convert_workbook(workbook => $workbook, format => $format, password => $password, out_path => $out_path);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_put_convert_workbook: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **workbook** | **string**| File to convert | 
 **format** | **string**| The format to convert. | [optional] 
 **password** | **string**| The workbook password. | [optional] 
 **out_path** | **string**| Path to save result | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_put_document_protect_from_changes**
> CellsCloudResponse cells_workbook_put_document_protect_from_changes(name => $name, password => $password, folder => $folder, storage_name => $storage_name)

Protect document from changes.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $password = AsposeCellsCloud::Object::PasswordRequest->new(); # PasswordRequest | Modification password.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_put_document_protect_from_changes(name => $name, password => $password, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_put_document_protect_from_changes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **password** | [**PasswordRequest**](PasswordRequest.md)| Modification password. | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_put_workbook_background**
> CellsCloudResponse cells_workbook_put_workbook_background(name => $name, png => $png, folder => $folder, storage_name => $storage_name)

Set workbook background image.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $png = AsposeCellsCloud::Object::string->new(); # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_put_workbook_background(name => $name, png => $png, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_put_workbook_background: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **png** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_put_workbook_create**
> WorkbookResponse cells_workbook_put_workbook_create(name => $name, template_file => $template_file, data_file => $data_file, is_write_over => $is_write_over, folder => $folder, storage_name => $storage_name)

Create new workbook using deferent methods.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The new document name.
my $template_file = 'template_file_example'; # string | The template file, if the data not provided default workbook is created.
my $data_file = 'data_file_example'; # string | Smart marker data file, if the data not provided the request content is checked for the data.
my $is_write_over = 1; # boolean | write over file.
my $folder = 'folder_example'; # string | The new document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_workbook_put_workbook_create(name => $name, template_file => $template_file, data_file => $data_file, is_write_over => $is_write_over, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_put_workbook_create: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The new document name. | 
 **template_file** | **string**| The template file, if the data not provided default workbook is created. | [optional] 
 **data_file** | **string**| Smart marker data file, if the data not provided the request content is checked for the data. | [optional] 
 **is_write_over** | **boolean**| write over file. | [optional] 
 **folder** | **string**| The new document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorkbookResponse**](WorkbookResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_workbook_put_workbook_water_marker**
> CellsCloudResponse cells_workbook_put_workbook_water_marker(name => $name, folder => $folder, storage_name => $storage_name, text_water_marker_request => $text_water_marker_request)

Set workbook background image.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.
my $text_water_marker_request = AsposeCellsCloud::Object::TextWaterMarkerRequest->new(); # TextWaterMarkerRequest | The text water marker request.

eval { 
    my $result = $api_instance->cells_workbook_put_workbook_water_marker(name => $name, folder => $folder, storage_name => $storage_name, text_water_marker_request => $text_water_marker_request);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_workbook_put_workbook_water_marker: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 
 **text_water_marker_request** | [**TextWaterMarkerRequest**](TextWaterMarkerRequest.md)| The text water marker request. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_delete_worksheet_validation**
> ValidationResponse cells_worksheet_validations_delete_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, folder => $folder, storage_name => $storage_name)

Delete worksheet validation by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $validation_index = 56; # int | The validation index.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_delete_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_delete_worksheet_validation: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **validation_index** | **int**| The validation index. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ValidationResponse**](ValidationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_delete_worksheet_validations**
> CellsCloudResponse cells_worksheet_validations_delete_worksheet_validations(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Clear all validation in worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_delete_worksheet_validations(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_delete_worksheet_validations: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_get_worksheet_validation**
> ValidationResponse cells_worksheet_validations_get_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, folder => $folder, storage_name => $storage_name)

Get worksheet validation by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $validation_index = 56; # int | The validation index.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_get_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_get_worksheet_validation: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **validation_index** | **int**| The validation index. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ValidationResponse**](ValidationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_get_worksheet_validations**
> ValidationsResponse cells_worksheet_validations_get_worksheet_validations(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet validations.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_get_worksheet_validations(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_get_worksheet_validations: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ValidationsResponse**](ValidationsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_post_worksheet_validation**
> ValidationResponse cells_worksheet_validations_post_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, validation => $validation, folder => $folder, storage_name => $storage_name)

Update worksheet validation by index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $validation_index = 56; # int | The validation index.
my $validation = AsposeCellsCloud::Object::Validation->new(); # Validation | 
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_post_worksheet_validation(name => $name, sheet_name => $sheet_name, validation_index => $validation_index, validation => $validation, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_post_worksheet_validation: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **validation_index** | **int**| The validation index. | 
 **validation** | [**Validation**](Validation.md)|  | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ValidationResponse**](ValidationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheet_validations_put_worksheet_validation**
> ValidationResponse cells_worksheet_validations_put_worksheet_validation(name => $name, sheet_name => $sheet_name, range => $range, validation => $validation, folder => $folder, storage_name => $storage_name)

Add worksheet validation at index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $range = 'range_example'; # string | Specified cells area
my $validation = AsposeCellsCloud::Object::Validation->new(); # Validation | validation
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheet_validations_put_worksheet_validation(name => $name, sheet_name => $sheet_name, range => $range, validation => $validation, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheet_validations_put_worksheet_validation: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **range** | **string**| Specified cells area | [optional] 
 **validation** | [**Validation**](Validation.md)| validation | [optional] 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**ValidationResponse**](ValidationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_unprotect_worksheet**
> WorksheetResponse cells_worksheets_delete_unprotect_worksheet(name => $name, sheet_name => $sheet_name, protect_parameter => $protect_parameter, folder => $folder, storage_name => $storage_name)

Unprotect worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $protect_parameter = AsposeCellsCloud::Object::ProtectSheetParameter->new(); # ProtectSheetParameter | with protection settings. Only password is used here.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_unprotect_worksheet(name => $name, sheet_name => $sheet_name, protect_parameter => $protect_parameter, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_unprotect_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **protect_parameter** | [**ProtectSheetParameter**](ProtectSheetParameter.md)| with protection settings. Only password is used here. | [optional] 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetResponse**](WorksheetResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_worksheet**
> WorksheetsResponse cells_worksheets_delete_worksheet(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_worksheet(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetsResponse**](WorksheetsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_worksheet_background**
> CellsCloudResponse cells_worksheets_delete_worksheet_background(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Set worksheet background image.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_worksheet_background(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_worksheet_background: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_worksheet_comment**
> CellsCloudResponse cells_worksheets_delete_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name)

Delete worksheet's cell comment.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_worksheet_comment: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_name** | **string**| The cell name | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_worksheet_comments**
> CellsCloudResponse cells_worksheets_delete_worksheet_comments(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Delete all comments for worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_worksheet_comments(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_worksheet_comments: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_delete_worksheet_freeze_panes**
> CellsCloudResponse cells_worksheets_delete_worksheet_freeze_panes(name => $name, sheet_name => $sheet_name, row => $row, column => $column, freezed_rows => $freezed_rows, freezed_columns => $freezed_columns, folder => $folder, storage_name => $storage_name)

Unfreeze panes

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $row = 56; # int | 
my $column = 56; # int | 
my $freezed_rows = 56; # int | 
my $freezed_columns = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_delete_worksheet_freeze_panes(name => $name, sheet_name => $sheet_name, row => $row, column => $column, freezed_rows => $freezed_rows, freezed_columns => $freezed_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_delete_worksheet_freeze_panes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **row** | **int**|  | 
 **column** | **int**|  | 
 **freezed_rows** | **int**|  | 
 **freezed_columns** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_named_ranges**
> RangesResponse cells_worksheets_get_named_ranges(name => $name, folder => $folder, storage_name => $storage_name)

Read worksheets ranges info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_named_ranges(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_named_ranges: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**RangesResponse**](RangesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet**
> string cells_worksheets_get_worksheet(name => $name, sheet_name => $sheet_name, format => $format, vertical_resolution => $vertical_resolution, horizontal_resolution => $horizontal_resolution, area => $area, page_index => $page_index, folder => $folder, storage_name => $storage_name)

Read worksheet info or export.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $format = 'format_example'; # string | The exported file format.
my $vertical_resolution = 56; # int | Image vertical resolution.
my $horizontal_resolution = 56; # int | Image horizontal resolution.
my $area = 'area_example'; # string | Exported area.
my $page_index = 56; # int | Exported page index.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet(name => $name, sheet_name => $sheet_name, format => $format, vertical_resolution => $vertical_resolution, horizontal_resolution => $horizontal_resolution, area => $area, page_index => $page_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **format** | **string**| The exported file format. | [optional] 
 **vertical_resolution** | **int**| Image vertical resolution. | [optional] [default to 0]
 **horizontal_resolution** | **int**| Image horizontal resolution. | [optional] [default to 0]
 **area** | **string**| Exported area. | [optional] 
 **page_index** | **int**| Exported page index. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_calculate_formula**
> SingleValueResponse cells_worksheets_get_worksheet_calculate_formula(name => $name, sheet_name => $sheet_name, formula => $formula, folder => $folder, storage_name => $storage_name)

Calculate formula value.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $formula = 'formula_example'; # string | The formula.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_calculate_formula(name => $name, sheet_name => $sheet_name, formula => $formula, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_calculate_formula: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **formula** | **string**| The formula. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**SingleValueResponse**](SingleValueResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_comment**
> CommentResponse cells_worksheets_get_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name)

Get worksheet comment by cell name.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_comment: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_name** | **string**| The cell name | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CommentResponse**](CommentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_comments**
> CommentsResponse cells_worksheets_get_worksheet_comments(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet comments.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_comments(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_comments: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CommentsResponse**](CommentsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_merged_cell**
> MergedCellResponse cells_worksheets_get_worksheet_merged_cell(name => $name, sheet_name => $sheet_name, merged_cell_index => $merged_cell_index, folder => $folder, storage_name => $storage_name)

Get worksheet merged cell by its index.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $merged_cell_index = 56; # int | Merged cell index.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_merged_cell(name => $name, sheet_name => $sheet_name, merged_cell_index => $merged_cell_index, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_merged_cell: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **merged_cell_index** | **int**| Merged cell index. | 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**MergedCellResponse**](MergedCellResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_merged_cells**
> MergedCellsResponse cells_worksheets_get_worksheet_merged_cells(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet merged cells.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The workseet name.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_merged_cells(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_merged_cells: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The workseet name. | 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**MergedCellsResponse**](MergedCellsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheet_text_items**
> TextItemsResponse cells_worksheets_get_worksheet_text_items(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name)

Get worksheet text items.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $folder = 'folder_example'; # string | The workbook's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheet_text_items(name => $name, sheet_name => $sheet_name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheet_text_items: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **folder** | **string**| The workbook&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TextItemsResponse**](TextItemsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_get_worksheets**
> WorksheetsResponse cells_worksheets_get_worksheets(name => $name, folder => $folder, storage_name => $storage_name)

Read worksheets info.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_get_worksheets(name => $name, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_get_worksheets: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetsResponse**](WorksheetsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_autofit_worksheet_columns**
> CellsCloudResponse cells_worksheets_post_autofit_worksheet_columns(name => $name, sheet_name => $sheet_name, first_column => $first_column, last_column => $last_column, auto_fitter_options => $auto_fitter_options, first_row => $first_row, last_row => $last_row, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $first_column = 56; # int | 
my $last_column = 56; # int | 
my $auto_fitter_options = AsposeCellsCloud::Object::AutoFitterOptions->new(); # AutoFitterOptions | 
my $first_row = 56; # int | 
my $last_row = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_autofit_worksheet_columns(name => $name, sheet_name => $sheet_name, first_column => $first_column, last_column => $last_column, auto_fitter_options => $auto_fitter_options, first_row => $first_row, last_row => $last_row, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_autofit_worksheet_columns: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **first_column** | **int**|  | 
 **last_column** | **int**|  | 
 **auto_fitter_options** | [**AutoFitterOptions**](AutoFitterOptions.md)|  | [optional] 
 **first_row** | **int**|  | [optional] 
 **last_row** | **int**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_autofit_worksheet_row**
> CellsCloudResponse cells_worksheets_post_autofit_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, first_column => $first_column, last_column => $last_column, auto_fitter_options => $auto_fitter_options, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $row_index = 56; # int | 
my $first_column = 56; # int | 
my $last_column = 56; # int | 
my $auto_fitter_options = AsposeCellsCloud::Object::AutoFitterOptions->new(); # AutoFitterOptions | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_autofit_worksheet_row(name => $name, sheet_name => $sheet_name, row_index => $row_index, first_column => $first_column, last_column => $last_column, auto_fitter_options => $auto_fitter_options, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_autofit_worksheet_row: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **row_index** | **int**|  | 
 **first_column** | **int**|  | 
 **last_column** | **int**|  | 
 **auto_fitter_options** | [**AutoFitterOptions**](AutoFitterOptions.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_autofit_worksheet_rows**
> CellsCloudResponse cells_worksheets_post_autofit_worksheet_rows(name => $name, sheet_name => $sheet_name, auto_fitter_options => $auto_fitter_options, start_row => $start_row, end_row => $end_row, only_auto => $only_auto, folder => $folder, storage_name => $storage_name)

Autofit worksheet rows.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $auto_fitter_options = AsposeCellsCloud::Object::AutoFitterOptions->new(); # AutoFitterOptions | Auto Fitter Options.
my $start_row = 56; # int | Start row.
my $end_row = 56; # int | End row.
my $only_auto = 1; # boolean | Only auto.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_autofit_worksheet_rows(name => $name, sheet_name => $sheet_name, auto_fitter_options => $auto_fitter_options, start_row => $start_row, end_row => $end_row, only_auto => $only_auto, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_autofit_worksheet_rows: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **auto_fitter_options** | [**AutoFitterOptions**](AutoFitterOptions.md)| Auto Fitter Options. | [optional] 
 **start_row** | **int**| Start row. | [optional] 
 **end_row** | **int**| End row. | [optional] 
 **only_auto** | **boolean**| Only auto. | [optional] [default to false]
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_copy_worksheet**
> CellsCloudResponse cells_worksheets_post_copy_worksheet(name => $name, sheet_name => $sheet_name, source_sheet => $source_sheet, options => $options, source_workbook => $source_workbook, source_folder => $source_folder, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $source_sheet = 'source_sheet_example'; # string | 
my $options = AsposeCellsCloud::Object::CopyOptions->new(); # CopyOptions | 
my $source_workbook = 'source_workbook_example'; # string | 
my $source_folder = 'source_folder_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_copy_worksheet(name => $name, sheet_name => $sheet_name, source_sheet => $source_sheet, options => $options, source_workbook => $source_workbook, source_folder => $source_folder, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_copy_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **source_sheet** | **string**|  | 
 **options** | [**CopyOptions**](CopyOptions.md)|  | [optional] 
 **source_workbook** | **string**|  | [optional] 
 **source_folder** | **string**|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_move_worksheet**
> WorksheetsResponse cells_worksheets_post_move_worksheet(name => $name, sheet_name => $sheet_name, moving => $moving, folder => $folder, storage_name => $storage_name)

Move worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $moving = AsposeCellsCloud::Object::WorksheetMovingRequest->new(); # WorksheetMovingRequest | with moving parameters.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_move_worksheet(name => $name, sheet_name => $sheet_name, moving => $moving, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_move_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **moving** | [**WorksheetMovingRequest**](WorksheetMovingRequest.md)| with moving parameters. | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetsResponse**](WorksheetsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_rename_worksheet**
> CellsCloudResponse cells_worksheets_post_rename_worksheet(name => $name, sheet_name => $sheet_name, newname => $newname, folder => $folder, storage_name => $storage_name)

Rename worksheet

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $newname = 'newname_example'; # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_rename_worksheet(name => $name, sheet_name => $sheet_name, newname => $newname, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_rename_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **newname** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_update_worksheet_property**
> WorksheetResponse cells_worksheets_post_update_worksheet_property(name => $name, sheet_name => $sheet_name, sheet => $sheet, folder => $folder, storage_name => $storage_name)

Update worksheet property

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $sheet = AsposeCellsCloud::Object::Worksheet->new(); # Worksheet | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_update_worksheet_property(name => $name, sheet_name => $sheet_name, sheet => $sheet, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_update_worksheet_property: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **sheet** | [**Worksheet**](Worksheet.md)|  | [optional] 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetResponse**](WorksheetResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_update_worksheet_zoom**
> CellsCloudResponse cells_worksheets_post_update_worksheet_zoom(name => $name, sheet_name => $sheet_name, value => $value, folder => $folder, storage_name => $storage_name)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $value = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_update_worksheet_zoom(name => $name, sheet_name => $sheet_name, value => $value, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_update_worksheet_zoom: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **value** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_worksheet_comment**
> CellsCloudResponse cells_worksheets_post_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, comment => $comment, folder => $folder, storage_name => $storage_name)

Update worksheet's cell comment.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name
my $comment = AsposeCellsCloud::Object::Comment->new(); # Comment | Comment object
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, comment => $comment, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_worksheet_comment: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_name** | **string**| The cell name | 
 **comment** | [**Comment**](Comment.md)| Comment object | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_worksheet_range_sort**
> CellsCloudResponse cells_worksheets_post_worksheet_range_sort(name => $name, sheet_name => $sheet_name, cell_area => $cell_area, data_sorter => $data_sorter, folder => $folder, storage_name => $storage_name)

Sort worksheet range.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The workbook name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_area = 'cell_area_example'; # string | The range to sort.
my $data_sorter = AsposeCellsCloud::Object::DataSorter->new(); # DataSorter | with sorting settings.
my $folder = 'folder_example'; # string | The workbook folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_worksheet_range_sort(name => $name, sheet_name => $sheet_name, cell_area => $cell_area, data_sorter => $data_sorter, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_worksheet_range_sort: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The workbook name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_area** | **string**| The range to sort. | 
 **data_sorter** | [**DataSorter**](DataSorter.md)| with sorting settings. | [optional] 
 **folder** | **string**| The workbook folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_worksheet_text_search**
> TextItemsResponse cells_worksheets_post_worksheet_text_search(name => $name, sheet_name => $sheet_name, text => $text, folder => $folder, storage_name => $storage_name)

Search text.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $text = 'text_example'; # string | Text to search.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_worksheet_text_search(name => $name, sheet_name => $sheet_name, text => $text, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_worksheet_text_search: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **text** | **string**| Text to search. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**TextItemsResponse**](TextItemsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_post_worsheet_text_replace**
> WorksheetReplaceResponse cells_worksheets_post_worsheet_text_replace(name => $name, sheet_name => $sheet_name, old_value => $old_value, new_value => $new_value, folder => $folder, storage_name => $storage_name)

Replace text.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $old_value = 'old_value_example'; # string | The old text to replace.
my $new_value = 'new_value_example'; # string | The new text to replace by.
my $folder = 'folder_example'; # string | Document's folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_post_worsheet_text_replace(name => $name, sheet_name => $sheet_name, old_value => $old_value, new_value => $new_value, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_post_worsheet_text_replace: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **old_value** | **string**| The old text to replace. | 
 **new_value** | **string**| The new text to replace by. | 
 **folder** | **string**| Document&#39;s folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetReplaceResponse**](WorksheetReplaceResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_add_new_worksheet**
> WorksheetsResponse cells_worksheets_put_add_new_worksheet(name => $name, sheet_name => $sheet_name, position => $position, sheettype => $sheettype, folder => $folder, storage_name => $storage_name)

Add new worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The new sheet name.
my $position = 56; # int | The new sheet position.
my $sheettype = 'sheettype_example'; # string | The new sheet type.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_add_new_worksheet(name => $name, sheet_name => $sheet_name, position => $position, sheettype => $sheettype, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_add_new_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The new sheet name. | 
 **position** | **int**| The new sheet position. | [optional] 
 **sheettype** | **string**| The new sheet type. | [optional] 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetsResponse**](WorksheetsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_change_visibility_worksheet**
> WorksheetResponse cells_worksheets_put_change_visibility_worksheet(name => $name, sheet_name => $sheet_name, is_visible => $is_visible, folder => $folder, storage_name => $storage_name)

Change worksheet visibility.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | Worksheet name.
my $is_visible = 1; # boolean | New worksheet visibility value.
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_change_visibility_worksheet(name => $name, sheet_name => $sheet_name, is_visible => $is_visible, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_change_visibility_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| Worksheet name. | 
 **is_visible** | **boolean**| New worksheet visibility value. | 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetResponse**](WorksheetResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_protect_worksheet**
> WorksheetResponse cells_worksheets_put_protect_worksheet(name => $name, sheet_name => $sheet_name, protect_parameter => $protect_parameter, folder => $folder, storage_name => $storage_name)

Protect worksheet.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | Document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $protect_parameter = AsposeCellsCloud::Object::ProtectSheetParameter->new(); # ProtectSheetParameter | with protection settings.
my $folder = 'folder_example'; # string | Document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_protect_worksheet(name => $name, sheet_name => $sheet_name, protect_parameter => $protect_parameter, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_protect_worksheet: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| Document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **protect_parameter** | [**ProtectSheetParameter**](ProtectSheetParameter.md)| with protection settings. | [optional] 
 **folder** | **string**| Document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**WorksheetResponse**](WorksheetResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_worksheet_background**
> CellsCloudResponse cells_worksheets_put_worksheet_background(name => $name, sheet_name => $sheet_name, png => $png, folder => $folder, storage_name => $storage_name)

Set worksheet background image.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $png = AsposeCellsCloud::Object::string->new(); # string | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_worksheet_background(name => $name, sheet_name => $sheet_name, png => $png, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_worksheet_background: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **png** | **string**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_worksheet_comment**
> CommentResponse cells_worksheets_put_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, comment => $comment, folder => $folder, storage_name => $storage_name)

Add worksheet's cell comment.

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | The document name.
my $sheet_name = 'sheet_name_example'; # string | The worksheet name.
my $cell_name = 'cell_name_example'; # string | The cell name
my $comment = AsposeCellsCloud::Object::Comment->new(); # Comment | Comment object
my $folder = 'folder_example'; # string | The document folder.
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_worksheet_comment(name => $name, sheet_name => $sheet_name, cell_name => $cell_name, comment => $comment, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_worksheet_comment: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The document name. | 
 **sheet_name** | **string**| The worksheet name. | 
 **cell_name** | **string**| The cell name | 
 **comment** | [**Comment**](Comment.md)| Comment object | [optional] 
 **folder** | **string**| The document folder. | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CommentResponse**](CommentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cells_worksheets_put_worksheet_freeze_panes**
> CellsCloudResponse cells_worksheets_put_worksheet_freeze_panes(name => $name, sheet_name => $sheet_name, row => $row, column => $column, freezed_rows => $freezed_rows, freezed_columns => $freezed_columns, folder => $folder, storage_name => $storage_name)

Set freeze panes

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $name = 'name_example'; # string | 
my $sheet_name = 'sheet_name_example'; # string | 
my $row = 56; # int | 
my $column = 56; # int | 
my $freezed_rows = 56; # int | 
my $freezed_columns = 56; # int | 
my $folder = 'folder_example'; # string | 
my $storage_name = 'storage_name_example'; # string | storage name.

eval { 
    my $result = $api_instance->cells_worksheets_put_worksheet_freeze_panes(name => $name, sheet_name => $sheet_name, row => $row, column => $column, freezed_rows => $freezed_rows, freezed_columns => $freezed_columns, folder => $folder, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->cells_worksheets_put_worksheet_freeze_panes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**|  | 
 **sheet_name** | **string**|  | 
 **row** | **int**|  | 
 **column** | **int**|  | 
 **freezed_rows** | **int**|  | 
 **freezed_columns** | **int**|  | 
 **folder** | **string**|  | [optional] 
 **storage_name** | **string**| storage name. | [optional] 

### Return type

[**CellsCloudResponse**](CellsCloudResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **copy_file**
> copy_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id)

Copy file

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $src_path = 'src_path_example'; # string | Source file path e.g. '/folder/file.ext'
my $dest_path = 'dest_path_example'; # string | Destination file path
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name
my $version_id = 'version_id_example'; # string | File version ID to copy

eval { 
    $api_instance->copy_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling CellsApi->copy_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source file path e.g. &#39;/folder/file.ext&#39; | 
 **dest_path** | **string**| Destination file path | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 
 **version_id** | **string**| File version ID to copy | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **copy_folder**
> copy_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name)

Copy folder

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $src_path = 'src_path_example'; # string | Source folder path e.g. '/src'
my $dest_path = 'dest_path_example'; # string | Destination folder path e.g. '/dst'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name

eval { 
    $api_instance->copy_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name);
};
if ($@) {
    warn "Exception when calling CellsApi->copy_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source folder path e.g. &#39;/src&#39; | 
 **dest_path** | **string**| Destination folder path e.g. &#39;/dst&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_folder**
> create_folder(path => $path, storage_name => $storage_name)

Create the folder

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | Folder path to create e.g. 'folder_1/folder_2/'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    $api_instance->create_folder(path => $path, storage_name => $storage_name);
};
if ($@) {
    warn "Exception when calling CellsApi->create_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path to create e.g. &#39;folder_1/folder_2/&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_file**
> delete_file(path => $path, storage_name => $storage_name, version_id => $version_id)

Delete file

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | File path e.g. '/folder/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID to delete

eval { 
    $api_instance->delete_file(path => $path, storage_name => $storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling CellsApi->delete_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/folder/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID to delete | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_folder**
> delete_folder(path => $path, storage_name => $storage_name, recursive => $recursive)

Delete folder

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | Folder path e.g. '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name
my $recursive = 1; # boolean | Enable to delete folders, subfolders and files

eval { 
    $api_instance->delete_folder(path => $path, storage_name => $storage_name, recursive => $recursive);
};
if ($@) {
    warn "Exception when calling CellsApi->delete_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path e.g. &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **recursive** | **boolean**| Enable to delete folders, subfolders and files | [optional] [default to false]

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **download_file**
> string download_file(path => $path, storage_name => $storage_name, version_id => $version_id)

Download file

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | File path e.g. '/folder/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID to download

eval { 
    my $result = $api_instance->download_file(path => $path, storage_name => $storage_name, version_id => $version_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->download_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/folder/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID to download | [optional] 

### Return type

**string**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: multipart/form-data

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_disc_usage**
> DiscUsage get_disc_usage(storage_name => $storage_name)

Get disc usage

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_disc_usage(storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->get_disc_usage: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**DiscUsage**](DiscUsage.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_file_versions**
> FileVersions get_file_versions(path => $path, storage_name => $storage_name)

Get file versions

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | File path e.g. '/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_file_versions(path => $path, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->get_file_versions: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FileVersions**](FileVersions.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_files_list**
> FilesList get_files_list(path => $path, storage_name => $storage_name)

Get all files and folders within a folder

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | Folder path e.g. '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_files_list(path => $path, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->get_files_list: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path e.g. &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FilesList**](FilesList.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **move_file**
> move_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id)

Move file

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $src_path = 'src_path_example'; # string | Source file path e.g. '/src.ext'
my $dest_path = 'dest_path_example'; # string | Destination file path e.g. '/dest.ext'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name
my $version_id = 'version_id_example'; # string | File version ID to move

eval { 
    $api_instance->move_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling CellsApi->move_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source file path e.g. &#39;/src.ext&#39; | 
 **dest_path** | **string**| Destination file path e.g. &#39;/dest.ext&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 
 **version_id** | **string**| File version ID to move | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **move_folder**
> move_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name)

Move folder

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $src_path = 'src_path_example'; # string | Folder path to move e.g. '/folder'
my $dest_path = 'dest_path_example'; # string | Destination folder path to move to e.g '/dst'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name

eval { 
    $api_instance->move_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name);
};
if ($@) {
    warn "Exception when calling CellsApi->move_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Folder path to move e.g. &#39;/folder&#39; | 
 **dest_path** | **string**| Destination folder path to move to e.g &#39;/dst&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **o_auth_post**
> AccessTokenResponse o_auth_post(grant_type => $grant_type, client_id => $client_id, client_secret => $client_secret)

Get Access token

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $grant_type = 'grant_type_example'; # string | Grant Type
my $client_id = 'client_id_example'; # string | App SID
my $client_secret = 'client_secret_example'; # string | App Key

eval { 
    my $result = $api_instance->o_auth_post(grant_type => $grant_type, client_id => $client_id, client_secret => $client_secret);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->o_auth_post: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grant_type** | **string**| Grant Type | 
 **client_id** | **string**| App SID | 
 **client_secret** | **string**| App Key | 

### Return type

[**AccessTokenResponse**](AccessTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/x-www-form-urlencoded
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **object_exists**
> ObjectExist object_exists(path => $path, storage_name => $storage_name, version_id => $version_id)

Check if file or folder exists

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | File or folder path e.g. '/file.ext' or '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID

eval { 
    my $result = $api_instance->object_exists(path => $path, storage_name => $storage_name, version_id => $version_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->object_exists: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File or folder path e.g. &#39;/file.ext&#39; or &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID | [optional] 

### Return type

[**ObjectExist**](ObjectExist.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storage_exists**
> StorageExist storage_exists(storage_name => $storage_name)

Check if storage exists

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->storage_exists(storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->storage_exists: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storage_name** | **string**| Storage name | 

### Return type

[**StorageExist**](StorageExist.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upload_file**
> FilesUploadResult upload_file(path => $path, file => $file, storage_name => $storage_name)

Upload file

### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::CellsApi;
my $api_instance = AsposeCellsCloud::CellsApi->new(
);

my $path = 'path_example'; # string | Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.             
my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->upload_file(path => $path, file => $file, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CellsApi->upload_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.              | 
 **file** | **string**| File to upload | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FilesUploadResult**](FilesUploadResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

