use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use App::Greple::xlate qw(%opt);
use App::Greple::xlate::llm;

# quiet progress output during tests
$App::Greple::xlate::show_progress = 0;

my %param = (
    model     => 'test-model',
    max       => 1000,
    options   => [ [ alpha => 'one' ], [ beta => 'two' ] ],
    prompt    => "Translate the following JSON array into %s.\n",
    lang_from => 'ORIGINAL',
    lang_to   => 'JA',
);

subtest 'build_system' => sub {
    my $system = App::Greple::xlate::llm::build_system(\%param);
    like($system, qr/\ATranslate the following JSON array into Japanese\./,
         '%s expands to language name');

    {
        my @saved = @{$opt{contexts}};
        @{$opt{contexts}} = ('background info');
        my $system = App::Greple::xlate::llm::build_system(\%param);
        like($system, qr/Translation context:\n- background info/,
             '--xlate-context is appended');
        @{$opt{contexts}} = @saved;
    }
    {
        my $saved = ${$opt{prompt}};
        ${$opt{prompt}} = "Custom prompt.";
        my $system = App::Greple::xlate::llm::build_system(\%param);
        is($system, "Custom prompt.", '--xlate-prompt replaces the default');
        ${$opt{prompt}} = $saved;
    }
    {
        my %p = (%param, lang_to => 'XX');
        ok(!eval { App::Greple::xlate::llm::build_system(\%p); 1 },
           'unknown language dies');
        like($@, qr/XX: unknown lang/, 'die message names the language');
    }
};

subtest 'llm_command' => sub {
    my @cmd = App::Greple::xlate::llm::llm_command(\%param, 'SYSTEM PROMPT');
    is_deeply(\@cmd,
              [ 'llm', '-m', 'test-model', '-s', 'SYSTEM PROMPT',
                '-o', 'alpha', 'one', '-o', 'beta', 'two',
                '--no-stream', '--no-log' ],
              'command line assembled in order');
};

my $bin = File::Spec->rel2abs('t/bin');
my $tmpdir = tempdir(CLEANUP => 1);

sub trap (&) {
        my $code = shift;
        eval { $code->() };
        $@;
}

subtest 'xlate_with via stub' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    my @to = App::Greple::xlate::llm::xlate_with(\%param, "hello\n", "world\n");
    is_deeply(\@to, ["HELLO\n", "WORLD\n"], 'round trip through stub llm');

    @to = App::Greple::xlate::llm::xlate_with(\%param, "one\ntwo\n", "three\n");
    is_deeply(\@to, ["ONE\nTWO\n", "THREE\n"], 'line counts per block preserved');
};

subtest 'batching by maxlen' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    my $log = "$tmpdir/batch.log";
    local $ENV{LLM_STUB_LOG} = $log;
    my %p = (%param, max => 12);
    my @to = App::Greple::xlate::llm::xlate_with(\%p, "aaaa bbbb\n", "cccc dddd\n");
    is_deeply(\@to, ["AAAA BBBB\n", "CCCC DDDD\n"], 'both blocks translated');
    open my $fh, '<', $log or die "$log: $!";
    my @calls = <$fh>;
    is(scalar @calls, 2, 'split into two llm calls (maxlen=12)');

    my %q = (%param, max => 4);
    like(trap { App::Greple::xlate::llm::xlate_with(\%q, "too long line\n") },
         qr/longer than max length/, 'oversized block dies');
};

subtest 'error handling' => sub {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    {
        local $ENV{LLM_STUB_MODE} = 'short';
        like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n", "b\n") },
             qr/Unexpected response \(1 < 2\)/, 'element count mismatch dies');
    }
    {
        local $ENV{LLM_STUB_MODE} = 'badjson';
        like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") },
             qr/Invalid JSON response/, 'non-JSON response dies');
    }
    {
        local $ENV{LLM_STUB_MODE} = 'fail';
        my $err = trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") };
        like($err, qr/llm failed/, 'generic failure reported');
        like($err, qr/simulated failure/, 'stderr from llm included');
    }
    {
        local $ENV{LLM_STUB_MODE} = 'nomodel';
        my %p = (%param, model => 'gpt-5.5');
        like(trap { App::Greple::xlate::llm::xlate_with(\%p, "a\n") },
             qr/does not know model "gpt-5\.5"/, 'unknown model diagnosed');
    }
};

subtest 'llm command not found' => sub {
    local $ENV{PATH} = $tmpdir;    # empty directory: no llm here
    like(trap { App::Greple::xlate::llm::xlate_with(\%param, "a\n") },
         qr/llm: command not found/, 'missing command diagnosed');
};

done_testing;
