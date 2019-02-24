#!perl
use strict;
use warnings;
use Data::Dumper;
use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';
use Spreadsheet::XLSX;
use File::Temp;

use Test::More tests => 29;
use Test::Deep;

my $content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

# array of array
{
ok((my $content = get "/rest/a_o_a?content-type=$content_type"), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
cmp_deeply(
  read_sheet($excel->{Worksheet}[0]),
  [[1,2,3],[4,5,6]],
  'array_of_array -> sheet'
);
}

# number-like data does not get numified
{
ok((my $content = get "/rest/no_numify?content-type=$content_type"), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
cmp_deeply(
  read_sheet($excel->{Worksheet}[0]),
  [['01',' 2',3],[4,5,'006']],
  'data is not numified'
);
}

# Test automatic column widths
{
ok((my $content= get "/rest/auto_widths?content-type=$content_type"), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
my $sheet = $excel->{Worksheet}[0];

# internal representation of column widths is as floats
# and for some reason there's a width set on the column beyond the last

=begin column_widths
cmp_deeply(
  [ map int, @{ $sheet->{ColWidth} }[0..1] ],
  [ 3, 6 ],
  'column_widths'
);
=cut

cmp_deeply(
  read_sheet($sheet),
  [ [qw/Foo Bar/], [1,2], [3,999999] ],
  'auto_widths -> sheet'
);
}

# Test multiple worksheets as array of array of array
{
ok((my $content = get "/rest/multi_worksheet_a_o_a_o_a?content-type=$content_type"), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
my $sheet1 = $excel->{Worksheet}[0];
my $sheet2 = $excel->{Worksheet}[1];

cmp_deeply(
  read_sheet($sheet1),
  [[1,2,3],[4,5,6]],
  'multi worksheet array_of_array_of_array -> sheet1'
);

cmp_deeply(
  read_sheet($sheet2),
  [[7,8,9],[10,11,12]],
  'multi worksheet array_of_array_of_array -> sheet2'
);
}

# Test hashref with options
{
ok((my $resp = request "/rest/fancy?content-type=$content_type"), 'received response');
is($resp->header('Content-Type'), $content_type, 'Content-Type');
is($resp->header('Content-Disposition'), 'attachment; filename=mtfnpy.xlsx', 'Content-Disposition');

ok((my $content = $resp->content), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
my $sheet = $excel->{Worksheet}[0];

=begin column_widths 
cmp_deeply(
  [ map int, @{ $sheet->{ColWidth} }[0..1] ],
  [ 10, 20 ],
  'column_widths'
);
=cut

cmp_deeply(
  read_sheet($sheet),
  [ [qw/Foo Bar/], [1,2], [3,4] ],
  'with options -> sheet'
);
}

# Test multiple worksheets as hash
{
ok((my $resp = request "/rest/multi_worksheet_hash?content-type=$content_type"), 'received response');
is($resp->header('Content-Type'), $content_type, 'Content-Type');
is($resp->header('Content-Disposition'), 'attachment; filename=mtfnpy.xlsx', 'Content-Disposition');

ok((my $content = $resp->content), 'received file');
open my $fh, '<', \$content;
ok((my $excel = Spreadsheet::XLSX->new($fh)), 'parsed file');
my $sheet1 = $excel->{Worksheet}[0];
my $sheet2 = $excel->{Worksheet}[1];
my $sheet3 = $excel->{Worksheet}[2];

is eval { $sheet1->get_name }, 'MySheet1', 'multi sheets hash -> sheet1 name';

cmp_deeply(
  read_sheet($sheet1),
  [ [qw/Foo Bar/], [1,2], [3,4] ],
  'multi sheets hash -> sheet1'
);

is eval { $sheet2->get_name }, 'MySheet2', 'multi sheets hash -> sheet2 name';

cmp_deeply(
  read_sheet($sheet2),
  [ [qw/Baz Quux/], [5,6], [7,8] ],
  'multi sheets hash -> sheet2'
);

cmp_deeply(
  read_sheet($sheet3),
  [ [9,10], [11,12] ],
  'multi sheets hash -> sheet3 (as array)'
);
}

sub read_sheet {
  my $sheet = shift;
  my $res;
  $sheet->{MaxRow} ||= $sheet->{MinRow};
  foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
    $sheet->{MaxCol} ||= $sheet->{MinCol};
    foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
      my $cell = $sheet->{Cells}[$row][$col];
      if ($cell) {
        $res->[$row][$col] = $cell->{Val};
      }
    }
  }
  $res
}
