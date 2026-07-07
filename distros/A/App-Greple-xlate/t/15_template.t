use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
$ENV{PATH} = File::Spec->rel2abs('t/bin') . ":$ENV{PATH}";

my $dir = tempdir(CLEANUP => 1);

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

sub stub_calls {
    my($log) = @_;
    return () unless -f $log;
    open my $fh, '<', $log or die "$log: $!";
    map JSON::PP->new->decode($_), <$fh>;
}

sub sys_of {
    my($rec) = @_;
    my @a = @{$rec->{argv}};
    my($i) = grep { $a[$_] eq '-s' } 0 .. $#a;
    $a[$i + 1];
}

my @XLATE = (qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US),
             qw(--xlate-format=xtxt --all --need=0),
             '--re', '^([a-z].*\n)+');

sub run_xlate {
    my($file, @extra) = @_;
    xlate(@XLATE, @extra, $file)->run;
}

subtest 'expressions preserved (Japanese variable names)' => sub {
    # スタブは uc 変換: 日本語・記号は不変なので式はそのまま返る
    my $doc = "$dir/tmpl.txt";
    write_file($doc, <<'END');
this case was handled by {{ 報告者 }} yesterday

the client {{ 発注会社 }} agreed
END
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/ok.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-template=');
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $sys = sys_of($calls[0]);
    like($sys, qr/opaque placeholders/, 'preservation instruction present');
    like($r->stdout, qr/\{\{ 報告者 \}\}/, 'expression intact in output');
    like($r->stdout, qr/\{\{ 発注会社 \}\}/, 'second expression intact in output');
};

subtest 'broken expression is detected' => sub {
    # ASCII 変数名はスタブの uc で {{ REPORTER }} に変形される →
    # 式列不一致 → die(非ゼロ終了)
    my $doc = "$dir/broken.txt";
    write_file($doc, <<'END');
handled by {{ reporter }} yesterday

shown {% if flag %}sometimes{% endif %} here
END
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $r = run_xlate($doc, '--xlate-template=');
    isnt($r->status, 0, 'mangled expression dies');
};

subtest 'cache preserved on verification failure' => sub {
    my $doc = "$dir/protect.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
first stable paragraph here

second stable paragraph here

third closing paragraph here
END
    write_file($cache, '');
    run_xlate($doc);            # 3 対訳のキャッシュを作る
    # 同一実行内で: 領域 1(先頭段落の修正)は成功して checkpoint、
    # 領域 2(末尾段落の式化)は検証 die → freeze
    write_file($doc, <<'END');
first amended paragraph here

second stable paragraph here

handled by {{ reporter }} now
END
    my $r = run_xlate($doc, '--xlate-template=');
    isnt($r->status, 0, 'run fails on the second region');
    my $after = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    like($after, qr/FIRST AMENDED PARAGRAPH/,
         'earlier region result was checkpointed before the failure');
    like($after, qr/third closing paragraph here/,
         "failing region's old pair survives thanks to the freeze");
};

subtest 'anonymized text inside expressions verifies correctly' => sub {
    my $dict = "$dir/t4dict.json";
    write_file($dict, '[ { "category": "person", "text": "yamada taro" } ]');
    my $doc = "$dir/combo.txt";
    write_file($doc, <<'END');
the client {{ yamada taro }} agreed
END
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $r = run_xlate($doc, '--xlate-template=', "--xlate-anonymize=$dict");
    is($r->status, 0, 'no false-positive die');
    like($r->stdout, qr/\{\{ yamada taro \}\}/,
         'expression restored with the real name inside');
};

subtest 'front matter: excluded, values anonymized, slices adjusted' => sub {
    my $doc = "$dir/fm.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
---
template: report.j2
報告者: "yamada taro"
発注会社: acme corporation
---
opening paragraph of the body

the visitor was yamada taro that day

closing paragraph of the body
END
    write_file($cache, '');
    my $log0 = "$dir/fm0.log";
    {
        local $ENV{LLM_STUB_LOG} = $log0;
        my $r0 = run_xlate($doc, '--xlate-frontmatter');
        is($r0->status, 0, 'initial run succeeds');
        my @calls = stub_calls($log0);
        my $payload = join '', map $_->{stdin}, @calls;
        unlike($payload, qr/report\.j2|template:/,
               'front matter is not a translation target');
        unlike($payload, qr/yamada taro/, 'value anonymized in body');
        like($payload, qr/<var id=\d+ \/>/, 'var category tag used');
    }
    # 文脈スライスにも front matter が出ないこと(1 段落変更)
    (my $mod = do { open my $fh, '<', $doc or die; local $/; <$fh> })
        =~ s/visitor was/visitor happened to be/;
    write_file($doc, $mod);
    my $log = "$dir/fm.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-frontmatter');
    is($r->status, 0, 'second run succeeds');
    my @calls = stub_calls($log);
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/template: report\.j2/, 'slice does not show front matter');
    unlike($sys, qr/yamada taro|acme corporation/,
           'values hidden from context too');
};

subtest 'no frontmatter option: behavior unchanged' => sub {
    my $doc = "$dir/nofm.txt";
    write_file($doc, "---\nkey: value\n---\nbody paragraph here\n");
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/nofm.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'runs');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/key: value/, 'without the option fm is ordinary text');
};

subtest 'warn when front matter runs into the body' => sub {
    my $doc = "$dir/fmwarn.txt";
    write_file($doc, "---\nkey: value\n---\nbody starts immediately\n");
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    my $r = run_xlate($doc, '--xlate-frontmatter');
    like($r->stdout, qr/no blank line after front matter/,
         'straddle warning printed');
};

subtest 'reordered expressions accepted (multiset check)' => sub {
    # 翻訳先の語順に合わせた式の並べ替えは正当なので許容する
    my $doc = "$dir/swap.txt";
    write_file($doc, "both {{ 報告者 }} and {{ 発注会社 }} appear here\n");
    write_file("$doc.xlate-gpt5-EN-US.json", '');
    local $ENV{LLM_STUB_MODE} = 'swap';
    my $r = run_xlate($doc, '--xlate-template=');
    is($r->status, 0, 'run succeeds despite reordering');
    like($r->stdout, qr/\{\{ 発注会社 \}\}.*\{\{ 報告者 \}\}/s,
         'expressions come back reordered');
};

done_testing;
