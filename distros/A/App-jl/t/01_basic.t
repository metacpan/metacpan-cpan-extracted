use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;
use JSON qw/encode_json/;

use App::jl;

sub jl_test {
    my ($name, $src_json, $opt) = @_;

    note $name;
    note(
        App::jl->new($opt ? @{$opt} : ())->process($src_json)
    );
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

jl_test('BASIC', $JSON);

jl_test('NOT_JSON', 'aikoの詩。');

jl_test('SORT_KEYS', encode_json({ z => 1, b => 1, a => 1 }));

jl_test('JA', encode_json({ aiko => '詩' }));

jl_test('NO_PRETTY', $JSON, ['--no-pretty']);

jl_test('DEPTH', $JSON, ['--depth', '1']);

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51]\t[warn]\t$src_json\n| });
    jl_test('X', $json_in_log, ['-x']);
}

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51] foo, bar, baz \n$src_json\n| });
    jl_test('XX', $json_in_log, ['-xx']);
}

{
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51](warn)<server> \n$src_json\n| });
    jl_test('XXX', $json_in_log, ['-xxx']);
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
    jl_test('XXXX', $json_in_log, ['-xxxx', '--timestamp-key', 'ts']);
}

STDIN: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new->run;
    };
    close $IN;
    note 'STDIN';
    note $stdout;
}

STDERR: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new('--stderr')->run;
    };
    close $IN;
    note 'STDERR';
    is $stdout, '';
    ok $stderr;
}

STDIN_WITH_NOT_JSON: {
    my $str = 'aikoの詩。';
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new->run;
    };
    close $IN;
    note 'NOT JSON';
    note $stdout;
    is $stdout, $str;
}

GREP: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new('--grep', 'baz')->run;
    };
    close $IN;
    note 'GREP';
    ok $stdout;
}

IGNORE: {
    open my $IN, '<', \$JSON;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new('--ignore', 'baz')->run;
    };
    close $IN;
    note 'IGNORE';
    ok !$stdout;
}

{
    my $src_json = encode_json([
        { created => 1560026367 },
    ]);
    my $json_in_log = encode_json({ message => qq|[info]\n$src_json\n| });
    jl_test('GMTIME', $json_in_log, ['-xxxx', '--gmtime']);
}

jl_test('TRIM', encode_json({ message => qq|  info\tfoo\tbar\tbaz  | }), ['-x']);

{
    my $json = encode_json({
        service => 'Foo-Service',
        message => encode_json({
            timestamp => time(),
            log => "[PID:12345]<info>\nThis is log message. foo, bar, baz, qux, long message is going to be splitted nicely to treat JSON by jq without any special function",
        }),
        pod     => 'bar-baz-12345',
    });
    jl_test('LONG', $json, ['-xxxx']);
}

jl_test('YAML', $JSON, ['-yaml']);

{
    my $src_json = encode_json([
        { created => 946684800 },
    ]);
    my $json_in_log = encode_json({ message => qq|[info]\n$src_json\n| });
    jl_test('XXXXX', $json_in_log, ['-xxxxx']);
}

done_testing;
