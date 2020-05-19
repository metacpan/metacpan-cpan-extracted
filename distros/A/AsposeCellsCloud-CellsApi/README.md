# Perl REST API for Spreadsheet Processing in Cloud

This Cloud SDK enhances your Perl cloud-based apps to [process & manipulate Microsoft Excel spreadsheets](https://products.aspose.cloud/cells/perl) in the cloud, without MS Office.

## Spreadsheet Processing Features

- Add, update or delete charts, worksheet pictures, shapes, hyperlinks & validations.
- Add or remove cells area for conditional formatting, or OleObjects from Excel worksheets.
- Insert or delete, horizontal or vertical page breaks
- Add ListObject at a specific place within an Excel file & convert them to a range of cells.
- Delete specific or all ListObjects in a worksheet or summarize its data with pivot table.
- Apply custom criteria to list filters of various types.
- Get, update, show or hide chart legend & titles.
- Manipulate page setup, header & footer.
- Create, update, fetch or delete document properties.
- Fetch the required shape from worksheet.
- Load & Process Excel Spreadsheets via Cloud SDK.
- Cloud SDK to Read & Process Excel Worksheets.
- Leverage the Power of Pivot Tables & Ranges.

## Enhancements in Version 20.4

- Support to export area or page of sheet to JPEG.
- Support to add background for workbook.
- Enhancement for splitting workbook.
- Enhancement for create workbook.

## Read & Write Spreadsheet Formats

**Microsoft Excel:** XLS, XLSX, XLSB, XLSM, XLT, XLTX, XLTM
**OpenOffice:** ODS
**SpreadsheetML:** XML
**Text:** CSV, TSV, TXT (TabDelimited)
**Web:** HTML, MHTML
**PDF**

## Save Spreadsheet As

DIF, HTML, MHTML,PNG,JPG, TIFF, XPS, SVG, MD (Markdown), ODS ,xlsx,xls,xlsb, PDF,XML,TXT,CSV

## Read Spreadsheet Formats

SXC, FODS

## Getting Started with Aspose.Cells Cloud SDK for Perl

The complete source code is available in this repository folder. You can either directly use it in your project via source code or get [Packagist distribution](https://www.cpan.org/) (recommended). For more details, please visit our [documentation website](https://docs.aspose.cloud/display/cellscloud/Available+SDKs).


Please check the [GitHub Repository](https://github.com/aspose-cells-cloud/aspose-cells-cloud-perl) for other common usage scenarios.


```

## Using Perl to Convert an Excel File to another File Format

The following code example elaborates how you can use Perl code to convert an Excel document to another file format in the cloud:

```Perl
    @api = AsposeCellsCloud::CellsApi.new("appsid","appkey")
    my $format = 'pdf'; # replace NULL with a proper value
    my $password = undef; # replace NULL with a proper value
    my $out_path = undef; # replace NULL with a proper value
    my $Book1_data =undef;
    my @fileinfos = stat("D:\\Projects\\Aspose\\Aspose.Cloud\\Aspose.Cells.Cloud.SDK\\src\\TestData\\Book1.xlsx");
    my $filelength = @fileinfos[7];
    open(DATA, "<D:\\Projects\\Aspose\\Aspose.Cloud\\Aspose.Cells.Cloud.SDK\\src\\TestData\\Book1.xlsx") or die "file.txt can not open, $!";
    binmode(DATA);
    # while( read (DATA, $Book1_data, 8)) {};
    read (DATA, $Book1_data, $filelength);
    close (DATA);    
    my $folder = $TEMPFOLDER; # replace NULL with a proper value
    # ready_file('api'=> $api, 'file'=>$name ,'folder' =>$folder) ;  
    $result = $api->cells_workbook_put_convert_workbook( workbook => $Book1_data, format => $format, password => $password, out_path => $out_path,folder =>$folder);conver
```

[Product Page](https://products.aspose.cloud/cells/perl) | [Documentation](https://docs.aspose.cloud/display/cellscloud/Home) | [Live Demo](https://products.aspose.app/cells/family) | [API Reference](https://apireference.aspose.cloud/cells/) | [Code Samples](https://github.com/aspose-cells-cloud/aspose-cells-cloud-perl) | [Blog](https://blog.aspose.cloud/category/cells/) | [Free Support](https://forum.aspose.cloud/c/cells) | [Free Trial](https://dashboard.aspose.cloud/#/apps)


