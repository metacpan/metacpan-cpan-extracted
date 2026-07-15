# ABSTRACT: Show board summary

package App::karr::Cmd::Board;
our $VERSION = '0.401';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr board [--json] [--compact] [--tags] [--done]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use Term::ANSIColor qw( colored );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';

option tags => (
  is => 'ro',
  doc => 'Show each task\'s tags on an extra indented line',
);

option done => (
  is => 'ro',
  doc => 'Include the Done section (hidden by default)',
);


my %STATUS_COLOR = (
  backlog       => 'bright_black',
  todo          => 'cyan',
  'in-progress' => 'yellow',
  review        => 'magenta',
  done          => 'green',
  archived      => 'bright_black',
);

my %PRIORITY_COLOR = (
  critical => 'bold red',
  high     => 'red',
  medium   => 'yellow',
  low      => 'bright_black',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my $ec = $self->store->effective_config;
  my @statuses = $self->store->all_status_names;
  my @tasks = $self->load_tasks;

  my %by_status;
  for my $t (@tasks) {
    push @{$by_status{$t->status}}, $t;
  }

  if ($self->json) {
    my $board_name = $ec->{board}{name} // 'Kanban Board';
    my %board_data = (
      name     => $board_name,
      total    => scalar @tasks,
      columns  => [],
    );
    for my $status (@statuses) {
      my $tasks_in_status = $by_status{$status} // [];
      # Hide done task payloads by default (keep the column and its real count
      # so the all-columns shape and total stay intact); --done reveals them.
      my $hide = $status eq 'done' && !$self->done;
      my %col = (
        status => $status,
        count  => scalar @$tasks_in_status,
        tasks  => $hide ? [] : [ map { $_->to_frontmatter } @$tasks_in_status ],
      );
      push @{$board_data{columns}}, \%col;
    }
    $self->print_json(\%board_data);
    return;
  }

  if ($self->compact) {
    for my $status (@statuses) {
      my $tasks_in_status = $by_status{$status} // [];
      my $count = scalar @$tasks_in_status;
      my $ids = join(',', map { $_->id } @$tasks_in_status);
      printf "%s(%d): %s\n", $status, $count, $ids || '-';
    }
    return;
  }

  my $board_name = $ec->{board}{name} // 'Kanban Board';

  # Colour only when writing to a real terminal — piped or redirected output
  # stays clean plaintext so the board diffs, greps, and pastes cleanly.
  my $color = -t STDOUT && !$ENV{NO_COLOR};
  my $c = sub {
    my ($text, $spec) = @_;
    return $color ? colored($text, $spec) : $text;
  };
  my $sep = $c->('|', 'bright_black');

  print $c->("# $board_name", 'bold cyan'), "\n";

  # Skip empty archived unless it has tasks; hide done unless --done was given
  # (the footer still notes how many done tasks were hidden).
  my @display_statuses = grep {
    ($_ ne 'archived' || @{$by_status{$_} // []})
      && ($_ ne 'done' || $self->done)
  } @statuses;

  for my $status (@display_statuses) {
    my $tasks  = $by_status{$status} // [];
    my $label  = join ' ', map { ucfirst } split /-/, $status;
    my $accent = $STATUS_COLOR{$status} // 'white';
    print "\n", $c->("## $label", "bold $accent"), "\n";

    for my $t (@$tasks) {
      my @meta;
      if ($t->priority && $t->priority ne 'medium') {
        push @meta, $c->('priority:' . $t->priority, $PRIORITY_COLOR{$t->priority} // 'white');
      }
      if ($t->has_claimed_by && $t->status ne 'done' && $t->status ne 'archived') {
        push @meta, $c->('@' . $t->claimed_by, 'cyan');
      }
      if ($t->has_blocked) {
        my $reason = $t->blocked;
        $reason = substr($reason, 0, 40) . '...' if defined $reason && length $reason > 43;
        push @meta, $c->(
          defined $reason && length $reason ? "blocked:$reason" : 'blocked', 'bold red');
      }
      if ($t->has_due) {
        push @meta, $c->('due:' . $t->due, 'yellow');
      }

      my $line = join ' ', $c->('-', 'bright_black'), $t->id, $sep, $t->title;
      $line .= " $sep " . join(" $sep ", @meta) if @meta;
      print $line, "\n";

      if ($self->tags && @{$t->tags}) {
        print '  ', $c->(join(' ', map { "#$_" } @{$t->tags}), 'bright_black'), "\n";
      }
    }
  }

  # Summary footer
  my $blocked = grep { $_->has_blocked } @tasks;
  my $claimed = grep { $_->has_claimed_by && $_->status ne 'done' && $_->status ne 'archived' } @tasks;
  my $done_hidden = $self->done ? 0 : scalar @{ $by_status{done} // [] };
  my $total_label = scalar(@tasks) . ' tasks';
  $total_label .= " ($done_hidden done hidden)" if $done_hidden;
  my @summary = ( $total_label );
  push @summary, "$claimed claimed" if $claimed;
  push @summary, "$blocked blocked" if $blocked;
  print "\n", $c->(join('  ', @summary), 'bold'), "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Board - Show board summary

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    karr board
    karr board --tags
    karr board --compact
    karr board --json
    karr board --done

=head1 DESCRIPTION

Renders a board-oriented summary grouped by status. The default output is a
compact, Markdown-flavoured plaintext board: the board name as an C<#> heading,
each status as a C<##> section, and one C<- id | title | meta...> line per task.
This stays readable when piped, redirected, diffed, or pasted. Colour is added
only when standard output is a terminal (and C<NO_COLOR> is unset). Compact and
JSON modes remain available for automation and scripting.

=head1 OUTPUT MODES

=over 4

=item * Default output

Lists every status as a C<## Status> section (in board order, empty sections
included; an empty C<archived> is hidden, and C<done> is hidden unless C<--done>
is given). Each task renders as C<- id | title> followed by C<priority>
(non-default only), C<@claimant>, C<blocked:reason>, and C<due:date> tokens where
applicable. A footer line totals tasks, claims, and blocks, and — when the
C<done> section is hidden and non-empty — appends a C<(N done hidden)> hint so
the count is not silently lost.

=item * C<--tags>

Adds an extra indented line of C<#tag> tokens beneath each task that has tags.

=item * C<--done>

Includes the C<done> section, which is hidden by default, and suppresses the
hidden-count footer hint. Applies to the default, C<--tags>, and C<--json>
renderings; C<--compact> always lists every status regardless.

=item * C<--compact>

Prints one line per status in the form C<status(count): ids>.

=item * C<--json>

Emits the board name, total task count, and a structured C<columns> array with
per-status task lists.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Context>

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
