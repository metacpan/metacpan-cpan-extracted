# ABSTRACT: Install, check, and update bundled agent skills

package App::karr::Cmd::Skill;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr skill [install|check|update|show] [--agent NAME] [--global] [--force]',
);
use App::karr::Role::Output;
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;
use App::karr::Role::SkillFile;
use App::karr::Error qw( user_error clean_error );
use Path::Tiny;

# ExitCodes: unknown option / bad option value exits 2, not 1 (ADR 0002). Skill
# is board-less, so it does not inherit ExitCodes via BoardDiscovery.
# SkillFile: _skill_content and _write_skill, shared with `karr init
# --claude-skill`, which writes the same file this command writes for the
# claude-code agent (tickets #145, #146).
with 'App::karr::Role::Output', 'App::karr::Role::CliArgs',
     'App::karr::Role::ExitCodes', 'App::karr::Role::SkillFile';


option agent => (
  is => 'ro',
  format => 's',
  doc => 'Target agent (claude-code, codex, cursor)',
);

option global => (
  is => 'ro',
  doc => 'Install/check globally (~/) instead of project-level',
);

option force => (
  is => 'ro',
  doc => 'Force reinstall even if current',
);

my %AGENTS = (
  'claude-code' => { project => '.claude/skills', global => '.claude/skills' },
  'codex'       => { project => '.agents/skills', global => '.codex/skills' },
  'cursor'      => { project => '.cursor/skills', global => '.cursor/skills' },
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my @pos    = $self->positional_args($args_ref);
  my $action = $pos[0] // 'install';
  $self->check_positional_args($args_ref, 1);   # only the action is a positional

  if ($action eq 'install') {
    $self->_install;
  } elsif ($action eq 'check') {
    $self->_check;
  } elsif ($action eq 'update') {
    $self->_update;
  } elsif ($action eq 'show') {
    $self->_show;
  } else {
    # Leading "Usage:" is what bin/karr's handler keys on to exit 2 rather than
    # 1 (ADR 0002: an invalid value is a usage error). Becomes a one-line swap
    # to Role::ExitCodes' usage_error once that lands (ticket #76).
    user_error( "Usage: karr skill [install|check|update|show]\n",
                "Unknown action: $action (use install, check, update, or show)" );
  }
}

sub _show {
  my ($self) = @_;
  my $content = $self->_skill_content;

  if ($self->json) {
    # Characters in, characters out, exactly like the plain branch below:
    # print_json goes through App::karr::Encoding::json_encode, which is the
    # character-level codec, and STDOUT's :encoding(UTF-8) layer does the one
    # and only encode. _skill_content is already decoded (slurp_utf8), so it
    # goes in untouched.
    return $self->print_json({ content => $content });
  }

  # Ticket #33 encoded here, because back then the rest of the CLI handed raw
  # octets to print and a layer on STDOUT would have double-encoded them.
  # Ticket #53 removed that premise: STDOUT now carries :encoding(UTF-8) and
  # every command prints characters, so _skill_content goes out as-is.
  # Encoding it again here would be the very double encode #33 was avoiding.
  print $content;
  return;
}

sub _install {
  my ($self) = @_;
  my @agents = $self->_target_agents;
  my $content = $self->_skill_content;
  my @results;

  for my $agent (@agents) {
    my $dir = $self->_skill_dir($agent);
    my $file = $dir->child('SKILL.md');

    if ($file->exists && !$self->force) {
      push @results, { agent => $agent, status => 'exists', path => "$file" };
      printf "%-12s already installed (use --force to reinstall)\n", $agent unless $self->json;
      next;
    }

    $self->_write_skill($file, $content);
    push @results, { agent => $agent, status => 'installed', path => "$file" };
    printf "%-12s installed to %s\n", $agent, $file unless $self->json;
  }

  if ($self->json) {
    $self->print_json(\@results);
  }
}

sub _check {
  my ($self) = @_;
  my @agents = $self->_target_agents;
  my $current = $self->_skill_content;
  my @results;
  my $outdated = 0;

  for my $agent (@agents) {
    my $file = $self->_skill_dir($agent)->child('SKILL.md');

    unless ($file->exists) {
      push @results, { agent => $agent, status => 'not installed' };
      printf "%-12s not installed\n", $agent unless $self->json;
      next;
    }

    my $installed = $self->_read_skill($file);
    if ($installed eq $current) {
      push @results, { agent => $agent, status => 'current' };
      printf "%-12s current\n", $agent unless $self->json;
    } else {
      push @results, { agent => $agent, status => 'outdated' };
      printf "%-12s outdated\n", $agent unless $self->json;
      $outdated++;
    }
  }

  if ($self->json) {
    $self->print_json(\@results);
  }

  exit(1) if $outdated;
}

sub _update {
  my ($self) = @_;
  my @agents = $self->_target_agents;
  my $content = $self->_skill_content;
  my @results;

  for my $agent (@agents) {
    my $file = $self->_skill_dir($agent)->child('SKILL.md');

    unless ($file->exists) {
      push @results, { agent => $agent, status => 'not installed' };
      printf "%-12s not installed (run 'karr skill install' first)\n", $agent unless $self->json;
      next;
    }

    my $installed = $self->_read_skill($file);
    if ($installed eq $content) {
      push @results, { agent => $agent, status => 'current' };
      printf "%-12s already current\n", $agent unless $self->json;
    } else {
      $self->_write_skill($file, $content);
      push @results, { agent => $agent, status => 'updated' };
      printf "%-12s updated\n", $agent unless $self->json;
    }
  }

  if ($self->json) {
    $self->print_json(\@results);
  }
}

# Path::Tiny raises Path::Tiny::Error objects that stringify with the call site
# appended ("mkpath failed for ...: Permission denied at .../Cmd/Skill.pm line
# NNN."), so an unwritable skill directory used to report a karr source
# location at the user. App::karr::Error reduces it to the one line that is
# actually about them (ticket #77).
sub _read_skill {
  my ($self, $file) = @_;
  my $content = eval { $file->slurp_utf8 };
  defined $content
    or user_error( "Could not read $file: ", clean_error($@) );
  return $content;
}

# _write_skill -- the in-place write, and why it has to be one -- lives in
# App::karr::Role::SkillFile, composed above: `karr init --claude-skill` writes
# the very same .claude/skills/karr/SKILL.md, and kept its own spew_utf8 copy of
# this rule until ticket #145 because the rule lived here (#142). _skill_content,
# which finds the bundled file in the first place, followed it there in #146 --
# it was duplicated in Cmd::Init down to the last line but one.

sub _target_agents {
  my ($self) = @_;
  if ($self->agent) {
    my @names = split /,/, $self->agent;
    for my $name (@names) {
      # --agent is a value MooX::Options cannot validate, so the usage error is
      # raised here; see the note on the unknown-action branch in execute.
      user_error( "Usage: karr skill --agent NAME[,NAME,...]\n",
                  "Unknown agent: $name (known: ", join( ', ', sort keys %AGENTS ), ")" )
        unless $AGENTS{$name};
    }
    return @names;
  }
  # Auto-detect: return agents whose directories exist, or all if none found
  my @detected;
  for my $name (sort keys %AGENTS) {
    my $dir = $self->_skill_dir($name)->parent;
    push @detected, $name if $dir->exists;
  }
  return @detected ? @detected : sort keys %AGENTS;
}

sub _skill_dir {
  my ($self, $agent) = @_;
  my $spec = $AGENTS{$agent} or die "Unknown agent: $agent\n";
  my $base = $self->global
    ? path($ENV{HOME})->child($spec->{global})
    : path('.')->child($spec->{project});
  return $base->child('karr');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Skill - Install, check, and update bundled agent skills

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr skill install
    karr skill install --agent codex,cursor
    karr skill check --global
    karr skill update --force
    karr skill show

=head1 DESCRIPTION

Installs and maintains the bundled C<karr> skill file for supported agent
clients. The command can target project-local directories or global skill
locations in the current user's home directory, which makes it useful both for
direct Perl installs and Docker-wrapped vendor usage.

Writes go into the target file B<in place>, keeping its inode, so a
F<SKILL.md> that is one link of a hardlink chain shared across projects stays
part of that chain instead of being silently broken out of it.

=head1 SUPPORTED AGENTS

The built-in agent targets are C<claude-code>, C<codex>, and C<cursor>. When
C<--agent> is omitted, the command auto-detects available client directories and
falls back to all known agents if nothing is detected.

=head1 ACTIONS

=over 4

=item * C<install>

Writes the current bundled skill file to the selected target locations.

=item * C<check>

Compares installed skill files with the bundled version and exits non-zero when
one or more targets are outdated.

=item * C<update>

Refreshes existing installed copies in place.

=item * C<show>

Prints the bundled skill content to standard output. With C<--json> the same
content is emitted as a JSON object under the C<content> key instead of raw
Markdown.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Init>,
L<App::karr::Cmd::Context>, L<App::karr::Cmd::Config>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
