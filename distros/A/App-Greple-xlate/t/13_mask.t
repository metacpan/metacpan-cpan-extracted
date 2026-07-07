use v5.14;
use warnings;
use utf8;

use Test::More;

use App::Greple::xlate::Mask;

sub trap (&) {
    my $code = shift;
    eval { $code->() };
    $@;
}

subtest 'legacy path unchanged' => sub {
    my $m = App::Greple::xlate::Mask->new(pattern => ['C<[^>]*>']);
    my @t = ("see C<foo> and C<foo> here\n");
    $m->mask(@t);
    is($t[0], "see <m id=1 /> and <m id=2 /> here\n",
       'per-occurrence numbering');
    $m->unmask(@t);
    is($t[0], "see C<foo> and C<foo> here\n", 'restored');
};

subtest 'stable numbering with categories' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person  => quotemeta('山田太郎'));
    $m->add_rule(company => quotemeta('アクメ株式会社'));
    my @t = ("山田太郎はアクメ株式会社の山田太郎である\n",
             "翌日、山田太郎が来た\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />は<company id=1 />の<person id=1 />である\n",
       'same string same tag; per-category counters');
    is($t[1], "翌日、<person id=1 />が来た\n", 'stable across texts');
    $m->unmask(@t);
    is($t[0], "山田太郎はアクメ株式会社の山田太郎である\n", 'restored 0');
    is($t[1], "翌日、山田太郎が来た\n", 'restored 1');
};

subtest 'stable numbering persists across mask/reset cycles' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @a = ("山田太郎です\n");
    $m->mask(@a); $m->unmask(@a); $m->reset;
    my @b = ("また山田太郎です\n");
    $m->mask(@b);
    like($b[0], qr/<person id=1 \/>/, 'same id after reset');
    $m->unmask(@b); $m->reset;
};

subtest 'reference mode is not verified' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @payload = ("本文に山田太郎がいる\n");
    my @context = ("文脈にも山田太郎がいる\n");
    $m->mask(@payload);
    $m->mask_reference(@context);
    like($context[0], qr/<person id=1 \/>/, 'context masked with same tag');
    # 応答は本文のみ。文脈のタグが応答に無くても die しない
    my @resp = ($payload[0]);
    ok(!trap { $m->unmask(@resp) }, 'unmask verifies payload tags only');
    is($resp[0], "本文に山田太郎がいる\n", 'payload restored');
    $m->reset;
};

subtest 'missing tracked tag dies' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_rule(person => quotemeta('山田太郎'));
    my @t = ("山田太郎です\n");
    $m->mask(@t);
    my @resp = ("タグが消えた応答\n");
    like(trap { $m->unmask(@resp) }, qr/Masking error/,
         'lost payload tag detected');
    $m->reset;
};

subtest 'escape layer round trip with nesting' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->add_escape_rule;
    $m->add_rule(person => quotemeta('山田太郎'));
    my @t = ("原文に <person id=1 /> というリテラルと山田太郎がいる\n");
    $m->mask(@t);
    like($t[0], qr/<lit id=1 \/>/, 'tag-shaped literal escaped first');
    unlike($t[0], qr/山田太郎/, 'real name is gone from payload');
    is($t[0], "原文に <lit id=1 /> というリテラルと<person id=1 />がいる\n",
       'literal and name each got their own tag without collision');
    $m->unmask(@t);
    is($t[0], "原文に <person id=1 /> というリテラルと山田太郎がいる\n",
       'nested round trip restores exactly');
    $m->reset;
};

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

subtest 'dictionary: JSON format' => sub {
    my $f = "$dir/dict.json";
    write_file($f, "\x{FEFF}" . <<'END');
[
  { "category": "person",  "text": "山田太郎", "note": "ignored" },
  { "category": "company", "regex": "アクメ(?:株式会社)?" }
]
END
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->load_anonymize_file($f);
    my @t = ("山田太郎はアクメ株式会社にいた。アクメの件。\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />は<company id=1 />にいた。<company id=2 />の件。\n",
       'literal and regex rules from JSON');
    $m->unmask(@t); $m->reset;
};

subtest 'dictionary: JSON errors' => sub {
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    my $bad1 = "$dir/bad1.json";
    write_file($bad1, '[ { "category": "person" } ]');
    like(trap { $m->load_anonymize_file($bad1) }, qr/text.*regex|regex.*text/i,
         'missing text/regex dies');
    my $bad2 = "$dir/bad2.json";
    write_file($bad2, '[ { "category": "person", "text": "a", "regex": "b" } ]');
    like(trap { $m->load_anonymize_file($bad2) }, qr/both/i,
         'both text and regex dies');
    my $bad3 = "$dir/bad3.json";
    write_file($bad3, '[ { "category": "lit", "text": "a" } ]');
    like(trap { $m->load_anonymize_file($bad3) }, qr/lit.*reserved/i,
         'lit category dies');
    my $bad4 = "$dir/bad4.json";
    write_file($bad4, '[ { "category": "Bad-Name", "text": "a" } ]');
    like(trap { $m->load_anonymize_file($bad4) }, qr/invalid category/i,
         'invalid category dies');
};

subtest 'dictionary: line format' => sub {
    my $f = "$dir/dict.txt";
    write_file($f, <<'END');
# comment
person   山田太郎
company  /アクメ(?:株式会社)?/
END
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->load_anonymize_file($f);
    my @t = ("山田太郎とアクメ株式会社\n");
    $m->mask(@t);
    is($t[0], "<person id=1 />と<company id=1 />\n", 'line format rules');
    $m->unmask(@t); $m->reset;
};

subtest 'inline mark extraction' => sub {
    my $text = <<'END';
担当は {{ person("山田太郎") }} である。
発注元は {{ company('アクメ株式会社') }} である。
再訪: {{ person("山田太郎") }}
END
    my $rules = App::Greple::xlate::Mask::extract_marks(
        $text, $App::Greple::xlate::Mask::DEFAULT_MARK);
    is(scalar @$rules, 2, 'deduplicated to two rules');
    is($rules->[0][0], 'person', 'category extracted');
    like("山田太郎", qr/$rules->[0][1]/, 'pattern matches the literal');

    like(trap {
        App::Greple::xlate::Mask::extract_marks(
            '{{ person("X") }} {{ company("X") }}',
            $App::Greple::xlate::Mask::DEFAULT_MARK)
    }, qr/conflicting categor/i, 'same text different category dies');

    like(trap {
        App::Greple::xlate::Mask::extract_marks('x', 'no captures here')
    }, qr/category.*text|named capture/i, 'regex without captures dies');

    like(trap {
        App::Greple::xlate::Mask::extract_marks(
            '{{ lit("X") }}', $App::Greple::xlate::Mask::DEFAULT_MARK)
    }, qr/lit.*reserved/i, 'lit mark dies');
};

subtest 'dictionary: line continuation' => sub {
    my $f = "$dir/cont.txt";
    write_file($f, "person   Very Long\\\nName\n");
    my $m = App::Greple::xlate::Mask->new(STABLE => 1);
    $m->load_anonymize_file($f);
    my @t = ("meet Very Long\nName today\n");
    $m->mask(@t);
    like($t[0], qr/<person id=1 \/>/, 'continued literal pattern matches');
    $m->unmask(@t);
    is($t[0], "meet Very Long\nName today\n", 'restored');
    $m->reset;
};

done_testing;
