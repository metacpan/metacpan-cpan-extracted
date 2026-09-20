# ABSTRACT: Store helper payloads in a Git ref

package App::karr::Cmd::SetRefs;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr set-refs REF CONTENT... (CONTENT omitted: read stdin)',
);
use App::karr::Encoding qw( from_octets );
use App::karr::Git;
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;

# Unknown option / bad option value exits 2, not 1 (ADR 0002 exit-code
# contract). This board-less command has no BoardDiscovery to inherit it from.
with 'App::karr::Role::CliArgs', 'App::karr::Role::ExitCodes';

# Declared locally rather than inherited from App::karr::Role::BoardDiscovery:
# this command deliberately has no board, it only needs the discovery seed to
# find the repository the helper ref is written into. Both documented
# placements now work (ticket #71): `karr set-refs REF TEXT --dir PATH` binds
# this option, while `karr --dir PATH set-refs REF TEXT` leaves --dir on the
# root and is adopted from the MooX::Cmd command_chain in execute(). Declaring
# it with format=s is also what keeps `--dir PATH` out of the joined payload.
option dir => (
  is        => 'ro',
  format    => 's',
  doc       => 'Path used as the starting point for Git repository discovery',
  predicate => 1,
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  my ($ref_input, @content_parts) = $self->positional_args($args_ref);
  die "Usage: karr set-refs REF CONTENT...\n" unless defined $ref_input;

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

  # for_write: a helper ref may be read from every namespace it may not be
  # written to. refs/karr-foundation/chain/ and .../log/ are karr-foundation's
  # own structured state, and this command writes last-writer-wins with its
  # arguments joined by a space, which is not how a chain step is updated.
  my $ref = $git->validate_helper_ref( $ref_input, for_write => 1 );

  # Arguments join with a space -- one line, which is what a hint or a status
  # word is. A document is not that shape, and handing one over the obvious way
  # (a heredoc, an unquoted paste) used to collapse every newline into a space
  # and store the result without a word (#195). Reading stdin when there is
  # nothing to join is the addition that costs no existing caller anything:
  # that argv shape was a usage error before, so no invocation that worked
  # changes meaning -- whereas joining with newlines instead would silently
  # rewrite the payload of every multi-word call, including the one this
  # command's own SYNOPSIS, the README and the packaged skill all teach.
  my $content = @content_parts
    ? join( ' ', @content_parts )
    : $self->_payload_from_stdin;

  $git->write_ref($ref, $content) or die "Failed to write $ref\n";
  $git->push_ref($ref) or die "Failed to push $ref\n";

  print STDERR "Stored $ref\n";
}

# The payload as it arrives on stdin, as characters.
#
# STDIN is the one input edge App::karr::Encoding leaves without a PerlIO layer
# (App::karr::Cmd::Restore reads it the same way), so the decode is explicit and
# happens exactly once.
sub _payload_from_stdin {
  my ($self) = @_;

  # A terminal has nothing queued and would just sit there with no prompt, so
  # the shape that was a usage error before stays one instead of becoming a
  # hang.
  die "Usage: karr set-refs REF CONTENT...\n" if -t STDIN;

  binmode STDIN, ':raw';
  my $content = do { local $/; <STDIN> };

  # An empty stdin is not an empty payload: `karr set-refs REF < /dev/null`, or
  # a generator upstream that produced nothing, is a mistake, and storing '' for
  # it would report success. The deliberate way to store an empty payload is
  # still `karr set-refs REF ""`. A runtime failure (exit 1) rather than a usage
  # error, on the same reading as App::karr::Cmd::Restore's empty stdin: the
  # invocation was right, what arrived on the pipe was not.
  die "No payload on stdin. Pass CONTENT as arguments or pipe a payload in.\n"
    unless defined $content && length $content;

  return from_octets($content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::SetRefs - Store helper payloads in a Git ref

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr set-refs superpowers/spec/1234.md draft ready
    karr set-refs refs/superpowers/spec/1234.md "full payload"
    karr set-refs superpowers/spec/1234.md < design.md
    karr set-refs superpowers/spec/1234.md "payload" --dir /path/to/repo

=head1 DESCRIPTION

Writes a helper payload into a free-form Git ref outside the protected board
namespace. This is intended for adjunct workflow data such as AI planning
artifacts or coordination hints that should sync through Git without becoming a
task card.

The payload is every argument after C<REF>, joined with a single space. That is
a one-line shape on purpose, and it is the whole payload: a multi-line document
handed over as several arguments would come back as one long line. So a
document is piped instead -- with no C<CONTENT> argument at all the payload is
read from standard input verbatim, newlines and all, and
C<< karr set-refs REF E<lt> file >> round-trips through
C<< karr get-refs REF E<gt> file >>. Stdin is only read when there is nothing
to join, so an argument form that worked before is untouched, and a bare
C<karr set-refs REF> at a terminal is still the usage error it always was
rather than a command that sits there waiting.

Like the rest of the Perl CLI, this works fine from a local install, and the
same command can be run from the Docker wrapper if you prefer the vendored
runtime style described in the README.

C<--dir> names the starting point for Git repository discovery and works both
before the command (C<karr --dir PATH set-refs REF TEXT>) and after it.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::GetRefs>,
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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
