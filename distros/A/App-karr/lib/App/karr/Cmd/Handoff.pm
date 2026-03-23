# ABSTRACT: Hand off a task for review

package App::karr::Cmd::Handoff;
our $VERSION = '0.101';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr handoff ID --claim NAME [--note TEXT] [--block REASON] [--release]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output', 'App::karr::Role::ClaimTimeout';


option claim => (
  is => 'ro',
  format => 's',
  required => 1,
  doc => 'Agent name claiming the task',
);

option note => (
  is => 'ro',
  format => 's',
  doc => 'Handoff note to append to body',
);

option timestamp => (
  is => 'ro',
  short => 't',
  doc => 'Prefix timestamp to note',
);

option block => (
  is => 'ro',
  format => 's',
  doc => 'Block task with reason',
);

option release => (
  is => 'ro',
  doc => 'Release claim after handoff',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->sync_before;

  my $id = $args_ref->[0] or die "Usage: karr handoff ID --claim NAME [--note TEXT] [--block REASON] [--release]\n";

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );

  my $task = $self->find_task($id);
  die "Task $id not found\n" unless $task;

  # Validate claim ownership
  if ($task->has_claimed_by && $task->claimed_by ne $self->claim) {
    my $timeout = $self->_parse_timeout($config->claim_timeout);
    unless ($self->_claim_expired($task, $timeout)) {
      die sprintf "Task %d is claimed by %s\n", $task->id, $task->claimed_by;
    }
  }

  # Move to review
  my $old_status = $task->status;
  if ($task->status ne 'review') {
    $task->status('review');
  }

  # Refresh claim
  $task->claimed_by($self->claim);
  $task->claimed_at(gmtime->datetime . 'Z');

  # Block if requested
  if ($self->block) {
    $task->blocked($self->block);
  }

  # Append note
  if ($self->note) {
    my $note_text = $self->note;
    if ($self->timestamp) {
      $note_text = gmtime->strftime('%Y-%m-%d %H:%M') . ' ' . $note_text;
    }
    $task->body(($task->body ? $task->body . "\n" : '') . $note_text);
  }

  # Release claim if requested
  if ($self->release) {
    $task->claimed_by(undef);
    $task->claimed_at(undef);
  }

  $task->save;

  $self->sync_after;

  if ($self->json) {
    my $data = $task->to_frontmatter;
    $data->{body} = $task->body if $task->body;
    $self->print_json($data);
    return;
  }

  my $msg = sprintf "Handed off task %d -> review", $task->id;
  $msg .= sprintf " (blocked: %s)", $self->block if $self->block;
  $msg .= " (claim released)" if $self->release;
  print "$msg\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Handoff - Hand off a task for review

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    karr handoff 7 --claim agent-fox
    karr handoff 7 --claim agent-fox --note "Implementation complete" --timestamp
    karr handoff 7 --claim agent-fox --block "waiting for QA" --release

=head1 DESCRIPTION

Moves a task into C<review> and refreshes its claim so the next stage of work
can see who handed it off. The command can append a note, add a blocker, and
optionally release the claim after the handoff.

=head1 OPTIONS

=over 4

=item * C<--claim>

Required. Identifies the agent performing the handoff and is validated against
the current claim unless that claim has expired.

=item * C<--note>, C<--timestamp>

Append handoff text to the task body, optionally prefixed with the current UTC
timestamp.

=item * C<--block>, C<--release>

Record a blocking reason and/or clear the claim immediately after the handoff.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Log>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
