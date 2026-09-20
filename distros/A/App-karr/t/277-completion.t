use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestKarr ();

# Ticket #277: `karr completion bash|zsh|fish` -- a static shell completion
# script, built by App::karr::Cmd::Completion from the command table in
# App::karr (lib/App/karr.pm's @COMMANDS) and each command class's own
# MooX::Options declarations. "Static" is the point: the script must never
# invoke karr itself at completion time (Completion.pm's own DESCRIPTION).
#
# This file's own run_karr never chdirs (there is no repository to isolate --
# completion needs none, like `karr skill`; see t/84-skill-usage-exit.t), so
# '.' is passed as the cwd.

sub run_karr {
    my (@argv) = @_;
    return TestKarr::run_karr( '.', @argv );
}

# Comments are allowed to mention `karr completion bash` as prose --
# Completion.pm's own header does, backticks included -- but no line that is
# not a comment may shell out to karr live: a command substitution or backtick
# call would defeat the whole "never invokes karr at completion time" promise.
sub _never_calls_karr_live {
    my ($script) = @_;
    my $body = join "\n", grep { !/^\s*#/ } split /\n/, $script;
    return $body !~ /[\$`]\(?\s*karr\b/;
}

my %markers = (
    bash => [ qr/^_karr\(\) \{/m,   qr/^complete -F _karr karr$/m ],
    zsh  => [ qr/^#compdef karr$/m, qr/^compdef _karr karr$/m ],
    fish => [ qr/^complete -c karr -f$/m ],
);

for my $shell (qw( bash zsh fish )) {
    subtest "karr completion $shell" => sub {
        my $rv = run_karr( 'completion', $shell );
        is( $rv->{exit}, 0, 'exits 0' ) or diag $rv->{stderr};
        ok( length $rv->{stdout}, 'prints a non-empty script' );

        like( $rv->{stdout}, $_, "looks like a $shell completion script" )
            for @{ $markers{$shell} };

        ok( _never_calls_karr_live( $rv->{stdout} ),
            'never shells out to karr at completion time' );
    };
}

subtest 'bash, zsh and fish: at least one hyphenated option name' => sub {
    # The root's own options (App::karr::Role::Color's --no-color among them)
    # are embedded unconditionally, regardless of which subcommand a caller is
    # completing. bash and fish always did; zsh's _zsh_script now does too,
    # emitting them via _arguments in both root branches (CURRENT == 2 and the
    # no-subcommand-yet fallback) the same way bash and fish embed theirs. The
    # generated script is static text, so no zsh binary is needed to check it.
    for my $shell (qw( bash zsh fish )) {
        my $rv = run_karr( 'completion', $shell );
        like( $rv->{stdout}, qr/--no-color\b/,
            "$shell: names a hyphenated option (--no-color)" );
    }
};

subtest 'an unknown or missing shell is a usage error (exit 2)' => sub {
    my $missing = run_karr('completion');
    is( $missing->{exit}, 2, 'karr completion with no shell exits 2' )
        or diag $missing->{stderr};
    like( $missing->{stderr}, qr/^Usage: karr completion bash\|zsh\|fish$/m,
        'and says so' );

    my $unknown = run_karr( 'completion', 'powershell' );
    is( $unknown->{exit}, 2, 'karr completion powershell exits 2' )
        or diag $unknown->{stderr};
    like( $unknown->{stderr}, qr/^Usage error: unknown shell 'powershell'/m,
        'and names the unrecognised shell' );
};

subtest 'the generated script names the real commands and their options' => sub {
    # App::karr::Cmd::Completion::execute assigns _command_data's result to a
    # plain scalar before handing it to _bash_script/_zsh_script/_fish_script,
    # so _command_data has to return its list in LIST context -- its own last
    # statement is `return sort { ... } @out;`, and perlfunc is explicit that
    # sort()'s return value in scalar context is undefined (in practice,
    # undef). Calling it in scalar context silently empties every generated
    # script: no subcommand name and no subcommand's own options, in any of
    # the three shells. All three shells must also embed the root's own
    # options (see the hyphenated-option subtest above), zsh included.
    #
    # Extraction is deliberately narrow: each shell keeps its offered command
    # names in one recognisable construct, and only that construct is read
    # here -- a blanket /\bcreate\b/ over the whole script would "pass" on
    # nothing more than a doc string that happens to contain the word (fish's
    # own --done help text names "board"; bash's own comment names "list"),
    # which would mask a real regression behind an unrelated prose change.
    my %offered_commands = (
        bash => sub {
            my ($script) = @_;
            my ($list) = $script =~ /^\s*local commands="([^"]*)"/m;
            return defined $list ? split( ' ', $list ) : ();
        },
        zsh => sub {
            my ($script) = @_;
            my ($list) = $script =~ /^\s*names=\(\s*([^)]*)\)/m;
            return defined $list ? split( ' ', $list ) : ();
        },
        fish => sub {
            my ($script) = @_;
            return $script =~ /^complete -c karr -n '__fish_use_subcommand' -a '([^']+)'/mg;
        },
    );

    for my $shell (qw( bash zsh fish )) {
        my $rv = run_karr( 'completion', $shell );
        my @offered = $offered_commands{$shell}->( $rv->{stdout} );
        for my $cmd (qw( create list board show )) {
            ok( ( grep { $_ eq $cmd } @offered ), "$shell: offers the '$cmd' command" );
        }
    }
};

done_testing;
