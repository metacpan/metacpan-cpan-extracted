use warnings;
use strict;
use Test::More;
use Data::Kanji::Kanjidic ':all';
use FindBin;
use utf8;

binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $kanji = parse_kanjidic ("$FindBin::Bin/kanjidic-sample");
ok ($kanji->{亜}, "Got entry for 亜");
my $a = $kanji->{亜};
cmp_ok ($a->{Q}->[0], '<', 100000, "Sane value for four corner code");

done_testing ();

# Local variables:
# mode: perl
# End:
