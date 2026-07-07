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

my $DOC = <<'END';
prologue paragraph one

yamada taro visited acme corporation

yamada taro came back again

epilogue paragraph last
END

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

my $dict = "$dir/dict.json";
write_file($dict, <<'END');
[
  { "category": "person",  "text": "yamada taro" },
  { "category": "company", "text": "acme corporation" }
]
END

subtest 'dictionary anonymization end to end' => sub {
    my $doc = "$dir/doc.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, $DOC);
    write_file($cache, '');
    run_xlate($doc, "--xlate-anonymize=$dict");   # 全訳を作る
    # 1 段落変更して文脈つき再翻訳を発生させる
    (my $mod = $DOC) =~ s/came back again/came back once more/;
    write_file($doc, $mod);
    my $log = "$dir/dict.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    is(scalar @calls, 1, 'one call');
    my $payload = $calls[0]{stdin};
    my $sys = sys_of($calls[0]);
    unlike($payload, qr/yamada taro/, 'payload has no real name');
    like($payload, qr/<person id=1 \/>/, 'payload uses category tag');
    unlike($sys, qr/yamada taro/, 'context sections have no real name');
    unlike($sys, qr/acme corporation/, 'context sections have no company');
    like($sys, qr/<person id=1 \/>/, 'context uses the same tag');
    like($r->stdout, qr/yamada taro CAME BACK ONCE MORE/,
         'restored name stays lowercase; only surrounding text upcased');
};

subtest 'inline mark anonymization' => sub {
    my $doc = "$dir/mark.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    my $marked = <<'END';
introduction line here

the contact is {{ person("suzuki hanako") }} for now

suzuki hanako answers the phone
END
    write_file($doc, $marked);
    write_file($cache, '');
    my $log = "$dir/mark.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, '--xlate-anonymize-mark=');
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '',
        map { join '', @{ JSON::PP->new->decode($_->{stdin}) } } @calls;
    unlike($payload, qr/suzuki hanako/, 'marked name gone everywhere');
    like($payload, qr/\{\{ person\("<person id=1 \/>"\) \}\}/,
         'mark syntax survives around the tag');
    like($r->stdout, qr/suzuki hanako ANSWERS THE PHONE/,
         'unmarked occurrence restored too');
    like($r->stdout, qr/\{\{ PERSON\("suzuki hanako"\) \}\}|\{\{ person\("suzuki hanako"\) \}\}/i,
         'mark restored in output');
};

subtest 'escape layer protects tag-shaped literals' => sub {
    my $doc = "$dir/esc.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
literal <person id=1 /> appears here

yamada taro appears here
END
    write_file($cache, '');
    my $log = "$dir/esc.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/<lit id=1 \/>/, 'literal escaped');
    like($r->stdout, qr/LITERAL <person id=1 \/> APPEARS|literal <person id=1 \/> appears/i,
         'literal restored exactly');
};

subtest 'maskfile combination keeps both layers working' => sub {
    my $doc = "$dir/combo.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, <<'END');
keep C<verbatim> and yamada taro together
END
    write_file($cache, '');
    my $mf = "$dir/maskfile";
    write_file($mf, "C<[^>]*>\n");
    my $log = "$dir/combo.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my $r = run_xlate($doc, "--xlate-anonymize=$dict",
                      '--xlate-setopt', "maskfile=$mf");
    is($r->status, 0, 'run succeeds');
    my @calls = stub_calls($log);
    my $payload = join '', map $_->{stdin}, @calls;
    like($payload, qr/<m id=1 \/>/, 'maskfile layer applied');
    like($payload, qr/<person id=1 \/>/, 'anonymize layer applied');
    unlike($payload, qr/yamada taro|C<verbatim>/, 'both hidden');
    like($r->stdout, qr/C<verbatim>/, 'maskfile restored');
    like($r->stdout, qr/YAMADA TARO|yamada taro/i, 'name restored');
};

subtest 'dryrun previews the anonymized form' => sub {
    my $doc = "$dir/dry.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, "yamada taro visited acme corporation\n");
    write_file($cache, '');
    my $before = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    my $r = run_xlate($doc, '--xlate-dryrun', "--xlate-anonymize=$dict");
    is($r->status, 0, 'dryrun succeeds');
    like($r->stdout, qr/<person id=1 \/> visited <company id=1 \/>/,
         'From preview shows the anonymized payload');
    my $after = do { open my $fh, '<', $cache or die; local $/; <$fh> };
    is($after, $before, 'cache untouched by dryrun');
};

subtest 'progress From display shows the masked form' => sub {
    my $doc = "$dir/prog.txt";
    my $cache = "$doc.xlate-gpt5-EN-US.json";
    write_file($doc, "yamada taro visited acme corporation\n");
    write_file($cache, '');
    my $r = run_xlate($doc, "--xlate-anonymize=$dict");
    is($r->status, 0, 'run succeeds');
    my($from) = $r->stdout =~ /^\[xlate\.pm\] From:\n(.*)$/m;
    like($from, qr/<person id=1 \/>/, 'From line shows the masked payload');
    unlike($from, qr/yamada taro/, 'From line has no plaintext secret');
};

done_testing;
