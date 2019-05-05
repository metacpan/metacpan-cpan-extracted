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
    note( App::jl->new->process($JSON) );
}

NO_PRETTY: {
    note( App::jl->new('--no-pretty')->process($JSON) );
}

DEPTH: {
    note( App::jl->new('--depth', '1')->process($JSON) );
}

TEST_RUN_WITH_NOT_JSON: {
    my $str = 'Not JSON String';
    open my $IN, '<', \$str;
    local *STDIN = *$IN;
    my ($stdout, $stderr) = capture {
        App::jl->new->run;
    };
    close $IN;
    is $stdout, $str;
}

done_testing;
