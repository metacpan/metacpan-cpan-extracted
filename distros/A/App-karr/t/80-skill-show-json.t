use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );
use Encode qw( encode_utf8 decode FB_CROAK LEAVE_SRC );
use JSON::MaybeXS qw( decode_json );
use App::karr::Cmd::Skill;

# Ticket #79: `karr skill show --json` printed the raw skill Markdown, byte for
# byte identical to `karr skill show`, so the flag was ignored and the output
# was not JSON at all (probed pre-fix: `diff <(karr skill show) <(karr skill
# show --json)` empty, decode_json on it dies "malformed number ... before
# '---\nname: karr'"). Its siblings `skill check --json` and `skill install
# --json` were already correct, so only this one action was wrong.
#
# The second half of this file guards the character/octet boundary
# (App::karr::Encoding, tickets #53/#63). _skill_content hands back decoded
# characters and Role::Output::print_json is character-level too, so exactly
# one encode may happen between the share file and the terminal -- the
# :encoding(UTF-8) layer F<bin/karr> installs. See t/65-skill-show-utf8.t for
# the same property on the plain branch.
#
# Written with \x{} escapes so the expectation does not depend on the source
# encoding of this test file.
my $SKILL_TEXT = "# karr \x{2014} skill\n\nBl\x{00f6}cke \x{2026} \x{00fc}ml\x{00e4}ute\n";

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Captured with the layer F<bin/karr> installs
# (App::karr::Encoding::enable_std_utf8): reopening STDOUT drops it, so without
# restoring it the capture would not be the bytes a caller actually sees.
# $out therefore holds octets, exactly like t/51-json-output.t.
#
# Since the split into kanban-issues-karr-coordination and
# kanban-issues-karr-ticket, show prints one skill's SKILL.md when named and
# all of them otherwise, and --json is always an array of {skill, content}.
# The in-process runs name the ticket skill, the one planted below.
my $SKILL = 'kanban-issues-karr-ticket';

sub run_skill_show {
    my (@cmd_opts) = @_;
    # The #285 layout: the skill is a directory, and show prints its SKILL.md.
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = path($dir)->child("$SKILL/SKILL.md");
    $file->parent->mkpath;
    $file->spew_utf8($SKILL_TEXT);

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return $dir };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    open my $capture, '>:encoding(UTF-8)', \my $out
        or die "cannot open in-memory handle: $!";
    my $prev = select $capture;
    my $ok   = eval {
        App::karr::Cmd::Skill->new(@cmd_opts)->execute( [ 'show', $SKILL ], [] );
        1;
    };
    my $err = $@;
    select $prev;
    close $capture;
    die $err unless $ok;

    return ( $out, \@warnings );
}

subtest 'skill show --json emits JSON, not raw Markdown' => sub {
    my ( $out, $warnings ) = run_skill_show( json => 1 );

    unlike $out, qr/\A---\nname: karr/,
        'the payload no longer starts with the raw skill frontmatter';

    my $data = eval { decode_json($out) };
    ok !$@, 'the payload parses as JSON' or diag "decode_json said: $@\nraw: $out";
    is ref($data), 'ARRAY', 'it is a JSON array';
    is scalar(@{ $data || [] }), 1, 'with one entry for the one skill named';
    is ref( $data->[0] ), 'HASH', 'which is an object';
    is_deeply [ sort keys %{ $data->[0] || {} } ], [ 'content', 'skill' ],
        'with the keys "content" and "skill"';
    is $data->[0]{skill}, $SKILL, 'naming the skill it holds';
    is scalar(@$warnings), 0, 'no warnings emitted' or diag "@$warnings";
};

subtest 'the JSON payload carries the skill content, encoded exactly once' => sub {
    my ($json_out)  = run_skill_show( json => 1 );
    my ($plain_out) = run_skill_show();

    # decode_json is octet-level, and $json_out is what actually reached the
    # handle, so this asserts on the bytes rather than on an identity round
    # trip through the same codec that produced them (the #63 lesson).
    my $data = decode_json($json_out)->[0];

    is $data->{content}, $SKILL_TEXT,
        'the decoded content is the skill text, character for character';
    is encode_utf8( $data->{content} ), $plain_out,
        'and re-encoding it reproduces the plain-output bytes byte for byte';

    # The failure mode a second encode anywhere on the JSON path would produce:
    # bytes that are still valid UTF-8 but decode to the mojibake of the text.
    my $decoded_once = eval { decode( 'UTF-8', $json_out, FB_CROAK | LEAVE_SRC ) };
    ok defined $decoded_once, 'stdout decodes as UTF-8 exactly once';
    unlike $decoded_once, qr/\x{00e2}\x{0080}\x{0094}/,
        'the em dash did not survive as double-encoded bytes';
};

subtest 'plain skill show is unchanged by the --json branch' => sub {
    my ( $out, $warnings ) = run_skill_show();
    is $out, encode_utf8($SKILL_TEXT), 'stdout still carries singly-encoded UTF-8 bytes';
    my @wide = grep { /Wide character/ } @$warnings;
    is scalar(@wide), 0, 'still no "Wide character in print" warning'
        or diag "@$warnings";
};

subtest 'karr skill show --json through the real CLI' => sub {
    my @skills = App::karr::Cmd::Skill->_skill_names;
    my @missing = grep { !path($ROOT)->child("share/$_/SKILL.md")->exists } @skills;
    plan skip_all => "no share/@missing/SKILL.md in this checkout" if @missing;

    my $run = sub {
        my (@argv) = @_;
        my $err_fh = gensym;
        my $pid = open3( my $in, my $out_fh, $err_fh, $^X, "-I$ROOT/lib", $BIN, @argv );
        close $in;
        binmode $out_fh;
        my $stdout = do { local $/; <$out_fh> };
        my $stderr = do { local $/; <$err_fh> };
        waitpid( $pid, 0 );
        return { exit => $? >> 8, stdout => $stdout // '', stderr => $stderr // '' };
    };

    my $plain = $run->( 'skill', 'show' );
    my $json  = $run->( 'skill', 'show', '--json' );

    is $json->{exit}, 0, 'karr skill show --json exits 0' or diag $json->{stderr};
    isnt $json->{stdout}, $plain->{stdout},
        '--json output is no longer identical to the plain output';

    my $data = eval { decode_json( $json->{stdout} ) };
    ok !$@, 'the CLI payload parses as JSON'
        or diag "decode_json said: $@";
    is_deeply [ map { $_->{skill} } @{ $data || [] } ], \@skills,
        'one entry per bundled skill, in the order show prints them';
    is join( "\n", map { encode_utf8( $_->{content} ) } @{ $data || [] } ), $plain->{stdout},
        'their contents re-encode to exactly the bytes karr skill show prints';
    unlike $json->{stderr}, qr/Wide character/, 'no wide-character warning on the CLI path';

    for my $skill (@skills) {
        my $one_plain = $run->( 'skill', 'show', $skill );
        my $one_json  = $run->( 'skill', 'show', $skill, '--json' );
        is $one_json->{exit}, 0, "show $skill --json exits 0" or diag $one_json->{stderr};
        my $one = eval { decode_json( $one_json->{stdout} ) } || [];
        is scalar(@$one), 1, "show $skill --json holds one entry";
        is encode_utf8( $one->[0]{content} // '' ), $one_plain->{stdout},
            "and its content is what show $skill prints";
    }
};

subtest 'show with an unknown skill name is a usage error' => sub {
    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh, $^X, "-I$ROOT/lib", $BIN,
        'skill', 'show', 'kanban-issues-karr-cli' );
    close $in;
    my $stdout = do { local $/; <$out_fh> };
    my $stderr = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    is $? >> 8, 2, 'exit 2 (ADR 0002)';
    like $stderr, qr/Unknown skill: kanban-issues-karr-cli/, 'naming the rejected name';
    like $stderr, qr/kanban-issues-karr-ticket/, 'and the known ones';
    is $stdout // '', '', 'nothing on stdout';
};

done_testing;
