#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::More;

use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use BriefingTest qw( repo_root run_cli sandbox write_file );
use JSON::MaybeXS qw( encode_json );
use Path::Tiny qw( path );

# briefing doctor --tsv: one row per finding, WHAT<TAB>ok|missing|warn<TAB>NAME<TAB>TEXT.

my $TAB = "\t";

sub briefing_script {
  return path( repo_root(), 'script', 'briefing' )->stringify;
}

sub briefing_argv {
  return (
    $^X,
    '-I'.path(repo_root(), 'lib')->stringify,
    briefing_script(),
    @_,
  );
}

sub agent_text {
  my ( $name, %o ) = @_;
  my @skills = $o{skills} ? @{ $o{skills} } : ('harbor-core');
  my $description = exists $o{description} ? $o{description} : 'Does the work.';
  my $text = "---\nname: $name\n";
  $text .= "description: $description\n" if defined $description;
  $text .= $o{extra} if defined $o{extra};
  if (!$o{no_briefing}) {
    $text .= "briefing:\n";
    $text .= $o{briefing} if defined $o{briefing};
    $text .= "  skills:\n".join( '', map { "    - $_\n" } @skills )
      unless defined $o{briefing};
  }
  return $text."---\n\nYou are $name.\n";
}

sub put_agent {
  my ( $box, $file, $text ) = @_;
  return write_file( path( $box->{cwd}, '.claude', 'agents', $file ), $text );
}

sub good_settings {
  return encode_json({
    enabledPlugins         => {
      'briefing@getty'                => JSON::MaybeXS::true,
      'demo@claude-plugins-official'  => JSON::MaybeXS::true,
    },
    extraKnownMarketplaces => { getty => { source => { source => 'github', repo => 'Getty/m' } } },
  });
}

sub put_settings {
  my ( $box, $json ) = @_;
  $json = good_settings() unless defined $json;
  return write_file( path( $box->{cwd}, '.claude', 'settings.json' ), $json );
}

# A good team: two agents, one declared skill, settings in order.
sub team {
  my $box = sandbox();
  put_agent( $box, 'harbor-worker.md',   agent_text('harbor-worker') );
  put_agent( $box, 'harbor-reviewer.md', agent_text('harbor-reviewer') );
  write_file(
    path( $box->{cwd}, '.claude', 'skills', 'harbor-core', 'SKILL.md' ),
    "---\nname: harbor-core\n---\nCORE\n",
  );
  put_settings($box);
  return $box;
}

sub tsv {
  my ( $box, @extra ) = @_;
  my $result = run_cli(
    sandbox => $box,
    argv    => [ briefing_argv( 'doctor', '--tsv', '--cwd', $box->{cwd}, @extra ) ],
  );
  $result->{rows} = [ map { [ split /\t/, $_, -1 ] } split /\n/, $result->{stdout} ];
  return $result;
}

sub rows_of {
  my ( $result, $what, $status, $name ) = @_;
  return [ grep {
    $_->[0] eq $what
      && ( !defined $status || $_->[1] eq $status )
      && ( !defined $name   || $_->[2] eq $name )
  } @{ $result->{rows} } ];
}

sub one_row {
  my ( $result, $what, $status, $name ) = @_;
  my $hits = rows_of( $result, $what, $status, $name );
  is( scalar @{$hits}, 1, join( ' ', grep { defined } 'one', $what, $status, $name, 'row' ) )
    or diag $result->{stdout};
  return $hits->[0] || [];
}

# --- the good team: every row, exactly -------------------------------------

{
  my $box = team();
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'good team: exit 0' );
  is( $r->{stderr}, '', 'good team: quiet stderr' );
  is_deeply(
    $r->{rows},
    [
      [ 'agent',    'ok', 'harbor-reviewer.md',   '' ],
      [ 'agent',    'ok', 'harbor-worker.md',     '' ],
      [ 'skill',    'ok', 'harbor-core',          '' ],
      [ 'settings', 'ok', '.claude/settings.json', '' ],
      [ 'hook',     'ok', 'harbor-worker',        '' ],
    ],
    'good team: one ok row per finding, in the contract order',
  );
  my @lines = split /\n/, $r->{stdout};
  ok( ( !grep { !/\t\z/ } grep { /\tok\t/ } @lines ),
    'an empty last field keeps its tab' );
  is( $lines[0], join( $TAB, 'agent', 'ok', 'harbor-reviewer.md', '' ),
    'raw first line is four tab-separated fields ending in a tab' );
  like( $r->{stdout}, qr/\n\z/, 'every row ends in a newline' );
  is( ( scalar grep { @{$_} != 4 } @{ $r->{rows} } ), 0, 'every row has exactly four fields' );

  # Reading changes nothing.
  my @before = sort map { $_->stringify } path( $box->{cwd} )->children( qr// );
  tsv($box);
  my @after = sort map { $_->stringify } path( $box->{cwd} )->children( qr// );
  is_deeply( \@after, \@before, 'doctor --tsv writes nothing into the project' );
}

# --- exit codes and row kinds -----------------------------------------------

{
  # exit 0 with warn rows only.
  my $box = team();
  put_agent( $box, 'harbor-plain.md', agent_text( 'harbor-plain', no_briefing => 1 ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'warn rows alone keep exit 0' );
  is_deeply( one_row( $r, 'agent', 'warn', 'harbor-plain.md' ),
    [ 'agent', 'warn', 'harbor-plain.md', 'no briefing' ], 'no briefing is a warn row' );
}

{
  # exit 1 with a missing row, and the missing row is the only reason.
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['harbor-gone'] ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'a missing row makes exit 1' );
  my $skill = one_row( $r, 'skill', 'missing', 'harbor-gone' );
  like( $skill->[3], qr/\Aharbor-worker\.md declares it; .*briefing would refuse the spawn\z/,
    'skill row names the declaring agent and the consequence' );
  my $hook = one_row( $r, 'hook', 'missing', 'harbor-worker' );
  like( $hook->[3], qr/harbor-gone/, 'hook row carries the hook reason naming the skill' );
  is( scalar @{ rows_of( $r, 'agent', 'missing' ) }, 0, 'the agent file itself is fine' );
  one_row( $r, 'skill', 'ok', 'harbor-core' ) if 0;
}

{
  # exit 2: usage errors; nothing on stdout.
  my $box = team();
  my $nodir = run_cli(
    sandbox => $box,
    argv    => [ briefing_argv( 'doctor', '--tsv', '--cwd', path( $box->{root}, 'nowhere' )->stringify ) ],
  );
  is( $nodir->{exit_code}, 2, 'a --cwd that is no directory exits 2' );
  is( $nodir->{stdout}, '', 'no rows on a usage error' );
  like( $nodir->{stderr}, qr/not a directory/, 'the reason goes to stderr' );

  my $codex = tsv( $box, '--harness', 'codex' );
  is( $codex->{exit_code}, 2, '--tsv with --harness codex exits 2' );
  is( $codex->{stdout}, '', 'no rows for --harness codex' );
  like( $codex->{stderr}, qr/Claude Code team only/, 'the codex refusal says why' );

  is( tsv( $box, '--harness', 'claude' )->{exit_code}, 0, '--tsv with --harness claude works' );
  is( tsv( $box, '--harness', 'both' )->{exit_code}, 0, '--tsv with --harness both works' );

  my $bogus = tsv( $box, '--bogus' );
  is( $bogus->{exit_code}, 2, 'an unknown option exits 2' );
  is( $bogus->{stdout}, '', 'no rows for an unknown option' );

  my $novalue = run_cli(
    sandbox => $box,
    argv    => [ briefing_argv( 'doctor', '--tsv', '--cwd' ) ],
  );
  is( $novalue->{exit_code}, 2, '--cwd without a value exits 2' );
}

{
  # --cwd decides the project, not the process directory; the default is the process directory.
  my $box = team();
  my $other = sandbox();
  my $r = run_cli(
    sandbox => $other,
    argv    => [ briefing_argv( 'doctor', '--tsv', '--cwd', $box->{cwd} ) ],
  );
  is( $r->{exit_code}, 0, '--cwd reads the named project' );
  like( $r->{stdout}, qr/^agent\tok\tharbor-worker\.md\t$/m, '--cwd rows come from the named project' );

  my $default = run_cli( sandbox => $box, argv => [ briefing_argv( 'doctor', '--tsv' ) ] );
  is( $default->{exit_code}, 0, 'without --cwd the process directory is the project' );
  like( $default->{stdout}, qr/^agent\tok\tharbor-worker\.md\t$/m, 'default directory is read' );
}

# --- agents -----------------------------------------------------------------

{
  my $box = sandbox();
  put_settings($box);
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'no agent files: exit 1' );
  is_deeply( one_row( $r, 'agent', 'missing', '.claude/agents' ),
    [ 'agent', 'missing', '.claude/agents', 'no agent files' ], 'no agent files row' );
  is( scalar @{ rows_of( $r, 'hook' ) }, 0, 'no hook row without agents' );
}

{
  my $box = team();
  put_agent( $box, 'README.md', "How the agents work.\n" );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'a file without frontmatter only warns' );
  is_deeply( one_row( $r, 'agent', 'warn', 'README.md' ),
    [ 'agent', 'warn', 'README.md', 'no frontmatter (Claude Code does not load it)' ],
    'no frontmatter row' );
  my $plain = tsv( team() );
  is_deeply( [ grep { $_->[2] ne 'README.md' } @{ $r->{rows} } ], $plain->{rows},
    'the README adds exactly one row and no skill or hook row' );
}

{
  my $box = team();
  put_agent( $box, 'notes.txt', "---\nname: x\n---\n" );
  put_agent( $box, 'sub/harbor-deep.md', agent_text('harbor-deep') );
  my $r = tsv($box);
  is( scalar @{ rows_of( $r, 'agent', undef, 'notes.txt' ) }, 0, 'non-markdown files are ignored' );
  one_row( $r, 'agent', 'ok', 'sub/harbor-deep.md' );
}

{
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-other' ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'name differing from the file: exit 1' );
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', "name 'harbor-other' differs from the file name" ],
    'name mismatch row' );
}

{
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    "---\ndescription: x\nbriefing:\n  skills:\n    - harbor-core\n---\n" );
  my $r = tsv($box);
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', 'no name' ], 'missing name row' );
}

{
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', description => '' ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'empty description: exit 1' );
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', 'description is empty' ], 'empty description row' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', description => undef ) );
  is_deeply( one_row( tsv($box), 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', 'description is empty' ],
    'an absent description is empty too' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', description => '""' ) );
  one_row( tsv($box), 'agent', 'missing', 'harbor-worker.md' );
}

{
  # a folded or literal description is text, however many lines it spans.
  for my $marker ( '>', '|', '>-' ) {
    my $box = team();
    put_agent( $box, 'harbor-worker.md',
      "---\nname: harbor-worker\ndescription: $marker\n  Does the\n  work.\n"
      ."briefing:\n  skills:\n    - harbor-core\n---\nbody\n" );
    my $r = tsv($box);
    is( $r->{exit_code}, 0, "folded description ($marker) counts as text" );
    one_row( $r, 'agent', 'ok', 'harbor-worker.md' );
  }
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    "---\nname: harbor-worker\ndescription: >\nbriefing:\n  skills:\n    - harbor-core\n---\nbody\n" );
  is_deeply( one_row( tsv($box), 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', 'description is empty' ],
    'a folded marker without any text is still empty' );
}

{
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    agent_text( 'harbor-worker', extra => "allowed-tools: Read\n" ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'allowed-tools: exit 1' );
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md', 'allowed-tools: ignored by Claude Code; use disallowedTools' ],
    'allowed-tools row' );

  # in the body it is no finding
  put_agent( $box, 'harbor-worker.md',
    agent_text('harbor-worker') );
  my $text = path( $box->{cwd}, '.claude', 'agents', 'harbor-worker.md' )->slurp_utf8;
  path( $box->{cwd}, '.claude', 'agents', 'harbor-worker.md' )
    ->spew_utf8( $text."\nallowed-tools: Read\nskills: x\n" );
  is( tsv($box)->{exit_code}, 0, 'allowed-tools and skills in the body are no findings' );
}

{
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    agent_text( 'harbor-worker', extra => "skills:\n  - harbor-core\n" ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'top-level skills only warns' );
  is_deeply( one_row( $r, 'agent', 'warn', 'harbor-worker.md' ),
    [ 'agent', 'warn', 'harbor-worker.md', 'skills: briefing reads only briefing.skills' ],
    'top-level skills row' );

  # and is not read as the briefing declaration
  put_agent( $box, 'harbor-worker.md',
    "---\nname: harbor-worker\ndescription: x\nskills:\n  - harbor-gone\n---\n" );
  $r = tsv($box);
  is( scalar @{ rows_of( $r, 'skill', undef, 'harbor-gone' ) }, 0,
    'top-level skills are not resolved as briefing skills' );
  one_row( $r, 'agent', 'warn', 'harbor-worker.md' ) if 0;
  ok( ( scalar grep { $_->[3] eq 'no briefing' } @{ rows_of( $r, 'agent', 'warn', 'harbor-worker.md' ) } ),
    'and the agent has no briefing' );
}

{
  # unclosed flow list
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    "---\nname: harbor-worker\ndescription: x\nbriefing:\n  skills: [harbor-core,\n    harbor-extra]\n---\n" );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'unclosed flow list: exit 1' );
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-worker.md' ),
    [ 'agent', 'missing', 'harbor-worker.md',
      'briefing.skills is not readable (keep the list on one line or use one "- name" per line)' ],
    'unclosed flow list row' );
  is( scalar @{ rows_of( $r, 'agent', 'warn' ) }, 0, 'no extra no-briefing warn for the unreadable list' );

  # a closed one-line list reads fine
  put_agent( $box, 'harbor-worker.md',
    agent_text( 'harbor-worker', briefing => "  skills: [harbor-core, \"harbor-extra\"]\n" ) );
  $r = tsv($box);
  one_row( $r, 'agent', 'ok', 'harbor-worker.md' );
  one_row( $r, 'skill', 'ok', 'harbor-core' );
  one_row( $r, 'skill', 'missing', 'harbor-extra' );
}

{
  # BOM before the frontmatter: Claude Code loads the agent, so the briefing must read it too
  my $box = team();
  put_agent( $box, 'harbor-worker.md', "\x{FEFF}".agent_text('harbor-worker') );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'a BOM before the frontmatter is fine' );
  one_row( $r, 'agent', 'ok', 'harbor-worker.md' );
  one_row( $r, 'skill', 'ok', 'harbor-core' );
  one_row( $r, 'hook', 'ok', 'harbor-worker' );
  my $spawn = hook( $box, { hook_event_name => 'SubagentStart', agent_type => 'harbor-worker', cwd => $box->{cwd} } );
  like( $spawn->{stdout}, qr/CORE/, 'the real hook briefs an agent file that starts with a BOM' );

  # CRLF

  ( my $crlf = agent_text('harbor-worker') ) =~ s/\n/\r\n/g;
  path( $box->{cwd}, '.claude', 'agents', 'harbor-worker.md' )->spew_raw($crlf);
  $r = tsv($box);
  is( $r->{exit_code}, 0, 'CRLF files read the same' );
  one_row( $r, 'agent', 'ok', 'harbor-worker.md' );
  one_row( $r, 'skill', 'ok', 'harbor-core' );
  ok( $r->{stdout} !~ /\r/, 'no carriage return leaks into the rows' );
}

{
  # quoted name
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    "---\nname: \"harbor-worker\"\ndescription: 'x'\nbriefing:\n  skills:\n    - harbor-core\n---\n" );
  one_row( tsv($box), 'agent', 'ok', 'harbor-worker.md' );
}

{
  # .local. prefix is stripped from the file name only
  my $box = team();
  put_agent( $box, '.local.harbor-checker.md', agent_text('harbor-checker') );
  put_agent( $box, 'harbor-api.local.md',      agent_text('harbor-api.local') );
  put_agent( $box, 'harbor-bad.local.md',      agent_text('harbor-bad') );
  my $r = tsv($box);
  one_row( $r, 'agent', 'ok',      '.local.harbor-checker.md' );
  one_row( $r, 'agent', 'ok',      'harbor-api.local.md' );
  is_deeply( one_row( $r, 'agent', 'missing', 'harbor-bad.local.md' ),
    [ 'agent', 'missing', 'harbor-bad.local.md', "name 'harbor-bad' differs from the file name" ],
    'only a leading .local. is stripped from the file name' );

  put_agent( $box, '.local.harbor-checker.md', agent_text('.local.harbor-checker') );
  one_row( tsv($box), 'agent', 'missing', '.local.harbor-checker.md' );
}

SKIP: {
  # dangling symlink
  my $box = team();
  my $link = path( $box->{cwd}, '.claude', 'agents', 'harbor-gone.md' )->stringify;
  skip 'Windows doctor does not detect dangling symlinks yet (k9)', 5
    if $^O eq 'MSWin32';
  skip 'no symlinks here', 5
    unless eval { symlink( path( $box->{root}, 'nowhere.md' )->stringify, $link ) };
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'a dangling symlink only warns' );
  is_deeply( one_row( $r, 'agent', 'warn', 'harbor-gone.md' ),
    [ 'agent', 'warn', 'harbor-gone.md', 'dangling symlink (Claude Code cannot load it)' ],
    'dangling symlink row' );
  is( scalar @{ rows_of( $r, 'hook', undef, 'harbor-gone' ) }, 0, 'no hook row for the dangling link' );
  is( scalar @{ rows_of( $r, 'agent', 'missing' ) }, 0, 'and no missing agent row' );
  unlike( join( '', map { $_->[2] eq 'harbor-gone.md' ? '' : join( $TAB, @{$_} ) } @{ $r->{rows} } ),
    qr/harbor-gone/, 'harbor-gone appears in no other row' );

  # a live symlink is an agent
  my $target = write_file( path( $box->{root}, 'shared', 'harbor-linked.md' ), agent_text('harbor-linked') );
  symlink( $target, path( $box->{cwd}, '.claude', 'agents', 'harbor-linked.md' )->stringify );
  one_row( tsv($box), 'agent', 'ok', 'harbor-linked.md' );
}

# --- skills -----------------------------------------------------------------

{
  # the same missing skill in two agents gives two rows
  my $box = team();
  put_agent( $box, 'harbor-worker.md',   agent_text( 'harbor-worker',   skills => ['harbor-gone'] ) );
  put_agent( $box, 'harbor-reviewer.md', agent_text( 'harbor-reviewer', skills => ['harbor-gone'] ) );
  my $r = tsv($box);
  my $rows = rows_of( $r, 'skill', 'missing', 'harbor-gone' );
  is( scalar @{$rows}, 2, 'a skill missing in two agents gives two rows' );
  like( $rows->[0][3], qr/\Aharbor-reviewer\.md declares it/, 'first row names the first agent' );
  like( $rows->[1][3], qr/\Aharbor-worker\.md declares it/,   'second row names the second agent' );

  # a skill declared by two agents and found: one ok row
  my $good = team();
  is( scalar @{ rows_of( tsv($good), 'skill', 'ok', 'harbor-core' ) }, 1,
    'a found skill declared twice gives one ok row' );
}

{
  # skill resolution: home skills, glob characters
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['home-skill'] ) );
  write_file( path( $box->{home}, '.claude', 'skills', 'home-skill', 'SKILL.md' ), "H\n" );
  one_row( tsv($box), 'skill', 'ok', 'home-skill' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['harbor-*'] ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 1, 'a glob-character skill name is missing' );
  like( one_row( $r, 'skill', 'missing', 'harbor-*' )->[3], qr/not a usable skill name/,
    'glob name gets the not-usable reason' );
}

sub install_plugin {
  my ( $box, $plugin, $skill, %o ) = @_;
  my $market  = $o{market} || 'getty';
  my $enabled = exists $o{enabled} ? $o{enabled} : JSON::MaybeXS::true;
  my $root = path( $box->{home}, '.claude', 'plugins', 'cache', $market, $plugin, '1.0.0' )->stringify;
  write_file( path( $root, 'skills', $skill, 'SKILL.md' ), "PLUGIN\n" ) if defined $skill;
  write_file(
    path( $box->{home}, '.claude', 'plugins', 'installed_plugins.json' ),
    encode_json({ version => 2, plugins => { "$plugin\@$market" => [ { scope => 'user', installPath => $root } ] } }),
  );
  write_file(
    path( $box->{home}, '.claude', 'settings.json' ),
    encode_json({ enabledPlugins => { "$plugin\@$market" => $enabled } }),
  );
  return;
}

{
  # plugin:skill
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => [ 'kit:deploy', 'harbor-core' ] ) );
  install_plugin( $box, 'kit', 'deploy' );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'plugin:skill of an installed, enabled plugin resolves' );
  one_row( $r, 'skill', 'ok', 'kit:deploy' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['other:deploy'] ) );
  $r = tsv($box);
  is( $r->{exit_code}, 1, 'plugin:skill of another plugin is missing' );
  like( one_row( $r, 'skill', 'missing', 'other:deploy' )->[3],
    qr/plugin 'other' is not installed and enabled/, 'unknown plugin reason' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['kit:nothing'] ) );
  like( one_row( tsv($box), 'skill', 'missing', 'kit:nothing' )->[3],
    qr/plugin 'kit' has no skill 'nothing'/, 'plugin without the skill reason' );

  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['deploy'] ) );
  one_row( tsv($box), 'skill', 'ok', 'deploy' );   # a bare name is found in an enabled plugin

  install_plugin( $box, 'kit', 'deploy', enabled => JSON::MaybeXS::false );
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['kit:deploy'] ) );
  $r = tsv($box);
  is( $r->{exit_code}, 1, 'a disabled plugin does not resolve' );
  one_row( $r, 'skill', 'missing', 'kit:deploy' );

  install_plugin( $box, 'kit', 'deploy', enabled => 'true' );
  is( tsv($box)->{exit_code}, 1, 'a string "true" does not enable a plugin' );
}

# --- hook rows --------------------------------------------------------------

{
  # the first worker is briefed; others only report a denial
  my $box = team();
  put_agent( $box, 'harbor-aaa.md', agent_text('harbor-aaa') );
  my $r = tsv($box);
  is_deeply( $r->{rows} && rows_of( $r, 'hook' ), [ [ 'hook', 'ok', 'harbor-worker', '' ] ],
    'the hook row goes to the first agent named -worker, not the first one' );

  my $solo = sandbox();
  put_settings($solo);
  put_agent( $solo, 'harbor-zeta.md', agent_text('harbor-zeta') );
  put_agent( $solo, 'harbor-alpha.md', agent_text('harbor-alpha') );
  write_file( path( $solo->{cwd}, '.claude', 'skills', 'harbor-core', 'SKILL.md' ), "C\n" );
  is_deeply( rows_of( tsv($solo), 'hook' ), [ [ 'hook', 'ok', 'harbor-alpha', '' ] ],
    'without a worker the first agent is checked' );
}

{
  # a denial is reported for every agent, a second reason per agent
  my $box = team();
  put_agent( $box, 'harbor-worker.md',   agent_text( 'harbor-worker',   skills => ['harbor-gone'] ) );
  put_agent( $box, 'harbor-reviewer.md', agent_text( 'harbor-reviewer', skills => ['harbor-gone'] ) );
  my $r = tsv($box);
  is( scalar @{ rows_of( $r, 'hook', 'missing' ) }, 2, 'the hook denial is reported for each agent' );
}

{
  # a skill that exists but the agent briefs nothing: warn
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', no_briefing => 1 ) );
  put_agent( $box, 'harbor-reviewer.md', agent_text( 'harbor-reviewer', no_briefing => 1 ) );
  my $r = tsv($box);
  is( $r->{exit_code}, 0, 'agents without a briefing do not fail the check' );
  is_deeply( one_row( $r, 'hook', 'warn', 'harbor-worker' ),
    [ 'hook', 'warn', 'harbor-worker', 'the hook briefs nothing for this agent' ],
    'a worker without a briefing: hook warn row' );
}

# --- settings ---------------------------------------------------------------

sub settings_row {
  my ( $json ) = @_;
  my $box = team();
  if (defined $json) { put_settings( $box, $json ) }
  else { path( $box->{cwd}, '.claude', 'settings.json' )->remove }
  return tsv($box);
}

{
  my $r = settings_row(undef);
  is( $r->{exit_code}, 1, 'settings file missing: exit 1' );
  is_deeply( one_row( $r, 'settings', 'missing', '.claude/settings.json' ),
    [ 'settings', 'missing', '.claude/settings.json', 'not found or not readable' ], 'missing settings row' );

  $r = settings_row("not json at all\n");
  is( $r->{exit_code}, 1, 'settings not JSON: exit 1' );
  like( one_row( $r, 'settings', 'missing', '.claude/settings.json' )->[3], qr/not a valid JSON object/,
    'invalid settings row' );
  is( scalar @{ rows_of( $r, 'settings', 'ok' ) }, 0, 'invalid settings are never ok' );

  $r = settings_row('[1,2]');
  like( one_row( $r, 'settings', 'missing', '.claude/settings.json' )->[3], qr/not a valid JSON object/,
    'a JSON array is not a settings object' );

  # undeclared marketplace
  $r = settings_row( encode_json({
    enabledPlugins         => { 'briefing@getty' => JSON::MaybeXS::true, 'tool@elsewhere' => JSON::MaybeXS::true },
    extraKnownMarketplaces => { getty => {} },
  }) );
  is( $r->{exit_code}, 1, 'undeclared marketplace: exit 1' );
  is_deeply( one_row( $r, 'settings', 'missing', 'tool@elsewhere' ),
    [ 'settings', 'missing', 'tool@elsewhere', "marketplace 'elsewhere' is not in extraKnownMarketplaces" ],
    'undeclared marketplace row' );
  is( scalar @{ rows_of( $r, 'settings', 'ok' ) }, 0, 'no ok row next to a missing one' );

  # official marketplace needs no declaration (the good settings already use it)
  is( tsv( team() )->{exit_code}, 0, 'claude-plugins-official needs no declaration' );

  # briefing not enabled
  $r = settings_row( encode_json({ enabledPlugins => { 'skilletor@getty' => JSON::MaybeXS::true },
    extraKnownMarketplaces => { getty => {} } }) );
  is_deeply( one_row( $r, 'settings', 'missing', 'briefing' ),
    [ 'settings', 'missing', 'briefing', 'the briefing plugin is not enabled in enabledPlugins' ],
    'briefing not enabled row' );

  # false is not enabled
  $r = settings_row( encode_json({ enabledPlugins => { 'briefing@getty' => JSON::MaybeXS::false },
    extraKnownMarketplaces => { getty => {} } }) );
  is( $r->{exit_code}, 1, 'briefing set to false is not enabled' );
  one_row( $r, 'settings', 'missing', 'briefing' );

  # only a literal true counts
  for my $value ( '"true"', '1', '"yes"', 'null', '{}' ) {
    $r = settings_row( qq({"enabledPlugins": {"briefing\@getty": $value}, "extraKnownMarketplaces": {"getty": {}}}) );
    is( $r->{exit_code}, 1, "enabledPlugins value $value does not enable briefing" );
    one_row( $r, 'settings', 'missing', 'briefing' );
  }
  $r = settings_row( q({"enabledPlugins": {"briefing@getty": true}, "extraKnownMarketplaces": {"getty": {}}}) );
  is( $r->{exit_code}, 0, 'literal true enables briefing (minified JSON)' );

  # a non-literal value never demands a marketplace either
  $r = settings_row( q({"enabledPlugins": {"briefing@getty": true, "tool@elsewhere": "true"}, "extraKnownMarketplaces": {"getty": {}}}) );
  is( $r->{exit_code}, 0, 'a string "true" plugin needs no marketplace' );

  # disabled plugin needs no marketplace
  $r = settings_row( q({"enabledPlugins": {"briefing@getty": true, "tool@elsewhere": false}, "extraKnownMarketplaces": {"getty": {}}}) );
  is( $r->{exit_code}, 0, 'a disabled plugin needs no marketplace' );

  # nested enabledPlugins is not the top level one
  $r = settings_row( q({"x": {"enabledPlugins": {"briefing@getty": true}}}) );
  is( $r->{exit_code}, 1, 'a nested enabledPlugins does not count' );
  one_row( $r, 'settings', 'missing', 'briefing' );

  # a string that merely contains the text
  $r = settings_row( q({"note": "\"enabledPlugins\": {\"briefing@getty\": true}"}) );
  is( $r->{exit_code}, 1, 'enabledPlugins text inside a string does not count' );

  # settings.local.json is not read
  my $box = team();
  path( $box->{cwd}, '.claude', 'settings.json' )->remove;
  write_file( path( $box->{cwd}, '.claude', 'settings.local.json' ),
    q({"enabledPlugins": {"briefing@getty": true}, "extraKnownMarketplaces": {"getty": {}}}) );
  $r = tsv($box);
  is( $r->{exit_code}, 1, 'settings.local.json does not stand in for settings.json' );
  one_row( $r, 'settings', 'missing', '.claude/settings.json' );
}

# --- tab and newline hygiene -----------------------------------------------

{
  # a tab or a newline inside a field must never split or add a row
  my $box = team();
  put_agent( $box, 'harbor-worker.md',
    agent_text( 'harbor-worker', skills => ["tab\tskill"] ) );
  my $r = tsv($box);
  is( ( scalar grep { @{$_} != 4 } @{ $r->{rows} } ), 0, 'a tab inside a name never adds a field' );
}

# --- the hook command takes an event ----------------------------------------

sub hook {
  my ( $box, $payload, @args ) = @_;
  return run_cli(
    sandbox => $box,
    argv    => [ briefing_argv( 'hook', @args ) ],
    input   => encode_json($payload),
  );
}

{
  my $box = team();
  write_file( path( $box->{cwd}, '.claude', 'skills', 'harbor-core', 'SKILL.md' ), "CORE BODY\n" );
  my %bare = ( agent_type => 'harbor-worker', cwd => $box->{cwd}, session_id => 's1' );

  my $none = hook( $box, \%bare );
  is( $none->{exit_code}, 0, 'a payload without an event and without an argument is a no-op' );
  is( $none->{stdout}, '', 'and prints nothing' );

  for my $spelling ( 'subagent-start', 'SUBAGENT-START', 'Subagent-Start', 'subagentstart', 'SubagentStart', 'subagent_start' ) {
    my $r = hook( $box, \%bare, $spelling );
    is( $r->{exit_code}, 0, "hook $spelling exits 0" );
    like( $r->{stdout}, qr/CORE BODY/, "hook $spelling briefs the agent without hook_event_name" );
  }

  my $override = hook( $box, { %bare, hook_event_name => 'PreToolUse' }, 'subagent-start' );
  like( $override->{stdout}, qr/CORE BODY/, 'the argument replaces hook_event_name in the payload' );

  my $other = hook( $box, { %bare, hook_event_name => 'SubagentStart' }, 'pre-tool-use' );
  unlike( $other->{stdout}, qr/CORE BODY/, 'pre-tool-use does not brief even when the payload says SubagentStart' );
}

{
  # pre-tool-use denies a spawn with a missing skill
  my $box = team();
  put_agent( $box, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['harbor-gone'] ) );
  my %spawn = (
    cwd => $box->{cwd}, session_id => 's1', tool_name => 'Agent',
    tool_input => { subagent_type => 'harbor-worker', description => 'x' },
  );
  for my $spelling ( 'pre-tool-use', 'PRE-TOOL-USE', 'PreToolUse', 'pretooluse' ) {
    my $r = hook( $box, \%spawn, $spelling );
    is( $r->{exit_code}, 0, "hook $spelling exits 0" );
    my $out = eval { decode_json_text( $r->{stdout} ) } || {};
    is( $out->{hookSpecificOutput}{permissionDecision}, 'deny', "hook $spelling denies a missing skill" );
    like( $out->{hookSpecificOutput}{permissionDecisionReason}, qr/harbor-gone/, 'the reason names the skill' );
  }
}

sub decode_json_text { return JSON::MaybeXS::decode_json( $_[0] ) }

{
  # session-start runs the pre-flight; a healthy project is silent, a broken one speaks
  my $good = team();
  my $r = hook( $good, { cwd => $good->{cwd}, session_id => 's1', source => 'startup' }, 'session-start' );
  is( $r->{exit_code}, 0, 'hook session-start exits 0' );

  my $bad = team();
  put_agent( $bad, 'harbor-worker.md', agent_text( 'harbor-worker', skills => ['harbor-gone'] ) );
  my $both = hook( $bad, { cwd => $bad->{cwd}, session_id => 's1', source => 'startup' }, 'session-start' );
  my $same = hook( $bad, { cwd => $bad->{cwd}, session_id => 's1', source => 'startup', hook_event_name => 'SessionStart' } );
  is( $both->{exit_code}, $same->{exit_code}, 'session-start by argument equals SessionStart by payload (exit)' );
  is( $both->{stdout}, $same->{stdout}, 'session-start by argument equals SessionStart by payload (output)' );
  like( $both->{stdout}, qr/harbor-gone/, 'and the pre-flight names the missing skill' );
  unlike( $r->{stdout}, qr/harbor-gone/, 'a healthy project says nothing about skills' );
}

{
  # unknown event word: invalid hook input, so exit 0 (a hook never blocks), nothing on
  # stdout, never the hook; only a wrong argument count stays a usage error (exit 2)
  my $box = team();
  my %bare = ( agent_type => 'harbor-worker', cwd => $box->{cwd}, hook_event_name => 'SubagentStart' );
  for my $bad ( 'bogus', 'subagent', 'stop', 'subagent-stop', '', 'SubagentStart extra' ) {
    my $r = hook( $box, \%bare, $bad );
    is( $r->{exit_code}, 0, "hook '$bad' exits 0" );
    is( $r->{stdout}, '', "hook '$bad' prints nothing on stdout" );
  }
  my $two = hook( $box, \%bare, 'subagent-start', 'session-start' );
  is( $two->{exit_code}, 2, 'two event arguments exit 2' );
  is( $two->{stdout}, '', 'and print nothing' );

  my $plain = hook( $box, \%bare );
  like( $plain->{stdout}, qr/CORE|additionalContext/, 'without an argument the payload event still routes' );
}

done_testing;
