use v5.14;
use warnings;
use utf8;
use Encode;

use Test::More;
use File::Spec;
use Data::Dumper;

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Test with DeepL
SKIP: {
    skip 'DEEPL_AUTH_KEY not set', 2 unless $ENV{DEEPL_AUTH_KEY};

    subtest 'deepl engine - English to Japanese' => sub {
        my $input = "Hello\n";
        my $result = xlate(qw(--xlate --xlate-engine=deepl --xlate-to=JA --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'deepl engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese characters');
    };

    subtest 'deepl engine - Japanese to English' => sub {
        my $input = "こんにちは\n";
        my $result = xlate(qw(--xlate --xlate-engine=deepl --xlate-to=EN-US --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'deepl engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[Hh]ello/i, 'Japanese translated to English');
    };
}

# Test with GPT-4o
SKIP: {
    skip 'OPENAI_API_KEY not set', 2 unless $ENV{OPENAI_API_KEY};

    subtest 'gpt4o engine - English to Japanese' => sub {
        my $input = "Good morning\n";
        my $result = xlate(qw(--xlate --xlate-engine=gpt4o --xlate-to=JA --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'gpt4o engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese characters');
    };

    subtest 'gpt4o engine - Japanese to English' => sub {
        my $input = "おはよう\n";
        my $result = xlate(qw(--xlate --xlate-engine=gpt4o --xlate-to=EN --xlate-format=xtxt .+))
            ->setstdin($input)->run;
        is($result->status, 0, 'gpt4o engine exits successfully');
        my $output = $result->stdout;
        like($output, qr/[Mm]orning|[Hh]ello|[Gg]ood/i, 'Japanese translated to English');
    };
}

##############################################################################
# Tests for script/xlate command with real APIs
##############################################################################

my $xlate_cmd = File::Spec->rel2abs('script/xlate');

sub run_xlate {
    my $out = `@_`;
    my $status = $? >> 8;
    return (Encode::decode('utf-8', $out), $status);
}

# Test script/xlate with DeepL
SKIP: {
    skip 'DEEPL_AUTH_KEY not set', 1 unless $ENV{DEEPL_AUTH_KEY};

    subtest 'script/xlate with deepl engine' => sub {
        my ($out, $status) = run_xlate(qq{echo "Hello" | $xlate_cmd -a -e deepl -t JA -p '.+' 2>&1});
        is($status, 0, 'script/xlate with deepl exits successfully');
        like($out, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese');
    };
}

# Test script/xlate with GPT-4o
SKIP: {
    skip 'OPENAI_API_KEY not set', 1 unless $ENV{OPENAI_API_KEY};

    subtest 'script/xlate with gpt4o engine' => sub {
        my ($out, $status) = run_xlate(qq{echo "Hello" | $xlate_cmd -a -e gpt4o -t JA -p '.+' 2>&1});
        is($status, 0, 'script/xlate with gpt4o exits successfully');
        like($out, qr/[\x{3040}-\x{30FF}\x{4E00}-\x{9FFF}]/, 'output contains Japanese');
    };
}

done_testing;
