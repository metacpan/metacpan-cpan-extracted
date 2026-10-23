use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);
use lib 'lib';

my $fixtures = File::Spec->catdir('t', 'fixtures');

# ── helpers ───────────────────────────────────────────────────────────────────

sub adapter_ok {
    my ($adapter) = @_;
    for my $method (qw(name tag tag_color find_sessions running launch delete_session load_messages)) {
        ok($adapter->can($method), ref($adapter) . "->can('$method')");
    }
    ok(length($adapter->name)      > 0, ref($adapter) . '->name is non-empty');
    ok(length($adapter->tag)       > 0, ref($adapter) . '->tag is non-empty');
    ok(length($adapter->tag_color) > 0, ref($adapter) . '->tag_color is non-empty');
    ok(length($adapter->tag) <= 5,      ref($adapter) . '->tag is <= 5 chars');
}

sub session_ok {
    my ($s, $label) = @_;
    for my $key (qw(id title date epoch cwd project _file _size _adapter)) {
        ok(exists $s->{$key}, "$label has key '$key'");
    }
    ok(length($s->{id})    > 0, "$label id is non-empty");
    ok(length($s->{title}) > 0, "$label title is non-empty");
    ok($s->{epoch} >= 0,        "$label epoch is non-negative");
    ok(-f $s->{_file},          "$label _file exists on disk");
}

# ── Claude ────────────────────────────────────────────────────────────────────

{
    require App::Saisons::Adapter::Claude;
    my $adapter = App::Saisons::Adapter::Claude->new;
    adapter_ok($adapter);

    local $ENV{HOME} = "$fixtures/claude";
    my @sessions = $adapter->find_sessions;
    ok(@sessions == 2, 'Claude: found 2 sessions');

    my ($s) = grep { $_->{id} eq 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' } @sessions;
    session_ok($s, 'Claude session');
    is($s->{id},    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'Claude: correct id');
    is($s->{title}, 'Fix the login bug',                    'Claude: aiTitle used as title');
    is($s->{cwd},   '/home/user/myproject',                 'Claude: correct cwd');
    like($s->{date}, qr/^2026-01-15/,                       'Claude: correct date');

    my @msgs = $adapter->load_messages($s);
    ok(@msgs >= 2,                   'Claude: loaded messages');
    is($msgs[0]{role}, 'user',       'Claude: first message is user');
    is($msgs[1]{role}, 'assistant',  'Claude: second message is assistant');
    like($msgs[0]{text}, qr/login/,  'Claude: user message text');
}

# ── Claude: _derive_path ─────────────────────────────────────────────────────

{
    # _derive_path is called when a session file has no "cwd" field.
    # It must not convert dashes within directory names to slashes.
    no warnings 'once';
    my $fn = \&App::Saisons::Adapter::Claude::_derive_path;
    # When cwd is absent, return the raw project dir name as fallback.
    # We cannot reliably reverse the encoding (dashes-as-separators vs dashes
    # in directory names are ambiguous), so don't try.
    is($fn->('-projects-claude-perl'),  '-projects-claude-perl',  '_derive_path: returns raw dir name (no mangling)');
    is($fn->('-projects-saisons'),      '-projects-saisons',      '_derive_path: returns raw dir name');
    isnt($fn->('-projects-claude-perl'), '/projects/claude/perl', '_derive_path: does NOT split on dashes');
}

# ── Claude: move_session ──────────────────────────────────────────────────────

{
    require App::Saisons::Adapter::Claude;
    my $adapter = App::Saisons::Adapter::Claude->new;

    my $tmp = tempdir(CLEANUP => 1);
    dircopy("$fixtures/claude/.claude", "$tmp/.claude");

    local $ENV{HOME} = $tmp;
    my @sessions = $adapter->find_sessions;
    my ($s) = grep { $_->{id} eq 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' } @sessions;

    my $old_file = $s->{_file};
    my $new_cwd  = '/home/user/newproject';
    mkdir "$tmp/.claude/projects/-home-user-newproject";

    my ($ok, $err) = $adapter->move_session($s, $new_cwd);
    ok($ok,           'Claude move_session: succeeded');
    ok(!-f $old_file, 'Claude move_session: old file removed');
    ok(-f $s->{_file},'Claude move_session: new file exists');
    is($s->{cwd}, $new_cwd, 'Claude move_session: cwd updated in session');

    open my $fh, '<', $s->{_file} or die;
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content,   qr|"cwd":"$new_cwd"|, 'Claude move_session: cwd rewritten in file');
    unlike($content, qr|"cwd":"/home/user/myproject"|, 'Claude move_session: old cwd not present');
}

# ── Codex ─────────────────────────────────────────────────────────────────────

{
    require App::Saisons::Adapter::Codex;
    my $adapter = App::Saisons::Adapter::Codex->new;
    adapter_ok($adapter);

    local $ENV{CODEX_HOME} = "$fixtures/codex";
    my @sessions = $adapter->find_sessions;
    ok(@sessions == 1, 'Codex: found 1 session');

    my $s = $sessions[0];
    session_ok($s, 'Codex session');
    is($s->{id},    'cccccccc-dddd-eeee-ffff-000000000000', 'Codex: correct id');
    is($s->{title}, 'Refactor the auth module',             'Codex: first user message as title');
    is($s->{cwd},   '/home/user/myproject',                 'Codex: correct cwd');
    like($s->{date}, qr/^2026-01-15/,                       'Codex: correct date from filename');

    my @msgs = $adapter->load_messages($s);
    ok(@msgs == 2,                        'Codex: loaded 2 messages');
    is($msgs[0]{role}, 'user',            'Codex: first message is user');
    is($msgs[1]{role}, 'assistant',       'Codex: second message is assistant');
    like($msgs[0]{text}, qr/auth module/, 'Codex: user message text');
}

# ── Aider ─────────────────────────────────────────────────────────────────────

{
    require App::Saisons::Adapter::Aider;
    my $adapter = App::Saisons::Adapter::Aider->new;
    adapter_ok($adapter);

    local $ENV{SAISONS_SEARCH_DIRS} = "$fixtures/aider";
    my @sessions = $adapter->find_sessions;
    ok(@sessions == 2, 'Aider: found 2 sessions');

    # Sessions come back sorted newest-first via the main script, but here
    # they're in file order — most recent header last in the file comes last
    my ($newer) = sort { $b->{epoch} <=> $a->{epoch} } @sessions;
    session_ok($newer, 'Aider session');
    is($newer->{title}, 'Add dark mode support', 'Aider: first user message as title');
    like($newer->{cwd}, qr/myproject/,            'Aider: cwd derived from file path');
    like($newer->{date}, qr/^2026-01-15/,         'Aider: correct date');

    my @msgs = $adapter->load_messages($newer);
    ok(@msgs >= 1,                          'Aider: loaded messages');
    is($msgs[0]{role}, 'user',              'Aider: first message is user');
    like($msgs[0]{text}, qr/dark mode/,     'Aider: user message text');
}

# ── Gemini ────────────────────────────────────────────────────────────────────

{
    require App::Saisons::Adapter::Gemini;
    my $adapter = App::Saisons::Adapter::Gemini->new;
    adapter_ok($adapter);

    local $ENV{HOME} = "$fixtures/gemini";
    my @sessions = $adapter->find_sessions;
    ok(@sessions == 1, 'Gemini: found 1 session');

    my $s = $sessions[0];
    session_ok($s, 'Gemini session');
    is($s->{id},    'abcd1234-ef56-7890-abcd-ef1234567890', 'Gemini: correct id');
    is($s->{title}, 'Review Kubernetes manifests',          'Gemini: summary used as title');
    is($s->{cwd},   '/home/user/myproject',                 'Gemini: cwd from directories');
    like($s->{date}, qr/^2026-01-15/,                       'Gemini: correct date');

    my @msgs = $adapter->load_messages($s);
    ok(@msgs == 2,                          'Gemini: loaded 2 messages');
    is($msgs[0]{role}, 'user',              'Gemini: first message is user');
    is($msgs[1]{role}, 'assistant',         'Gemini: second message is assistant');
    like($msgs[0]{text}, qr/k8s/,           'Gemini: user message text');
}

# ── opencode ──────────────────────────────────────────────────────────────────

subtest 'opencode' => sub {
    require App::Saisons::Adapter::Opencode;
    my $adapter = App::Saisons::Adapter::Opencode->new;
    adapter_ok($adapter);

    plan skip_all => 'sqlite3 CLI not available'
        unless App::Saisons::Adapter::Opencode::_sqlite3();

    # Build a fixture DB mirroring opencode's storage layout
    my $tmp  = tempdir(CLEANUP => 1);
    my $data = "$tmp/.local/share";
    make_path("$data/opencode");
    my $db = "$data/opencode/opencode.db";

    my $sql = <<'SQL';
CREATE TABLE session (
    id text PRIMARY KEY,
    directory text NOT NULL,
    title text NOT NULL,
    time_created integer NOT NULL,
    time_updated integer NOT NULL,
    time_archived integer
);
CREATE TABLE message (
    id text PRIMARY KEY,
    session_id text NOT NULL,
    time_created integer NOT NULL,
    data text NOT NULL
);
CREATE TABLE part (
    id text PRIMARY KEY,
    message_id text NOT NULL,
    session_id text NOT NULL,
    time_created integer NOT NULL,
    data text NOT NULL
);
INSERT INTO session VALUES ('ses_live0000000000001','/home/user/myproject','Add opentelemetry tracing',1768474200000,1768474800000,NULL);
INSERT INTO session VALUES ('ses_arch0000000000001','/home/user/myproject','Archived session',1768470000000,1768470100000,1768470200000);
INSERT INTO message VALUES ('msg_u1','ses_live0000000000001',1768474201000,'{"role":"user"}');
INSERT INTO part VALUES ('part_u1a','msg_u1','ses_live0000000000001',1768474201100,'{"type":"text","text":"Please add opentelemetry tracing to the API"}');
INSERT INTO message VALUES ('msg_a1','ses_live0000000000001',1768474202000,'{"role":"assistant"}');
INSERT INTO part VALUES ('part_a1r','msg_a1','ses_live0000000000001',1768474202100,'{"type":"reasoning","text":"thinking..."}');
INSERT INTO part VALUES ('part_a1t','msg_a1','ses_live0000000000001',1768474202200,'{"type":"text","text":"Done, tracing is wired up."}');
SQL
    my $exe = App::Saisons::Adapter::Opencode::_sqlite3();
    ok(system($exe, $db, $sql) == 0, 'opencode: built fixture DB');

    local $ENV{HOME}          = $tmp;
    local $ENV{XDG_DATA_HOME} = $data;

    my @sessions = $adapter->find_sessions;
    ok(@sessions == 1, 'opencode: found 1 live session (archived skipped)');

    my $s = $sessions[0];
    session_ok($s, 'opencode session');
    is($s->{id},     'ses_live0000000000001',     'opencode: correct id');
    is($s->{title},  'Add opentelemetry tracing', 'opencode: title from session row');
    is($s->{cwd},    '/home/user/myproject',      'opencode: correct cwd');
    like($s->{date}, qr/^2026-01-15/,             'opencode: correct date');
    is($s->{epoch},  1768474800,                  'opencode: epoch derived from ms timestamp');
    cmp_ok($s->{_size}, '>', 0,                   'opencode: size from message+part bytes');

    # XDG_DATA_HOME unset → falls back to $HOME/.local/share
    {
        local $ENV{XDG_DATA_HOME} = undef;
        my @fallback = $adapter->find_sessions;
        ok(@fallback == 1, 'opencode: HOME fallback finds sessions without XDG_DATA_HOME');
    }

    my @msgs = $adapter->load_messages($s);
    ok(@msgs == 2,                            'opencode: loaded 2 messages (reasoning skipped)');
    is($msgs[0]{role}, 'user',                'opencode: first message is user');
    is($msgs[1]{role}, 'assistant',           'opencode: second message is assistant');
    like($msgs[0]{text}, qr/opentelemetry/,   'opencode: user message text');
    like($msgs[1]{text}, qr/wired up/,        'opencode: assistant message text');

    ok($adapter->delete_session($s),          'opencode: delete_session succeeded');
    ok(!scalar $adapter->find_sessions,       'opencode: no sessions after delete');

    # Default opencode titles are derived from the first user text part
    my $extra = <<'SQL';
INSERT INTO session VALUES ('ses_defa0000000000001','/home/user/myproject','New session - 2026-01-15T10:00:00.000Z',1768475000000,1768475100000,NULL);
INSERT INTO message VALUES ('msg_du1','ses_defa0000000000001',1768475001000,'{"role":"user"}');
INSERT INTO part VALUES ('part_du1a','msg_du1','ses_defa0000000000001',1768475001100,'{"type":"text","text":"  Who moved my cheese?\n\nreally  "}');
SQL
    ok(system($exe, $db, $extra) == 0, 'opencode: built default-title fixture');
    my @derived = $adapter->find_sessions;
    ok(@derived == 1, 'opencode: found derived-title session');
    is($derived[0]{title}, 'Who moved my cheese? really', 'opencode: default title derived from first user message');

    my $blank = <<'SQL';
INSERT INTO session VALUES ('ses_empt0000000000001','/home/user/myproject','New session - 2026-01-15T11:00:00.000Z',1768475200000,1768475300000,NULL);
SQL
    ok(system($exe, $db, $blank) == 0, 'opencode: built no-text fixture');
    my ($empty) = grep { $_->{id} eq 'ses_empt0000000000001' } $adapter->find_sessions;
    is($empty->{title}, '(no title)', 'opencode: default title without user text falls back to (no title)');
};

done_testing;
