# ABSTRACT: Fetch helper payloads from a Git ref

package App::karr::Cmd::GetRefs;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr get-refs REF',
);
use App::karr::Git;
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;

# Unknown option / bad option value exits 2, not 1 (ADR 0002 exit-code
# contract). This board-less command has no BoardDiscovery to inherit it from.
with 'App::karr::Role::CliArgs', 'App::karr::Role::ExitCodes';

# Declared locally rather than inherited from App::karr::Role::BoardDiscovery:
# this command deliberately has no board, it only needs the discovery seed to
# find the repository the helper ref lives in. Both documented placements now
# work (ticket #71): `karr get-refs REF --dir PATH` binds this option, while
# `karr --dir PATH get-refs REF` leaves --dir on the root and is adopted from
# the MooX::Cmd command_chain in execute(). Declaring it with format=s is also
# what lets positional_args skip `--dir PATH` instead of reading the path as
# the ref.
option dir => (
  is        => 'ro',
  format    => 's',
  doc       => 'Path used as the starting point for Git repository discovery',
  predicate => 1,
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my ($ref_input) = $self->positional_args($args_ref);
  die "Usage: karr get-refs REF\n" unless defined $ref_input;

  my $repo_dir = '.';
  if ($self->has_dir) {
    $repo_dir = $self->dir;
  }
  elsif ($chain_ref && @$chain_ref) {
    my $root = $chain_ref->[0];
    if ($root && $root->can('has_dir') && $root->has_dir) {
      $repo_dir = $root->dir;
    }
  }

  my $git = App::karr::Git->new(dir => $repo_dir);
  die "Not a git repository.\n" unless $git->is_repo;

  my $ref = $git->validate_helper_ref($ref_input);
  $git->pull_ref($ref) or die "Failed to fetch $ref\n";

  # read_ref cannot tell "absent" from "present but empty" -- it answers '' for
  # both -- so ask before reading. Without this the command reported success and
  # printed one empty line for a ref that does not exist, which turns the
  # documented `karr get-refs spec.md > spec.md` shape into silent data loss
  # (ticket #74). A runtime failure, so exit 1 per ADR 0002. Checked after
  # pull_ref so a ref that only exists on the remote is fetched first.
  die "Ref $ref not found\n" unless $git->ref_exists($ref);

  my $content = $git->read_ref($ref);
  print STDERR "Fetched $ref\n";
  print $content;
  print "\n" unless $content =~ /\n\z/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::GetRefs - Fetch helper payloads from a Git ref

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr get-refs superpowers/spec/1234.md
    karr get-refs refs/superpowers/spec/1234.md
    karr get-refs superpowers/spec/1234.md --dir /path/to/repo

=head1 DESCRIPTION

Fetches a single helper ref from the remote and prints only its payload to
standard output. Informational messages go to standard error so the command can
be composed into scripts or agent pipelines.

A ref that does not exist is a runtime failure: nothing is written to standard
output and the command exits C<1>, so C<< karr get-refs spec.md > spec.md >>
cannot silently truncate its own target. A ref that exists but carries an empty
payload is still a success.

C<--dir> names the starting point for Git repository discovery and works both
before the command (C<karr --dir PATH get-refs REF>) and after it.

This is especially useful for AI-oriented workflows that want shared spec or
planning blobs without coupling them to the task board itself.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::SetRefs>,
L<App::karr::Cmd::Backup>, L<App::karr::Git>

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
