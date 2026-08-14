# ABSTRACT: Migrate an old board off double-encoded UTF-8 and off impossible start stamps

package App::karr::Cmd::Repair;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr repair [--yes] [--json]',
);
use App::karr::Encoding qw(
  BOARD_ENCODING_VERSION repair_mojibake
  yaml_load yaml_dump json_decode json_encode
);
use App::karr::Task;
use App::karr::Role::BoardDiscovery;
use App::karr::Role::SyncLifecycle;
use App::karr::Role::CliArgs;
use App::karr::Role::Output;

with 'App::karr::Role::BoardDiscovery';
with 'App::karr::Role::SyncLifecycle';
with 'App::karr::Role::CliArgs';
with 'App::karr::Role::Output';


option yes => (
  is => 'ro',
  doc => 'Rewrite the affected refs instead of only reporting them',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 0);

  my $store = $self->store;
  my $git   = $self->git;

  # A dry run still pulls (a legacy board may only exist on the remote), but it
  # must not push, so its guard is closed immediately. --yes takes the full
  # lifecycle: pull, rewrite, push, with SyncGuard insurance on a crash.
  my $guard = $self->sync_before;
  $guard->done unless $self->yes;

  die "No karr board found. Run 'karr init' to create one.\n"
    unless $store->has_board_refs;

  # The encoding migration is first and is the only one that can be skipped
  # wholesale: a board already at the current version needs none of it. The
  # stamp survey below runs on every board, which is why this no longer returns
  # here the way it did while repair had only the one job.
  my $legacy = $git->board_is_legacy_encoded ? 1 : 0;
  my ( $repaired, $skipped ) = ( [], [] );
  if ($legacy) {
    ( $repaired, $skipped ) = $self->_repair_refs($git);
    $git->write_encoding_version if $self->yes;
  }

  # Deliberately after the encoding pass, and after the marker: the cards read
  # here are the cards as they now stand. write_encoding_version invalidates the
  # cached version, so load_task_ref stops undoing a double encode at exactly
  # the point the refs stopped carrying one, and a clamped card is written back
  # once, in its repaired form.
  my $stamps = $self->_survey_stamps($git);
  $self->_clamp_started( $git, $stamps->{clamp} ) if $self->yes;

  $self->sync_after if $self->yes;

  return $self->_report_json( $git, $legacy, $repaired, $skipped, $stamps )
    if $self->json;

  $self->_report_encoding( $git, $legacy, $repaired, $skipped );
  print "\n";
  $self->_report_stamps($stamps);

  # One hint for the whole run, not one per section: both findings are applied
  # by the same --yes, and printing it twice made the report read as two
  # separate offers.
  print "\nRun 'karr repair --yes' to apply.\n"
    if !$self->yes && ( @$repaired || @{ $stamps->{clamp} } );
}

sub _report_encoding {
  my ( $self, $git, $legacy, $repaired, $skipped ) = @_;

  if ( !$legacy ) {
    my $version = $git->board_encoding_version;
    print "Board encoding is already at version $version; nothing to repair.\n";
    return;
  }

  # Never quietly: a ref this could not handle is left as it was, and the marker
  # goes on regardless, so the user has to be told which ones to look at.
  if (@$skipped) {
    printf STDERR "Left %d ref(s) unchanged (could not parse, or not a known board payload):\n", scalar @$skipped;
    print STDERR "  $_\n" for @$skipped;
  }

  if ( !@$repaired ) {
    print $self->yes
      ? "No double-encoded payloads found; marked the board as encoding version "
        . BOARD_ENCODING_VERSION . ".\n"
      : "No double-encoded payloads found. Run with --yes to mark the board as encoding version "
        . BOARD_ENCODING_VERSION . ".\n";
    return;
  }

  printf "%s %d ref(s):\n", ( $self->yes ? 'Repaired' : 'Would repair' ), scalar @$repaired;
  print "  $_\n" for @$repaired;
}

# The two costs of the clamp are stated here and nowhere else in the run, in the
# indicative and about this board's own cards, because after --yes neither of
# them can be read back out of the data (ticket #138).
sub _report_stamps {
  my ( $self, $stamps ) = @_;
  my @ids = map { $_->id } @{ $stamps->{clamp} };

  if ( !@ids ) {
    print "No card carries a bare-date 'started' that precedes its own 'created'.\n";
  }
  elsif ( $self->yes ) {
    printf "Raised 'started' to 'created' on %d card(s): %s\n",
      scalar @ids, join( ', ', @ids );
    print <<'END_APPLIED';
Those cards now say the work began the instant the card was filed. That is not
what happened: karr wrote 'started' as a bare date before ticket #68, so the
real start was only ever known to the day, and a card filed in the morning and
picked up at night now reports no queue time at all. Nothing on the cards marks
the stamp as having been day-granular any more, so this run cannot be told from
real data afterwards, and cannot be undone from it.
END_APPLIED
  }
  else {
    printf "Would raise 'started' to 'created' on %d card(s): %s\n",
      scalar @ids, join( ', ', @ids );
    print <<'END_DRY';
Each of those cards would then say the work began the instant the card was
filed -- no queue time -- which is false for one filed in the morning and picked
up at night, and nothing on the card would mark the stamp as having been
day-granular any more. The clamp cannot be undone from the data afterwards.
END_DRY
  }

  # The one cost the clamp creates rather than inherits, and the reason it gets
  # its own line instead of a row in the survey below: `completed` was written
  # day-granular by the same old karr, so raising `started` to a `created` later
  # in that day steps over it. Such a card's cycle time reads negative
  # afterwards, where before the clamp it was merely absent.
  if ( my @over = @{ $stamps->{clamped_over_completed} } ) {
    my $one = @over == 1;
    printf
        "%d of them %s a bare-date 'completed' that %s before the new 'started'.\n"
      . "karr wrote that stamp day-granular too and this command does not touch it,\n"
      . "so %s cycle time %s negative: %s\n",
      scalar @over,
      ( $one ? 'carries' : 'carry' ),
      ( $self->yes ? 'falls' : 'would fall' ),
      ( $one ? 'its' : 'their' ),
      ( $self->yes ? 'reads' : 'would read' ),
      join( ', ', @over );
  }

  my @found = grep { @{ $stamps->{ $_->[0] } } } (
    [ started_before_created_unclamped =>
      "'started' precedes 'created' in a shape this repair does not recognise"
      . " as the pre-#68 bare-date stamp" ],
    [ completed_before_started => "'completed' precedes 'started'" ],
    [ completed_before_created => "'completed' precedes 'created'" ],
    [ updated_before_created   => "'updated' precedes 'created'" ],
    [ unreadable_stamps        => "a stamp in a shape karr cannot compare" ],
    [ unparseable_cards        => "a ref that does not parse as a card at all,"
      . " so its stamps were not examined" ],
  );
  return unless @found;

  printf "\nFound and NOT repaired -- this command clamps 'started' only.\n"
    . "Counted as the stamps %s:\n",
    ( $self->yes ? 'now stand' : 'would stand after --yes' );
  for my $row (@found) {
    my ( $key, $what ) = @$row;
    my @rows = @{ $stamps->{$key} };
    printf "  %d card(s) with %s: %s\n", scalar @rows, $what, join( ', ', @rows );
  }
}

sub _report_json {
  my ( $self, $git, $legacy, $repaired, $skipped, $stamps ) = @_;
  return $self->print_json({
    version =>
        !$legacy      ? $git->board_encoding_version
      : $self->yes    ? BOARD_ENCODING_VERSION
      :                 1,
    up_to_date      => $legacy ? \0 : \1,
    applied         => $self->yes ? \1 : \0,
    repaired        => $repaired,
    skipped         => $skipped,
    started_clamped => [ map { $_->id + 0 } @{ $stamps->{clamp} } ],
    started_clamped_over_completed => $stamps->{clamped_over_completed},
    stamp_anomalies => {
      map { $_ => $stamps->{$_} }
        qw( started_before_created_unclamped completed_before_started
            completed_before_created updated_before_created
            unreadable_stamps unparseable_cards )
    },
  });
}

# Returns ( \@changed, \@unparseable ). Anything whose stored text is pure ASCII
# is skipped outright rather than parsed and re-serialized: that is what makes
# "does not touch ASCII data" a property of the code rather than a property of
# the repair heuristic.
sub _repair_refs {
  my ( $self, $git ) = @_;
  my ( @repaired, @skipped );

  for my $ref ( sort $git->list_refs('refs/karr/') ) {
    my $content = $git->read_ref($ref);
    next unless defined $content && length $content;
    next unless $content =~ /[^\x00-\x7F]/;

    # A non-ASCII payload under refs/karr/ that is none of the three known
    # shapes is reported rather than passed over: it may well be legacy-encoded
    # too, and the marker is about to say the whole board is clean.
    my $known =
         $ref =~ m{\Arefs/karr/tasks/\d+/data\z}
      || $ref eq 'refs/karr/config'
      || $ref =~ m{\Arefs/karr/log/};
    if ( !$known ) {
      push @skipped, $ref;
      next;
    }

    my $fixed =
        $ref eq 'refs/karr/config'    ? $self->_repair_config($content)
      : $ref =~ m{\Arefs/karr/log/}   ? $self->_repair_log($content)
      :                                 $self->_repair_task($content);

    if ( !defined $fixed ) {
      push @skipped, $ref;
      next;
    }

    # read_ref chomps one trailing newline and the re-serialized document has
    # one, so compare with that difference normalized away. Without this every
    # task whose *body* has non-ASCII -- a body was never double-encoded and
    # needs no repair -- looked changed and got rewritten for nothing: 63 refs
    # instead of 17 on karr's own board.
    ( my $comparable = $fixed ) =~ s/\n\z//;
    next if $comparable eq $content;

    push @repaired, $ref;
    $git->write_ref( $ref, $fixed ) if $self->yes;
  }

  return ( \@repaired, \@skipped );
}

# The pre-#68 `started`, and the shape karr has written for every other stamp
# since the beginning. Nothing else is a karr stamp, and nothing else is
# clamped.
my $BARE_DATE_STAMP = qr/\A\d{4}-\d{2}-\d{2}\z/;
my $KARR_STAMP      = qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/;

# Both shapes as one string that sorts chronologically, or undef for anything
# else. A bare date becomes midnight UTC -- which is not a normalisation, it is
# what the stamp already meant, and precisely why it lands before a card created
# later the same day.
#
# This is why no third copy of App::karr::Cmd::Metrics' _epoch is needed here:
# both results are the same canonical UTC spelling, so `lt` answers "earlier
# than" exactly. It is also why a stamp carrying an offset (kanban-md writes
# RFC3339 with a local one) is refused rather than compared -- string order
# stops meaning time order the moment two stamps sit in different zones, and a
# command that rewrites refs must not guess there.
sub _utc_key {
  my ($stamp) = @_;
  return undef unless defined $stamp && length $stamp;
  return $stamp . 'T00:00:00Z' if $stamp =~ $BARE_DATE_STAMP;
  return $stamp                if $stamp =~ $KARR_STAMP;
  return undef;
}

# Walks every card once and sorts its lifecycle stamps into the buckets the
# report prints. `clamp` holds task objects (they are about to be written);
# every other bucket holds ids, because nothing acts on them.
#
# Cards are loaded one ref at a time under eval rather than through
# BoardStore/load_tasks: a ref that does not parse must be counted and reported,
# not allowed to kill a repair run halfway through -- that is the same junk ref
# the encoding pass above already answers for by name.
sub _survey_stamps {
  my ( $self, $git ) = @_;

  my %found = map { $_ => [] } qw(
    clamp clamped_over_completed
    started_before_created_unclamped completed_before_started
    completed_before_created updated_before_created
    unreadable_stamps unparseable_cards
  );

  for my $id ( $git->list_task_refs ) {
    my $task = eval { $git->load_task_ref($id) };
    if ( !defined $task ) {
      push @{ $found{unparseable_cards} }, $id + 0;
      next;
    }

    my $created   = _utc_key( $task->created );
    my $updated   = _utc_key( $task->updated );
    my $started   = $task->has_started   ? _utc_key( $task->started )   : undef;
    my $completed = $task->has_completed ? _utc_key( $task->completed ) : undef;

    push @{ $found{unreadable_stamps} }, $id + 0
      if !defined $created
      || !defined $updated
      || ( $task->has_started   && !defined $started )
      || ( $task->has_completed && !defined $completed );

    if ( defined $created && defined $started && $started lt $created ) {
      # Only the known bug is migrated. A start that precedes its card while
      # carrying a time of day is a different fault with an unknown cause, and
      # clamping it would destroy the only evidence that it happened.
      if ( $task->started =~ $BARE_DATE_STAMP && $task->created =~ $KARR_STAMP ) {
        push @{ $found{clamp} }, $task;
        # The clamp's own doing, called out separately in the report: the same
        # old karr wrote `completed` day-granular as well, so the new start can
        # land after it.
        push @{ $found{clamped_over_completed} }, $id + 0
          if defined $completed && $completed lt $created;
        $started = $created;
      }
      else {
        push @{ $found{started_before_created_unclamped} }, $id + 0;
      }
    }

    # Everything below describes the board the run leaves behind -- $started is
    # the clamped value where the clamp applies. A survey taken before the write
    # would report an ordering the very same run then breaks, and the user would
    # first see it on the next invocation.
    push @{ $found{completed_before_started} }, $id + 0
      if defined $completed && defined $started && $completed lt $started;
    push @{ $found{completed_before_created} }, $id + 0
      if defined $completed && defined $created && $completed lt $created;
    push @{ $found{updated_before_created} }, $id + 0
      if defined $updated && defined $created && $updated lt $created;
  }

  return \%found;
}

# Through Git::save_task_ref, not BoardStore::save_task: that one bumps
# `updated` on every write to an existing ref, and a migration that re-dated 75
# cards to the moment it ran would destroy more history than it repaired. The
# encoding pass above writes for the same reason.
sub _clamp_started {
  my ( $self, $git, $tasks ) = @_;
  for my $task (@$tasks) {
    $task->started( $task->created );
    $git->save_task_ref($task);
  }
  return;
}

sub _repair_task {
  my ( $self, $content ) = @_;
  my $task = eval { App::karr::Task->from_string( $content, repair_frontmatter => 1 ) };
  return undef unless $task;
  return $task->to_markdown;
}

sub _repair_config {
  my ( $self, $content ) = @_;
  my $data = eval { yaml_load($content) };
  return undef unless ref $data eq 'HASH';
  return yaml_dump( repair_mojibake($data) );
}

sub _repair_log {
  my ( $self, $content ) = @_;
  my @lines;
  for my $line ( split /\n/, $content ) {
    next unless length $line;
    my $entry = eval { json_decode($line) };
    return undef unless $entry;
    push @lines, json_encode( repair_mojibake($entry) );
  }
  return join "\n", @lines;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Repair - Migrate an old board off double-encoded UTF-8 and off impossible start stamps

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr repair              # report what would change
    karr repair --yes        # rewrite the affected refs
    karr repair --json

=head1 DESCRIPTION

Two migrations of old board data, reported and applied together but kept apart
in the output, because a board can need either one without the other.

Neither of them touches C<updated>: a migration is not an edit, and bumping the
stamp on every card it rewrites would destroy the very history it is repairing.

=head2 Double-encoded UTF-8

karr up to and including 0.402 handed C<YAML::XS::Dump> output — UTF-8 octets —
around as if it were characters, so every board written by those versions
carries UTF-8 encoded twice in its task frontmatter, its board config, and its
activity log. Task bodies are not affected: they were concatenated onto the
Markdown document verbatim and are correctly encoded.

Such a board is still read correctly, because C<refs/karr/meta/encoding> is
absent and everything that loads board state undoes the second encoding on the
way in (see L<App::karr::Encoding/repair_mojibake>). This command makes that
permanent: it rewrites the affected refs once and stamps the marker, after
which nothing guesses at the board's bytes again.

It is safe to run on any board:

=over 4

=item * a board already at the current version is left completely alone;

=item * a ref whose payload is pure ASCII is skipped, so an ASCII-only board
comes out bit-identical apart from the new marker ref;

=item * running it twice changes nothing the second time.

=back

=head2 Start stamps that precede their own card

karr wrote C<started> as a bare C<YYYY-MM-DD> date until ticket #68 made it a
full timestamp. A bare date reads as midnight UTC, so every card filed and
picked up on the same day carries a C<started> that is earlier than its own
C<created> — by up to a day. On karr's own board that is 75 of 116 finished
cards. Nothing can be measured from such a stamp: counted, its cycle time
exceeds its lead time, which is why L<App::karr::Cmd::Metrics> leaves those
cards out of the averages entirely.

This command raises C<started> to the card's own C<created> — the only
defensible value, since the work cannot have begun before the card existed.

B<What that costs, stated because it is not recoverable afterwards:>

=over 4

=item * A clamped card asserts that the work began the instant the card was
filed, i.e. zero queue time. For a card filed in the morning and picked up at
night that is false, and the true start is not recorded anywhere else — the
activity log does not cover the boards whose history is oldest.

=item * After the clamp nothing on the card marks the stamp as having been
day-granular. A migrated card is indistinguishable from one that really was
started the second it was created, so the migration cannot be undone or
audited from the data.

=item * Those cards become measurable for C<karr metrics>, with a cycle time
equal to their lead time and a flow efficiency of 100%. That is arithmetic on
the clamped value, not a finding about how the work ran.

=item * The same old karr wrote C<completed> day-granular too, and this command
does not touch it. Where such a C<completed> falls before the card's own
C<created>, raising C<started> to C<created> steps over it, and the card's cycle
time reads negative afterwards where before it was merely absent. That is 42 of
the 75 clamped cards on karr's own board. They are counted on a line of their
own in the report and in C<started_clamped_over_completed> under C<--json>,
because the clamp creates that state rather than inheriting it (ticket #139).

=back

The criterion is deliberately narrow. A card is clamped only when its
C<started> is a bare C<YYYY-MM-DD> date I<and> its C<created> is a full
C<YYYY-MM-DDTHH:MM:SSZ> stamp of karr's own writing I<and> midnight of that
date really does precede that C<created>. A C<started> that precedes C<created>
in any other shape is a different, unknown fault — a hand edit, a clock skew,
an import from another tool — and clamping it blind would erase the evidence
for it, so it is reported and left alone.

=head2 Stamps this command does not repair

Every card is checked for the other orderings that cannot be true either
(C<completed> before C<started>, C<completed> before C<created>, C<updated>
before C<created>), and for stamps in a shape karr cannot compare at all. Those
are counted and reported, never rewritten: this command clamps C<started> and
nothing else (ticket #138), and a repair that quietly normalised the rest would
be the same mistake in a larger size. The counts describe the board as the run
leaves it, so a dry run shows what C<--yes> would produce rather than what is
there now. C<completed> is the one with a ticket of its own (#139): karr wrote
it day-granular before #68 as well, on more cards than C<started>, and unlike
C<started> it has no single defensible value to be raised to.

=head1 OPTIONS

=over 4

=item * C<--yes>

Actually rewrite the refs. Without it the command only reports what it would
change.

=item * C<--json>

Emit the report as JSON instead of text. C<up_to_date> answers for the encoding
migration alone, as it always has, so it is not on its own an answer to "does
this board need repairing" — read C<started_clamped> beside it. C<applied>
distinguishes a dry run's C<repaired>/C<started_clamped> ("would") from a
C<--yes> run's ("did"). C<stamp_anomalies> carries the findings above, and its
lists are never acted on.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Encoding>, L<App::karr::Cmd::Backup>,
L<App::karr::Cmd::Import>, L<App::karr::Cmd::Metrics>, L<App::karr::Task>

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
