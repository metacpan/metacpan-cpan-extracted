use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub;
use Aozora2Epub::Gensym;
use lib qw/./;
use t::Util;

plan tests => 1 * blocks;

sub eval_unicode_notation {
    my $s = shift;
    $s =~ s|\\x\{([0-9a-fA-F]+)\}|chr(hex($1))|esg;
    return $s;
}

filters {
    html => 'chomp',
    expected => ['chomp', 'eval_unicode_notation'],
};

run {
    my $block = shift;
    Aozora2Epub::Gensym->reset_counter;

    my $doc = Aozora2Epub->new($block->html, no_fetch_assets=>1);
    my $got = join('', map { $_->as_html } @{$doc->files});
    is_deeply($got, $block->expected, $block->name);
};

__DATA__

=== simple unicode
--- html
※<span class="notes">［＃「てへん＋去」、U+62BE、369-2］</span>
--- expected
\x{62be}

=== non gaiji note
--- html
あああ<span class="notes">［＃ あああはママ］</span>
--- expected
あああ<span class="notes">［＃ あああはママ］</span>

=== within ruby
--- html
嘴<ruby><rb>鸚※</rb><rp>（</rp><rt>おうむ</rt><rp>）</rp></ruby><span class="notes">［＃「母＋鳥」、U+4CC7、217-9］</span>のごとく
--- expected
嘴<ruby><rb>鸚\x{4cc7}</rb><rp>（</rp><rt>おうむ</rt><rp>）</rp></ruby>のごとく

=== corrupted ruby
--- html
嘴<ruby><rb>鸚</rb><rp>（</rp><rt>おうむ</rt><rp>）</rp></ruby><span class="notes">［＃「母＋鳥」、U+4CC7、217-9］</span>のごとく
--- expected
嘴<ruby><rb>鸚</rb><rp>（</rp><rt>おうむ</rt><rp>）</rp></ruby><span class="notes">［＃「母＋鳥」、U+4CC7、217-9］</span>のごとく

=== within ruby 2
--- html
人里に出て<ruby><rb>※腹</rb><rp>（</rp><rt>きょうふく</rt><rp>）</rp></ruby><span class="notes">［＃「木＋号」、U+67B5、532-2］</span>を充たしたい
--- expected
人里に出て<ruby><rb>\x{67b5}腹</rb><rp>（</rp><rt>きょうふく</rt><rp>）</rp></ruby>を充たしたい

=== within ruby 3
--- html
人里に出て<ruby><rb>※腹腹</rb><rp>（</rp><rt>きょうふく</rt><rp>）</rp></ruby><span class="notes">［＃「木＋号」、U+67B5、532-2］</span>を充たしたい
--- expected
人里に出て<ruby><rb>\x{67b5}腹腹</rb><rp>（</rp><rt>きょうふく</rt><rp>）</rp></ruby>を充たしたい

=== simple jis
--- html
※<span class="notes">［＃「火＋華」、第3水準1-87-62］</span>
--- expected
\x{71c1}

=== simple jis 2
--- html
※<span class="notes">［＃「さんずい＋鼾のへん」、第4水準2-79-37］</span>
--- expected
\x{6fde}

=== corrupted jis
--- html
ああ<span class="notes">［＃「さんずい＋鼾のへん」、第4水準2-79-37］</span>
--- expected
ああ<span class="notes">［＃「さんずい＋鼾のへん」、第4水準2-79-37］</span>

=== image gaiji in rb
--- html
博物学者は<ruby><rb>※<img src="../../../gaiji/1-91/1-91-65.png" alt="※(「虫＋斯」、第3水準1-91-65)" class="gaiji" /></rb><rp>（</rp><rt>けむし</rt><rp>）</rp></ruby><span class="notes">［＃「虫＋占」、U+86C5、18-5］</span>の変じ
--- expected
博物学者は<ruby><rb>\x{86c5}\x{87d6}</rb><rp>（</rp><rt>けむし</rt><rp>）</rp></ruby>の変じ

=== kindle font broken jis
--- html
<img src="../../../gaiji/1-90/1-90-61.png" />
--- expected
<img src="../gaiji/1-90/1-90-61.png" />

=== kindle font broken jis 2
--- html
<img src="../../../gaiji/2-15/2-15-73.png" />
--- expected
<img src="../gaiji/2-15/2-15-73.png" />

=== kindle font broken jis 3
--- html
<img src="../../../gaiji/1-06/1-06-88.png" />
--- expected
<img src="../gaiji/1-06/1-06-88.png" />

=== kindle font broken unicode
--- html
※<span class="notes">［＃「あああ」、U+2152、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+2152、369-2］</span>

=== kindle font broken unicode 2
--- html
※<span class="notes">［＃「あああ」、U+2189、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+2189、369-2］</span>

=== kindle font broken unicode 3
--- html
※<span class="notes">［＃「あああ」、U+26BD、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+26BD、369-2］</span>

=== kindle font broken unicode 4
--- html
※<span class="notes">［＃「あああ」、U+26BE、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+26BE、369-2］</span>

=== kindle font broken unicode 5
--- html
※<span class="notes">［＃「あああ」、U+3244、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+3244、369-2］</span>

=== kindle font broken unicode over 0xffff
--- html
※<span class="notes">［＃「あああ」、U+1F130、369-2］</span>
--- expected
※<span class="notes">［＃「あああ」、U+1F130、369-2］</span>

=== kindle font broken unicode over 0xffff but ok
--- html
※<span class="notes">［＃「あああ」、U+2a2b2、369-2］</span>
--- expected
\x{2a2b2}
