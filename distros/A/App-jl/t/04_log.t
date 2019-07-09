use strict;
use warnings;
use Test::More;
use JSON qw/encode_json decode_json/;

use App::jl;

my $payload = encode_json({
    message => "Could not find",
    dump    => {
        userId => "12345",
    },
});

my $resource = encode_json({
    type   => 'global',
    label => encode_json({
        projectId => "myloggingproject",
    }),
});

my $log = encode_json({
    textPayload => $payload,
    insertId    => "vd4m1if7h7u1a",
    resource    => $resource,
    timestamp   => "1562434910.718100792",
    logName     => "projects/myloggingproject/logs/my-test-log",
});


my $jl = App::jl->new('-xxxxx');
$jl->{__current_orig_line} = $log;
my $output = $jl->_run_line;

my $j = decode_json($output);

#note $output;

is $j->{textPayload}{dump}{userId}, "12345";
is $j->{resource}{label}{projectId}, "myloggingproject";

done_testing;
