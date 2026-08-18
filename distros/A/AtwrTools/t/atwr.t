use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use AtwrTools;

my @findings = AtwrTools::scan_invisible_characters("A\x{200B}\x{202F}B");
is(scalar @findings, 2, 'scan count');
is($findings[0]{codePoint}, 'U+200B', 'first codepoint');
is($findings[0]{index}, 1, 'first index');
is(AtwrTools::remove_invisible_characters("A\x{200B} B\x{FEFF}"), 'A B', 'remove');
is(AtwrTools::strip_markdown_paste_residue("## Heading\n- **Item**\n\\[link\\]"), "Heading\nItem\n[link]", 'tidy');
done_testing();
