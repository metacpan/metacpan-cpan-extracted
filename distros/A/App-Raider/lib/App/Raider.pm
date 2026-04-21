# ABSTRACT: Autonomous CLI agent that can browse directories, edit files, and run bash commands

package App::Raider;
our $VERSION = '0.003';
use Moose;
use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Run::Bash;
use Module::Runtime ();
use Path::Tiny;
use YAML::PP ();

use App::Raider::FileTools qw( build_file_tools_server );
use App::Raider::WebTools  qw( build_web_tools_server );
use Langertha::Raider;



has engine_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    return 'anthropic' if $ENV{ANTHROPIC_API_KEY};
    return 'openai'    if $ENV{OPENAI_API_KEY};
    return 'deepseek'  if $ENV{DEEPSEEK_API_KEY};
    return 'groq'      if $ENV{GROQ_API_KEY};
    return 'mistral'   if $ENV{MISTRAL_API_KEY};
    return 'gemini'    if $ENV{GEMINI_API_KEY};
    return 'anthropic';
  },
  init_arg => 'engine',
);


my %DEFAULT_MODEL = (
  anthropic => 'claude-haiku-4-5',
  openai    => 'gpt-4o-mini',
  deepseek  => 'deepseek-chat',
  groq      => 'llama-3.3-70b-versatile',
  mistral   => 'mistral-small-latest',
  gemini    => 'gemini-2.5-flash',
  cerebras  => 'llama3.1-8b',
);

sub env_var_for_engine {
  my ($engine) = @_;
  my %map = (
    anthropic  => 'ANTHROPIC_API_KEY',
    openai     => 'OPENAI_API_KEY',
    deepseek   => 'DEEPSEEK_API_KEY',
    groq       => 'GROQ_API_KEY',
    mistral    => 'MISTRAL_API_KEY',
    gemini     => 'GEMINI_API_KEY',
    minimax    => 'MINIMAX_API_KEY',
    cerebras   => 'CEREBRAS_API_KEY',
    openrouter => 'OPENROUTER_API_KEY',
    ollama     => undef,
  );
  return $map{$engine};
}

sub default_model_for_engine {
  my ($engine) = @_;
  return $DEFAULT_MODEL{$engine};
}


has model => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  predicate => 'has_explicit_model',
  default   => sub {
    my ($self) = @_;
    return default_model_for_engine($self->engine_name) // '';
  },
);

sub has_model {
  my ($self) = @_;
  return 1 if $self->has_explicit_model;
  return length($self->model) ? 1 : 0;
}


sub api_key_env {
  my ($self) = @_;
  return env_var_for_engine($self->engine_name);
}


has api_key => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_api_key',
);


has mission => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_mission',
);

sub _build_mission {
  my ($self) = @_;
  my $root = $self->root;
  my $base = <<"EOM";
You are Langertha, viking shield-maiden. Autonomous CLI agent on user's
local machine. CLI name: "raider". Just CLI. No pause, no abort, no ask
to stop. You do things.

Name, persona, tone are defaults. User can rename you, rewrite your
background, or change persona entirely via C<.raider.md> in working dir.
If present, its content appended below as user's custom instructions.
User's custom instructions override this default where they conflict.

Working directory: $root

Tools (MCP):
  - list_files(path)
  - read_file(path)
  - write_file(path, content)
  - edit_file(path, old_string, new_string)
  - bash(command, [working_directory], [timeout])
  - web_search(query, [limit])
  - web_fetch(url, [as_html])

How you work:
  - User turn = task. Pursue with tools until done. Unlimited iterations.
  - Read before write. No guessing file contents.
  - After write_file / edit_file: verify. Re-read, or run check (perl -c,
    tests, etc.).
  - Small targeted edits > full rewrites.
  - bash is full shell, not sandbox. Use freely.
  - Skip irreversible ops (rm -rf, git reset --hard, force pushes) unless
    user explicit ask.

Communication (Caveman mode, default):
  - Terse. Drop articles (a/an/the), filler (just/really/basically/
    actually/simply), pleasantries (sure/certainly/of course/happy to),
    hedging (maybe/perhaps/I think).
  - Fragments OK. Short synonyms (big not extensive, fix not "implement
    a solution for").
  - Technical terms exact. Code blocks unchanged. Errors quoted exact.
  - Pattern: `[thing] [action] [reason]. [next step].`
  - Not: "Sure! I'd be happy to help. The issue is likely caused by..."
  - Yes: "Bug in auth middleware. Token check uses `<` not `<=`. Fix:"
  - Drop caveman for: destructive ops warnings, irreversible confirmations,
    multi-step sequences where fragment order could confuse. Resume after.
  - User says "normal mode" or "stop caveman": revert, write normal.

You have no yield / ask / abort tool. Task done: plain text reply. CLI
loops back to user.
EOM

  my $custom_file = path($self->root)->child('.raider.md');
  if (-f $custom_file) {
    my $custom = eval { $custom_file->slurp_utf8 };
    if (defined $custom && length $custom) {
      $base .= "\n\n---\nUser's custom instructions (from $custom_file):\n\n$custom\n";
    }
  }

  my @skills = $self->_load_skill_texts;
  if (@skills) {
    $base .= "\n\n---\nLoaded skills (domain knowledge the user enabled for this session):\n\n"
           . join("\n\n", @skills) . "\n";
  }

  return $base;
}


has root => (
  is      => 'ro',
  isa     => 'Str',
  default => sub { Path::Tiny->cwd->stringify },
);


has allowed_commands => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  predicate => 'has_allowed_commands',
);


has max_iterations => (
  is      => 'ro',
  isa     => 'Int',
  default => 10_000,
);


has trace => (
  is      => 'ro',
  isa     => 'Bool',
  default => sub { -t STDOUT ? 1 : 0 },
);


has max_context_tokens => (
  is      => 'ro',
  isa     => 'Int',
  default => 40_000,
);


has context_compress_threshold => (
  is      => 'ro',
  isa     => 'Num',
  default => 0.7,
);


has skill_sources => (
  is      => 'ro',
  isa     => 'ArrayRef[HashRef]',
  lazy    => 1,
  builder => '_build_skill_sources',
);

sub _normalize_skill_spec {
  my ($spec) = @_;
  if (!ref $spec) {
    return (
      { type => 'file',   path => 'CLAUDE.md' },
      { type => 'claude', path => '.claude/skills' },
    ) if $spec eq 'claude';
    return { type => 'file', path => 'AGENTS.md' } if $spec eq 'openai'
                                                   || $spec eq 'agents'
                                                   || $spec eq 'codex';
    return { type => 'dir',  path => $spec };
  }
  return $spec if ref $spec eq 'HASH';
  return;
}

# Well-known per-tool files + source dirs. Used both for loading (when the
# matching profile flag is set) and for the "ignored but present" notice.
our %AGENT_PROFILES = (
  claude => [
    { type => 'file',   path => 'CLAUDE.md' },
    { type => 'claude', path => '.claude/skills' },
  ],
  openai => [
    { type => 'file',   path => 'AGENTS.md' },
  ],
);

sub _build_skill_sources {
  my ($self) = @_;
  # Pull from .raider.yml if the user didn't set sources explicitly.
  my $file = path($self->root)->child('.raider.yml');
  return [] unless -f $file;
  my $yml = eval { YAML::PP->new->load_string($file->slurp_utf8) };
  return [] unless ref $yml eq 'HASH' && defined $yml->{skills};
  my $raw = $yml->{skills};
  my @list = ref $raw eq 'ARRAY' ? @$raw : ($raw);
  my @specs;
  for my $item (@list) {
    push @specs, _normalize_skill_spec($item);
  }
  return \@specs;
}

sub _load_skill_texts {
  my ($self) = @_;
  my @out;
  for my $spec (@{$self->skill_sources}) {
    my $type = $spec->{type} // 'dir';
    my $rel  = $spec->{path};
    next unless defined $rel && length $rel;
    my $base = Path::Tiny::path($rel);
    $base = Path::Tiny::path($self->root)->child($rel) unless $base->is_absolute;
    next unless $type eq 'file' || -d $base;

    my @files;
    if ($type eq 'file') {
      # Single markdown file — $base is that file, not a directory.
      my $f = Path::Tiny::path($rel);
      $f = Path::Tiny::path($self->root)->child($rel) unless $f->is_absolute;
      next unless -f $f;
      @files = ($f);
    }
    elsif ($type eq 'claude') {
      # Claude layout: $base/<skill>/SKILL.md
      for my $dir ($base->children) {
        next unless -d $dir;
        my $f = $dir->child('SKILL.md');
        push @files, $f if -f $f;
      }
    }
    else {
      my $glob = $spec->{glob} // '*.md';
      push @files, $base->children(qr/\Q$glob\E$/);
      # Fallback: recurse if nothing matched at the top level
      if (!@files) {
        @files = grep { -f $_ && /\.md$/ } $base->children;
      }
    }

    for my $f (sort @files) {
      my $name = $type eq 'claude' ? $f->parent->basename : $f->basename;
      my $body = eval { $f->slurp_utf8 } // next;
      # Strip YAML frontmatter if present.
      $body =~ s/\A---\s*\n.*?\n---\s*\n//s;
      push @out, "### Skill: $name\n\n$body";
    }
  }
  return @out;
}


has engine_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub _load_yml_options {
  my ($self) = @_;
  my $file = path($self->root)->child('.raider.yml');
  return {} unless -f $file;
  my $yml = eval { YAML::PP->new->load_string($file->slurp_utf8) };
  return {} unless ref $yml eq 'HASH';
  # Shape: either flat or under engine-name / 'default' keys.
  my %opts;
  if (ref $yml->{default} eq 'HASH') { %opts = (%opts, %{$yml->{default}}) }
  my $name = $self->engine_name;
  if (ref $yml->{$name} eq 'HASH')   { %opts = (%opts, %{$yml->{$name}}) }
  # If no per-engine/default keys, treat whole file as flat options.
  if (!%opts && !grep { ref $yml->{$_} eq 'HASH' } keys %$yml) {
    %opts = %$yml;
  }
  return \%opts;
}

has loop => (
  is      => 'ro',
  isa     => 'IO::Async::Loop',
  lazy    => 1,
  default => sub { IO::Async::Loop->new },
);

has _engine => (is => 'ro', lazy => 1, builder => '_build_engine');
has _raider => (is => 'ro', lazy => 1, builder => '_build_raider');
has _mcps   => (is => 'ro', lazy => 1, builder => '_build_mcps');

sub _build_api_key {
  my ($self) = @_;
  my $var = env_var_for_engine($self->engine_name);
  return '' unless $var;
  return $ENV{$var} // '';
}

sub _engine_class {
  my ($self) = @_;
  my %map = (
    anthropic  => 'Langertha::Engine::Anthropic',
    openai     => 'Langertha::Engine::OpenAI',
    deepseek   => 'Langertha::Engine::DeepSeek',
    groq       => 'Langertha::Engine::Groq',
    mistral    => 'Langertha::Engine::Mistral',
    gemini     => 'Langertha::Engine::Gemini',
    minimax    => 'Langertha::Engine::MiniMax',
    cerebras   => 'Langertha::Engine::Cerebras',
    openrouter => 'Langertha::Engine::OpenRouter',
    ollama     => 'Langertha::Engine::Ollama',
  );
  my $class = $map{$self->engine_name}
    or die "Unknown engine: " . $self->engine_name . "\n";
  return $class;
}

sub _build_mcps {
  my ($self) = @_;

  my $files = build_file_tools_server(root => $self->root);

  my $bash = MCP::Run::Bash->new(
    tool_name         => 'bash',
    tool_description  => 'Run a shell command with bash -c. Returns exit code, stdout, and stderr. Use this for ls, grep, find, git, cat, running tests, any shell pipeline — anything you would type at a terminal.',
    working_directory => $self->root,
    ($self->has_allowed_commands ? (allowed_commands => $self->allowed_commands) : ()),
    timeout => 120,
  );

  my $web = build_web_tools_server(loop => $self->loop);

  my @clients;
  for my $server ($files, $bash, $web) {
    my $client = Net::Async::MCP->new(server => $server);
    $self->loop->add($client);
    push @clients, $client;
  }
  return \@clients;
}

sub _build_engine {
  my ($self) = @_;
  my $class = $self->_engine_class;
  Module::Runtime::require_module($class);

  my %args = (
    mcp_servers => $self->_mcps,
  );
  $args{api_key} = $self->api_key if length $self->api_key;
  $args{model}   = $self->model   if $self->has_model;

  # Engine-level overrides: .raider.yml then engine_options (CLI wins).
  my $yml = $self->_load_yml_options;
  %args = (%args, %$yml, %{$self->engine_options});

  return $class->new(%args);
}

sub _build_raider {
  my ($self) = @_;
  my @plugins;
  if ($self->trace) {
    # Pass as name(s) so PluginHost injects `host` (required by
    # Langertha::Plugin). The flat-list form is [Name, {args}, Name, ...].
    push @plugins, '+App::Raider::Plugin::Trace';
  }
  push @plugins, '+App::Raider::Plugin::Situation';
  return Langertha::Raider->new(
    engine                     => $self->_engine,
    mission                    => $self->mission,
    max_iterations             => $self->max_iterations,
    max_context_tokens         => $self->max_context_tokens,
    context_compress_threshold => $self->context_compress_threshold,
    (@plugins ? (plugins => \@plugins) : ()),
  );
}


async sub raid_f {
  my ($self, @messages) = @_;
  for my $mcp (@{$self->_mcps}) {
    await $mcp->initialize;
  }
  return await $self->_raider->raid_f(@messages);
}


sub run {
  my ($self, @messages) = @_;
  my $f = $self->raid_f(@messages);
  $self->loop->await($f);
  return $f->get;
}


sub raider { $_[0]->_raider }



sub loaded_skill_names {
  my ($self) = @_;
  my @names;
  for my $spec (@{$self->skill_sources}) {
    my $type = $spec->{type} // 'dir';
    my $rel  = $spec->{path};
    next unless defined $rel && length $rel;
    my $base = Path::Tiny::path($rel);
    $base = Path::Tiny::path($self->root)->child($rel) unless $base->is_absolute;
    if ($type eq 'file') {
      push @names, $base->basename if -f $base;
      next;
    }
    next unless -d $base;
    if ($type eq 'claude') {
      for my $dir (sort $base->children) {
        next unless -d $dir;
        push @names, $dir->basename if -f $dir->child('SKILL.md');
      }
    }
    else {
      for my $f (sort $base->children) {
        push @names, $f->basename if -f $f && $f =~ /\.md$/;
      }
    }
  }
  return @names;
}


sub ignored_agent_files {
  my ($self) = @_;

  my %loaded;
  for my $s (@{$self->skill_sources}) {
    next unless ($s->{type} // '') eq 'file';
    my $p = Path::Tiny::path($s->{path});
    $p = Path::Tiny::path($self->root)->child($s->{path}) unless $p->is_absolute;
    $loaded{ $p->canonpath }++;
  }

  my @out;
  for my $profile (sort keys %AGENT_PROFILES) {
    for my $spec (@{$AGENT_PROFILES{$profile}}) {
      next unless $spec->{type} eq 'file';
      my $p = Path::Tiny::path($self->root)->child($spec->{path});
      next unless -f $p;
      next if $loaded{ $p->canonpath };
      push @out, { path => $p->basename, profile => $profile };
    }
  }
  return @out;
}

sub trace_plugin {
  my ($self) = @_;
  return unless $self->trace;
  for my $p (@{$self->_raider->_plugin_instances}) {
    return $p if $p->isa('App::Raider::Plugin::Trace');
  }
  return;
}


sub token_stats {
  my ($self) = @_;
  my $t = $self->trace_plugin or return;
  return $t->token_stats;
}


sub reload_mission {
  my ($self) = @_;
  my $new = $self->_build_mission;
  # Raider's `mission` is declared 'ro' — write directly into the object
  # hash so we can hot-swap after editing .raider.md without dropping
  # history or metrics.
  $self->_raider->{mission} = $new;
  return $new;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider - Autonomous CLI agent that can browse directories, edit files, and run bash commands

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use App::Raider;

    my $app = App::Raider->new(
        # engine/model/api_key auto-detected from *_API_KEY env vars
        root           => '/path/to/project',
        skill_sources  => [
            { type => 'file',   path => 'CLAUDE.md' },
            { type => 'claude', path => '.claude/skills' },
        ],
        engine_options => { temperature => 0.2 },
    );

    my $result = $app->run('Explore the repo and summarize it.');
    print $result;

=head1 DESCRIPTION

L<App::Raider> wraps L<Langertha::Raider> with a standard toolbox for a
working coding/system agent:

=over

=item * Local filesystem access, confined to L</root>
(L<App::Raider::FileTools>).

=item * Full shell via L<MCP::Run::Bash> (the C<bash> tool).

=item * Web search + fetch via L<Net::Async::WebSearch> and
L<Net::Async::HTTP> (L<App::Raider::WebTools>).

=item * Per-engine cheap-model defaults and automatic engine selection from
the first C<*_API_KEY> env var found.

=item * Optional skill-loading from C<.claude/skills/*/SKILL.md>,
C<AGENTS.md>, plain markdown directories, or any mix.

=item * Engine-attribute config via C<.raider.yml> in L</root> plus
L</engine_options> merge.

=item * Live trace plugin (L<App::Raider::Plugin::Trace>) and
situation-injection plugin (L<App::Raider::Plugin::Situation>).

=item * On-the-fly how-to-use-raider documentation generator
(L<App::Raider::Skill>).

=back

The distribution intentionally stays small. It is the thin CLI-oriented
layer on top of Langertha's engine/agent machinery. The CLI front-end is
L<raider>.

=head2 engine_name

Langertha engine class shortcut (e.g. C<'anthropic'>, C<'openai'>,
C<'deepseek'>, C<'groq'>, C<'mistral'>, C<'gemini'>, C<'ollama'>). Defaults to
C<'anthropic'>.

=head2 default_model_for_engine

Per-engine default model when L</model> is not explicitly set.

=head2 model

Model identifier to pass to the engine. If unset, the engine picks its default.

=head2 api_key_env

Name of the environment variable used for the current engine's API key
(for display / debugging). Returns undef for engines that don't use an API
key (e.g. ollama).

=head2 api_key

API key for the engine. Defaults to an engine-appropriate environment variable.

=head2 mission

System prompt / mission statement for the Raider. Defaults to a generic
assistant persona.

=head2 root

Working directory for tool operations. Defaults to the current process cwd.
File tools are chrooted to this directory; bash commands inherit it as their
default working directory.

=head2 allowed_commands

Optional arrayref restricting which bash commands may run (first word match).
When undef, any command is allowed.

=head2 max_iterations

Maximum tool-calling iterations per raid. Defaults to 10_000 — effectively
unlimited, so a raid only ends when the model itself stops emitting tool
calls. The conversation history is preserved between raids, so the next user
message in the REPL simply continues the same thread.

Set this to a smaller number if you want a hard safety cap.

=head2 trace

Emit live ANSI-colored progress output (iteration markers, tool calls, tool
results) via L<App::Raider::Plugin::Trace>. Defaults to on when STDOUT is a
terminal.

=head2 max_context_tokens

Trigger history auto-compression once the last prompt exceeds
C<context_compress_threshold * max_context_tokens>. Defaults to 40_000, which
keeps the running session comfortably under typical per-minute rate limits
(Anthropic org default: 50k input tokens/min on Haiku).

=head2 context_compress_threshold

Fraction of L</max_context_tokens> at which compression kicks in. Defaults to
C<0.7>.

=head2 skill_sources

ArrayRef of skill-source specs to load and append to the mission. Each spec
is a hashref:

    { type => 'claude', path => '.claude/skills' }  # Claude Code SKILL.md tree
    { type => 'dir',    path => 'my-skills', glob => '*.md' }

Settable via L</skill_sources>, via the C<skills> key in F<.raider.yml>, or
via the CLI flags C<--claude> / C<--skills PATH>.

=head2 engine_options

HashRef of extra attributes forwarded to the engine constructor
(e.g. C<temperature>, C<response_size>, C<seed>). Merged on top of values
loaded from C<.raider.yml> in the working directory.

=head2 raid_f

    my $result = await $app->raid_f($prompt);

Async variant: drives one raid iteration and returns the
L<Langertha::Raider::Result>.

=head2 run

    my $result = $app->run($prompt);

Synchronous convenience wrapper around L</raid_f>. Runs the I/O loop until the
raid completes and returns the result (which stringifies to the final text).

=head2 raider

Returns the underlying L<Langertha::Raider> instance (lazily built).

=head2 trace_plugin

Returns the loaded L<App::Raider::Plugin::Trace> instance, or undef if trace
is disabled.

=head2 loaded_skill_names

Returns a list of skill names currently discoverable from the configured
L</skill_sources>. Intended for banner/status display.

=head2 ignored_agent_files

Returns a list of per-tool agent files that exist in the working root but
are NOT covered by the current L</skill_sources>. Intended to power the
banner's "seeing AGENTS.md, ignoring" notice.

=head2 token_stats

Cumulative token counts for this session (hashref with C<prompt>,
C<completion>, C<total>, C<calls>) — available when trace is enabled.

=head2 reload_mission

Rebuilds the mission (e.g. after C<.raider.md> has been edited) and swaps it
into the underlying L<Langertha::Raider>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider>

=item * L<App::Raider::FileTools>

=item * L<MCP::Run::Bash>

=item * L<raider> — the CLI entry point

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
