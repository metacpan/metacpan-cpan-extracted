package App::Briefing;
# ABSTRACT: Preload declared skills into Claude Code and Codex subagents at spawn time

use Moo;
use App::Briefing::Filesystem;
use B qw( SVf_POK SVp_POK svref_2object );
use Carp qw( croak );
use Encode qw( encode_utf8 );
use JSON::MaybeXS ();
use namespace::clean;

our $VERSION = '0.006000';

use constant BUDGET_BYTES => 64 * 1024;

has filesystem => ( is => 'lazy' );


has cwd => ( is => 'lazy' );


has home => ( is => 'lazy' );


has codex_home => ( is => 'lazy' );


has _json => ( is => 'lazy', init_arg => undef );

sub filesystem_class { 'App::Briefing::Filesystem' }
sub toml_parser_class { 'TOML::Tiny::Parser' }

sub _build_filesystem {
  my ( $self ) = @_;
  return $self->filesystem_class->new;
}

sub _build_cwd {
  my ( $self ) = @_;
  my $pwd = $self->filesystem->environment_value('PWD');
  return $pwd if defined $pwd;
  return $self->filesystem->current_dir;
}

sub _build_home {
  my ( $self ) = @_;
  my $value = $self->filesystem->environment_value('HOME');
  return $value if defined $value;

  if ($self->filesystem->is_windows) {
    $value = $self->filesystem->environment_value('USERPROFILE');
    return $value if defined $value;
    my $drive = $self->filesystem->environment_value('HOMEDRIVE');
    my $path  = $self->filesystem->environment_value('HOMEPATH');
    return $drive.$path if defined $drive && defined $path;
  }

  my $home = (getpwuid $<)[7];
  return $self->filesystem->decode_path($home) if defined $home && length $home;
  return $self->filesystem->current_dir;
}

sub _build_codex_home {
  my ( $self ) = @_;
  my $codex_home = $self->filesystem->environment_value('CODEX_HOME');
  return $codex_home if defined $codex_home;
  return $self->filesystem->join_path( $self->home, '.codex' );
}

sub _build__json {
  my ( $self ) = @_;
  return JSON::MaybeXS->new(
    allow_nonref    => 0,
    canonical       => 1,
    convert_blessed => 1,
    utf8            => 0,
  );
}

sub _is_string {
  my ( $self, $value ) = @_;
  return 0 unless defined $value && !ref $value;
  my $flags = svref_2object( \$value )->FLAGS;
  return $flags & ( SVf_POK | SVp_POK ) ? 1 : 0;
}

sub _nonempty_string {
  my ( $self, $value ) = @_;
  return $self->_is_string($value) && length $value ? 1 : 0;
}

sub _trim {
  my ( $self, $value ) = @_;
  $value = '' unless defined $value;
  $value =~ s/\A\s+//;
  $value =~ s/\s+\z//;
  return $value;
}

sub _split_frontmatter {
  my ( $self, $text ) = @_;
  $text = '' unless defined $text;
  $text =~ s/\A(?:\x{FEFF}|\xEF\xBB\xBF)//;
  return ( $1, $2 )
    if $text =~ /\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z/s;
  return ( '', $text );
}

sub _dedent {
  my ( $self, $block ) = @_;
  my @lines = split /\r?\n/, $block, -1;
  my @indents = map {
    my ( $indent ) = /\A([ \t]*)/;
    length $indent;
  } grep { /\S/ } @lines;
  return $block unless @indents;

  my $common = $indents[0];
  for my $indent (@indents) {
    $common = $indent if $indent < $common;
  }
  return join( "\n", map { length($_) >= $common ? substr( $_, $common ) : $_ } @lines );
}

sub _parse_skills_list {
  my ( $self, $frontmatter ) = @_;
  return [] unless defined $frontmatter && length $frontmatter;
  return [] unless $frontmatter =~ /^briefing:[ \t]*\r?\n((?:[ \t]+[^\r\n]*(?:\r?\n|$))+)/m;

  my $block = $self->_dedent($1);
  if ($block =~ /^skills:[ \t]*\r?\n((?:[ \t]*-[ \t]*[^\r\n]+\r?\n?)+)/m) {
    my $items = $1;
    my @skills;
    while ($items =~ /^[ \t]*-[ \t]*(["']?)([^"'\r\n]+)\1[ \t]*$/mg) {
      my $skill = $self->_trim($2);
      push @skills, $skill if length $skill;
    }
    return \@skills;
  }

  if ($block =~ /^skills:[ \t]*\[([^\]\r\n]+)\]/m) {
    my @skills;
    for my $item (split /,/, $1) {
      $item = $self->_trim($item);
      $item =~ s/\A["']//;
      $item =~ s/["']\z//;
      push @skills, $item if length $item;
    }
    return \@skills;
  }
  return [];
}

sub _parse_frontmatter_name {
  my ( $self, $frontmatter ) = @_;
  return unless defined $frontmatter;
  return $self->_trim($2)
    if $frontmatter =~ /^name:[ \t]*(["']?)([^"'\r\n]+?)\1[ \t]*$/m;
  return;
}

sub _find_first_readable {
  my ( $self, @files ) = @_;
  for my $file (@files) {
    next unless defined $file && length $file;
    return $file if $self->filesystem->is_readable_file($file);
  }
  return;
}

sub _claude_agent_roots {
  my ( $self ) = @_;
  return (
    $self->filesystem->join_path( $self->cwd,  '.claude', 'agents' ),
    $self->filesystem->join_path( $self->home, '.claude', 'agents' ),
  );
}

sub _claude_agent_name {
  my ( $self, $file ) = @_;
  my ( $frontmatter ) = $self->_split_frontmatter(
    $self->filesystem->slurp_utf8($file),
  );
  my $name = $self->_parse_frontmatter_name($frontmatter);
  return $name if defined $name;
  my $basename = $self->filesystem->basename($file);
  $basename =~ s/\.md\z//;
  return $basename;
}

sub _find_claude_agent {
  my ( $self, $agent ) = @_;
  for my $root ($self->_claude_agent_roots) {
    next unless $self->filesystem->is_dir($root);
    my $direct = $self->filesystem->join_path( $root, $agent.'.md' );
    if (
      $self->_find_first_readable($direct)
      && $self->_claude_agent_name($direct) eq $agent
    ) {
      return $direct;
    }
    for my $file (@{ $self->filesystem->walk_files( $root, '.md' ) }) {
      next if $file eq $direct;
      return $file if $self->_claude_agent_name($file) eq $agent;
    }
  }
  return;
}

sub _list_claude_agents {
  my ( $self ) = @_;
  my %agents;
  for my $root ($self->_claude_agent_roots) {
    next unless $self->filesystem->is_dir($root);
    for my $file (@{ $self->filesystem->walk_files( $root, '.md' ) }) {
      my $name = $self->_claude_agent_name($file);
      $agents{$name} = $file unless exists $agents{$name};
    }
  }
  return \%agents;
}

sub _load_json {
  my ( $self, $file ) = @_;
  my $text = $self->filesystem->slurp_utf8($file);
  my $data = eval { $self->_json->decode( length($text) ? $text : '{}' ) };
  return ref $data eq 'HASH' ? $data : {};
}

sub _enabled_plugins {
  my ( $self ) = @_;
  my %enabled;
  for my $file (
    $self->filesystem->join_path( $self->home, '.claude', 'settings.json' ),
    $self->filesystem->join_path( $self->cwd, '.claude', 'settings.json' ),
    $self->filesystem->join_path( $self->cwd, '.claude', 'settings.local.json' ),
  ) {
    my $values = $self->_load_json($file)->{enabledPlugins};
    next unless ref $values eq 'HASH';
    for my $key (keys %{$values}) {
      next unless JSON::MaybeXS::is_bool( $values->{$key} );
      $enabled{$key} = $values->{$key} ? 1 : 0;
    }
  }
  return \%enabled;
}

sub _claude_plugins {
  my ( $self ) = @_;
  my $registry = $self->_load_json(
    $self->filesystem->join_path(
      $self->home,
      '.claude',
      'plugins',
      'installed_plugins.json',
    ),
  )->{plugins};
  return [] unless ref $registry eq 'HASH';

  my $enabled = $self->_enabled_plugins;
  my @found;
  for my $key (keys %{$registry}) {
    next unless $enabled->{$key};
    my $entries = $registry->{$key};
    next unless ref $entries eq 'ARRAY';
    for my $entry (@{$entries}) {
      next unless ref $entry eq 'HASH';
      my $root = $entry->{installPath};
      next unless $self->_nonempty_string($root);
      my $project = $entry->{projectPath};
      if ($self->_nonempty_string($project)) {
        next unless $self->filesystem->within( $self->cwd, $project );
        push @found, [ -length($project), $key, $root ];
      }
      else {
        push @found, [ 0, $key, $root ];
      }
    }
  }

  my @plugins;
  for my $item (sort {
    $a->[0] <=> $b->[0]
      || $a->[1] cmp $b->[1]
      || $a->[2] cmp $b->[2]
  } @found) {
    my ( undef, $key, $root ) = @{$item};
    my $manifest = $self->_load_json(
      $self->filesystem->join_path(
        $root,
        '.claude-plugin',
        'plugin.json',
      ),
    );
    my $name = $self->_nonempty_string( $manifest->{name} )
      ? $manifest->{name}
      : (split /\@/, $key, 2)[0];
    push @plugins, [ $name, $root, $manifest ];
  }
  return \@plugins;
}

sub _plugin_skill_dirs {
  my ( $self, $root, $manifest ) = @_;
  my $extra = $manifest->{skills};
  my @extra = $self->_is_string($extra)
    ? ($extra)
    : ref $extra eq 'ARRAY'
      ? grep { $self->_is_string($_) } @{$extra}
      : ();
  my @bases = (
    $self->filesystem->join_path( $root, 'skills' ),
    map { $self->filesystem->join_path( $root, $_ ) } @extra,
  );

  my @directories;
  for my $base (@bases) {
    next unless $self->filesystem->within( $base, $root );
    if ($self->filesystem->is_file(
      $self->filesystem->join_path( $base, 'SKILL.md' ),
    )) {
      push @directories, $base;
      next;
    }
    next unless $self->filesystem->is_dir($base);
    for my $directory (@{ $self->filesystem->child_directories($base) }) {
      push @directories, $directory
        if $self->filesystem->is_file(
          $self->filesystem->join_path( $directory, 'SKILL.md' ),
        );
    }
  }
  return \@directories;
}

sub _resolve_plugin_skill {
  my ( $self, $skill, $wanted_plugin ) = @_;
  for my $plugin (@{ $self->_claude_plugins }) {
    my ( $name, $root, $manifest ) = @{$plugin};
    next if defined $wanted_plugin && $name ne $wanted_plugin;
    for my $directory (@{ $self->_plugin_skill_dirs( $root, $manifest ) }) {
      next unless $self->filesystem->basename($directory) eq $skill;
      my $file = $self->filesystem->join_path( $directory, 'SKILL.md' );
      return $file if $self->filesystem->is_readable_file($file);
    }
  }
  return;
}

sub _resolve_skill_claude {
  my ( $self, $name ) = @_;
  if ($name =~ /:/ && $name !~ /\A:/) {
    my ( $plugin, $skill ) = split /:/, $name, 2;
    return $self->_resolve_plugin_skill( $skill, $plugin )
      if length($plugin) && length($skill) && $plugin !~ / /;
  }

  for my $base (
    $self->filesystem->join_path( $self->cwd,  '.claude', 'skills' ),
    $self->filesystem->join_path( $self->home, '.claude', 'skills' ),
  ) {
    my $file = $self->filesystem->join_path( $base, $name, 'SKILL.md' );
    return $file if $self->filesystem->is_readable_file($file);
  }
  return $self->_resolve_plugin_skill($name);
}

sub _toml_string_state {
  my ( $self, $line, $state ) = @_;
  my $index = 0;
  my $length = length $line;
  while ($index < $length) {
    if (!defined $state) {
      my $character = substr( $line, $index, 1 );
      last if $character eq '#';
      my $triple = substr( $line, $index, 3 );
      if ($triple eq q{"""} || $triple eq q{'''}) {
        $state = $triple;
        $index += 3;
        next;
      }
      if ($character eq q{"} || $character eq q{'}) {
        $index++;
        while ($index < $length && substr( $line, $index, 1 ) ne $character) {
          $index += $character eq q{"}
            && substr( $line, $index, 1 ) eq '\\'
            ? 2
            : 1;
        }
      }
      $index++;
      next;
    }

    if ($state eq q{"""} && substr( $line, $index, 1 ) eq '\\') {
      $index += 2;
      next;
    }
    if (substr( $line, $index, 3 ) eq $state) {
      $state = undef;
      $index += 3;
      next;
    }
    $index++;
  }
  return $state;
}

sub _parse_skills_comment {
  my ( $self, $text ) = @_;
  my $state;
  for my $line (split /\r?\n/, defined $text ? $text : '') {
    if (!defined $state && $line =~ /\A[ \t]*#[ \t]*briefing:[ \t]*skills[ \t]*=[ \t]*\[([^\]\r\n]*)\]/) {
      my $items = $1;
      my @skills;
      while ($items =~ /["']([^"']+)["']/g) {
        my $skill = $self->_trim($1);
        push @skills, $skill if length $skill;
      }
      return \@skills;
    }
    $state = $self->_toml_string_state( $line, $state );
  }
  return [];
}

sub _toml_parser {
  my ( $self ) = @_;
  my $parser_class = $self->toml_parser_class;
  # Loaded on first use, not with this module: compiling TOML::Tiny::Parser is a large share
  # of every start-up, and only Codex TOML files need it. This stays outside the parse eval,
  # so a missing parser dies loudly instead of making every Codex agent declare nothing.
  # A parser class that is already defined (an inline override) is used as it is.
  unless ($parser_class->can('new')) {
    ( my $file = $parser_class.'.pm' ) =~ s{::}{/}g;
    require $file;
  }
  return $parser_class;
}

sub _parse_toml {
  my ( $self, $text ) = @_;
  return {} unless defined $text && length $text;
  my $parser_class = $self->_toml_parser;
  my $document = eval {
    $parser_class->new(
      strict           => 1,
      inflate_boolean  => sub { return [ boolean => $_[0] ] },
      inflate_datetime => sub { return [ datetime => $_[0] ] },
      inflate_float    => sub { return [ float => $_[0] ] },
      inflate_integer  => sub { return [ integer => $_[0] ] },
    )->parse( encode_utf8($text) );
  };
  return ref $document eq 'HASH' ? $document : {};
}

sub _parse_skills_toml {
  my ( $self, $text ) = @_;
  my $document = $self->_parse_toml($text);
  my $briefing = $document->{briefing};
  return [] unless ref $briefing eq 'HASH';
  my $skills = $briefing->{skills};
  return [] unless ref $skills eq 'ARRAY';
  return [
    map { $self->_trim($_) }
    grep { $self->_is_string($_) && length $self->_trim($_) }
    @{$skills}
  ];
}

sub _parse_toml_name {
  my ( $self, $text ) = @_;
  my $state;
  for my $line (split /\r?\n/, defined $text ? $text : '') {
    if (!defined $state) {
      return if $line =~ /\A[ \t]*\[/;
      if ($line =~ /\A[ \t]*name[ \t]*=[ \t]*(?:"([^"\\]*)"|'([^']*)')/) {
        return defined $1 ? $1 : $2;
      }
    }
    $state = $self->_toml_string_state( $line, $state );
  }
  return;
}

sub _project_dirs {
  my ( $self ) = @_;
  my $cwd = $self->filesystem->absolute( $self->cwd );
  my @directories;
  my $directory = $cwd;
  while (1) {
    push @directories, $directory;
    return \@directories
      if $self->filesystem->exists(
        $self->filesystem->join_path( $directory, '.git' ),
      );
    my $parent = $self->filesystem->parent($directory);
    return [$cwd] if $parent eq $directory;
    $directory = $parent;
  }
}

sub _codex_layers {
  my ( $self ) = @_;
  return [
    (map { $self->filesystem->join_path( $_, '.codex' ) }
      @{ $self->_project_dirs }),
    $self->codex_home,
    $self->filesystem->join_path( '/', 'etc', 'codex' ),
  ];
}

sub _expand_home {
  my ( $self, $file ) = @_;
  return $self->home if $file eq '~';
  return $self->filesystem->join_path( $self->home, substr( $file, 2 ) )
    if $file =~ /\A~[\\\/]/;
  return $file;
}

sub _declared_roles {
  my ( $self, $layer ) = @_;
  my $document = $self->_parse_toml(
    $self->filesystem->slurp_utf8(
      $self->filesystem->join_path( $layer, 'config.toml' ),
    ),
  );
  my $agents = $document->{agents};
  return {} unless ref $agents eq 'HASH';

  my %roles;
  for my $name (keys %{$agents}) {
    my $role = $agents->{$name};
    next unless ref $role eq 'HASH';
    my $file = $role->{config_file};
    next unless $self->_nonempty_string($file);
    $file = $self->_expand_home($file);
    $roles{$name} = $self->filesystem->is_absolute($file)
      ? $file
      : $self->filesystem->join_path( $layer, $file );
  }
  return \%roles;
}

sub _find_codex_agent {
  my ( $self, $agent ) = @_;
  for my $layer (@{ $self->_codex_layers }) {
    my $declared = $self->_declared_roles($layer)->{$agent};
    if ($declared && $self->_find_first_readable($declared)) {
      return ( $declared, $self->filesystem->slurp_utf8($declared) );
    }

    my $root = $self->filesystem->join_path( $layer, 'agents' );
    next unless $self->filesystem->is_dir($root);
    my $direct = $self->filesystem->join_path( $root, $agent.'.toml' );
    if ($self->_find_first_readable($direct)) {
      my $text = $self->filesystem->slurp_utf8($direct);
      my $name = $self->_parse_toml_name($text);
      return ( $direct, $text ) if !defined $name || $name eq $agent;
    }
    for my $file (@{ $self->filesystem->walk_files( $root, '.toml' ) }) {
      next if $file eq $direct;
      my $text = $self->filesystem->slurp_utf8($file);
      my $name = $self->_parse_toml_name($text);
      return ( $file, $text ) if defined $name && $name eq $agent;
    }
  }
  return;
}

sub _list_codex_agents {
  my ( $self ) = @_;
  my %agents;
  for my $layer (@{ $self->_codex_layers }) {
    my %layer_agents;
    my $declared = $self->_declared_roles($layer);
    for my $name (keys %{$declared}) {
      $layer_agents{$name} = $declared->{$name}
        if $self->_find_first_readable( $declared->{$name} );
    }

    my $root = $self->filesystem->join_path( $layer, 'agents' );
    if ($self->filesystem->is_dir($root)) {
      for my $file (@{ $self->filesystem->walk_files( $root, '.toml' ) }) {
        my $name = $self->_parse_toml_name(
          $self->filesystem->slurp_utf8($file),
        );
        $layer_agents{$name} = $file
          if defined $name && !exists $layer_agents{$name};
      }
    }

    for my $name (keys %layer_agents) {
      $agents{$name} = $layer_agents{$name} unless exists $agents{$name};
    }
  }
  return \%agents;
}

sub _resolve_codex_plugin_skill {
  my ( $self, $plugin, $skill ) = @_;
  my $cache = $self->filesystem->join_path(
    $self->codex_home,
    'plugins',
    'cache',
  );

  for my $marketplace (@{ $self->filesystem->child_directories($cache) }) {
    my $plugin_root = $self->filesystem->join_path( $marketplace, $plugin );
    for my $version (@{ $self->filesystem->child_directories($plugin_root) }) {
      my $file = $self->filesystem->join_path(
        $version,
        'skills',
        $skill,
        'SKILL.md',
      );
      return $file if $self->filesystem->is_readable_file($file);
    }
  }

  my $direct_root = $self->filesystem->join_path( $cache, $plugin );
  for my $version (@{ $self->filesystem->child_directories($direct_root) }) {
    my $file = $self->filesystem->join_path(
      $version,
      'skills',
      $skill,
      'SKILL.md',
    );
    return $file if $self->filesystem->is_readable_file($file);
  }

  for my $marketplace (@{ $self->filesystem->child_directories($cache) }) {
    my $file = $self->filesystem->join_path(
      $marketplace,
      $plugin,
      'skills',
      $skill,
      'SKILL.md',
    );
    return $file if $self->filesystem->is_readable_file($file);
  }
  return;
}

sub _resolve_skill_codex {
  my ( $self, $name ) = @_;
  if ($name =~ /:/ && $name !~ /\A:/) {
    my ( $plugin, $skill ) = split /:/, $name, 2;
    return $self->_resolve_codex_plugin_skill( $plugin, $skill )
      if length($plugin) && length($skill) && $plugin !~ / /;
  }

  my @bases;
  for my $directory (@{ $self->_project_dirs }) {
    push @bases,
      $self->filesystem->join_path( $directory, '.codex',  'skills' ),
      $self->filesystem->join_path( $directory, '.agents', 'skills' );
  }
  push @bases,
    $self->filesystem->join_path( $self->codex_home, 'skills' ),
    $self->filesystem->join_path( $self->home, '.agents', 'skills' ),
    $self->filesystem->join_path( $self->codex_home, 'skills', '.system' ),
    $self->filesystem->join_path( '/', 'etc', 'codex', 'skills' );

  for my $base (@bases) {
    my $file = $self->filesystem->join_path( $base, $name, 'SKILL.md' );
    return $file if $self->filesystem->is_readable_file($file);
  }
  return;
}

sub resolve_skill {
  my ( $self, $name, %options ) = @_;
  my $harness = defined $options{harness} ? $options{harness} : 'claude';
  croak __PACKAGE__.'->resolve_skill requires harness claude or codex'
    unless $harness eq 'claude' || $harness eq 'codex';
  return unless $self->_nonempty_string($name);
  return $harness eq 'claude'
    ? $self->_resolve_skill_claude($name)
    : $self->_resolve_skill_codex($name);
}


sub _usable_skill_name {
  my ( $self, $name ) = @_;
  return $name =~ m{\A[^*?\[\]/\\]+\z} ? 1 : 0;
}

sub skill_problem {
  my ( $self, $name ) = @_;
  return unless $self->_nonempty_string($name);
  return if $self->resolve_skill( $name, harness => 'claude' );

  if ($name =~ /:/) {
    my ( $plugin, $skill ) = split /:/, $name, 2;
    return 'not a usable skill name'
      unless $self->_usable_skill_name($plugin)
      && $self->_usable_skill_name($skill);
    return "plugin '".$plugin."' has no skill '".$skill."'"
      if grep { $_->[0] eq $plugin } @{ $self->_claude_plugins };
    return "plugin '".$plugin."' is not installed and enabled";
  }
  return 'not a usable skill name' unless $self->_usable_skill_name($name);
  return 'no such skill in .claude/skills, ~/.claude/skills or an installed and enabled plugin';
}


sub claude_agent_skills {
  my ( $self, $file ) = @_;
  my ( $skills ) = $self->_claude_declaration($file);
  return $skills;
}


sub _claude_declaration {
  my ( $self, $file ) = @_;
  my ( $frontmatter ) = $self->_split_frontmatter(
    $self->filesystem->slurp_utf8($file),
  );
  return ( $self->_parse_skills_list($frontmatter), 0 );
}

sub _codex_declaration {
  my ( $self, $text ) = @_;
  my $legacy = $self->_parse_skills_toml($text);
  my $comment = $self->_parse_skills_comment($text);
  return ( @{$comment} ? $comment : $legacy, @{$legacy} ? 1 : 0 );
}

sub _briefing_result {
  my ( $self, $agent, $path, $skills, $harness, $legacy ) = @_;
  my @missing;
  my @blocks;
  for my $name (@{$skills}) {
    my $skill_file = $harness eq 'claude'
      ? $self->_resolve_skill_claude($name)
      : $self->_resolve_skill_codex($name);
    if (!$skill_file) {
      push @missing, $name;
      next;
    }
    my ( undef, $body ) = $self->_split_frontmatter(
      $self->filesystem->slurp_utf8($skill_file),
    );
    my $directory = $self->filesystem->absolute(
      $self->filesystem->parent($skill_file),
    );
    push @blocks,
      '<skill name="'.$name.'" dir="'.$directory.'">'."\n"
      .$self->_trim($body)."\n</skill>";
  }

  my $resolved_text = join "\n\n", @blocks;
  return {
    agent   => $agent,
    path    => $path,
    harness => $harness,
    skills  => [ @{$skills} ],
    missing => \@missing,
    text    => @missing ? '' : $resolved_text,
    size    => length encode_utf8($resolved_text),
    legacy  => $legacy ? 1 : 0,
  };
}

sub _brief_agent_claude {
  my ( $self, $agent ) = @_;
  my $file = $self->_find_claude_agent($agent);
  return unless $file;
  my ( $skills, $legacy ) = $self->_claude_declaration($file);
  return unless @{$skills};
  return $self->_briefing_result(
    $agent,
    $file,
    $skills,
    'claude',
    $legacy,
  );
}

sub _brief_agent_codex {
  my ( $self, $agent ) = @_;
  my ( $file, $text ) = $self->_find_codex_agent($agent);
  return unless $file;
  my ( $skills, $legacy ) = $self->_codex_declaration($text);
  return unless @{$skills};
  return $self->_briefing_result(
    $agent,
    $file,
    $skills,
    'codex',
    $legacy,
  );
}

sub brief_agent {
  my ( $self, $agent, %options ) = @_;
  my $harness = $options{harness};
  croak __PACKAGE__.'->brief_agent requires harness claude or codex'
    unless defined $harness && ($harness eq 'claude' || $harness eq 'codex');
  return $harness eq 'claude'
    ? $self->_brief_agent_claude($agent)
    : $self->_brief_agent_codex($agent);
}


sub check_agents {
  my ( $self, %options ) = @_;
  my $harness = defined $options{harness} ? $options{harness} : 'both';
  croak __PACKAGE__.'->check_agents requires harness claude, codex, or both'
    unless $harness eq 'claude' || $harness eq 'codex' || $harness eq 'both';

  my @results;
  if ($harness eq 'claude' || $harness eq 'both') {
    my $agents = $self->_list_claude_agents;
    for my $name (sort keys %{$agents}) {
      my $result = $self->_brief_agent_claude($name);
      push @results, $result if $result;
    }
  }
  if ($harness eq 'codex' || $harness eq 'both') {
    my $agents = $self->_list_codex_agents;
    for my $name (sort keys %{$agents}) {
      my $result = $self->_brief_agent_codex($name);
      push @results, $result if $result;
    }
  }
  return \@results;
}


sub _for_payload {
  my ( $self, $payload ) = @_;
  my $cwd = $payload->{cwd};
  return $self unless $self->_nonempty_string($cwd) && $cwd ne $self->cwd;
  return $self->new(
    cwd        => $cwd,
    home       => $self->home,
    codex_home => $self->codex_home,
    filesystem => $self->filesystem,
  );
}

sub _harnesses_for_payload {
  my ( $self, $payload ) = @_;
  my $transcript = $payload->{transcript_path};
  $transcript = '' unless $self->_is_string($transcript);
  $transcript =~ tr{\\}{/};
  my $codex_home = $self->codex_home;
  $codex_home =~ tr{\\}{/};
  return ['codex']
    if index( $transcript, '/.codex/' ) >= 0
    || (length($codex_home) && index( $transcript, $codex_home.'/' ) == 0);
  return ['claude'] if index( $transcript, '/.claude/' ) >= 0;
  return [qw( claude codex )];
}

sub _spawn_harness {
  my ( $self, $payload, $agent ) = @_;
  my $harnesses = $self->_harnesses_for_payload($payload);
  return $harnesses->[0] if @{$harnesses} == 1;
  return 'codex' if exists $payload->{turn_id};
  return $self->_find_claude_agent($agent) ? 'claude' : 'codex';
}

sub _legacy_note {
  my ( $self, $result ) = @_;
  return 'briefing: '.$result->{path}
    .' declares skills in a [briefing] table. Codex 0.153+ rejects that as an '
    .'unknown field and ignores the whole agent. Replace the table with a '
    .'comment line: # briefing: skills = [...]';
}

sub _missing_note {
  my ( $self, $result ) = @_;
  return "briefing: agent '".$result->{agent}."' references unknown skill(s): "
    .join( ', ', @{ $result->{missing} } );
}

sub _size_note {
  my ( $self, $result ) = @_;
  return "briefing: agent '".$result->{agent}."' is briefed with "
    .int( $result->{size} / 1024 ).' kB of skill text (over '
    .int( BUDGET_BYTES / 1024 ).' kB) '."\x{2014}".' consider declaring fewer or smaller skills.';
}

sub _audit_line {
  my ( $self, $result ) = @_;
  my $kilobytes = 0;
  if ($result->{size}) {
    my $whole = int( $result->{size} / 1024 );
    my $remainder = $result->{size} % 1024;
    $kilobytes = $whole
      + ($remainder > 512 || ($remainder == 512 && $whole % 2) ? 1 : 0);
    $kilobytes = 1 if $kilobytes < 1;
  }
  return 'briefing: '.$result->{agent}.' '."\x{2190}".' '
    .join( ', ', @{ $result->{skills} } ).' ('.$kilobytes.' kB)';
}

sub _problems {
  my ( $self, $result ) = @_;
  my ( @failures, @warnings );
  push @failures, 'unknown skill(s): '.join( ', ', @{ $result->{missing} } )
    if @{ $result->{missing} };
  push @failures,
    '[briefing] table '."\x{2014}".' Codex 0.153+ ignores this whole agent; use # briefing: skills = [...]'
    if $result->{legacy};
  push @warnings,
    int( $result->{size} / 1024 ).' kB of skill text, over '
      .int( BUDGET_BYTES / 1024 ).' kB'
    if $result->{size} > BUDGET_BYTES;
  return ( \@failures, \@warnings );
}

sub _spawn_header {
  my ( $self, $harness ) = @_;
  my $dont = $harness eq 'claude'
    ? 'do NOT call the Skill tool for any of these names'
    : 'do NOT go looking for their SKILL.md files';
  return '# Briefing '."\x{2014}".' pre-loaded skills'."\n\n"
    .'The skills below have been injected directly into your context by the'."\n"
    .'briefing plugin, one <skill> element each. Treat them as already loaded '."\x{2014}\n"
    .$dont.'; their content is already here. Only the SKILL.md body is'."\n"
    .'included: paths a skill mentions (references/, scripts/, '."\x{2026}"
    .') are relative to'."\n"
    .'its element\'s dir, so read them from there when you need them.'."\n\n";
}

sub _abort_context {
  my ( $self, $result ) = @_;
  return '# Briefing '."\x{2014}".' FAILED'."\n\n"
    .'The skills this agent declares could not be loaded: '
    .join( ', ', @{ $result->{missing} } ).'.'."\n\n"
    .'You are NOT briefed for this task. Do NOT attempt it and do NOT'."\n"
    .'improvise a substitute. Report this exact failure to whoever'."\n"
    .'delegated to you, and stop.'."\n";
}

sub _process_subagent_start {
  my ( $self, $payload ) = @_;
  my $agent = $payload->{agent_type};
  return ( undef, '' ) unless $self->_nonempty_string($agent);

  my $harness = $self->_spawn_harness( $payload, $agent );
  my $result = $self->brief_agent( $agent, harness => $harness );
  return ( undef, '' ) unless $result;

  my @notes = $result->{legacy} ? ($self->_legacy_note($result)) : ();
  if (@{ $result->{missing} }) {
    my $message = $self->_missing_note($result);
    return (
      {
        systemMessage      => join( "\n", $message, @notes ),
        hookSpecificOutput => {
          hookEventName     => 'SubagentStart',
          additionalContext => $self->_abort_context($result),
        },
      },
      $message."\n",
    );
  }

  push @notes, $self->_size_note($result)
    if $result->{size} > BUDGET_BYTES;
  my $stderr = @notes ? join( "\n", @notes )."\n" : '';
  return (
    {
      systemMessage      => join( "\n", $self->_audit_line($result), @notes ),
      hookSpecificOutput => {
        hookEventName     => 'SubagentStart',
        additionalContext => $self->_spawn_header($harness).$result->{text},
      },
    },
    $stderr,
  );
}

sub _process_guard {
  my ( $self, $payload ) = @_;
  my $tool_input = $payload->{tool_input};
  return ( undef, '' ) unless ref $tool_input eq 'HASH';
  my $agent = $tool_input->{subagent_type};
  return ( undef, '' ) unless $self->_nonempty_string($agent);

  my $result = $self->brief_agent( $agent, harness => 'claude' );
  return ( undef, '' ) unless $result && @{ $result->{missing} };
  my $message = $self->_missing_note($result);
  return (
    {
      hookSpecificOutput => {
        hookEventName            => 'PreToolUse',
        permissionDecision       => 'deny',
        permissionDecisionReason => $message,
      },
    },
    $message."\n",
  );
}

sub _harness_label {
  my ( $self, $harness ) = @_;
  return $harness eq 'claude' ? 'Claude Code' : 'Codex';
}

sub _process_session_start {
  my ( $self, $payload ) = @_;
  my $source = $payload->{source};
  return ( undef, '' )
    if defined $source && ($source ne 'startup' && $source ne 'resume');

  my @lines;
  for my $harness (@{ $self->_harnesses_for_payload($payload) }) {
    for my $result (@{ $self->check_agents( harness => $harness ) }) {
      my ( $failures ) = $self->_problems($result);
      push @lines, map {
        '  '.$self->_harness_label($harness)." agent '"
          .$result->{agent}."': ".$_
      } @{$failures};
    }
  }
  return ( undef, '' ) unless @lines;

  my @shown = @lines > 8 ? @lines[0 .. 7] : @lines;
  push @shown, '  '."\x{2026}".' and '.(@lines - @shown).' more'
    if @lines > @shown;
  return (
    {
      systemMessage => 'briefing: declared skills that will not work '."\x{2014}"
        .' run briefing-doctor for details'."\n".join( "\n", @shown ),
    },
    '',
  );
}

sub process_hook {
  my ( $self, $payload, %options ) = @_;
  my $empty = { output => undef, stderr => '', exit_code => 0 };
  return $empty unless ref $payload eq 'HASH';

  my $context = $self->_for_payload($payload);
  my ( $output, $stderr );
  my $event = defined $options{event}
    ? $options{event}
    : $payload->{hook_event_name};
  if ($context->_is_string($event) && $event eq 'SubagentStart') {
    ( $output, $stderr ) = $context->_process_subagent_start($payload);
  }
  elsif ($context->_is_string($event) && $event eq 'SessionStart') {
    ( $output, $stderr ) = $context->_process_session_start($payload);
  }
  elsif (
    $context->_is_string( $payload->{tool_name} )
    && $payload->{tool_name} eq 'Agent'
  ) {
    ( $output, $stderr ) = $context->_process_guard($payload);
  }
  else {
    return $empty;
  }

  return {
    output    => $output,
    stderr    => defined $stderr ? $stderr : '',
    exit_code => 0,
  };
}


sub _installed_marketplace {
  my ( $self ) = @_;
  my $root = $self->filesystem->environment_value('CLAUDE_PLUGIN_ROOT');
  return unless defined $root;
  # The components os.path.normpath gives hooks/briefing-marketplace-notice: "\" separates
  # only on Windows, "." is dropped and ".." folded lexically, so both stay silent alike.
  $root =~ tr{\\}{/} if $self->filesystem->is_windows;
  my $absolute = $root =~ m{\A/} ? 1 : 0;
  my @parts;
  for my $part (split m{/+}, $root) {
    next if $part eq '' || $part eq '.';
    if ($part eq '..') {
      if (@parts && $parts[-1] ne '..') {
        pop @parts;
        next;
      }
      next if $absolute;
    }
    push @parts, $part;
  }
  for my $index (0 .. $#parts - 1) {
    return $parts[$index + 1] if $parts[$index] eq 'cache';
  }
  return;
}

sub process_notice {
  my ( $self, $payload ) = @_;
  my $result = { output => undef, stderr => '', exit_code => 0 };
  my $marketplace = $self->_installed_marketplace;
  return $result unless defined $marketplace && $marketplace ne 'getty';

  my $state = $self->filesystem->join_path(
    $self->home,
    '.claude',
    '.briefing-marketplace-notice',
  );
  return $result if $self->filesystem->exists($state);

  my $parent = $self->filesystem->parent($state);
  $self->filesystem->make_path($parent);
  $self->filesystem->spew_utf8( $state, $marketplace."\n" );

  $result->{output} = {
    systemMessage => 'briefing is now also in the shared Getty marketplace, '
      .'alongside the other plugins: /plugin marketplace add Getty/marketplace '
      ."\x{2014}".' then /plugin install briefing@getty. Your install from Getty/briefing '
      .'keeps working and stays maintained, so there is nothing you have to do.',
  };
  return $result;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing - Preload declared skills into Claude Code and Codex subagents at spawn time

=head1 VERSION

version 0.006000

=head1 SYNOPSIS

Install the plugin in Claude Code:

    /plugin marketplace add Getty/marketplace
    /plugin install briefing@getty

or in Codex:

    codex plugin marketplace add Getty/marketplace
    codex plugin add briefing@getty

Declare the skills an agent needs, here in F<.claude/agents/reviewer.md>:

    ---
    name: reviewer
    description: Reviews a change and runs the tests
    briefing:
      skills:
        - code-style
        - superpowers:brainstorming
    ---

or as a comment line in a Codex agent's TOML file:

    # briefing: skills = ["code-style", "superpowers:brainstorming"]

Check every declaration of a project before anything spawns:

    briefing doctor --cwd ~/dev/shop

Or ask the library the same questions:

    use App::Briefing;

    my $briefing = App::Briefing->new( cwd => '/home/you/dev/shop' );

    my $result = $briefing->brief_agent( 'reviewer', harness => 'claude' );
    print "missing: @{ $result->{missing} }\n" if $result && @{ $result->{missing} };

    for my $agent (@{ $briefing->check_agents( harness => 'both' ) }) {
      printf "%s %s: %d bytes\n", $agent->{harness}, $agent->{agent}, $agent->{size};
    }

=head1 DESCRIPTION

briefing makes sure a subagent starts with the skills it needs. An agent
declares them; when Claude Code or Codex spawns it, briefing's hook puts the
full text of each declared skill into the agent's context, so it is briefed
before its first turn instead of being told in its prompt to go and load them.
If a declared skill cannot be found, nothing goes ahead on a partial briefing:
Claude Code refuses the spawn, and a Codex agent, which cannot be stopped at
that point, is told not to attempt the task and to report the failure.

Most people use briefing as a plugin, installed from the Getty marketplace as
shown above. Codex runs a plugin's hooks only after you trust them, and loads
a project's own agents only in a trusted project. The plugin's README covers
installation, the first agent and what each platform needs:
L<https://github.com/Getty/briefing>.

A Claude Code agent lists its skills under C<briefing.skills> in its
frontmatter, one C<- name> per line or as C<[a, b]> on one line. A Codex agent
carries one comment line, C<# briefing: skills = [...]>, outside any
multi-line string: Codex drops an agent file over any key it does not know, so
the declaration has to be a comment. An old C<[briefing]> table is still read,
and reported as a failure, because Codex 0.153 and later ignores the whole
agent over it.

Names resolve nearest first, where the harness itself looks. A bare name such
as C<code-style> comes, under Claude Code, from F<.claude/skills> in the
project, then F<~/.claude/skills>, then the skills of installed plugins that
are switched on in C<enabledPlugins>. Under Codex it comes from
F<.codex/skills> and F<.agents/skills> in the working directory and each parent
up to the repository root, then F<$CODEX_HOME/skills>, F<~/.agents/skills>,
F<$CODEX_HOME/skills/.system> and F</etc/codex/skills>, never from a plugin. A
namespaced name such as C<superpowers:brainstorming> goes straight to that
plugin: under Claude Code only to one that is installed and enabled, under
Codex to its plugin cache. Claude Code agents are the F<.md> files under
F<.claude/agents> in the project, then F<~/.claude/agents>, matched by their
C<name>; Codex agents are found by C<name> in any F<*.toml> under F<agents/>,
or through C<[agents.NAME] config_file>, in F<.codex> from the working
directory up to the repository root, then C<$CODEX_HOME>, then F</etc/codex>.

Each skill arrives as its own element holding the F<SKILL.md> body without its
frontmatter; C<dir> lets the agent read the skill's F<references/> and
F<scripts/> when it needs them, as they are not included:

    <skill name="code-style" dir="/home/you/dev/shop/.claude/skills/code-style">
    ...
    </skill>

Every briefing leaves you one audit line, such as
C<< briefing: reviewer E<0x2190> code-style, review-checklist (13 kB) >>, and a
second one when the skills add up to more than 64 kB; such a spawn still goes
ahead. When a session starts or resumes, the hook names every declaration of
that harness that would fail. C<briefing doctor> (see L<briefing>) shows the
whole picture for both harnesses and exits 1 when a spawn would fail, so it can
guard CI.

This distribution, App-Briefing, holds briefing's core: this library and the
command L<briefing>, which runs the hooks and the doctor. The plugin runs the
same core through its own launcher, as a prebuilt binary once a plugin version
pins one. Installing App-Briefing gives you the library and the command; it
does not install the plugin into Claude Code or Codex.

As a library, an App::Briefing object answers for one project. L</cwd>,
L</home> and L</codex_home> fix the context explicitly, so the answers do not
depend on the process's working directory, and the methods return data instead
of printing: L</brief_agent> and L</check_agents> for declarations,
L</process_hook> for a whole hook payload. Only L</process_notice> writes, its
one state file. L<App::Briefing::Team> builds the doctor's tab-separated team
findings on it, and L<App::Briefing::CLI> is the command's terminal side. The
attributes and methods follow.

=head2 filesystem

The filesystem adapter every file and environment read goes through. Defaults
to a new L<App::Briefing::Filesystem> object.

=head2 cwd

The project directory: agents and skills are looked up as a harness started
there would look them up. Defaults to C<PWD>, else the process's current
directory. Nothing changes the process's working directory.

=head2 home

The user's home directory, which holds F<.claude> and F<.agents>. Defaults to
C<HOME>; on Windows then C<USERPROFILE>, then C<HOMEDRIVE> plus C<HOMEPATH>;
then the home directory in the user's password entry; then the process's
current directory. An empty variable counts as unset.

=head2 codex_home

The Codex configuration directory. Defaults to C<CODEX_HOME>, else F<.codex>
below L</home>.

=head2 resolve_skill

    my $file = $briefing->resolve_skill('superpowers:brainstorming', harness => 'claude');

Returns the path of the F<SKILL.md> a spawn would be briefed with for one
declared skill name, or nothing when the name does not resolve. C<harness> is
C<claude> (the default) or C<codex>; each searches where that harness looks
(see L</DESCRIPTION>). The spawn hooks, the session-start check, the
doctor and L<App::Briefing::Team> all use this resolution.

=head2 skill_problem

    my $reason = $briefing->skill_problem('superpowers:brainstorming');

Returns a short reason why a skill name does not resolve under Claude Code,
such as C<plugin 'superpowers' is not installed and enabled>, or nothing when
it resolves.

=head2 claude_agent_skills

    my $skills = $briefing->claude_agent_skills($agent_file);

Returns an array reference of the C<briefing.skills> names declared in one
Claude Code agent file, read as the spawn hook reads them; empty when the file
declares none.

=head2 brief_agent

    my $result = $briefing->brief_agent('reviewer', harness => 'claude');

Resolves one agent's declaration for C<harness>, C<claude> or C<codex>
(required). Returns undef when that harness has no agent by that name or the
agent declares no skills, else a hash reference:

=over 4

=item *

C<agent>, C<path>, C<harness>

The agent's name, its file and the harness.

=item *

C<skills>

The declared names, in order.

=item *

C<missing>

The names that did not resolve.

=item *

C<text>

The C<< <skill> >> elements a spawn receives, without the header. Empty when
anything is missing: there is never a partial briefing.

=item *

C<size>

The UTF-8 size in bytes of the resolved skill text.

=item *

C<legacy>

True when a Codex agent declares its skills in a C<[briefing]> table.

=back

=head2 check_agents

    my $results = $briefing->check_agents(harness => 'both');

Returns an array reference with the L</brief_agent> result of every agent that
declares skills, for C<harness> C<claude>, C<codex> or C<both> (the default):
Claude Code first, each harness sorted by agent name. The doctor and the
session-start check report from it. Nothing is printed or written.

=head2 process_hook

    my $operation = $briefing->process_hook($payload);
    my $operation = $briefing->process_hook($payload, event => 'SubagentStart');

Answers one decoded hook payload as the plugin's hooks do. C<SubagentStart>
briefs the agent, or tells it to abort when a skill is missing; C<SessionStart>
reports the declarations that would fail; any other payload whose C<tool_name>
is C<Agent> goes to the Claude Code guard, which denies a spawn with a missing
skill; everything else has no answer. C<event> (C<SubagentStart>, C<PreToolUse>
or C<SessionStart>) takes the place of the payload's C<hook_event_name>, and a
C<cwd> in the payload applies to this call only.

Returns a hash reference with C<output> (the hook's JSON answer as a hash
reference, or undef for none), C<stderr> (text for standard error, possibly
empty) and C<exit_code> (0). Nothing is printed or written.

=head2 process_notice

    my $operation = $briefing->process_notice({});

Evaluates the one-time note that points installs from another marketplace at
the shared Getty marketplace, and returns the same hash as L</process_hook>.
The output is empty unless C<CLAUDE_PLUGIN_ROOT> lies in a marketplace cache
(C<.../cache/MARKETPLACE/...>) other than C<getty> and
F<.claude/.briefing-marketplace-notice> below L</home> does not exist yet.
Unlike L</process_hook>, this method writes: it creates that state file, so the
note appears once. A state file that cannot be written does not suppress the
note. It prints nothing itself.

=head1 SEE ALSO

=over

=item * L<briefing> - the command: hooks and the doctor

=item * L<App::Briefing::CLI> - argument parsing and output of the command

=item * L<App::Briefing::Team> - the findings of C<briefing doctor --tsv>

=item * L<App::Briefing::Filesystem> - environment access, and file access that is Unicode-safe on Windows

=item * L<https://github.com/Getty/briefing> - the plugin, its installation and its status

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/briefing/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
