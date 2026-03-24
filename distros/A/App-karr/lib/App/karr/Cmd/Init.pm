# ABSTRACT: Initialize a new karr board

package App::karr::Cmd::Init;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr init [--name TEXT] [--statuses LIST] [--claude-skill]',
);
use Path::Tiny;
use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;


option name => (
  is => 'ro',
  format => 's',
  doc => 'Board name',
);

option statuses => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated status list',
);

option claude_skill => (
  is => 'ro',
  doc => 'Install Claude Code skill for karr',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my $git = App::karr::Git->new( dir => '.' );
  die "Not a git repository. karr requires Git.\n" unless $git->is_repo;

  my $root = $git->repo_root;
  my $store = App::karr::BoardStore->new( git => App::karr::Git->new( dir => $root->stringify ) );
  die "Board already exists in refs/karr/\n" if $store->board_exists;

  my $overrides = { version => 1 };
  $overrides->{board} = { name => $self->name } if defined $self->name;

  if ($self->statuses) {
    my @statuses = split /,/, $self->statuses;
    $overrides->{statuses} = \@statuses;
  }

  my $effective = App::karr::Config->effective_config($overrides);
  $store->save_config($effective);
  $store->set_next_id(1);

  print "Initialized karr board in refs/karr/\n";

  if ($self->claude_skill) {
    $self->_install_claude_skill($root);
  }
}

sub _install_claude_skill {
  my ($self, $root) = @_;
  my $skill_dir = $root->child('.claude/skills/karr');
  $skill_dir->mkpath;

  my $skill_content = $self->_find_skill_source;
  $skill_dir->child('SKILL.md')->spew_utf8($skill_content);
  print "Installed Claude Code skill to .claude/skills/karr/SKILL.md\n";
}

sub _find_skill_source {
  my ($self) = @_;

  # Try File::ShareDir (installed dist)
  my $installed = eval {
    require File::ShareDir;
    my $dir = File::ShareDir::dist_dir('App-karr');
    my $file = path($dir)->child('claude-skill.md');
    $file->slurp_utf8 if $file->exists;
  };
  return $installed if defined $installed && length $installed;

  # Fallback: relative to module location (development)
  my $module_path = $INC{'App/karr/Cmd/Init.pm'};
  if ($module_path) {
    my $share = path($module_path)->parent(5)->child('share/claude-skill.md');
    return $share->slurp_utf8 if $share->exists;
  }

  die "Could not find claude-skill.md. Is App::karr properly installed?\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Init - Initialize a new karr board

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr init --name "My Project"
    karr init --statuses backlog,todo,in-progress,review,done
    karr init --name "Client Work" --claude-skill

=head1 DESCRIPTION

Creates a new board inside C<refs/karr/*> in the current Git repository. The
command writes the initial config and metadata refs and can optionally install
the bundled Claude Code skill into the repository.

=head1 OPTIONS

=over 4

=item * C<--name>

Sets the board name stored in C<board.name>.

=item * C<--statuses>

Replaces the default status list with the comma-separated statuses you supply.

=item * C<--claude-skill>

Copies the bundled skill file to F<.claude/skills/karr/SKILL.md>.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Config>,
L<App::karr::Cmd::Create>, L<App::karr::Cmd::Skill>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
