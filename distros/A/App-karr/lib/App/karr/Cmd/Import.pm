# ABSTRACT: Import a tasks/ file view back into the ref-backed board

package App::karr::Cmd::Import;
our $VERSION = '0.400';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr import --yes [--dir PATH] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option yes => (
  is => 'ro',
  doc => 'Acknowledge destructive replacement of refs from the file view',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  die "Importing the file view replaces refs/karr/tasks/* and config from the tasks/ directory. Re-run with --yes.\n"
    unless $self->yes;

  # Guard against wiping every task ref when there is no view to import: a
  # missing tasks/ directory would make serialize_from delete all task refs.
  my $store     = $self->store;
  my $board_dir = $self->git_root;
  die "No materialized task view found at $board_dir (no tasks/ directory).\n"
    . "Run 'karr materialize' first, or place a tasks/ directory there before importing.\n"
    unless $board_dir->child('tasks')->exists;

  # Writing command: pull before, push after, with SyncGuard insurance.
  $self->sync_before;
  $store->serialize_from( $board_dir->stringify );
  $self->sync_after;

  my @tasks = $store->load_tasks;

  # The imported set is a task collection (like `list`), so --json always emits
  # an array -- never a bare object for a one-task board.
  return $self->print_json([ map { $_->to_json_hash } @tasks ]) if $self->json;

  printf STDERR "Imported %d task(s) from %s into refs/karr/*\n", scalar @tasks, $board_dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Import - Import a tasks/ file view back into the ref-backed board

=head1 VERSION

version 0.400

=head1 SYNOPSIS

    karr import --yes
    karr import --yes --dir path/to/repo
    karr import --yes --json

=head1 DESCRIPTION

Reads the file view at the repository root -- a F<config.yml> plus a F<tasks/>
directory of Markdown cards, as written by C<karr materialize> or by kanban-md
tooling -- back into the canonical C<refs/karr/*> board. Original task
timestamps are preserved verbatim, so importing an unchanged view is a no-op on
the C<updated> field.

This is the destructive inverse of C<karr materialize>: task refs are replaced
by the file view, and task refs with no matching file are deleted. It therefore
requires an explicit C<--yes> acknowledgement, and, because it mutates refs, it
pulls before and pushes after like the other writing commands.

=head1 OPTIONS

=over 4

=item * C<--yes>

Required acknowledgement for the destructive replacement of refs from files.

=item * C<--json>

Print the imported tasks as a JSON array instead of a human-readable summary.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Materialize>,
L<App::karr::Cmd::Restore>, L<App::karr::BoardStore>

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
