use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;
use JSON qw/encode_json/;
use Encode qw//;

use App::jl;

sub jl_test {
    my ($name, $src_json, $opt, $test_ref, $do_note) = @_;

    my $jl = App::jl->new($opt ? @{$opt} : ());
    $jl->{__current_orig_line} = $src_json;
    my $output = $jl->_run_line;

    note $name  if $do_note;
    note $output if $do_note;

    if (ref $test_ref eq 'CODE') {
        $test_ref->($output, $src_json);
    }
}

my $JSON = encode_json({
    foo => encode_json({
        bar => encode_json({
            baz => encode_json({
                hoge => 123,
            }),
        }),
    }),
});

note $JSON;

jl_test('BASIC', $JSON, [], sub {
    my ($output, $src) = @_;

    ok $output =~ m!foo!;
});

{
    my $like_json_not_json = '{"not":"JSON"';
    jl_test('LIKE_JSON_NOT_JSON', $like_json_not_json, [], sub {
        my ($output, $src) = @_;

        is $output, $like_json_not_json;
    });
}

jl_test('SORT_KEYS', encode_json({ z => 1, b => 1, a => 1 }), [], sub {
    my ($output, $src) = @_;

    ok $output =~ m!a.*b.*z!sm;
});

jl_test('JA', encode_json({ aiko => '詩' }), [], sub {
    my ($output, $src) = @_;

    my $s = Encode::encode('utf8', '詩');

    ok $output =~ m!"aiko"\s*:\s*"$s"!;
});

jl_test('NO_PRETTY', $JSON, ['--no-pretty'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!foo.*bar.*baz.*hoge!;
});

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51]\t[warn]\t$src_json\n| });
    jl_test('X', $json_in_log, ['-x'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!\Q"[warn]",!;
    });
}

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51] foo, bar, baz \n$src_json\n| });
    jl_test('XX', $json_in_log, ['-xx'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!"bar",! && $output =~ m!"baz"! && $output =~ m!"foo"\s*:\s*"bar"!;
    });
}

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51](warn)<server> \n$src_json\n| });
    jl_test('XXX', $json_in_log, ['-xxx'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!"\Q(warn)"! && $output =~ m!"<server>"! && $output =~ m!"foo"\s*:\s*"bar"!;
    });
}

{
    my $src_json = encode_json([
        { created    => 1560026367 },
        { updated    => 1560026367.123 },
        { created_at => '1560026367' },
        { time       => '1560026367123' },
        { unixtime   => 1560026367123 },
        { date       => '1560026367.123' },
        { ts         => 1560026367 },
    ]);
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51] (warn) <server>\n$src_json\n| });
    jl_test('XXXX', $json_in_log, ['-xxxx', '--timestamp-key', 'ts'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!"\Q(warn)"! && $output =~ m!"<server>"! && $output !~ m!1560026367!;
    });
}

jl_test('NO_CONTENT_LINE', "\t \r\n\t\n", [], sub {
    my ($output, $src) = @_;

    is $output, undef;
});

STDIN: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new->run;
    };
    close $IN;
    ok $stdout !~ m!\\!;
    if (0) {
        note 'STDIN';
        note $stdout;
    }
}

STDERR: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new('--stderr')->run;
    };
    close $IN;
    is $stdout, '';
    ok $stderr;
    if (0) {
        note 'STDERR';
        note $stdout;
        note $stderr;
    }
}

STDIN_NOT_JSON: {
    my $str = 'aikoの詩。';
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new->run;
    };
    close $IN;
    is $stdout, $str;
    if (0) {
        note 'NOT JSON';
        note $stdout;
    }
}

STDIN_SWEEP: {
    my $str = 'aikoの詩。';
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new('--sweep')->run;
    };
    close $IN;
    is $stdout, '';
    if (0) {
        note 'SWEEP';
        note $stdout;
    }
}

jl_test('GREP', $JSON, ['--grep', 'baz'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!baz!;
});

jl_test('GREP_MULTI', $JSON, ['--grep', 'baz', '--grep', 'no_match_cond'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!baz!;
});

jl_test('GREP_MULTI2', $JSON, ['--grep', 'baz', '--grep', 'bar'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!baz!;
});

jl_test('GREP_NO_MATCH', $JSON, ['--grep', 'no match'], sub {
    my ($output, $src) = @_;

    is $output, undef;
});

jl_test('IGNORE', $JSON, ['--ignore', 'baz'], sub {
    my ($output, $src) = @_;

    is $output, undef;
});

jl_test('IGNORE_MULTI', $JSON, ['--ignore', 'baz', '--ignore', 'bar'], sub {
    my ($output, $src) = @_;

    is $output, undef;
});

jl_test('IGNORE_BUT_SHOW', $JSON, ['--ignore', 'baz', '--ignore', 'no_match_cond'], sub {
    my ($output, $src) = @_;

    is $output, undef;
});

{
    my $src_json = encode_json([
        { created => 1560026367 },
    ]);
    my $json_in_log = encode_json({ message => qq|[info]\n$src_json\n| });
    jl_test('GMTIME', $json_in_log, ['-xxxx', '--gmtime'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!2019-06-!;
    });
}

jl_test('TRIM', encode_json({ message => qq|  info\tfoo\tbar\tbaz  | }), ['-x'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!"info! && $output =~ m!baz"!;
});

{
    my $json = encode_json({
        service => 'Foo-Service',
        message => encode_json({
            timestamp => 1560026367,
            log => "[PID:12345]<info>\nThis is log message. foo, bar, baz, qux, long message is going to be splitted nicely to treat JSON by jq without any special function",
        }),
        pod     => 'bar-baz-12345',
    });
    jl_test('LONG', $json, ['-xxxx'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!\Q[PID:12345]! && $output =~ m!"<info>"! && $output =~ m!"bar"! && $output =~ m!2019-06-!;
    });
}

jl_test('YAML', $JSON, ['-yaml'], sub {
    my ($output, $src) = @_;

    ok $output =~ m!foo:!;
});

{
    my $src_json = encode_json([
        { created => 946684800 },
    ]);
    my $json_in_log = encode_json({ message => qq|[info]\n$src_json\n| });
    jl_test('XXXXX', $json_in_log, ['-xxxxx'], sub {
        my ($output, $src) = @_;

        ok $output =~ m!\Q[info]! && $output !~ m!946684800!;
    });
}

jl_test('UA', encode_json({
    'user agent' => "L\nF",
    'user-agent' => "L\nF",
    user_agent => "L\nF",
    userAgent => "L\nF",
    UserAgent => "L\nF",
}), ['-x'], sub {
    my ($output, $src) = @_;

    ok $output !~ m!"L"!;
});

jl_test('UA-COMMA', encode_json({
    useragent => "L, F",
}), ['-xx'], sub {
    my ($output, $src) = @_;

    ok $output !~ m!"L"!;
});

jl_test('UA-LABEL', encode_json({
    useragent => "foo [bar] baz",
}), ['-xxx'], sub {
    my ($output, $src) = @_;

    ok $output !~ m!"foo"!;
});

done_testing;
