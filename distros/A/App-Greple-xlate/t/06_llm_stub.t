use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Command::Run;

my $stub = File::Spec->rel2abs('t/bin/llm');
ok(-x $stub, 'stub is executable');

my $tmpdir = tempdir(CLEANUP => 1);

sub run_stub {
    my %args = @_;
    local %ENV = (%ENV, %{$args{env} // {}});
    Command::Run->new->command($stub, @{$args{argv} // []})
        ->run(stdin => $args{stdin} // '', stderr => 'capture');
}

subtest 'ok mode' => sub {
    my $log = "$tmpdir/ok.log";
    my $r = run_stub(argv  => ['-m', 'test-model'],
                     stdin => q(["hello\n"]),
                     env   => { LLM_STUB_LOG => $log });
    is($r->{result}, 0, 'exit status 0');
    is_deeply(JSON::PP->new->decode($r->{data}), ["HELLO\n"], 'uppercased array');
    open my $fh, '<', $log or die "$log: $!";
    my $rec = JSON::PP->new->decode(scalar <$fh>);
    is_deeply($rec->{argv}, ['-m', 'test-model'], 'argv recorded');
    is($rec->{stdin}, q(["hello\n"]), 'stdin recorded');
};

subtest 'models subcommand' => sub {
    my $r = run_stub(argv => ['models']);
    is($r->{result}, 0, 'exit status 0');
    like($r->{data}, qr/gpt-5\.5/, 'lists gpt-5.5');
    $r = run_stub(argv => ['models'], env => { LLM_STUB_MODE => 'nomodel' });
    unlike($r->{data}, qr/gpt-5\.5/, 'nomodel mode hides gpt-5.5');
};

subtest 'failure modes' => sub {
    my $r = run_stub(env => { LLM_STUB_MODE => 'fail' }, stdin => q(["a\n"]));
    isnt($r->{result}, 0, 'fail mode exits non-zero');
    like($r->{error}, qr/simulated failure/, 'error message on stderr');

    $r = run_stub(env => { LLM_STUB_MODE => 'short' }, stdin => q(["a\n","b\n"]));
    is_deeply(JSON::PP->new->decode($r->{data}), ["A\n"], 'short mode drops last element');

    $r = run_stub(env => { LLM_STUB_MODE => 'badjson' }, stdin => q(["a\n"]));
    ok(!eval { JSON::PP->new->decode($r->{data}); 1 }, 'badjson mode returns non-JSON');
};

subtest 'tag-shaped spans survive the transform' => sub {
    my $r = run_stub(stdin => q(["see <person id=1 /> and text\n"]));
    is($r->{result}, 0, 'exit 0');
    is_deeply(JSON::PP->new->decode($r->{data}),
              [ "SEE <person id=1 /> AND TEXT\n" ],
              'tag kept verbatim, rest uppercased');
};

done_testing;
