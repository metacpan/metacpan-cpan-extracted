# ABSTRACT: Create a new task

package App::karr::Cmd::Create;
our $VERSION = '0.101';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr create --title TEXT [--priority LEVEL] [--status STATUS] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Task;
use App::karr::Config;

with 'App::karr::Role::BoardAccess';


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

  $self->sync_before;

  my $title = $self->title // $args_ref->[0]
    or die "Title is required. Use --title or pass as argument.\n";

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );
  my $defaults = $config->data->{defaults} // {};

  my %task_args = (
    id       => $self->allocate_next_id,
    title    => $title,
    status   => $self->status   // $defaults->{status}   // 'backlog',
    priority => $self->priority // $defaults->{priority}  // 'medium',
    class    => $self->class    // $defaults->{class}     // 'standard',
  );

  $task_args{assignee} = $self->assignee if $self->assignee;
  $task_args{tags}     = [split /,/, $self->tags] if $self->tags;
  $task_args{due}      = $self->due if $self->due;
  $task_args{estimate} = $self->estimate if $self->estimate;
  $task_args{body}     = $self->body if $self->body;

  my $task = App::karr::Task->new(%task_args);
  my $file = $task->save($self->tasks_dir);

  $self->sync_after;

  printf "Created task %d: %s (%s)\n", $task->id, $task->title, $file->basename;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Create - Create a new task

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    karr create "Fix login bug"
    karr create --title "Write release notes" --priority high --status todo
    karr create --title "Review API" --tags docs,review --body "Check CLI help"

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

=item * C<--body>

Adds Markdown body text below the YAML frontmatter.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Move>

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
