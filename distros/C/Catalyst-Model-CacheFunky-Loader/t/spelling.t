use Test::More;
use Test::Spelling;
$ENV{LANG} = 'C';

my $spell_cmd;
foreach my $path (split(/:/, $ENV{PATH})) {
    -x "$path/spell"  and $spell_cmd="spell", last;
    -x "$path/ispell" and $spell_cmd="ispell -l", last;
    -x "$path/aspell" and $spell_cmd="aspell list", last;
}
$ENV{SPELL_CMD} and $spell_cmd = $ENV{SPELL_CMD};
$spell_cmd or plan skip_all => "no spell/ispell/aspell";
set_spell_cmd($spell_cmd);

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
Tomohiro
Teranishi
