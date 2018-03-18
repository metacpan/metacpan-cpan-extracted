use Dwarf::Pragma;
use Dwarf;
use Encode qw/decode_utf8/;
use Test::More;
use Test::Requires 'Text::CSV_XS';

my $c = Dwarf->new();

$c->load_plugin("Text::CSV_XS" => {});

ok $c->can('read_csv');
ok $c->can('decode_csv');
ok $c->can('encode_csv');

my $file = 't/00_dwarf/file/sample.csv';
my @data = $c->read_csv($file);

my $expected = << "==========";
"日本語","data","ああああ"
"日本語","data","ああああ"
"日本語","data","ああああ"
==========

$expected =~ s/\n/\r\n/g;

my $encoded = $c->encode_csv(@data);
is decode_utf8($encoded), $expected; 

my @data2 = $c->decode_csv($encoded);

is_deeply(\@data, \@data2);

done_testing;
