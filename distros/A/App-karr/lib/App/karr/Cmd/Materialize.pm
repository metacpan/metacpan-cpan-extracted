# ABSTRACT: Write the ref-backed board out as a tasks/ file view

package App::karr::Cmd::Materialize;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr materialize [--dir PATH] [--force] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option force => (
  is => 'ro',
  doc => 'Replace git-tracked config.yml / tasks cards at the destination',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  # Read-only: materialize reflects the current local refs into files, so it
  # syncs nothing (matching the reading commands list/show/board).
  my $store = $self->store;
  die "No karr board found. Run 'karr init' to create one.\n"
    unless $store->has_board_refs;

  # Asked before materialize_to runs, so the answer is about the working tree
  # as the project left it: with --force a tracked card the sweep is about to
  # delete is still on disk to be found, and none of the cards we are about to
  # write (all untracked) can be mistaken for the project's.
  my @owned = $store->project_owned_view_paths( $self->git_root->stringify );

  my $board_dir = $store->materialize_to(
    $self->git_root->stringify,
    force => $self->force,
  );

  # The file view we just wrote must never be committed; ensure the board-root
  # .gitignore covers it (idempotent -- a no-op once init or a prior run added
  # the entries). Done regardless of --json so the guard never depends on the
  # output format.
  #
  # Unless the project got there first, which is the one thing that stops it:
  # init already declines to claim paths the project tracks, and materialize
  # appending them anyway put back the exact untrue claim init had just refused
  # to make (tickets #89, #100). The entry would be inert -- git applies no
  # ignore rule to a tracked file -- so all it can do is mislead.
  my @ignored = @owned ? () : $store->ensure_gitignore( $self->git_root->stringify );

  my @tasks = $store->load_tasks;

  # The view is a task collection (like `list`), so --json always emits an
  # array -- never a bare object for a one-task board.
  return $self->print_json([ map { $_->to_json_hash } @tasks ]) if $self->json;

  printf STDERR "Materialized %d task(s) to %s\n", scalar @tasks, $board_dir;
  printf STDERR "Added .gitignore entries for the file view: %s\n", join( ', ', @ignored )
    if @ignored;
  printf STDERR "Left .gitignore alone: git already tracks content at %s.\n"
    . "Those paths belong to the project, not to karr's file view, so karr is not\n"
    . "claiming them here.\n", join( ', ', @owned )
    if @owned;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Materialize - Write the ref-backed board out as a tasks/ file view

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr materialize
    karr materialize --dir path/to/repo
    karr materialize --json
    karr materialize --force

=head1 DESCRIPTION

Writes the canonical C<refs/karr/*> board out to the repository root as a
kanban-md compatible file view: a F<config.yml> plus a F<tasks/> directory of
Markdown cards. The view is disposable and gitignored -- regenerate it whenever
you want to grep the board as files or hand it to kanban-md tooling. It is never
the source of truth, and writing through it only takes effect via C<karr import>.

The refs are read but never modified, so this command performs no remote sync.
Stale cards from a previous materialization -- the F<tasks/> files named the way
karr and kanban-md name them, C<NNN-slug.md> -- are removed before the current
tasks are written. Any other file in F<tasks/> is left alone.

F<tasks/> and F<config.yml> at a repository root are ordinary names for a
project to already use, so the command refuses to run at all when it would
overwrite or delete something Git tracks, and names every such path. Nothing is
written on that path. Pass C<--force> once you are sure those files are yours to
replace.

For the same reason the F<.gitignore> entries for the view are only topped up
when the project has nothing of its own at those paths -- the check C<karr init>
makes. Git applies no ignore rule to a file it already tracks, so an entry there
would be inert and would claim a path the project owns.

=head1 OPTIONS

=over 4

=item * C<--force>

Materialize even though git-tracked files at the destination will be
overwritten or deleted.

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
