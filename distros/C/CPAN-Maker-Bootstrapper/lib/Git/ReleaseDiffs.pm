#!/usr/bin/env perl
package Git::ReleaseDiffs;

use strict;
use warnings;

use Git::Raw;
use Archive::Tar;
use Cwd qw(getcwd);
use Data::Dumper;
use File::Basename qw(basename);
use CLI::Simple::Utils qw(slurp);

use version;

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(repo last_tag diffs diff_list repo_path release_version));

caller or exit __PACKAGE__->main;

########################################################################
sub _last_tag {
########################################################################
  my ( $self, $repo ) = @_;

  my @tags = map { basename( $_->name ) } grep { $_->name =~ /\d+[.]\d+[.]\d+$/xsm } $repo->tags;

  return
    if !@tags;

  @tags = reverse sort { version->parse($a) <=> version->parse($b) } @tags;

  return $tags[0];
}

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{repo_path} //= getcwd;

  my $self = $class->SUPER::new($options);

  die "ERROR: directory not found\n"
    if !-d $self->get_repo_path;

  die sprintf "ERROR: not a git repository (%s)\n", $self->get_repo_path
    if !-d sprintf '%s/.git', $self->get_repo_path;

  if ( !$self->get_release_version ) {
    my $release_version = eval { slurp('VERSION') };
    die "ERROR: could not determine release version\n"
      if !$release_version;

    chomp $release_version;

    $self->set_release_version($release_version);
  }

  my $repo = Git::Raw::Repository->open( $self->get_repo_path );

  $self->set_repo($repo);

  $self->set_last_tag( $ENV{LAST_TAG} // $self->_last_tag($repo) );

  $self->_diffs;

  return $self;
}

########################################################################
sub _diffs {
########################################################################
  my ($self) = @_;

  my $repo = $self->get_repo;
  my $tag  = sprintf 'refs/tags/%s', $self->get_last_tag;
  my $ref  = Git::Raw::Reference->lookup( $tag, $repo );

  my $commit = $ref->peel('commit');

  my $index = $repo->index;
  $index->read;
  my $index_tree = $index->write_tree;

  my $diff = $commit->tree->diff( $index_tree, {} );

  $self->set_diffs( $diff->buffer('patch') );

  my @files = map { $_->new_file->path }
    grep { $_->status =~ /^(?:added|modified|renamed)$/xsm } $diff->deltas;

  $self->set_diff_list( \@files );

  return;
}

########################################################################
sub write_diffs {
########################################################################
  my ($self) = @_;

  my $file = sprintf 'release-%s.diffs', $self->get_release_version;

  open my $fh, '>', $file
    or die "ERROR: could not open $file for writing: $!\n";

  print {$fh} $self->get_diffs;

  close $fh;

  return $file;
}

########################################################################
sub write_list {
########################################################################
  my ($self) = @_;

  my $file = sprintf 'release-%s.lst', $self->get_release_version;

  open my $fh, '>', $file
    or die "ERROR: could not open $file for writing: $!\n";

  print {$fh} "$_\n" for @{ $self->get_diff_list };

  close $fh;

  return $file;
}

########################################################################
sub write_tarball {
########################################################################
  my ($self) = @_;

  my $tag = $self->get_release_version;

  my $tarball = sprintf 'release-%s.tar.gz', $tag;
  my $prefix  = sprintf 'release-%s',        $tag;

  my $tar = Archive::Tar->new;

  for my $file ( @{ $self->get_diff_list } ) {
    if ( -e $file ) {
      $tar->add_files($file);
      $tar->rename( $file, "$prefix/$file" );
    }
    else {
      warn "WARNING: $file not found, skipping\n";
    }
  }

  $tar->write( $tarball, COMPRESS_GZIP );

  return $tarball;
}

########################################################################
sub main {
########################################################################

  my $repo_path = shift @ARGV;

  my $release = Git::ReleaseDiffs->new( repo_path => $repo_path );

  my $diffs   = $release->write_diffs;
  my $list    = $release->write_list;
  my $tarball = $release->write_tarball;

  printf "wrote: %s\n", $_ for ( $diffs, $list, $tarball );

  return 0;
}
