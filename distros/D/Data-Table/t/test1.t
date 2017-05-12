use strict;
use Data::Table;
use Test::More tests => 5;

is(Data::Table::fromFileGuessOS("t_unix.csv"), 0, "Guess Unix file format");
#is(Data::Table::fromFileGuessOS("t_dos.csv"), 1, "Guess Windows file format");
is(Data::Table::fromFileGuessOS("t_mac.csv"), 2, "Guess MAC file format");

my $t_unix=Data::Table::fromFile("t_unix.csv");
my $t_unix_noheader=Data::Table::fromFile("t_unix_noheader.csv");
my $t_dos=Data::Table::fromFile("t_dos.csv");
my $t_mac=Data::Table::fromFile("t_mac.csv");

is_deeply($t_unix->rowRefs, $t_unix_noheader->rowRefs, 'rowRefs t_unix.csv');
is_deeply($t_unix->rowRefs, $t_dos->rowRefs, 'rowRefs t_dos.csv');
is_deeply($t_unix->rowRefs, $t_mac->rowRefs, "rowRefs t_mac.csv");

