use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;

use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Mojo::Util qw(decode);

use CallBackery::GuiPlugin::AbstractTable;
use CallBackery::Translate qw(trm trmJoin);

package TestTable;
use Mojo::Base 'CallBackery::GuiPlugin::AbstractTable', -signatures;
use CallBackery::Translate qw(trm trmJoin);

has app => sub { TestApp->new };
has user => sub { TestUser->new };

sub tableCfg ($self) {
    return [
        { key => 'host',   label => trm('Host'),         type => 'str' },
        { key => 'state',  label => trm('State of %1', 'AGW'), type => 'str' },
        { key => 'seen',   label => trm('Seen'),         type => 'date' },
    ];
}

sub getTableRowCount ($self, $args) { return 3 }

sub getTableData ($self, $args) {
    return [
        # a trm() built in this process
        { host => 'a', state => trm("\x{26a0} %1", trm('pending')),
          seen => 1_700_000_000_000 },
        # the same message after it went through JSON, which is how a
        # status reported by some other system arrives in a table
        { host => 'b', state => ["\x{26a0} %1", ['pending']] },
        { host => 'c', state => trmJoin("\n",
            trm('one'), trm('two %1', 'x')) },
    ];
}

package TestApp;
use Mojo::Base -base, -signatures;
use Mojo::Home;
use FindBin;
has home => sub { Mojo::Home->new($FindBin::Bin.'/..') };

package TestUser;
use Mojo::Base -base, -signatures;
has userInfo => sub { { lang => 'en' } };

package main;

my $plugin = TestTable->new;

# --- csv ---------------------------------------------------------------

my $csvOut = $plugin->makeExportAction(type => 'CSV')
    ->{actionHandler}->($plugin, {});
like($csvOut->{type}, qr{^text/csv;\s*charset=UTF-8$}i,
    'csv says which encoding it is in');
my $csv = decode('UTF-8', $csvOut->{asset}->slurp);
ok(defined $csv, 'csv is valid UTF-8');
$csv //= '';

like($csv, qr{^"?Host"?,"?State of AGW"?,"?Seen"?\r?$}m,
    'csv header substitutes label arguments');
# a cell Text::CSV refused used to come out as an empty line
like($csv, qr{^a,"?\x{26a0} pending"?,"?\d{4}-\d\d-\d\d \d\d:\d\d:\d\d [-+]\d{4}"?\r?$}m,
    'csv renders a nested trm() outside ASCII');
# an empty date used to come out as the start of 1970
like($csv, qr{^b,"?\x{26a0} pending"?,\r?$}m,
    'csv renders a message that arrived as JSON');
like($csv, qr{^c,"one\ntwo x",\r?$}m,
    'csv keeps a line break inside a quoted cell');
unlike($csv, qr{^\r?$}m, 'csv has no empty lines');
unlike($csv, qr{%\d|ARRAY\(}, 'csv has no raw placeholders or refs');

# --- xlsx ----------------------------------------------------------------

my $xlsx = $plugin->makeExportAction(type => 'XLSX')
    ->{actionHandler}->($plugin, {})->{asset}->slurp;

open my $zfh, '<', \$xlsx or die;
my $zip = Archive::Zip->new;
is($zip->readFromFileHandle($zfh), AZ_OK, 'the workbook is a readable zip');

my $sheet = decode('UTF-8', scalar $zip->contents('xl/worksheets/sheet1.xml'));
my $strings = decode('UTF-8', scalar $zip->contents('xl/sharedStrings.xml'));
my @shared = map { my $s = $_; $s =~ s/&#10;|\r?\n/\n/g; $s }
    $strings =~ m{<t(?: [^>]*)?>([^<]*)</t>}g;

# map every cell reference to its text
my %cell;
while ($sheet =~ m{<c r="([A-Z]+\d+)"[^>]*t="s"[^>]*><v>(\d+)</v></c>}g) {
    $cell{$1} = $shared[$2];
}

is($cell{B1}, 'State of AGW', 'xlsx header substitutes label arguments');
is($cell{B3}, "\x{26a0} pending", 'xlsx renders a nested trm()');
is($cell{B4}, "\x{26a0} pending", 'xlsx renders a message that arrived as JSON');
is($cell{B5}, "one\ntwo x", 'xlsx renders a trmJoin()');
ok(!exists $cell{C4} && !exists $cell{C3},
    'no message spills over into the next column');

done_testing;
