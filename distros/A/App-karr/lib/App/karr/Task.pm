# ABSTRACT: Task object representing a single kanban card

package App::karr::Task;
our $VERSION = '0.102';
use Moo;
use YAML::XS qw( Load Dump );
use Path::Tiny;
use Time::Piece;
use JSON::MaybeXS qw( encode_json );


has id         => ( is => 'ro', required => 1 );
has title      => ( is => 'rw', required => 1 );
has status     => ( is => 'rw', default => sub { 'backlog' } );
has priority   => ( is => 'rw', default => sub { 'medium' } );
has assignee   => ( is => 'rw', predicate => 1 );
has tags       => ( is => 'rw', default => sub { [] } );
has due        => ( is => 'rw', predicate => 1 );
has estimate   => ( is => 'rw', predicate => 1 );
has class      => ( is => 'rw', default => sub { 'standard' } );
has parent     => ( is => 'rw', predicate => 1 );
has depends_on => ( is => 'rw', default => sub { [] } );
has body       => ( is => 'rw', default => sub { '' } );
has created    => ( is => 'ro', default => sub { gmtime->datetime . 'Z' } );
has updated    => ( is => 'rw', default => sub { gmtime->datetime . 'Z' } );
has claimed_by => ( is => 'rw', predicate => 1 );
has claimed_at => ( is => 'rw', predicate => 1 );
has blocked    => ( is => 'rw', predicate => 1 );
has started    => ( is => 'rw', predicate => 1 );
has completed  => ( is => 'rw', predicate => 1 );
has file_path  => ( is => 'rw', predicate => 1 );

sub slug {
  my ($self) = @_;
  my $slug = lc($self->title);
  $slug =~ s/[^a-z0-9]+/-/g;
  $slug =~ s/^-|-$//g;
  $slug = substr($slug, 0, 50);
  return $slug;
}

sub filename {
  my ($self) = @_;
  return sprintf('%03d-%s.md', $self->id, $self->slug);
}

sub to_frontmatter {
  my ($self) = @_;
  my %fm = (
    id       => $self->id,
    title    => $self->title,
    status   => $self->status,
    priority => $self->priority,
    created  => $self->created,
    updated  => $self->updated,
    class    => $self->class,
  );
  $fm{assignee}   = $self->assignee   if $self->has_assignee;
  $fm{tags}       = $self->tags       if @{$self->tags};
  $fm{due}        = $self->due        if $self->has_due;
  $fm{estimate}   = $self->estimate   if $self->has_estimate;
  $fm{parent}     = $self->parent     if $self->has_parent;
  $fm{depends_on} = $self->depends_on if @{$self->depends_on};
  $fm{claimed_by} = $self->claimed_by if $self->has_claimed_by;
  $fm{claimed_at} = $self->claimed_at if $self->has_claimed_at;
  $fm{blocked}    = $self->blocked    if $self->has_blocked;
  $fm{started}    = $self->started    if $self->has_started;
  $fm{completed}  = $self->completed  if $self->has_completed;
  return \%fm;
}

sub to_markdown {
  my ($self) = @_;
  my $yaml = Dump($self->to_frontmatter);
  $yaml =~ s/\A---\n//;
  my $md = "---\n${yaml}---\n";
  $md .= "\n" . $self->body . "\n" if $self->body;
  return $md;
}

sub _parse_content {
  my ($class, $content) = @_;
  my ($yaml, $body) = $content =~ m{\A---\n(.+?)---(?:\n(.*))?\z}s
    or die "Invalid task format\n";
  $body //= '';
  $body =~ s/^\n//;
  $body =~ s/\n$//;
  return (Load($yaml), $body);
}

sub from_string {
  my ($class, $content) = @_;
  my ($fm, $body) = $class->_parse_content($content);
  return $class->new(%$fm, body => $body);
}

sub from_file {
  my ($class, $file) = @_;
  $file = path($file);
  my ($fm, $body) = $class->_parse_content($file->slurp_utf8);
  return $class->new(%$fm, body => $body, file_path => $file);
}

sub save {
  my ($self, $dir) = @_;
  $self->updated(gmtime->datetime . 'Z');
  my $file = $dir ? path($dir)->child($self->filename) : path($self->file_path);
  $file->spew_utf8($self->to_markdown);
  $self->file_path($file);
  return $file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Task - Task object representing a single kanban card

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    my $task = App::karr::Task->new(
      id    => 1,
      title => 'Fix login bug',
    );

    $task->save('/tmp/karr-materialized/tasks');
    my $same = App::karr::Task->from_file('/tmp/karr-materialized/tasks/001-fix-login-bug.md');

=head1 DESCRIPTION

L<App::karr::Task> models a single task card and knows how to translate between
the in-memory object and the Markdown plus YAML frontmatter format used on
disk and in Git refs. The same Markdown document is stored in
C<refs/karr/tasks/*/data> and in temporary task files that commands materialize
while they run.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::BoardStore>, L<App::karr::Git>,
L<App::karr::Config>

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
