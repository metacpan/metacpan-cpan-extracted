# ABSTRACT: Role providing board directory discovery and config access

package App::karr::Role::BoardAccess;
our $VERSION = '0.101';
use Moo::Role;
use Path::Tiny;
use YAML::XS qw( LoadFile DumpFile );
use Carp qw( croak );
use File::Temp qw( tempdir );


has board_dir => (
  is => 'lazy',
  clearer => '_clear_board_dir',
);

has config => (
  is => 'lazy',
  clearer => '_clear_config',
);

has git_root => (
  is => 'lazy',
);

has store => (
  is => 'lazy',
);

sub _build_board_dir {
  my ($self) = @_;
  my $store = $self->store;
  $store->git->pull;
  croak "No karr board found. Run 'karr init' to create one.\n"
    unless $store->board_exists;

  my $dir = path( tempdir( CLEANUP => 1 ) );
  $store->materialize_to($dir);
  return $dir;
}

sub _build_git_root {
  my ($self) = @_;
  require App::karr::Git;

  my $start = $self->can('has_dir') && $self->has_dir
    ? path($self->dir)->absolute
    : path('.')->absolute;

  while (1) {
    my $git = App::karr::Git->new( dir => $start->stringify );
    my $root = $git->repo_root;
    return $root if $root;
    last if $start->is_rootdir;
    $start = $start->parent;
  }
  croak "Not a git repository. karr requires Git.\n";
}

sub _build_store {
  my ($self) = @_;
  require App::karr::Git;
  require App::karr::BoardStore;
  my $git = App::karr::Git->new( dir => $self->git_root->stringify );
  return App::karr::BoardStore->new( git => $git );
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
  my $git = $self->store->git;
  $git->pull;
  $self->_clear_config;
  $self->_clear_board_dir;
  $self->board_dir;
}

sub sync_after {
  my ($self) = @_;
  my $git = $self->store->git;
  $self->_serialize_to_refs($git);
  $git->push;
  $self->_clear_config;
}

sub _materialize_from_refs {
  my ($self, $git) = @_;
  return $self->store->materialize_to( $self->board_dir );
}

sub _serialize_to_refs {
  my ($self, $git) = @_;
  return $self->store->serialize_from( $self->board_dir );
}

sub allocate_next_id {
  my ($self) = @_;
  return $self->store->allocate_next_id;
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

version 0.101

=head1 DESCRIPTION

This role gives command objects a consistent way to find the current board,
load tasks, read and write configuration, and synchronise temporary board files
with the Git ref backend. Most command modules in C<karr> compose this role.

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
