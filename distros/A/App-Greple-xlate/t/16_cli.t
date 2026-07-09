use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $script = abs_path('script/xlate');
my $dir    = tempdir(CLEANUP => 1);

# スタブ llm(-nn ケースで使用)と getoptlong.sh を PATH で解決
$ENV{PATH} = abs_path('t/bin') . ":$ENV{PATH}";
$ENV{PERL5LIB} = abs_path('lib') . ($ENV{PERL5LIB} ? ":$ENV{PERL5LIB}" : '');
$ENV{NO_COLOR} = 1;

sub write_file {
    my($path, $text) = @_;
    open my $fh, '>:encoding(utf8)', $path or die "$path: $!";
    print $fh $text;
    close $fh;
}

sub run_cli {
    my @cmd = ('bash', $script, @_);
    my $stderr = "$dir/stderr.$$";
    my $pid = open my $fh, '-|';
    defined $pid or die "fork: $!";
    if (!$pid) {
        open STDERR, '>', $stderr or die;
        exec @cmd or exit 127;
    }
    my $out = do { local $/; <$fh> };
    close $fh;
    my $status = $? >> 8;
    my $err = '';
    if (open my $e, '<', $stderr) { local $/; $err = <$e>; close $e }
    unlink $stderr;
    return { out => $out // '', err => $err, status => $status };
}

my $doc = "$dir/f.txt";
write_file($doc, "hello world\n");

subtest 'defaults: gpt5 engine, API mode' => sub {
    my $r = run_cli(qw(-n -t JA), $doc);
    is($r->{status}, 0, 'exit 0');
    like($r->{out}, qr/--xlate-engine=gpt5/, 'default engine is gpt5');
    like($r->{out}, qr/--xlate(?:\s|$)/m, 'API mode (--xlate)');
    unlike($r->{out}, qr/--xlate-labor/, 'not labor mode');
};

subtest '--no-api selects labor mode' => sub {
    my $r = run_cli(qw(-n --no-api -t JA), $doc);
    like($r->{out}, qr/--xlate-labor/, 'labor mode');
};

subtest '-a is a valid explicit default' => sub {
    my $base = run_cli(qw(-n -t JA), $doc);
    my $api  = run_cli(qw(-n -a -t JA), $doc);
    is($api->{out}, $base->{out}, 'same command as default');
    is($api->{status}, 0, 'exit 0');
};

subtest '-e deepl still works' => sub {
    my $r = run_cli(qw(-n -e deepl -t JA), $doc);
    like($r->{out}, qr/--xlate-engine=deepl/, 'deepl engine');
};

subtest '-nn runs greple with --xlate-dryrun' => sub {
    my $body = "hello dryrun world\n";
    my $d2 = "$dir/dry.txt";
    write_file($d2, $body);
    write_file("$d2.xlate-gpt5-EN-US.json", '');
    my $r = run_cli(qw(-nn -t EN-US), $d2);
    is($r->{status}, 0, 'exit 0');
    like($r->{out}, qr/\Qhello dryrun world\E/, 'original text passes through');
    like($r->{err}, qr/From/, 'transmission preview shown on stderr');
    unlike($r->{out}, qr/^greple /m, 'not an echoed command line');
};

subtest 'new 2.0 options map to module options' => sub {
    my @cases = (
        [ ['--anonymize=dict.json'],  qr/--xlate-anonymize=dict\.json/ ],
        [ ['--mark'],                 qr/--xlate-anonymize-mark=(?:\s|$)/m ],
        [ ['--mark=@@(.+)@@'],        qr/--xlate-anonymize-mark=\@\@\(\.\+\)\@\@/ ],
        [ ['--template'],             qr/--xlate-template=(?:\s|$)/m ],
        [ ['--template=<%.*?%>'],     qr/--xlate-template=<%\.\*\?%>/ ],
        [ ['--frontmatter'],          qr/--xlate-frontmatter/ ],
        [ ['--seed=prev.json'],       qr/--xlate-cache-seed=prev\.json/ ],
        [ ['--context=3'],            qr/--xlate-context-window=3/ ],
    );
    for my $c (@cases) {
        my($args, $want) = @$c;
        my $r = run_cli('-n', @$args, '-t', 'JA', $doc);
        is($r->{status}, 0, "@$args: exit 0");
        like($r->{out}, $want, "@$args maps correctly");
    }
};

subtest 'options absent by default' => sub {
    my $r = run_cli(qw(-n -t JA), $doc);
    unlike($r->{out}, qr/--xlate-anonymize|--xlate-template|--xlate-frontmatter|--xlate-cache-seed|--xlate-context-window/,
           'no new module options without CLI flags');
};

subtest 'file type presets unchanged' => sub {
    my $md = "$dir/f.md";
    my $pm = "$dir/f.pm";
    write_file($md, "# title\n");
    write_file($pm, "package F;\n1;\n");
    like(run_cli(qw(-n -t JA), $md)->{out}, qr/\^\[-\+#\]/, 'markdown area pattern');
    my $pmout = run_cli(qw(-n -t JA), $pm)->{out};
    like($pmout, qr/-Mperl/, 'perl module loaded for .pm');
    like($pmout, qr/--pod/, 'pod option for .pm');
};

sub find_gmake {
    for my $make (qw(gmake make)) {
        my $v = qx($make --version 2>/dev/null) // '';
        return $make if $v =~ /GNU/;
    }
    return;
}

subtest 'XLATE.mk expansion' => sub {
    my $gmake = find_gmake() or plan skip_all => 'GNU make not found';
    my $mk  = abs_path('share/XLATE.mk');
    my $sub = "$dir/mk"; mkdir $sub;
    write_file("$sub/doc.txt", "hello\n");
    my $run = sub {
        my(@vars) = @_;
        qx(cd '$sub' && '$gmake' -n -f '$mk' XLATE_LANG=JA @vars 2>&1);
    };
    my $out = $run->();
    like($out, qr/-e gpt5/, 'default engine is gpt5');
    $out = $run->('XLATE_ANONYMIZE=dict.json', 'XLATE_CONTEXT_WINDOW=3',
                  'XLATE_FRONTMATTER=1', 'XLATE_TEMPLATE=1',
                  'XLATE_MARK=1', 'XLATE_SEED=prev.json');
    like($out, qr/--anonymize='dict\.json'/, 'XLATE_ANONYMIZE');
    like($out, qr/--context='3'/,     'XLATE_CONTEXT_WINDOW');
    like($out, qr/--frontmatter/,          'XLATE_FRONTMATTER');
    like($out, qr/--template(?:\s|$)/m,    'XLATE_TEMPLATE=1 -> bare --template');
    like($out, qr/--mark(?:\s|$)/m,        'XLATE_MARK=1 -> bare --mark');
    like($out, qr/--seed='prev\.json'/,    'XLATE_SEED');
    $out = $run->('XLATE_TEMPLATE=X%.*?%X');
    like($out, qr/--template='X%\.\*\?%X'/, 'XLATE_TEMPLATE=regex');
    # xlate -M は値を二重引用符で包んで渡す (XLATE_MARK="1") が、
    # GNU Make はコマンドライン変数代入の引用符を剥がさないので、
    # REMOVE_QUOTE で剥がされて往復することを確認する
    $out = $run->(q{XLATE_MARK='"1"'}, q{XLATE_TEMPLATE='"1"'},
                  q{XLATE_ANONYMIZE='"dict.json"'});
    like($out, qr/--mark(?:\s|$)/m,     'quoted XLATE_MARK="1" -> bare --mark');
    like($out, qr/--template(?:\s|$)/m, 'quoted XLATE_TEMPLATE="1" -> bare --template');
    like($out, qr/--anonymize='dict\.json'/, 'quoted XLATE_ANONYMIZE unquoted');
    unlike($out, qr/--anonymize='?"/, 'no literal double quotes leak into option');
    # FILE.ANONYMIZE は XLATE_ANONYMIZE より優先
    write_file("$sub/doc.txt.ANONYMIZE", qq([{"category":"person","text":"X"}]\n));
    $out = $run->('XLATE_ANONYMIZE=global.json');
    like($out, qr/--anonymize='doc\.txt\.ANONYMIZE'/, 'FILE.ANONYMIZE wins');
    unlike($out, qr/--anonymize=global\.json/, 'variable overridden');
};

subtest 'XOPT quotes values so custom regexes survive the shell' => sub {
    my $gmake = find_gmake() or plan skip_all => 'GNU make not found';
    my $mk   = abs_path('share/XLATE.mk');
    my $sub2 = "$dir/mk3"; mkdir $sub2;
    mkdir "$sub2/bin" or die $!;
    write_file("$sub2/bin/xlate", "#!/bin/sh\nprintf '%s\\n' \"\$@\"\n");
    chmod 0755, "$sub2/bin/xlate";
    write_file("$sub2/doc.txt", "hello\n");
    # A realistic custom mark regex: unquoted parentheses in XLATE_MARK
    # are a hard /bin/sh syntax error at recipe execution time (make -n
    # never shows it, since -n never invokes the shell).
    my $mark_re = '@@(?<category>[a-z]+):(?<text>[^@]+)@@';
    my $target  = 'doc.gpt5-JA.xtxt';
    my $cmd = "cd '$sub2' && PATH='$sub2/bin:'\"\$PATH\" '$gmake' -f '$mk' " .
              "XLATE_LANG=JA 'XLATE_MARK=$mark_re' '$target' 2>&1";
    my $out = qx($cmd);
    my $status = $? >> 8;
    is($status, 0, 'make exits 0 (no shell syntax error from unquoted regex)')
        or diag($out);
    my $content = -f "$sub2/$target"
        ? do { open my $fh, '<', "$sub2/$target" or die; local $/; <$fh> }
        : '';
    like($content, qr/^--mark=\Q$mark_re\E$/m,
         'mark regex reaches xlate intact; quotes are stripped only by the shell');
};

subtest 'xlate -M passes new variables' => sub {
    my $gmake = find_gmake() or plan skip_all => 'GNU make not found';
    # インストール済みの古い share/XLATE.mk が解決されうるので、
    # make 出力ではなく --trace (set -x) の exec 行で転送を検証する
    my $sub = "$dir/mk2"; mkdir $sub;
    write_file("$sub/doc.txt", "hello\n");
    my $cwd = Cwd::getcwd();
    chdir $sub or die;
    my $r = run_cli(qw(-M -n --trace -t JA --anonymize=dict.json --context=3 --frontmatter));
    chdir $cwd or die;
    is($r->{status}, 0, 'exit 0') or diag($r->{err});
    like($r->{err}, qr/XLATE_ANONYMIZE=.?dict\.json/, 'XLATE_ANONYMIZE passed');
    like($r->{err}, qr/XLATE_CONTEXT_WINDOW=.?3/,     'XLATE_CONTEXT_WINDOW passed');
    like($r->{err}, qr/XLATE_FRONTMATTER=1/,          'XLATE_FRONTMATTER passed');
};

done_testing;
