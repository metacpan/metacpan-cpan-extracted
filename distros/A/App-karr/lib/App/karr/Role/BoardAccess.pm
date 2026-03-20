# ABSTRACT: Role providing board directory discovery and config access

package App::karr::Role::BoardAccess;
our $VERSION = '0.003';
use Moo::Role;
use Path::Tiny;
use YAML::XS qw( LoadFile DumpFile );
use Carp qw( croak );

has board_dir => (
  is => 'lazy',
);

has config => (
  is => 'lazy',
);

sub _build_board_dir {
  my ($self) = @_;
  if ($self->can('has_dir') && $self->has_dir) {
    return path($self->dir);
  }
  my $dir = path('.')->absolute;
  while (1) {
    my $candidate = $dir->child('karr');
    return $candidate if $candidate->is_dir && $candidate->child('config.yml')->exists;
    last if $dir->is_rootdir;
    $dir = $dir->parent;
  }
  croak "No karr board found. Run 'karr init' to create one.";
}

sub _build_config {
  my ($self) = @_;
  my $config_file = $self->board_dir->child('config.yml');
  croak "No config.yml found in " . $self->board_dir unless $config_file->exists;
  return LoadFile($config_file->stringify);
}

sub save_config {
  my ($self) = @_;
  DumpFile($self->board_dir->child('config.yml')->stringify, $self->config);
}

sub tasks_dir {
  my ($self) = @_;
  my $name = $self->config->{tasks_dir} // 'tasks';
  return $self->board_dir->child($name);
}

sub find_task {
  my ($self, $id) = @_;
  my $dir = $self->tasks_dir;
  return undef unless $dir->exists;
  require App::karr::Task;
  for my $file ($dir->children(qr/\.md$/)) {
    if ($file->basename =~ /^0*${id}-/) {
      return App::karr::Task->from_file($file);
    }
  }
  return undef;
}

sub load_tasks {
  my ($self) = @_;
  my $dir = $self->tasks_dir;
  return () unless $dir->exists;
  require App::karr::Task;
  my @files = sort $dir->children(qr/\.md$/);
  return map { App::karr::Task->from_file($_) } @files;
}

sub parse_ids {
  my ($self, $id_str) = @_;
  return split /,/, $id_str;
}

sub sync_before {
  my ($self) = @_;
  require App::karr::Git;
  my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
  return unless $git->is_repo;
  $git->pull;
  $self->_materialize_from_refs($git);
}

sub sync_after {
  my ($self) = @_;
  require App::karr::Git;
  my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
  return unless $git->is_repo;
  $self->_serialize_to_refs($git);
  $git->push;
}

sub _materialize_from_refs {
  my ($self, $git) = @_;
  my @ids = $git->list_task_refs;
  my $tasks_dir = $self->tasks_dir;
  $tasks_dir->mkpath;

  # Serialize locally-created tasks first
  if ($tasks_dir->exists) {
    for my $file ($tasks_dir->children(qr/\.md$/)) {
      require App::karr::Task;
      my $task = App::karr::Task->from_file($file);
      my $ref_content = $git->read_ref("refs/karr/tasks/" . $task->id . "/data");
      unless ($ref_content) {
        $git->save_task_ref($task);
        push @ids, $task->id unless grep { $_ == $task->id } @ids;
      }
    }
    # Clear stale files
    for my $old_file ($tasks_dir->children(qr/\.md$/)) {
      $old_file->remove;
    }
  }

  # Materialize from refs
  for my $id (@ids) {
    my $task = $git->load_task_ref($id);
    next unless $task;
    $task->save($tasks_dir);
  }

  # Materialize config with next_id merge
  my $config_content = $git->read_ref('refs/karr/config');
  if ($config_content) {
    require YAML::XS;
    my $local_config_file = $self->board_dir->child('config.yml');
    if ($local_config_file->exists) {
      my $remote_config = YAML::XS::Load($config_content);
      my $local_config = YAML::XS::LoadFile($local_config_file->stringify);
      my $local_nid = $local_config->{next_id} // 1;
      my $remote_nid = $remote_config->{next_id} // 1;
      $remote_config->{next_id} = $local_nid > $remote_nid ? $local_nid : $remote_nid;
      YAML::XS::DumpFile($local_config_file->stringify, $remote_config);
    } else {
      $local_config_file->spew_utf8($config_content);
    }
  }
}

sub _serialize_to_refs {
  my ($self, $git) = @_;
  for my $task ($self->load_tasks) {
    $git->save_task_ref($task);
  }
  my $config_file = $self->board_dir->child('config.yml');
  if ($config_file->exists) {
    $git->write_ref('refs/karr/config', $config_file->slurp_utf8);
  }
}

sub append_log {
  my ($self, $git, %entry) = @_;
  require JSON::MaybeXS;
  require POSIX;
  $entry{ts} //= POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
  my $identity = $git->git_user_email || 'unknown';
  $identity =~ s/[^a-zA-Z0-9._-]/_/g;
  my $ref = "refs/karr/log/$identity";
  my $existing = $git->read_ref($ref);
  my $line = JSON::MaybeXS::encode_json(\%entry);
  my $new = $existing ? "$existing\n$line" : $line;
  $git->write_ref($ref, $new);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::BoardAccess - Role providing board directory discovery and config access

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
