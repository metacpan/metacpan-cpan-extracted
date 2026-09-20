# ABSTRACT: Create a new task

package App::karr::Cmd::Create;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr create --title TEXT [--priority LEVEL] [--status STATUS] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::DependencyArgs;
use App::karr::Role::Output;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use App::karr::CrossBoard;
use App::karr::Error qw( user_error require_claim_message );
use Time::Piece;

# The set-time half only (ticket #137). A card that does not exist yet cannot be
# taken up, so create never has a dependency warning to emit and must not
# inherit the emitting half -- the half that would also require --quiet, which
# create does not take (ticket #137).
with 'App::karr::Role::BoardAccess', 'App::karr::Role::DependencyArgs',
     'App::karr::Role::Output', 'App::karr::Role::ClaimDefault';


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

option needs => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated BOARD#ID this task waits on in another repository',
);

option escalated_from => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated BOARD#ID this task was escalated from',
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

option claim => (
  is => 'ro',
  format => 's',
  doc => 'Claim task for an agent',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);

  # A title given twice is a contradiction, not a preference: the two spellings
  # can hold different strings, and `create TITLE --title OTHER` used to take
  # --title and drop the positional without a word (ticket #235). kanban-md
  # refuses that invocation (resolveCreateTitle, cmd/create.go:113-121,
  # InvalidInput), and karr answers a self-contradicting invocation that way one
  # command over already (the --claim/--release guard in App::karr::Cmd::Edit).
  # Before the required-title guard below, so a caller who named two titles is
  # told that, not that one is missing.
  #
  # length, not truth, on both halves: `--title 0` and a bare `0` are titles
  # that were given, and an empty one is no title at all -- the same rule the
  # guard below reads (ticket #230).
  $self->usage_error('title provided both as an argument and with --title; use one or the other')
      if ( defined $self->title && length $self->title )
      && ( defined $pos[0] && length $pos[0] );

  # length, not truth: "0" is one character long and a perfectly good title,
  # but the assignment below yields it as a false value, so both `--title 0`
  # and a bare positional `0` were rejected as "Title is required" -- the one
  # guard in this file ticket #153 left on truth while converting the options
  # below. kanban-md's resolveCreateTitle tests the flag against "" and the
  # args against length, and takes "0" (ticket #230).
  my $title = $self->title // $pos[0];
  die "Title is required. Use --title or pass as argument.\n"
    unless defined $title && length $title;

  my $ec = $self->store->effective_config;
  my $defaults = $ec->{defaults} // {};
  my $config = App::karr::Config->from_merged($ec);

  # Validate before allocating an id, so a rejected create does not burn one
  # (ticket #54).
  $config->validate_status( $self->status )     if defined $self->status;
  $config->validate_priority( $self->priority ) if defined $self->priority;
  $config->validate_class( $self->class )       if defined $self->class;
  App::karr::Config->validate_due( $self->due ) if defined $self->due;

  # A card that lands in a require_claim column with no owner is the state
  # `karr move` refuses to create (Role::TaskMutation/apply_status_change), and
  # create must not be the door that walks around it (ticket #270). The default
  # status is deliberately not consulted: a board whose default column needs a
  # claim is a board that says so, and create without --status keeps its
  # historical behaviour. The suggestion is the caller's own command line with
  # --claim added, the k263 shape.
  #
  # The same test is what lets KARR_CLAIM onto the card at all (ticket #286):
  # a column that demands a claim is one the card is being started in, and
  # that is the only create where the remembered claim means what a Claim is.
  # Held in a local so the guard here and the stamp below cannot disagree --
  # the env claim satisfies the guard exactly when it is then written.
  my $starts_work = defined $self->status
      && $self->store->status_requires_claim($self->status);
  if ( $starts_work
      && !( defined $self->resolved_claim && length $self->resolved_claim ) )
  {
    # A local, not "$self->status" inside the string: that would interpolate
    # the object and leave the literal text "->status" behind it.
    my $status = $self->status;
    user_error( require_claim_message(
        $status, 'create', $title, '--status', $status, '--claim', 'NAME' ) );
  }

  # Set-time dependency validation (ticket #124), under the same #54 rule.
  # A self-reference is not expressible here: the new id does not exist until
  # it is allocated below, and every dependency must already exist, so no
  # dependency can equal it. length, not truth (ticket #78).
  my $depends_on;
  if ( defined $self->depends_on && length $self->depends_on ) {
    $depends_on = $self->parse_dependency_ids( '--depends-on', $self->depends_on );
    $self->assert_dependencies_exist($depends_on);
  }

  # The cross-board half (ticket #192). Only the syntax is checked here, and
  # that is the whole story rather than a shortcut: the far board may not be on
  # this machine at all, and whether it is is local configuration, so a create
  # that refused a link it could not look up would refuse it on one machine and
  # accept it on the next for the same card. Whether the far card exists and
  # what state it is in is `karr needs`'s question.
  my @cross;
  push @cross, map { App::karr::CrossBoard->needs_tag($_) }
    @{ App::karr::CrossBoard->parse_refs( '--needs', $self->needs ) }
    if defined $self->needs && length $self->needs;
  push @cross, map { App::karr::CrossBoard->escalated_from_tag($_) }
    @{ App::karr::CrossBoard->parse_refs( '--escalated-from', $self->escalated_from ) }
    if defined $self->escalated_from && length $self->escalated_from;

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
  # Cross-board links live in the tag list (App::karr::CrossBoard explains why),
  # so they are appended to whatever --tags brought rather than replacing it.
  push @{ $task_args{tags} //= [] }, @cross if @cross;
  $task_args{depends_on} = $depends_on if $depends_on;
  $task_args{due}        = $self->due        if defined $self->due        && length $self->due;
  $task_args{estimate}   = $self->estimate   if defined $self->estimate   && length $self->estimate;
  # length, not truth: --body 0 is a body (ticket #78).
  $task_args{body}       = $self->body if defined $self->body && length $self->body;

  # Claim stamping, the same two fields and the same UTC instant `karr move
  # --claim` writes (ticket #270). There is no shared helper to call: move,
  # handoff, pick and edit all inline these two lines, and a single-use
  # abstraction would be worse than the copy.
  #
  # Which claim: an explicit --claim on any status; KARR_CLAIM only when the
  # card is being started in a require_claim column, the case the guard above
  # just let through on its strength (ticket #286). A Claim is an active lease
  # held while working a card (CONTEXT.md), and a card filed into the backlog
  # for whoever picks it next is not being worked -- so the filer's remembered
  # claim, which the skill has every agent export first thing, stays off it.
  # Before #286 resolved_claim was taken unconditionally, and a bug filed by
  # one agent was invisible to every other agent's `pick` and `list
  # --unclaimed` until claim_timeout ran out.
  my $claim = $starts_work ? $self->resolved_claim : $self->claim;
  if ( defined $claim && length $claim ) {
    $task_args{claimed_by} = $claim;
    $task_args{claimed_at} = gmtime->datetime . 'Z';
  }

  my $task = App::karr::Task->new(%task_args);
  $self->save_task($task);

  $self->sync_after;

  # --json emits the card in the same shape `karr show --json` uses and nothing
  # else on stdout, so a caller can pipe the new id into the next step (ticket
  # #268). Sync progress already goes to STDERR, so the JSON stream stays clean.
  if ($self->json) {
    $self->print_json( $task->to_json_hash );
  } else {
    printf "Created task %d: %s\n", $task->id, $task->title;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Create - Create a new task

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr create "Fix login bug"
    karr create --title "Write release notes" --priority high --status todo
    karr create --title "Review API" --tags docs,review --body "Check CLI help"
    karr create "Ship it" --depends-on 2,3
    karr create "Wait for the fix" --needs other-repo#7

=head1 DESCRIPTION

Creates a new task in the ref-backed board. The new task inherits defaults from
the materialized board config and can be seeded with metadata such as priority,
class of service, due date, tags, and body text.

=head1 OPTIONS

=over 4

=item * C<--title>

Explicit task title. If omitted, the first positional argument is used.
Giving the title both ways at once -- C<< karr create TITLE --title OTHER >> --
is rejected as a usage error (exit 2): the two can hold different strings and
nothing decides which one was meant.

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

=item * C<--needs>, C<--escalated-from>

The two ends of a cross-board dependency, comma-separated
C<< <board>#<id> >> references: C<--needs> for a card that cannot proceed until
something is fixed in another repository, C<--escalated-from> for the card
raised in that other repository to record where the escalation came from. Only
the syntax is validated -- whether the far board is on this machine is local
configuration, so the lookup belongs to C<karr needs> and not here. See
L<App::karr::CrossBoard>.

=item * C<--body>

Adds Markdown body text below the YAML frontmatter.

=item * C<--claim>

Claim the new task for an agent, stamping C<claimed_by> and C<claimed_at>
exactly as C<< karr move --claim >> does. A status the board's
C<require_claim> list covers is refused without it, with the invocation that
would have worked as the last line of the error.

C<KARR_CLAIM> (ADR 0005) stands in for the flag only when C<--status> names a
column that requires a claim -- the card is being started right now, and the
remembered claim is what satisfies that refusal and is then written. Without
C<--status>, or with one that needs no claim, the environment is not consulted
and the card is filed unclaimed: a Claim is a lease held while working a card,
and a card filed into the backlog for whoever picks it next is not being
worked. Before ticket #286 the filer's remembered claim landed on every card,
which hid a freshly filed bug from every other agent's C<karr pick> and
C<< karr list --unclaimed >> until C<claim_timeout> ran out. An explicit
C<--claim> stamps the claim on any status.

=item * C<--json>

Emit the created card in the same shape C<karr show --json> uses -- frontmatter
plus body, one object -- and nothing else on stdout, so a caller can pipe the
new id into the next step.

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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
