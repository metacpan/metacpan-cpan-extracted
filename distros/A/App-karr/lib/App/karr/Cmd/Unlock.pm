# ABSTRACT: Show and break task pick locks

package App::karr::Cmd::Unlock;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr unlock [ID[,ID,...]] [--all] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Lock;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output', 'App::karr::Role::ClaimTimeout';


option all => (
  is  => 'ro',
  doc => 'Break every lock on the board',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  # Pull first: a lock pushed by a command that died before it could release
  # one is on the remote, and this is the command for exactly that mess. The
  # guard is disarmed on the reporting path below, which writes nothing.
  my $guard = $self->sync_before;

  my $ec = $self->store->effective_config;
  my $lock = App::karr::Lock->new(
    git => $self->git,
    ttl => $self->_parse_timeout($ec->{lock_timeout},
                                 App::karr::Lock->DEFAULT_TTL),
  );

  my @pos = $self->positional_args($args_ref);
  my @held = $lock->locks;

  # No target: report only. Clearing a lock is destructive to whoever holds it,
  # so it takes an explicit id or --all.
  unless ($self->all || defined $pos[0]) {
    $guard->done;
    $self->_report(@held);
    return;
  }

  # break_lock clears both addresses a lock can have -- the current one and the
  # pre-#93 one inside refs/karr/* -- so a task holding one of each appears
  # twice in @held but must only be broken, and reported, once.
  my %seen;
  my @ids = $self->all
    ? grep { !$seen{$_}++ } map { $_->{task_id} } @held
    : $self->parse_ids($pos[0]);

  my @results;
  for my $id (@ids) {
    my ($ok, $owner) = $lock->break_lock($id);
    push @results, {
      id      => 0 + $id,
      broken  => $ok ? \1 : \0,
      ( $ok ? ( owner => $owner ) : () ),
    };
    next if $self->json;
    if ($ok) { printf "Broke lock on task %d (was held by %s)\n", $id, $owner }
    else     { printf "Task %d is not locked\n", $id }
  }

  $self->sync_after;

  $self->print_json_results(@results);
}

sub _report {
  my ($self, @held) = @_;

  if ($self->json) {
    $self->print_json([ map { { %$_,
      expired => $_->{expired} ? \1 : \0,
      legacy  => $_->{legacy}  ? \1 : \0,
    } } @held ]);
    return;
  }

  unless (@held) {
    print "No locks held.\n";
    return;
  }

  for my $l (@held) {
    printf "Task %-4d held by %s%s%s%s\n",
      $l->{task_id},
      $l->{owner},
      ( defined $l->{age} ? sprintf( ' for %s', _duration( $l->{age} ) ) : '' ),
      ( $l->{expired} ? ' [expired]' : '' ),
      # A lock still sitting in the board namespace was written by a karr older
      # than #93, or pulled from a remote that was given one. Nothing takes it
      # into account any more, and breaking it is how it finally goes away.
      ( $l->{legacy} ? ' [stray: pushed by an older karr, safe to break]' : '' );
  }
  print "\nBreak one with 'karr unlock ID', or all of them with 'karr unlock --all'.\n";
}

sub _duration {
  my ($secs) = @_;
  return "${secs}s" if $secs < 60;
  return int( $secs / 60 ) . 'm' if $secs < 3600;
  return int( $secs / 3600 ) . 'h';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Unlock - Show and break task pick locks

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr unlock
    karr unlock 12
    karr unlock 12,14 --json
    karr unlock --all

=head1 DESCRIPTION

Shows the C<karr pick> locks currently held on the board, and breaks them on
request.

Run with no arguments it only reports: one line per lock with the task it
covers, the identity holding it, how long it has been held, and whether that is
past the board's C<lock_timeout>. Nothing is destroyed unless a task id or
C<--all> is given.

=head1 WHY THIS EXISTS

C<karr pick> takes a lock ref, claims a card, and gives the lock back inside one
command, so under normal use there is nothing here to see. An agent that dies in
between -- killed mid-run, or a push that failed and aborted the command -- left
one behind, and before #45 that ref was permanent: no command could clear it,
C<karr delete> could not reach it, and every other agent skipped that task
forever. Digging the board out took a C<git update-ref -d> by hand.

Locks now expire on their own (C<lock_timeout>, default C<5m>), which is what an
unattended agent needs. This command is the other half: the way a human sees
what is stuck and clears it now instead of waiting, and the only way out at all
on a board that has set C<lock_timeout> to C<0s>.

=head1 STRAY LOCKS

Locks used to live inside C<refs/karr/*>, so a sync while one was held published
it and every other clone pulled it (#93). They are outside the board namespace
now, but the ones already published do not disappear on their own: an older
C<karr>, or a pull from a remote that still carries them, leaves refs at the old
address.

Nothing acts on those any more -- a lock taken in another clone says nothing
about this process -- but they are listed here, marked
C<[stray: pushed by an older karr, safe to break]>, and breaking a lock clears
the old address along with the current one. That is how a board that was
published with locks in it gets clean again.

Breaking a lock is safe by construction: it is not what makes a pick exclusive.
The claim is written under a compare-and-swap on the card itself
(L<App::karr::Cmd::Pick/EXCLUSIVITY>), so an agent whose lock is broken out from
under it mid-pick either completes its claim untouched or loses that swap to
whoever got there first. It can never overwrite somebody else's claim.

=head1 OPTIONS

=over 4

=item * C<--all>

Break every lock on the board instead of named ones.

=item * C<--json>

Emit the locks, or the results of breaking them, as JSON.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Pick>, L<App::karr::Lock>,
L<App::karr::Cmd::Config>

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
