use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;
$ENV{PATH} = File::Spec->rel2abs('t/bin') . ":$ENV{PATH}";

subtest 'gpt5 engine through greple pipeline' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
                          --xlate-cache=never --xlate-format=xtxt .+))
        ->setstdin("hello world\n")->run;
    is($result->status, 0, 'exits successfully');
    like($result->stdout, qr/HELLO WORLD/, 'stub translation appears in output');
};

subtest 'conflict format' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
                          --xlate-cache=never --xlate-format=cm .+))
        ->setstdin("hello world\n")->run;
    is($result->status, 0, 'exits successfully');
    like($result->stdout, qr/<<<<<<<.*hello world.*=======.*HELLO WORLD.*>>>>>>>/s,
         'conflict markers contain original and translation');
};

subtest 'response count mismatch fails' => sub {
    local $ENV{LLM_STUB_MODE} = 'short';
    my $result = xlate(qw(--xlate --xlate-engine=gpt5 --xlate-to=EN-US
                          --xlate-cache=never .+))
        ->setstdin("hello\nworld\n")->run;
    isnt($result->status, 0, 'non-zero exit on element count mismatch');
};

done_testing;
