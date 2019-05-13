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
    my $json_in_log = encode_json({ message => qq|[05/09/2019 23:51:51]\t[warn]\r$src_json\n| });
    note 'X';
    note( App::jl->new('-x')->process($json_in_log) );
}

done_testing;
