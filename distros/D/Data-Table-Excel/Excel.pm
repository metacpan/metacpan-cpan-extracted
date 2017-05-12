package Data::Table::Excel;
BEGIN { die "Your perl version is old, see README for instructions" if $] < 5.005; }

use strict;
use Data::Table;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
#use Spreadsheet::XLSX;
use Spreadsheet::ParseXLSX;
use Excel::Writer::XLSX;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;
use Exporter 'import';

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = ();
@EXPORT_OK = qw(
  tables2xls xls2tables tables2xlsx xlsx2tables xls2xlsx xlsx2xls is_xlsx excelFileToTable
);
$VERSION = '0.5';

sub xls2tables {
  my ($fileName, $sheetNames, $sheetIndices) = @_;
  return excelFileToTable($fileName, $sheetNames, $sheetIndices, '2003');
}

sub xlsx2tables {
  my ($fileName, $sheetNames, $sheetIndices) = @_;
  return excelFileToTable($fileName, $sheetNames, $sheetIndices, '2007');
}

sub is_xlsx {
    my $filename=shift;
    open(IN, $filename) or die "Cannot open $filename!";
    binmode IN;
    my $buffer;
    read(IN, $buffer, 2, 0);
    close(IN);
    return uc($buffer) eq 'PK';
}

sub excelFileToTable {
  my ($fileName, $sheetNames, $sheetIndices, $excelFormat) = @_;
  my %sheetsName = ();
  my %sheetsIndex = ();
  if (defined($sheetNames)) {
    $sheetNames=[$sheetNames] if (ref($sheetNames) eq 'SCALAR');
    if (ref($sheetNames) eq 'ARRAY') {
      foreach my $name (@$sheetNames) {
        $sheetsName{$name} = 1;
      }
    }
  } elsif (defined($sheetIndices)) {
    $sheetIndices=[$sheetIndices] if (ref($sheetIndices) eq 'SCALAR');
    if (ref($sheetIndices) eq 'ARRAY') {
      foreach my $idx (@$sheetIndices) {
        $sheetsIndex{$idx} = 1;
      }
    }
  }
  my $excel = undef;
  if (!defined($excelFormat)) {
    $excelFormat=is_xlsx($fileName)?'2007':'2003';
  }
  if ($excelFormat eq '2003') {
    $excel = Spreadsheet::ParseExcel::Workbook->Parse($fileName);
  } elsif ($excelFormat eq '2007') {
    #$excel = Spreadsheet::XLSX->new($fileName);
    my $parser=Spreadsheet::ParseXLSX->new;
    $excel = $parser->parse($fileName);
  } else {
    croak "Unrecognized Excel format, must be either 2003 or 2007!";
  }
  my @tables = ();
  my @sheets = ();
  my @column_headers = ();
  my $num = 0;
  foreach my $sheet (@{$excel->{Worksheet}}) {
    $num++;
    next if ((scalar keys %sheetsName) && !defined($sheetsName{$sheet->{Name}}));
    next if ((scalar keys %sheetsIndex) && !defined($sheetsIndex{$num}));
    next unless defined($sheet->{MinRow}) && defined($sheet->{MaxRow}) && defined($sheet->{MinCol}) && defined($sheet->{MaxRow});
    push @sheets, $sheet->{Name};
    #printf("Sheet: %s\n", $sheet->{Name});
    $sheet->{MaxRow} ||= $sheet->{MinRow};
    $sheet->{MaxCol} ||= $sheet->{MinCol};
    my @header = ();
    foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
      my $cel=$sheet->{Cells}[$sheet->{MinRow}][$col];
      push @header, defined($cel)?$cel->{Val}:undef;
    }    
    my $s = join($Data::Table::DEFAULTS{CSV_DELIMITER}, map {Data::Table::csvEscape($_)} @header);
    my $t = undef;
    my $hasColumnHeader=Data::Table::fromFileIsHeader($s, $Data::Table::DEFAULTS{CSV_DELIMITER});
    push @column_headers, $hasColumnHeader;
    if ($hasColumnHeader) {
      $t = new Data::Table([], \@header, 0);
    } else {
      my @newHeader =  map {"col$_"} (1..($sheet->{MaxCol}-$sheet->{MinCol}+1));
      # name each column as col1, col2, .. etc
      $t = new Data::Table([\@header], \@newHeader, 0);
    }
    foreach my $row (($sheet->{MinRow}+1) .. $sheet->{MaxRow}) {
      my @one = ();
      foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
        my $cel=$sheet->{Cells}[$row][$col];
        push @one, defined($cel)?$cel->{Val}:undef;
      }
      $t->addRow(\@one);
    }
    push @tables, $t;
  }
  return (\@tables, \@sheets, \@column_headers);
}

# color palette is defined in
# http://search.cpan.org/src/JMCNAMARA/Spreadsheet-WriteExcel-2.20/doc/palette.html
sub oneTable2Worksheet {
  my ($workbook, $t, $name, $colors, $portrait, $column_header) = @_;
  $column_header = 0 unless defined($column_header);
  # Add a worksheet
  my $worksheet = $workbook->add_worksheet($name);
  $portrait=1 unless defined($portrait);
  #my @BG_COLOR=(26,47,44);
  my @BG_COLOR=(44, 9, 30);
  @BG_COLOR=@$colors if ((ref($colors) eq "ARRAY") && (scalar @$colors==3));
  my $fmt_header= $workbook->add_format();
  $fmt_header->set_bg_color($BG_COLOR[2]);
  $fmt_header->set_bold();
  $fmt_header->set_color('white');
  my $fmt_odd= $workbook->add_format();
  $fmt_odd->set_bg_color($BG_COLOR[0]);
  my $fmt_even= $workbook->add_format();
  $fmt_even->set_bg_color($BG_COLOR[1]);
  my @FORMAT = ($fmt_odd, $fmt_even);

  my @header=$t->header;
  my $offset=($column_header)? 1:0;
  if ($portrait) {
    if ($column_header) {
      for (my $i=0; $i<@header; $i++) {
        $worksheet->write(0, $i, $header[$i], $fmt_header);
      }
    }
    for (my $i=0; $i<$t->nofRow; $i++) {
      for (my $j=0; $j<$t->nofCol; $j++) {
        $worksheet->write($i+$offset, $j, $t->elm($i,$j), $FORMAT[$i%2]);
      }
    }
  } else {
    if ($column_header) {
      for (my $i=0; $i<@header; $i++) {
        $worksheet->write($i, 0, $header[$i], $fmt_header);
      }
    }
    for (my $i=0; $i<$t->nofRow; $i++) {
      for (my $j=0; $j<$t->nofCol; $j++) {
        $worksheet->write($j, $i+$offset, $t->elm($i,$j), $FORMAT[$i%2]);
      }
    }
  }
}

sub tables2excelFile {
  my ($fileName, $tables, $names, $colors, $portrait, $excelFormat, $column_headers) = @_;
  confess("No table is specified!\n") unless (defined($tables)&&(scalar @$tables));
  $names =[] unless defined($names);
  $colors=[] unless defined($colors);
  $portrait=[] unless defined($portrait);
  $column_headers=[1] unless defined($column_headers);
  my $workbook = undef;
  $excelFormat='2007' unless defined($excelFormat);
  if ($excelFormat eq '2003') {
    $workbook = Spreadsheet::WriteExcel->new($fileName);
  } elsif ($excelFormat eq '2007') {
    $workbook = Excel::Writer::XLSX->new($fileName);
  } else {
    croak "Unrecognized Excel format, must be either 2003 or 2007!";
  }
  $portrait=[] unless defined($portrait);
  my ($prevColors, $prevPortrait, $prevColumnHeader) = (undef, undef, undef);
  for (my $i=0; $i<@$tables; $i++) {
    my $myColor=$colors->[$i];
    $myColor=$prevColors if (!defined($myColor) && defined($prevColors));
    $prevColors=$myColor;
    my $myPortrait=$portrait->[$i];
    $myPortrait=$prevPortrait if (!defined($myPortrait) && defined($prevPortrait));
    $prevPortrait=$myPortrait;
	my $mySheet = $names->[$i] ? $names->[$i]:"Sheet".($i+1);
    my $myColumnHeader = $column_headers->[$i];
    $myColumnHeader = $prevColumnHeader if (!defined($myColumnHeader) && defined($prevColumnHeader));
    $prevColumnHeader=$myColumnHeader;
    oneTable2Worksheet($workbook, $tables->[$i], $mySheet, $myColor, $myPortrait, $myColumnHeader);
  }
}

sub tables2xls {
  my ($fileName, $tables, $names, $colors, $portrait, $column_headers) = @_;
  tables2excelFile($fileName, $tables, $names, $colors, $portrait, '2003', $column_headers);
}

sub tables2xlsx {
  my ($fileName, $tables, $names, $colors, $portrait, $column_headers) = @_;
  tables2excelFile($fileName, $tables, $names, $colors, $portrait, '2007', $column_headers);
}

sub xls2xlsx {
  my ($xlsFile, $xlsxFile) = @_;
  unless (defined($xlsxFile)) {
    $xlsxFile = $xlsFile;
    $xlsxFile =~ s/\.xls$/\.xlsx/i;
  }
  my ($tables, $table_names, $column_headers) = xls2tables($xlsFile);
  tables2xlsx($xlsxFile, $tables, $table_names, undef, undef, $column_headers);
}

sub xlsx2xls {
  my ($xlsxFile, $xlsFile) = @_;
  unless (defined($xlsFile)) {
    $xlsFile = $xlsxFile;
    $xlsFile =~ s/\.xlsx$/\.xls/i;
  }
  my ($tables, $table_names, $column_headers) = xlsx2tables($xlsxFile);
  tables2xls($xlsFile, $tables, $table_names, undef, undef, $column_headers);
}

1;

__END__


=head1 NAME

Data::Table::Excel - Convert between Data::Table objects and Excel (xls/xlsx) files.

=head1 SYNOPSIS
  
  News: The package now includes "Perl Data::Table Cookbook" (PDF), which may serve as a better learning material.
  To download the free Cookbook, visit https://sites.google.com/site/easydatabase/

  use Data::Table::Excel qw (tables2xls xls2tables tables2xlsx xlsx2tables excelFileToTable is_xlsx xls2xlsx xlsx2xls);

  # read in two CSV tables and generate an Excel .xls binary file with two spreadsheets
  my $t_category = Data::Table::fromFile("Category.csv");
  my $t_product = Data::Table::fromFile("Product.csv");
  # the workbook will contain two sheets, named Category and Product
  # parameters: output file name, an array of tables to write, and their corresponding names
  tables2xls("NorthWind.xls", [$t_category, $t_product], ["Category","Product"]);

  # read in NorthWind.xls file as two Data::Table objects
  my ($tableObjects, $tableNames, $column_headers)=xls2tables("NorthWind.xls");
  for (my $i=0; $i<@$tableNames; $i++) {
    print "*** ". $tableNames->[$i], " ***\n";
    print $tableObjects->[$i]->csv($column_headers[$i]);
  }

  Outputs:
  *** Category ***
  CategoryID,CategoryName,Description
  1,Beverages,"Soft drinks, coffees, teas, beers, and ales"
  2,Condiments,"Sweet and savory sauces, relishes, spreads, and seasonings"
  3,Confections,"Desserts, candies, and sweet breads"
  ...
  
  *** Product ***
  ProductID,ProductName,CategoryID,UnitPrice,UnitsInStock,Discontinued
  1,Chai,1,18,39,FALSE
  2,Chang,1,19,17,FALSE
  3,Aniseed Syrup,2,10,13,FALSE
  ...

  # to deal with Excel 2007 format (.xlsx), use xlsx2tables instead.
  # since no table name is supplied, they will be named Sheet1 and Sheet2.
  # here we also provide custom colors for each sheet, color array is for [OddRow, EvenRow, HeaderRow]

  tables2xlsx("NorthWind.xlsx", [$t_category, $t_product], undef, [['silver','white','black'], [45,'white',37]]);
  # read in NorthWind.xlsx file as two Data::Table objects
  my ($tableObjects, $tableNames)=xlsx2tables("NorthWind.xlsx");
  # note: Spreadsheet::ParseXLSX module is used to parse .xlsx file.

  ($tableObjects, $tableNames, $column_headers)=excelFileToTable("NorthWind.xlsx");
  # excelFileToTable will automatically detect the Excel format for the input file

  # To convert Excel files between the two formats, use
  xlsx2xls("NorthWind.xlsx", "NorthWind.xls");
  xls2xlsx("NorthWind.xls", "NorthWind.xlsx");

=head1 ABSTRACT

This perl package provide utility methods to convert between an Excel file and Data::Table objects. It then enables you to take advantage of the Data::Table methods to further manipulate the data and/or export it into other formats such as CSV/TSV/HTML, etc.

=head1 DESCRIPTION

=over 4

To read and write Excel .xls (2003 and prior) format, we use Spreadsheet::WriteExcel and Spreadsheet::ParseExcel; to read and write Excel .xlsx (2007 format),
we use Spreadsheet::ParseXLSX and Excel::Writer::XLSX.  If this module gives incorrect results, please check if the corresponding Perl modules are updated. (We switch to Spreadsheet::ParseXLSX from Spreadsheet::XLSX from version 0.5)

=item xls2tables ($fileName, $sheetNames, $sheetIndices) 

=item xlsx2tables ($fileName, $sheetNames, $sheetIndices)

=item excelFileToTable ($fileName, $sheetNames, $sheetIndices, $excelFormat)

xls2tables is for reading Excel .xls files (binary, 2003 and prior), xlsx2table is for reading .xlsx file (2007, compressed XML format).
excelFileToTable can automatically detect Excel format if format is not specified.

$fileName is the input Excel file.
$sheetNames is a string or a reference to an array of sheet names.
$sheetIndices is a int or a reference to an array of sheet indices.
$excelFormat in excelFileToTable has to be either "2003" or "2007". Auto-detected if not specified.
If neither $sheetNames or $sheetIndices is provides, all sheets are converted into table objects, one table per sheet.
If $sheetNames is provided, only sheets found in the @$sheetNames array is converted.
If $sheetIndices is provided, only sheets match the index in the @$sheetIndices array is converted (notice the first spreadsheet has an index of 1).

The method returns an array ($tableObjects, $tableNames, $columnHeaders).
$tableObjects is a reference to an array of Data::Table objects.
$tableNames is a reference to an array of sheet names, corresponding to $tableObjects.
$columnHeaders is a reference to an array of booleans, indicating whether each table has original column header
If a table does not have a column header, columns are named Col1, Col2, etc.

  # print each of spreadsheet into an HTML table on the web
  ($tableObjects, $tableNames, $columnHeaders)=xls2tables("Tables.xls");
  foreach my $t (@$tableObjects) {
    print "<h1>", shift @$tableNames, "</h1><br>";
    print $t->html;
  }

  ($tableObjects, $tableNames, $columnHeaders)=xlsx2tables("Tables.xlsx", undef, [1]);

This will only read the first sheet. By providing sheet names or sheet indicies, you save time if you are not interested in all the sheets.

=item tables2xls ($fileName, $tables, $names, $colors, $portrait, $columnHeaders) 

=item tables2xlsx ($fileName, $tables, $names, $colors, $portrait, $columnHeaders) 

=item tables2excel ($fileName, $tables, $names, $colors, $portrait, $excelFormat, $columnHeaders)

table2xls is for writing Excel .xls files (binary, 2003 and prior), xlsx2table is for writing .xlsx file (2007, compressed XML format).
tables2excel will export to 2007 format, if $excelFormat is not specified.

$fileName is used to name the output Excel file.
$tables is a reference to an array of Data::Table objects to be write into the file, one sheet per table.
$names is a reference to an array of names used to name Spreadsheets, if not provided, it uses "Sheet1", "Sheet2", etc.
$colors is a reference to an array of reference to a color array.
Each color array has to contains three elements, defining Excel color index for odd rows, even rows and header row. 
Acceptable color index (or name) is defined by the docs\palette.html file in the CPAN Spreadsheet::WriteExcel package.

$portrait is a reference to an array of orientation flag (0 or 1), 1 is for Portrait (the default), where each row represents a table row.  In landscape (0) mode, each row represents a column.  (Similar to Data::Table::html and Data::Table::html2).

$columnHeaders is a reference to an array of boolean, indicating whether to export column headers for each table. By default, column headers are exported.

The arrays pointed by $names, $colors, $portraits and $columnHeader should be the same length as that of $tables. these customization values are applied to each table objects sequentially.
If a value is missing for a table, the method will use the setting from the previous table.

  tables2xls("TwoTables.xls", [$t_A, $t_B], ["Table_A","Table_B"], [["white","silver","gray"], undef], [1, 0], [1, 1]);

This will produce two spreadsheets named Table_A and Table_B for table $t_A and $t_B, respectively.  The first table is colored in a black-white style, the second is colored by the default style.
The first table is the default portrait oritentation, the second is in the transposed orientation.

=item is_xlsx($fileName)

Returns boolean whether the given file is 2007 format. It does not rely on file name, but reads the first two bytes of the file. .xlsx is in Zip format, therefore the first two bytes are "PK".

=item xlsx2xls($fromFileName, $toFileName)

=item xls2xlsx($fromFileName, $toFileName)

Converts an Excel file from one format to another. If $toFileName is not specified, $toFileName will be the same as $fromFileName, except with extension sets to .xlsx or .xls.

=back

=head1 AUTHOR

Copyright 2008, Yingyao Zhou. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
  
Please send bug reports and comments to: easydatabase at gmail dot com. When sending
bug reports, please provide the version of Data::Table::Excel.pm, the version of
Perl.

=head1 SEE ALSO

  Data::Table.

=cut


