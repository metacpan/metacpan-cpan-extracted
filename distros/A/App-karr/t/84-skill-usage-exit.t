use strict;
use warnings;
use Test::More;
use Cwd qw( abs_path );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

# Ticket #76, the rows that live in App::karr::Cmd::Skill: an invalid value is
# a usage error and must exit 2, not 1 (ADR 0002,
# docs/adr/0002-exit-code-contract.md).
#
# Probed pre-fix on this tree:
#   karr skill bogusaction            -> exit 1, "Unknown action: bogusaction ..."
#   karr skill check --agent bogus    -> exit 1, "Unknown agent: bogus ..."
#
# Neither is reachable by MooX::Options: the action is a positional and
# --agent's value is free-form, so App::karr::Role::ExitCodes' remap of
# option-parse failures never sees them. Both dies are therefore written with
# the leading "Usage:" marker bin/karr's central handler classifies on. When
# Role::ExitCodes gains a usage_error helper (the rest of #76), each becomes a
# one-line swap and this file keeps pinning the observable contract either way.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub run_karr {
    my (@argv) = @_;
    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh, $^X, "-I$ROOT/lib", $BIN, @argv );
    close $in;
    my $stdout = do { local $/; <$out_fh> };
    my $stderr = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    return {
        exit   => $? >> 8,
        stdout => $stdout // '',
        stderr => $stderr // '',
    };
}

subtest 'an unknown skill action is a usage error' => sub {
    my $rv = run_karr( 'skill', 'bogusaction' );
    is $rv->{exit}, 2, 'exits 2, not 1' or diag "stderr: $rv->{stderr}";
    like $rv->{stderr}, qr/^Usage: karr skill /m, 'stderr opens with the usage line';
    like $rv->{stderr}, qr/\QUnknown action: bogusaction\E/,
        'and names the action it rejected';
    unlike $rv->{stderr}, qr/ at \S+ line \d+/, 'no file:line suffix';
};

subtest 'an unknown --agent value is a usage error' => sub {
    my $rv = run_karr( 'skill', 'check', '--agent', 'bogusagent' );
    is $rv->{exit}, 2, 'exits 2, not 1' or diag "stderr: $rv->{stderr}";
    like $rv->{stderr}, qr/^Usage: karr skill --agent /m, 'stderr opens with the usage line';
    like $rv->{stderr}, qr/\QUnknown agent: bogusagent\E/, 'and names the agent it rejected';
    like $rv->{stderr}, qr/claude-code, codex, cursor/, 'and lists the known agents';
    unlike $rv->{stderr}, qr/ at \S+ line \d+/, 'no file:line suffix';

    # One bad name in a comma list rejects the whole list.
    my $mixed = run_karr( 'skill', 'check', '--agent', 'codex,bogusagent' );
    is $mixed->{exit}, 2, 'a bad name among good ones still exits 2';
};

subtest 'valid skill usage is unaffected' => sub {
    my $show = run_karr( 'skill', 'show' );
    is $show->{exit}, 0, 'karr skill show still exits 0' or diag $show->{stderr};

    my $check = run_karr( 'skill', 'check', '--agent', 'codex', '--json' );
    isnt $check->{exit}, 2, 'a valid --agent is not treated as a usage error'
        or diag "stderr: $check->{stderr}";
};

done_testing;
