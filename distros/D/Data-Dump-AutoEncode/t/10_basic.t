use strict;
use warnings;
use Test::More tests => 5;

# encoded/decoded Japanese hiragana (a)
my $str  = "\x{3042}";
my $char = "\x{82}\x{A0}";
my $data = {str => $str, array => [$str]};
my $re   = qr/\\x\{[^\}]+\}/;

require Data::Dump;
my $dump = Data::Dump::dump($data);
like $dump => qr/$re/;

require Data::Dump::AutoEncode;
Data::Dump::AutoEncode::set_encoding('utf-8');

my $encoded_dump = Data::Dump::AutoEncode::edump($data);
isnt $encoded_dump => $dump;
unlike $encoded_dump => qr/$re/;

# ::AutoEncode::dump is an alias of ::Encode::edump
$encoded_dump = Data::Dump::AutoEncode::dump($data);
isnt $encoded_dump => $dump;
unlike $encoded_dump => qr/$re/;
