use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;
use JSON qw/encode_json/;

use App::jl;

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

BASIC: {
    note 'BASIC';
    note( App::jl->new->process($JSON) );
}

NOT_JSON: {
    note 'NOT_JSON';
    note( App::jl->new->process('aikoの詩。') );
}

SORT_KEYS: {
    note 'SORT_KEYS';
    note( App::jl->new->process(encode_json({ z => 1, b => 1, a => 1 })) );
}

JA: {
    note 'JA';
    note( App::jl->new->process(encode_json({ aiko => '詩' })) );
}

NO_PRETTY: {
    note 'NO_PRETTY';
    note( App::jl->new('--no-pretty')->process($JSON) );
}

DEPTH: {
    note 'DEPTH';
    note( App::jl->new('--depth', '1')->process($JSON) );
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

X: {
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51]\t[warn]\t$src_json\n| });
    note 'X ' . $json_in_log;
    note( App::jl->new('-x')->process($json_in_log) );
}

XX: {
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51] foo, bar, baz \n$src_json\n| });
    note 'XX ' . $json_in_log;
    note( App::jl->new('-xx')->process($json_in_log) );
}

XXX: {
    my $src_json = encode_json({ foo => 'bar' });
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51](warn)<server> \n$src_json\n| });
    note 'XXX ' . $json_in_log;
    note( App::jl->new('-xxx')->process($json_in_log) );
}

XXXX: {
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
    note 'XXXX ' . $json_in_log;
    note( App::jl->new('-xxxx', '--timestamp-key', 'ts')->process($json_in_log) );
}

GMTIME: {
    my $src_json = encode_json([
        { created => 1560026367 },
    ]);
    my $json_in_log = encode_json({ message => qq|[info]\n$src_json\n| });
    note 'GMTIME ' . $json_in_log;
    note( App::jl->new('-xxxx', '--gmtime')->process($json_in_log) );
}

TRIM: {
    my $json_in_log = encode_json({ message => qq|  info\tfoo\tbar\tbaz  | });
    note 'GMTIME ' . $json_in_log;
    note( App::jl->new('-x')->process($json_in_log) );
}

{
    my $json = encode_json({
        service => 'Foo-Service',
        message => encode_json({
            timestamp => time(),
            log => "[PID:12345]<info>\nThis is log message. foo, bar, baz, qux, long message is going to be splitted nicely to treat JSON by jq without any special function",
        }),
        pod     => 'bar-baz-12345',
    });
    note $json;
    note( App::jl->new('-xxxx')->process($json) );
}

YAML: {
    note 'YAML';
    note( App::jl->new('--yaml')->process($JSON) );
}

done_testing;
