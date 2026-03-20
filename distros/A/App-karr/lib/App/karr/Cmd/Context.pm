# ABSTRACT: Generate board context summary for embedding

package App::karr::Cmd::Context;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr context [--write-to FILE] [--sections LIST] [--days N] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';

option write_to => (
  is => 'ro',
  format => 's',
  doc => 'Write context to file (create or update)',
);

option sections => (
  is => 'ro',
  format => 's',
  doc => 'Comma-separated section filter (in-progress,blocked,overdue,recently-completed)',
);

option days => (
  is => 'ro',
  format => 'i',
  default => sub { 7 },
  doc => 'Lookback days for recently-completed (default: 7)',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );

  my @tasks = $self->_load_tasks;
  my @statuses = $config->statuses;

  # Determine terminal and first statuses
  my $first_status = $statuses[0];
  my %terminal = map { $_ => 1 } ('done', 'archived');

  # Exclude archived from all operations
  my @active_tasks = grep { $_->status ne 'archived' } @tasks;

  # Build summary
  my $board_name = $config->data->{board}{name} // 'Kanban Board';
  my $total = scalar @active_tasks;
  my $active = grep { $_->status ne $first_status && !$terminal{$_->status} } @active_tasks;
  my $blocked = grep { $_->has_blocked } @active_tasks;
  my $overdue = $self->_count_overdue(\@active_tasks, \%terminal);

  # WIP warnings
  my @wip_warnings;
  for my $status (@statuses) {
    my $limit = $config->wip_limit($status);
    next unless $limit;
    my $count = grep { $_->status eq $status } @active_tasks;
    push @wip_warnings, "$status ($count/$limit)" if $count >= $limit;
  }

  # Build sections
  my %wanted_sections;
  if ($self->sections) {
    %wanted_sections = map { $_ => 1 } split /,/, $self->sections;
  }

  my @section_data;
  my @all_sections = qw(in-progress blocked overdue recently-completed);

  for my $sec (@all_sections) {
    next if $self->sections && !$wanted_sections{$sec};
    my @items;

    if ($sec eq 'in-progress') {
      @items = map { $self->_task_item($_) }
        sort { $self->_pri_order($a) <=> $self->_pri_order($b) }
        grep { $_->status ne $first_status && !$terminal{$_->status} && !$_->has_blocked }
        @active_tasks;
    } elsif ($sec eq 'blocked') {
      @items = map { $self->_task_item($_, 'blocked: ' . ($_->blocked // '')) }
        grep { $_->has_blocked }
        @active_tasks;
    } elsif ($sec eq 'overdue') {
      my $now = gmtime->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'due ' . $_->due) }
        grep { $_->has_due && $_->due lt $now && !$terminal{$_->status} }
        @active_tasks;
    } elsif ($sec eq 'recently-completed') {
      my $cutoff = (gmtime() - ($self->days * 86400))->strftime('%Y-%m-%d');
      @items = map { $self->_task_item($_, 'completed ' . ($_->completed // '')) }
        sort { ($b->completed // '') cmp ($a->completed // '') }
        grep { $terminal{$_->status} && $_->status ne 'archived'
               && $_->has_completed && $_->completed ge $cutoff }
        @active_tasks;
    }

    push @section_data, { name => $sec, items => \@items } if @items;
  }

  if ($self->json) {
    my $out = {
      board_name => $board_name,
      summary => {
        total_tasks => $total,
        active => $active,
        blocked => $blocked,
        overdue => $overdue,
        (@wip_warnings ? (wip_warning => 'WIP limit reached: ' . join(', ', @wip_warnings)) : ()),
      },
      sections => \@section_data,
    };
    $self->print_json($out);
    return;
  }

  # Render markdown
  my $md = $self->_render_markdown($board_name, $total, $active, $blocked, $overdue, \@wip_warnings, \@section_data);

  if ($self->write_to) {
    $self->_write_to_file($md);
  } else {
    print $md;
  }
}

sub _render_markdown {
  my ($self, $board_name, $total, $active, $blocked, $overdue, $wip_warnings, $sections) = @_;
  my $md = "<!-- BEGIN kanban-md context -->\n";
  $md .= "## Board: $board_name\n\n";
  $md .= "**$total tasks** | $active active | $blocked blocked | $overdue overdue\n\n";

  if (@$wip_warnings) {
    $md .= "> WIP limit reached: " . join(', ', @$wip_warnings) . "\n\n";
  }

  my %section_title = (
    'in-progress'        => 'In Progress',
    'blocked'            => 'Blocked',
    'overdue'            => 'Overdue',
    'recently-completed' => 'Recently Completed',
  );

  for my $sec (@$sections) {
    $md .= "### " . ($section_title{$sec->{name}} // $sec->{name}) . "\n\n";
    for my $item (@{$sec->{items}}) {
      $md .= sprintf "- **#%d** %s (%s", $item->{id}, $item->{title}, $item->{priority};
      $md .= ", \@$item->{assignee}" if $item->{assignee};
      $md .= ")";
      $md .= " — $item->{note}" if $item->{note};
      $md .= "\n";
    }
    $md .= "\n";
  }

  $md .= "<!-- END kanban-md context -->\n";
  return $md;
}

sub _write_to_file {
  my ($self, $md) = @_;
  require Path::Tiny;
  my $file = Path::Tiny::path($self->write_to);

  if ($file->exists) {
    my $content = $file->slurp_utf8;
    if ($content =~ /<!-- BEGIN kanban-md context -->.*<!-- END kanban-md context -->/s) {
      $content =~ s/<!-- BEGIN kanban-md context -->.*<!-- END kanban-md context -->\n?/$md/s;
      $file->spew_utf8($content);
    } else {
      my $sep = $content =~ /\n$/ ? "\n" : "\n\n";
      $file->spew_utf8($content . $sep . $md);
    }
  } else {
    $file->spew_utf8($md);
  }

  printf "Context written to %s\n", $self->write_to;
}

sub _task_item {
  my ($self, $task, $note) = @_;
  return {
    id       => $task->id,
    title    => $task->title,
    status   => $task->status,
    priority => $task->priority,
    ($task->has_assignee ? (assignee => $task->assignee) : ()),
    ($note ? (note => $note) : ()),
  };
}

sub _pri_order {
  my ($self, $task) = @_;
  my %order = (critical => 0, high => 1, medium => 2, low => 3);
  return $order{$task->priority} // 2;
}

sub _count_overdue {
  my ($self, $tasks, $terminal) = @_;
  my $now = gmtime->strftime('%Y-%m-%d');
  return scalar grep { $_->has_due && $_->due lt $now && !$terminal->{$_->status} } @$tasks;
}

sub _load_tasks {
  my ($self) = @_;
  my $dir = $self->tasks_dir;
  return () unless $dir->exists;
  my @files = sort $dir->children(qr/\.md$/);
  return map { App::karr::Task->from_file($_) } @files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Context - Generate board context summary for embedding

=head1 VERSION

version 0.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
