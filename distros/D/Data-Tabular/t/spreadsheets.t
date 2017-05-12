use strict;

use Test::More tests => 4;

use_ok( 'Data::Tabular' );

use Digest::MD5  qw(md5 md5_hex md5_base64);

my $t1 = Data::Tabular->new(
    headers => [ 'animal', 'color', 'owner', 'jan', 'feb', 'amount', 'date' ],
    data => [
	[ 'cat', 'black', 'jane', 1, 2, 1.01, 'jan 1 2002' ],
	[ 'cat', 'black', 'joey', 2, 3, 1.01, 'jan 1 2002' ],
	[ 'cat', 'white', 'jack', 3, 4, 1.01, 'jan 1 2002' ],
	[ 'cat', 'white', 'john', 4, 5, 1.01, 'mar 2 2002' ],
	[ 'bat', 'gray',  'john', 4, 5, -99999.99999999, 'mar 4 2003' ],
	[ 'dog', 'white', 'john', 5, 6, 1.01, 'mar 4 2003' ],
	[ 'dog', 'white', 'joey', 6, 7, 1.01, 'mar 4 2003' ],
	[ 'dog', 'black', 'jack', 7, 8, 1.01, 'mar 4 2003' ],
	[ 'dog', 'black', 'jane', 8, 90900, 100007.01, 'mar 4 2003' ],
	[ 'rabbit', 'black', 'jane', 8, 9, 1.01, 'mar 4 2003' ],
    ],
    extra => {
        extra1 => sub { 'extra column' },
        extra2 => sub { 'extra column' },
    },
);

print $t1->txt;
ok(1);

print $t1->html;
ok(1);

my $xls;

SKIP: {
    my $skip;
    eval { require Spreadsheet::WriteExcel::Simple; };
    $skip++ if $@;
    skip 'need Spreadsheet::WriteExcel::Simple', 1 if $skip;
    my $ss = Spreadsheet::WriteExcel::Simple->new("/tmp/test1.xls");
    my $workbook = $ss->book;
    my $worksheet = $ss->sheet;
    $t1->xls(workbook => $workbook, worksheet => $worksheet);
    $ss->save('/tmp/test1.xls');
    ok(1);
}
