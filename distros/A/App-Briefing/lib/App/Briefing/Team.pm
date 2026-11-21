package App::Briefing::Team;
# ABSTRACT: Findings about a project's Claude Code agent team

use Moo;
use JSON::MaybeXS ();
use namespace::clean;

our $VERSION = '0.006000';

has briefing => ( is => 'ro', required => 1 );


sub _trim {
  my ( $value ) = @_;
  $value = '' unless defined $value;
  $value =~ s/\A\s+//;
  $value =~ s/\s+\z//;
  return $value;
}

sub _unquote {
  my ( $value ) = @_;
  $value = _trim($value);
  if ($value =~ /\A"([^"]*)/) {
    return $1;
  }
  if ($value =~ /\A'([^']*)/) {
    return $1;
  }
  $value =~ s/[ \t]#.*\z//s;
  return _trim($value);
}

# Reads only the frontmatter, like the team check always did: the lines between
# a first line "---" (a BOM before it is fine) and the next "---".
sub _parse_agent {
  my ( $text ) = @_;
  my %agent = (
    frontmatter => 0,
    has_name    => 0,
    name        => '',
    description => 0,
    allowed     => 0,
    top_skills  => 0,
    bad_list    => 0,
  );
  $text = '' unless defined $text;
  $text =~ s/\A\x{FEFF}//;
  my @lines = split /\r?\n/, $text;
  return \%agent unless @lines && _trim( $lines[0] ) eq '---';
  $agent{frontmatter} = 1;
  shift @lines;

  my ( $mode, $briefing_indent ) = ( '', -1 );
  for my $line (@lines) {
    my $trimmed = _trim($line);
    last if $trimmed eq '---';
    next if $trimmed eq '' || $trimmed =~ /\A#/;

    if ($line =~ /\A[ \t]/) {
      if ($mode eq 'description') {
        $agent{description} = 1;
      }
      elsif ($mode eq 'briefing') {
        my ($indent) = $line =~ /\A([ \t]*)/;
        $briefing_indent = length $indent if $briefing_indent == -1;
        if (
          $trimmed =~ /\Askills:(.*)\z/s
          && length($indent) == $briefing_indent
        ) {
          my $value = _trim($1);
          $agent{bad_list} = 1
            if $value =~ /\A\[/ && $value !~ /\]/;
        }
      }
      next;
    }

    $mode = '';
    next unless $trimmed =~ /\A([^:]*):(.*)\z/s;
    my ( $key, $value ) = ( _trim($1), _trim($2) );
    if ($key eq 'name') {
      $agent{has_name} = 1;
      $agent{name} = _unquote($value);
    }
    elsif ($key eq 'description') {
      if ($value eq '' || $value =~ /\A[#>|]/) {
        $mode = 'description';
      }
      else {
        $agent{description} = 1 if length _unquote($value);
      }
    }
    elsif ($key eq 'allowed-tools') {
      $agent{allowed} = 1;
    }
    elsif ($key eq 'skills') {
      $agent{top_skills} = 1;
    }
    elsif ($key eq 'briefing') {
      ( $mode, $briefing_indent ) = ( 'briefing', -1 );
    }
  }
  return \%agent;
}

sub _agent_files {
  my ( $self ) = @_;
  my $fs = $self->briefing->filesystem;
  my $root = $fs->join_path( $self->briefing->cwd, '.claude', 'agents' );
  my @found;
  my @pending = ('');
  while (@pending) {
    my $relative = shift @pending;
    my $directory = length $relative ? $fs->join_path( $root, $relative ) : $root;
    for my $name (@{ $fs->children($directory) }) {
      my $child = length $relative ? $relative.'/'.$name : $name;
      my $path = $fs->join_path( $root, $child );
      if ($fs->is_dir($path)) {
        push @pending, $child;
      }
      elsif ($name =~ /\.md\z/ && ($fs->is_file($path) || $fs->is_dangling_symlink($path))) {
        push @found, [ $child, $path ];
      }
    }
  }
  return [ sort { $a->[0] cmp $b->[0] } @found ];
}

sub _finding {
  my ( $what, $status, $name, $text ) = @_;
  my @fields = map {
    my $field = defined $_ ? $_ : '';
    $field =~ s/\t/ /g;
    $field =~ s/\r//g;
    $field =~ s/\n/ /g;
    $field;
  } ( $what, $status, $name, $text );
  return { what => $fields[0], status => $fields[1], name => $fields[2], text => $fields[3] };
}

sub _check_agents {
  my ( $self, $findings ) = @_;
  my $briefing = $self->briefing;
  my $fs = $briefing->filesystem;
  my ( @agents, @pairs );

  for my $entry (@{ $self->_agent_files }) {
    my ( $relative, $path ) = @{$entry};
    my $base = $relative;
    $base =~ s{\A.*/}{};
    $base =~ s/\.md\z//;
    $base =~ s/\A\.local\.(?=.)//;

    if ($fs->is_dangling_symlink($path)) {
      push @{$findings},
        _finding( 'agent', 'warn', $relative, 'dangling symlink (Claude Code cannot load it)' );
      next;
    }
    my $agent = _parse_agent( $fs->slurp_utf8($path) );
    if (!$agent->{frontmatter}) {
      push @{$findings},
        _finding( 'agent', 'warn', $relative, 'no frontmatter (Claude Code does not load it)' );
      next;
    }
    push @agents, { name => $base, file => $relative };

    my $skills = $briefing->claude_agent_skills($path);
    my @problems;
    if (!$agent->{has_name} || !length $agent->{name}) {
      push @problems, [ 'missing', 'no name' ];
    }
    elsif ($agent->{name} ne $base) {
      push @problems,
        [ 'missing', "name '".$agent->{name}."' differs from the file name" ];
    }
    push @problems, [ 'missing', 'description is empty' ]
      unless $agent->{description};
    push @problems,
      [ 'missing', 'allowed-tools: ignored by Claude Code; use disallowedTools' ]
      if $agent->{allowed};
    if ($agent->{bad_list}) {
      push @problems, [
        'missing',
        'briefing.skills is not readable (keep the list on one line or use one "- name" per line)',
      ];
    }
    elsif (!@{$skills}) {
      push @problems, [ 'warn', 'no briefing' ];
    }
    push @problems, [ 'warn', 'skills: briefing reads only briefing.skills' ]
      if $agent->{top_skills};

    if (@problems) {
      push @{$findings}, _finding( 'agent', $_->[0], $relative, $_->[1] )
        for @problems;
    }
    else {
      push @{$findings}, _finding( 'agent', 'ok', $relative, '' );
    }
    push @pairs, [ $relative, $_ ] for @{$skills};
  }

  push @{$findings}, _finding( 'agent', 'missing', '.claude/agents', 'no agent files' )
    unless @agents;

  my %seen;
  for my $pair (@pairs) {
    my $skill = $pair->[1];
    next if $seen{$skill}++;
    my $reason = $briefing->skill_problem($skill);
    if (!defined $reason) {
      push @{$findings}, _finding( 'skill', 'ok', $skill, '' );
      next;
    }
    for my $other (grep { $_->[1] eq $skill } @pairs) {
      push @{$findings}, _finding(
        'skill',
        'missing',
        $skill,
        $other->[0].' declares it; '.$reason.'; briefing would refuse the spawn',
      );
    }
  }
  return \@agents;
}

sub _check_hooks {
  my ( $self, $findings, $agents ) = @_;
  return unless @{$agents};
  my $briefing = $self->briefing;
  # Same role match as ack-team: NAME-worker or NAME-worker-SUFFIX; else the first agent.
  my ($worker) = grep { $_->{name} =~ /-worker(?:-.+)?\z/s } @{$agents};
  $worker = $agents->[0] unless $worker;

  for my $agent (@{$agents}) {
    my $name = $agent->{name};
    my $guard = $briefing->process_hook(
      {
        hook_event_name => 'PreToolUse',
        session_id      => 'briefing-doctor',
        cwd             => $briefing->cwd,
        tool_name       => 'Agent',
        tool_input      => { subagent_type => $name, description => 'check' },
      },
    );
    my $decision = ref $guard->{output} eq 'HASH'
      ? $guard->{output}{hookSpecificOutput}
      : undef;
    if (ref $decision eq 'HASH' && ( $decision->{permissionDecision} // '' ) eq 'deny') {
      push @{$findings}, _finding(
        'hook', 'missing', $name,
        length( $decision->{permissionDecisionReason} // '' )
          ? $decision->{permissionDecisionReason}
          : 'the hook denied the spawn',
      );
      next;
    }
    next unless $agent == $worker;

    my $start = $briefing->process_hook(
      {
        hook_event_name => 'SubagentStart',
        session_id      => 'briefing-doctor',
        cwd             => $briefing->cwd,
        agent_type      => $name,
      },
    );
    my $context = ref $start->{output} eq 'HASH'
      && ref $start->{output}{hookSpecificOutput} eq 'HASH'
      ? $start->{output}{hookSpecificOutput}{additionalContext}
      : undef;
    $context = '' unless defined $context;
    if ($context =~ /could not be loaded: (.*?)\.\n/s) {
      push @{$findings}, _finding(
        'hook', 'missing', $name,
        'the hook reports skills that could not be loaded: '.$1,
      );
    }
    elsif (length $context) {
      push @{$findings}, _finding( 'hook', 'ok', $name, '' );
    }
    else {
      push @{$findings}, _finding( 'hook', 'warn', $name, 'the hook briefs nothing for this agent' );
    }
  }
  return;
}

sub _check_settings {
  my ( $self, $findings ) = @_;
  my $fs = $self->briefing->filesystem;
  my $name = '.claude/settings.json';
  my $file = $fs->join_path( $self->briefing->cwd, '.claude', 'settings.json' );
  if (!$fs->is_readable_file($file)) {
    push @{$findings}, _finding( 'settings', 'missing', $name, 'not found or not readable' );
    return;
  }
  my $settings = eval {
    JSON::MaybeXS->new( utf8 => 0 )->decode( $fs->slurp_utf8($file) );
  };
  if (ref $settings ne 'HASH') {
    push @{$findings}, _finding(
      'settings', 'missing', $name,
      'the settings file is not a valid JSON object. Correct the JSON syntax and run briefing doctor again.',
    );
    return;
  }

  my $enabled = ref $settings->{enabledPlugins} eq 'HASH' ? $settings->{enabledPlugins} : {};
  my $markets = ref $settings->{extraKnownMarketplaces} eq 'HASH'
    ? $settings->{extraKnownMarketplaces}
    : {};
  my ( $bad, $briefing ) = ( 0, 0 );
  for my $key (sort keys %{$enabled}) {
    my $value = $enabled->{$key};
    next unless JSON::MaybeXS::is_bool($value) && $value;
    $briefing = 1 if $key =~ /\Abriefing@/;
    next unless $key =~ /\@([^@]*)\z/;
    my $market = $1;
    next if $market eq 'claude-plugins-official' || exists $markets->{$market};
    push @{$findings}, _finding(
      'settings', 'missing', $key,
      "marketplace '".$market."' is not in extraKnownMarketplaces",
    );
    $bad = 1;
  }
  if (!$briefing) {
    push @{$findings}, _finding(
      'settings', 'missing', 'briefing',
      'the briefing plugin is not enabled in enabledPlugins',
    );
    $bad = 1;
  }
  push @{$findings}, _finding( 'settings', 'ok', $name, '' ) unless $bad;
  return;
}

sub findings {
  my ( $self ) = @_;
  my @findings;
  my $agents = $self->_check_agents( \@findings );
  $self->_check_settings( \@findings );
  $self->_check_hooks( \@findings, $agents );
  return \@findings;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing::Team - Findings about a project's Claude Code agent team

=head1 VERSION

version 0.006000

=head1 DESCRIPTION

The findings behind C<briefing doctor --tsv>, for tools that check a project's
Claude Code agent team. It reads the F<.md> files under the project's
F<.claude/agents>, subdirectories included, and reports:

=over 4

=item *

C<agent>

Per agent file: C<missing> for no C<name> or one that differs from the file
name, an empty C<description>, an C<allowed-tools> key (Claude Code ignores
it), or a C<briefing.skills> list that cannot be read; C<warn> for a file
without frontmatter, a dangling symlink, an agent without a briefing, or a
top-level C<skills:>; else C<ok>. When no agent file has frontmatter, one
C<missing> finding says so.

=item *

C<skill>

Each declared skill once: C<ok>, or C<missing> for every agent that declares it,
with the reason it does not resolve.

=item *

C<settings>

F<.claude/settings.json>: C<missing> when it cannot be read or is not a JSON
object, when an enabled plugin's marketplace (other than
C<claude-plugins-official>) is not in C<extraKnownMarketplaces>, or when
briefing is not enabled; else C<ok>.

=item *

C<hook>

What the hooks answer: C<missing> for every agent the guard would deny; for
one agent, the first whose name ends in C<-worker> or C<-worker-SUFFIX> (else
the first agent), also the briefing at spawn: C<ok>, C<missing> when skills
could not be loaded, C<warn> when it briefs nothing. When the guard denies that
agent, its deny is the only C<hook> finding for it and the spawn briefing is not
checked for any agent.

=back

Skills resolve through L<App::Briefing/resolve_skill> and the hook answers come
from L<App::Briefing/process_hook>, so the findings come from the same code a
real spawn runs.

=head2 briefing

The L<App::Briefing> context whose C<cwd> names the project. Skill resolution
and the hook simulation go through it, so the findings come from the same code
as a real spawn.

=head2 findings

    my $findings = App::Briefing::Team->new( briefing => $briefing )->findings;

Returns an array reference of findings, each a hash with C<what> (C<agent>,
C<skill>, C<settings> or C<hook>, in that order), C<status> (C<ok>, C<missing>
or C<warn>), C<name> and C<text>. Tabs and line ends in the fields become
spaces, so each finding is one TSV row. Nothing is printed or changed.

=head1 SEE ALSO

=over

=item * L<briefing> - C<briefing doctor --tsv> prints these findings

=item * L<App::Briefing>

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
