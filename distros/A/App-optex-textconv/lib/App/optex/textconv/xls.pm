package App::optex::textconv::xls;

our $VERSION = '1.01';

use v5.14;
use warnings;
use Carp;

our @EXPORT_OK = qw(to_text);

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.xls$/ => \&to_text ],
    );

use Spreadsheet::ParseExcel;

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.(xls)$/)[0] or return;
    my $book = Spreadsheet::ParseExcel::Workbook->Parse($file) or return;
    my $worksheet = $book->{Worksheet} // return;
    my @sheets = @{$worksheet} or return;
    join "\n\n", map sheet($_), @sheets;
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
