# ABSTRACT: Shared board-level computations for the rendering commands

package App::karr::Board;
our $VERSION = '0.601';
use Moo;
use App::karr::Config;

has store => ( is => 'ro', required => 1 );


has _config => (
  is      => 'lazy',
  builder => sub {
    my ($self) = @_;
    return App::karr::Config->from_merged( $self->store->effective_config );
  },
);



sub final_status {
  my ($self) = @_;
  my @statuses = grep { $_ ne App::karr::Config->ARCHIVED_STATUS }
    $self->store->all_status_names;
  my ($final) = grep { $self->store->is_terminal_status($_) } @statuses;
  return $final;
}


sub hidden_done_count {
  my ( $self, $tasks ) = @_;
  my $final = $self->final_status;
  return 0 unless defined $final;
  return scalar grep { $_->status eq $final } @$tasks;
}


sub group_keys {
  my ( $self, $task, $field ) = @_;
  if ( $field eq 'assignee' ) {
    return $task->has_assignee && length $task->assignee
      ? ( $task->assignee ) : ('(unassigned)');
  }
  if ( $field eq 'tag' ) {
    return @{ $task->tags } ? @{ $task->tags } : ('(untagged)');
  }
  if ( $field eq 'class' ) {
    return ( $task->class || 'standard' );
  }
  if ( $field eq 'priority' ) {
    return ( $task->priority );
  }
  return ( $task->status );
}


sub group_order {
  my ( $self, $groups, $field ) = @_;
  my @keys = keys %$groups;
  if ( $field eq 'status' || $field eq 'priority' || $field eq 'class' ) {
    my @order = $field eq 'status'   ? $self->_config->statuses
              : $field eq 'priority' ? $self->_config->priorities
              :                       $self->_config->classes;
    my %index;
    $index{$order[$_]} //= $_ for 0 .. $#order;
    @keys = sort { ( $index{$a} // -1 ) <=> ( $index{$b} // -1 ) } @keys;
  } else {
    @keys = sort @keys;
  }
  return @keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Board - Shared board-level computations for the rendering commands

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    my $board = App::karr::Board->new( store => $store );
    my $final = $board->final_status;
    my $hidden = $board->hidden_done_count( \@tasks );
    my @keys = $board->group_keys( $task, 'assignee' );
    my @order = $board->group_order( \%groups, 'status' );

=head1 DESCRIPTION

The computations the two rendering commands share. L<App::karr::Cmd::Board>
and L<App::karr::Cmd::List> both answer "how many finished cards did the
default view hide" and both split a task list into C<--group-by> groups; the
answers live here so neither command can drift from the other.

=head2 final_status

    my $final = $board->final_status;

The board's final status -- the column the default views hide. C<archived> is
never the answer: it is not a column, and the callers that ask this question
have already dropped it from their status list.

=head2 hidden_done_count

    my $hidden = $board->hidden_done_count( \@tasks );

How many of C<@$tasks> sit in the board's final status -- the count the
default views withhold and their footers name. The caller decides which tasks
are in scope: C<board> drops the archive before asking, C<list> asks over
everything it loaded, and the same grep answers both.

=head2 group_keys

    my @keys = $board->group_keys( $task, 'tag' );

The group keys a task belongs to under C<--group-by FIELD>, matching
kanban-md's C<extractGroupKeys> (internal/board/group.go): C<assignee> falls
back to C<(unassigned)>, a task without tags to C<(untagged)> -- and one with
several tags appears in each of them -- C<class> to the board's default, and
C<priority> and C<status> to their own values.

=head2 group_order

    my @order = $board->group_order( \%groups, 'status' );

The group headings in display order, matching kanban-md's C<sortGroupKeys>
(internal/board/group.go): C<status>, C<priority> and C<class> follow the
board config's own order, C<assignee> and C<tag> are alphabetical. Note that
C<priority> groups read the config list forward here -- low to critical on a
default board -- where C<--sort priority> reads it backwards for pick
agreement; grouping and sorting are separate axes.

=head2 store

The L<App::karr::BoardStore> this board's computations run against --
C<final_status> and C<hidden_done_count> read the board's status list from
it, and C<group_order> reads its config-derived status, priority, and class
ordering. Required.

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
