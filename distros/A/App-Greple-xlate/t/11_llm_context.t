use v5.14;
use warnings;
no warnings 'once';
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

my $DOC = <<'END';
## SECTION ONE

alpha paragraph original text

beta paragraph original text

## SECTION TWO

gamma paragraph original text

delta paragraph original text
END

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>', $path or die "$path: $!";
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

# 小文字始まりの段落だけを翻訳対象にする(見出し行は対象外)
my @XLATE = (qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US),
             qw(--xlate-format=xtxt --all --need=0),
             '--re', '^([a-z].*\n)+');

sub run_xlate {
    my($file, @extra) = @_;
    xlate(@XLATE, @extra, $file)->run;
}

# 準備: 全対訳入りのキャッシュを作る(スタブ llm は uc 変換)
my $doc = "$dir/doc.txt";
my $cache = "$doc.xlate-gpt5-EN-US.json";
write_file($doc, $DOC);
write_file($cache, '');
my $r0 = run_xlate($doc);
is($r0->status, 0, 'initial full translation succeeds');

subtest 'single changed paragraph goes through region path' => sub {
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/single.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'exactly one llm call for one gap');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "beta paragraph revised text\n" ],
              'only the changed paragraph is sent');
    like($r->stdout, qr/BETA PARAGRAPH REVISED TEXT/, 'translated output');
    like($r->stdout, qr/ALPHA PARAGRAPH ORIGINAL TEXT/, 'others from cache');
};

subtest 'duplicate paragraphs do not fake cache hits' => sub {
    my $dup = "$dir/dup.txt";
    write_file($dup, <<'END');
alpha duplicated text

alpha duplicated text

beta unique text
END
    write_file("$dup.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/dup.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($dup);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'all-miss doc with duplicates: single flat call');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "alpha duplicated text\n", "beta unique text\n" ],
              'duplicates deduped, no false hit classification');
    like($r->stdout, qr/ALPHA DUPLICATED TEXT.*ALPHA DUPLICATED TEXT.*BETA UNIQUE TEXT/s,
         'both occurrences rendered from the single translation');
};

subtest 'context sections appear in the system prompt' => sub {
    # 前 subtest の続き: 現キャッシュは beta 改訂版を含む
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph rerevised/;
    write_file($doc, $mod);
    my $log = "$dir/context.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one llm call');
    my $sys = sys_of($calls[0]);

    like($sys, qr/Surrounding document source/, 'source slice section');
    like($sys, qr/## SECTION ONE/, 'slice contains non-translated heading');
    like($sys, qr/\Q[...]\E/, 'slice has the passage marker');

    like($sys, qr/Reference translations/, 'reference section');
    like($sys, qr/alpha paragraph original text/, 'neighbor source');
    like($sys, qr/ALPHA PARAGRAPH ORIGINAL TEXT/, 'neighbor translation');

    like($sys, qr/Previous version of the passage/, 'previous section');
    like($sys, qr/beta paragraph revised text/, 'old source pair');
    like($sys, qr/BETA PARAGRAPH REVISED TEXT/, 'old translation pair');

    like($r->stdout, qr/BETA PARAGRAPH REREVISED TEXT/, 'output updated');
};

subtest 'truncation drops far flanks first' => sub {
    require App::Greple::xlate::llm;
    my $big = "x" x 5000;
    local $App::Greple::xlate::call_context = {
        source_before => "line before\n",
        source_after  => "line after\n",
        hits_before   => [ [ "near b\n", "NEAR B\n" ],
                           [ "$big\n",   "FAR B\n"  ] ],
        hits_after    => [ [ "near a\n", "NEAR A\n" ],
                           [ "$big\n",   "FAR A\n"  ] ],
        old_pairs     => [ [ "old src\n", "OLD TRANS\n" ] ],
    };
    my $text = App::Greple::xlate::llm::context_sections();
    cmp_ok(length($text), '<=', $App::Greple::xlate::llm::CONTEXT_MAX,
           'within limit');
    like($text, qr/NEAR B/, 'near flank kept');
    like($text, qr/NEAR A/, 'near flank kept (after)');
    unlike($text, qr/FAR B/, 'far flank dropped');
    like($text, qr/OLD TRANS/, 'old pair survives truncation');
};

subtest 'empty context renders nothing' => sub {
    local $App::Greple::xlate::call_context = undef;
    is(App::Greple::xlate::llm::context_sections(), '', 'undef context');
};

subtest 'two distant changes make two isolated regions' => sub {
    # 状態リセット: 原文とキャッシュを作り直す
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/alpha paragraph original/alpha paragraph revised/;
    $mod =~ s/delta paragraph original/delta paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/distant.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 2, 'two llm calls for two gaps');
    my($sys1, $sys2) = map sys_of($_), @calls;
    # Previous 節は最後の節なので、その見出し以降に何が居るかで判定する
    # (原文スライス節には他領域のテキストが正当に現れ得るため)
    like($sys1, qr/Previous version.*alpha paragraph original/s,
         'region 1 previous pair is alpha');
    unlike($sys1, qr/Previous version.*delta paragraph original/s,
           'region 1 does not carry delta as previous');
    like($sys2, qr/Previous version.*delta paragraph original/s,
         'region 2 previous pair is delta');
};

subtest 'consecutive changes form one region with both old pairs' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph revised/;
    $mod =~ s/gamma paragraph original/gamma paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/consec.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc);
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one llm call for adjacent misses');
    my $sys = sys_of($calls[0]);
    like($sys, qr/beta paragraph original/, 'old pair for beta');
    like($sys, qr/gamma paragraph original/, 'old pair for gamma');
    is_deeply(JSON::PP->new->decode($calls[0]{stdin}),
              [ "beta paragraph revised text\n",
                "gamma paragraph revised text\n" ],
              'both paragraphs in one payload');
};

subtest 'window=0 disables context and falls back to flat batch' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/gamma paragraph original/gamma paragraph revised/;
    write_file($doc, $mod);
    my $log = "$dir/nowin.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-context-window=0');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one call');
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/Reference translations/, 'no reference section');
    unlike($sys, qr/Surrounding document source/, 'no slice section');
};

subtest 'all-miss (fresh document) falls back without context' => sub {
    my $doc2 = "$dir/fresh.txt";
    write_file($doc2, $DOC);
    write_file("$doc2.xlate-gpt5-EN-US.json", '');
    my $log = "$dir/fresh.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc2);
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'single flat batch');
    my $sys = sys_of($calls[0]);
    unlike($sys, qr/Reference translations/, 'no context sections');
};

subtest 'cache seeding carries pairs across documents' => sub {
    # doc.txt のキャッシュを整えてから、それを seed に新文書を翻訳
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph seeded/;
    my $doc3 = "$dir/issue2.txt";
    my $cache3 = "$doc3.xlate-gpt5-EN-US.json";
    write_file($doc3, $mod);
    write_file($cache3, '');
    my $log = "$dir/seed.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc3, "--xlate-cache-seed=$cache");
    is($r->status, 0, 'seeded run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'only the changed paragraph is translated');
    my $sys = sys_of($calls[0]);
    like($sys, qr/beta paragraph original/, 'old pair comes from the seed');
    like($r->stdout, qr/ALPHA PARAGRAPH ORIGINAL TEXT/,
         'unchanged paragraphs come from the seed without API calls');

    # 2 回目: 対象キャッシュが実体化済みなので seed は無視される
    $mod =~ s/beta paragraph seeded/beta paragraph reseeded/;
    write_file($doc3, $mod);
    my $log2 = "$dir/seed2.log";
    local $ENV{LLM_STUB_LOG} = $log2;
    my $r2 = run_xlate($doc3, "--xlate-cache-seed=$cache");
    my @calls2 = stub_calls($log2);
    is(scalar @calls2, 1, 'second run: one call');
    my $sys2 = sys_of($calls2[0]);
    like($sys2, qr/beta paragraph seeded/,
         'previous pair comes from own cache, not the seed');
};

subtest 'failed llm call preserves the whole cache' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    my $before = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    (my $mod = $DOC) =~ s/gamma paragraph original/gamma paragraph doomed/;
    write_file($doc, $mod);
    {
        local $ENV{LLM_STUB_MODE} = 'fail';
        my $r = run_xlate($doc);
        isnt($r->status, 0, 'run fails when llm fails');
    }
    my $after = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    my %pairs = map @$_, @{ JSON::PP->new->decode($after) };
    is(scalar keys %pairs, 4, 'all four cached pairs survive the failure');
    is($pairs{"gamma paragraph original text\n"}, "GAMMA PARAGRAPH ORIGINAL TEXT\n",
       'old pair of the edited paragraph survives for the retry');
};

subtest 'dryrun leaves the cache file untouched' => sub {
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc);
    my $before = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    (my $mod = $DOC) =~ s/beta paragraph original/beta paragraph dryrun/;
    write_file($doc, $mod);
    my $r = run_xlate($doc, '--xlate-dryrun');
    is($r->status, 0, 'dryrun succeeds');
    my $after = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    is($after, $before, 'cache file is byte-identical after dryrun');
};

done_testing;
