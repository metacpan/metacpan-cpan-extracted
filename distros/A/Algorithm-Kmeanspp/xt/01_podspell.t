use strict;
use warnings;
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;

my $spell_cmd;
foreach my $path (split(/:/, $ENV{PATH})) {
    -x "$path/spell"  and $spell_cmd="spell", last;
    -x "$path/ispell" and $spell_cmd="ispell -l", last;
    -x "$path/aspell" and $spell_cmd="aspell list", last;
}
$ENV{SPELL_CMD} and $spell_cmd = $ENV{SPELL_CMD};
$spell_cmd or plan skip_all => "no spell/ispell/aspell";

$ENV{LANG} = 'C';
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
set_spell_cmd($spell_cmd);
all_pod_files_spelling_ok('lib');

__DATA__
Mizuki Fujisawa
fujisawa@bayon.cc
Algorithm::Kmeanspp
Wikipedia
