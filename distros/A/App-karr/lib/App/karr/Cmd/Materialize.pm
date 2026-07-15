# ABSTRACT: Write the ref-backed board out as a tasks/ file view

package App::karr::Cmd::Materialize;
our $VERSION = '0.401';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr materialize [--dir PATH] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  # Read-only: materialize reflects the current local refs into files, so it
  # syncs nothing (matching the reading commands list/show/board).
  my $store = $self->store;
  die "No karr board found. Run 'karr init' to create one.\n"
    unless $store->board_exists;

  my $board_dir = $store->materialize_to( $self->git_root->stringify );

  # The file view we just wrote must never be committed; ensure the board-root
  # .gitignore covers it (idempotent -- a no-op once init or a prior run added
  # the entries). Done regardless of --json so the guard never depends on the
  # output format.
  my @ignored = $store->ensure_gitignore( $self->git_root->stringify );

  my @tasks = $store->load_tasks;

  # The view is a task collection (like `list`), so --json always emits an
  # array -- never a bare object for a one-task board.
  return $self->print_json([ map { $_->to_json_hash } @tasks ]) if $self->json;

  printf STDERR "Materialized %d task(s) to %s\n", scalar @tasks, $board_dir;
  printf STDERR "Added .gitignore entries for the file view: %s\n", join( ', ', @ignored )
    if @ignored;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Materialize - Write the ref-backed board out as a tasks/ file view

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    karr materialize
    karr materialize --dir path/to/repo
    karr materialize --json

=head1 DESCRIPTION

Writes the canonical C<refs/karr/*> board out to the repository root as a
kanban-md compatible file view: a F<config.yml> plus a F<tasks/> directory of
Markdown cards. The view is disposable and gitignored -- regenerate it whenever
you want to grep the board as files or hand it to kanban-md tooling. It is never
the source of truth, and writing through it only takes effect via C<karr import>.

The refs are read but never modified, so this command performs no remote sync.
Stale F<tasks/*.md> files from a previous materialization are removed before the
current tasks are written.

=head1 OPTIONS

=over 4

=item * C<--json>

Print the materialized tasks as a JSON array instead of a human-readable
summary.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Import>, L<App::karr::BoardStore>,
L<App::karr::Task>

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
