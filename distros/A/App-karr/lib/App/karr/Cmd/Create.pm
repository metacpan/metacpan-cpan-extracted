# ABSTRACT: Create a new task

package App::karr::Cmd::Create;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr create --title TEXT [--priority LEVEL] [--status STATUS] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::DependencyArgs;
use App::karr::Task;
use App::karr::Config;

# The set-time half only (ticket #137). A card that does not exist yet cannot be
# taken up, so create never has a dependency warning to emit and must not
# inherit the emitting half -- which is also the half that would require a
# --json create has not got.
with 'App::karr::Role::BoardAccess', 'App::karr::Role::DependencyArgs';


option title => (
  is => 'ro',
  format => 's',
  doc => 'Task title',
);

option status => (
  is => 'ro',
  format => 's',
  doc => 'Initial status',
);

option priority => (
  is => 'ro',
  format => 's',
  doc => 'Priority level',
);

option assignee => (
  is => 'ro',
  format => 's',
  doc => 'Person assigned',
);

option tags => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated tags',
);

option due => (
  is => 'ro',
  format => 's',
  doc => 'Due date (YYYY-MM-DD)',
);

option estimate => (
  is => 'ro',
  format => 's',
  doc => 'Time estimate',
);

option depends_on => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated ids of tasks this one depends on',
);

option class => (
  is => 'ro',
  format => 's',
  doc => 'Class of service',
);

option body => (
  is => 'ro',
  format => 's',
  doc => 'Task description',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $title = $self->title // $pos[0]
    or die "Title is required. Use --title or pass as argument.\n";

  my $ec = $self->store->effective_config;
  my $defaults = $ec->{defaults} // {};
  my $config = App::karr::Config->from_merged($ec);

  # Validate before allocating an id, so a rejected create does not burn one
  # (ticket #54).
  $config->validate_status( $self->status )     if defined $self->status;
  $config->validate_priority( $self->priority ) if defined $self->priority;
  $config->validate_class( $self->class )       if defined $self->class;
  App::karr::Config->validate_due( $self->due ) if defined $self->due;

  # Set-time dependency validation (ticket #124), under the same #54 rule.
  # A self-reference is not expressible here: the new id does not exist until
  # it is allocated below, and every dependency must already exist, so no
  # dependency can equal it. length, not truth (ticket #78).
  my $depends_on;
  if ( defined $self->depends_on && length $self->depends_on ) {
    $depends_on = $self->parse_dependency_ids( '--depends-on', $self->depends_on );
    $self->assert_dependencies_exist($depends_on);
  }

  my %task_args = (
    id       => $self->allocate_next_id,
    title    => $title,
    status   => $self->status   // $defaults->{status}   // 'backlog',
    priority => $self->priority // $defaults->{priority}  // 'medium',
    class    => $self->class    // $defaults->{class}     // 'standard',
  );

  # length, not truth: a literal "0" is a meaningful assignee, tag, due or
  # estimate (ticket #153, extending ticket #78's rule from --body to its
  # siblings). --depends_on was already on the #78 pattern (see above).
  $task_args{assignee}   = $self->assignee   if defined $self->assignee   && length $self->assignee;
  $task_args{tags}       = [split /,/, $self->tags] if defined $self->tags && length $self->tags;
  $task_args{depends_on} = $depends_on if $depends_on;
  $task_args{due}        = $self->due        if defined $self->due        && length $self->due;
  $task_args{estimate}   = $self->estimate   if defined $self->estimate   && length $self->estimate;
  # length, not truth: --body 0 is a body (ticket #78).
  $task_args{body}       = $self->body if defined $self->body && length $self->body;

  my $task = App::karr::Task->new(%task_args);
  $self->save_task($task);

  $self->sync_after;

  printf "Created task %d: %s\n", $task->id, $task->title;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Create - Create a new task

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr create "Fix login bug"
    karr create --title "Write release notes" --priority high --status todo
    karr create --title "Review API" --tags docs,review --body "Check CLI help"
    karr create "Ship it" --depends-on 2,3

=head1 DESCRIPTION

Creates a new task in the ref-backed board. The new task inherits defaults from
the materialized board config and can be seeded with metadata such as priority,
class of service, due date, tags, and body text.

=head1 OPTIONS

=over 4

=item * C<--title>

Explicit task title. If omitted, the first positional argument is used.

=item * C<--status>, C<--priority>, C<--class>

Override the configured default lifecycle values for the new task.

=item * C<--assignee>, C<--tags>, C<--due>, C<--estimate>

Populate optional frontmatter fields at creation time.

=item * C<--depends-on>

Comma-separated ids of tasks this one depends on, same shape as C<--tags>.
Every id must name a task on this board; an unknown or non-numeric id rejects
the create as a usage error before an id is allocated, so nothing is burned
(ticket #54). Taking the new card up while a dependency is unfinished warns --
see L<App::karr::Cmd::Move>.

=item * C<--body>

Adds Markdown body text below the YAML frontmatter.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Move>

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
