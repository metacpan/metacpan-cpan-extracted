package App::optex::textconv::xls;

our $VERSION = '1.04';

use strict;
use warnings;

use Spreadsheet::ParseExcel;

sub to_text {
    my $file = shift;
    my $book = Spreadsheet::ParseExcel::Workbook->Parse($file) or return;
    my $worksheet = $book->{Worksheet} // return;
    my @sheets = @{$worksheet} or return;
    join "\n", grep { defined and length } map sheet($_), @sheets;
}

sub sheet {
    my $sheet = shift;
    my @rows = do {
	map  { join(' ', map $_->Value, grep defined, @$_) . "\n" }
	grep { defined and @$_ > 0 }
	@{$sheet->{Cells}}
    };
    join '', @rows;
}

1;
