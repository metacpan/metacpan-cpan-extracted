package CSS::Watcher::Monitor;

use strict;
use warnings;

use Carp;
use Log::Log4perl qw(:easy);
use File::Spec;
use Fcntl ':mode';
use List::MoreUtils qw(any);

our @STAT_FIELDS = qw(
                         dev inode mode num_links uid gid rdev size atime mtime ctime
                         blk_size blocks
             );

sub new {
    my $class= shift;
    my $options = shift;

    return bless ({
        dir => $options->{dir} // undef,
        oldstats => {},
    }, $class);
}

sub dir {
    my $self = shift;
    croak "dir attribute is read-only" if @_;
    return $self->{dir};
}

sub scan {
    my ($self, $callback, $skip_dirs) = @_;

    return 0 unless (defined $callback && defined $self->dir && -d $self->dir);

    my $newstat = $self->_get_files_info( $self->dir, $skip_dirs );

    my $changes = 0;
    while ( my( $fname, $stat ) = each %{$newstat->{files}} ) {
        unless ($self->_deep_compare ($self->_get_stat ($fname), $stat )) {
            $self->_set_stat ($fname, $stat);
            $callback->($fname);
            $changes++;
        }
    }
    return $changes;
}

sub is_changed {
    my ( $self, $filename ) = @_;
    my %objstat;
    @objstat{@STAT_FIELDS} = stat ( $filename );

    # this file may never present before and not exist, return false
    return 0 unless (defined ($objstat{atime}) && -f $filename);

    not $self->_deep_compare (
        $self->_get_stat ($filename),
        \%objstat);
}

sub make_dirty {
    my $self = shift;
    $self->{oldstats} = {};
}

sub _get_stat {
    my ( $self, $filename ) = @_;
    return $self->{oldstats}{$filename} // {};
}

sub _set_stat {
    my ( $self, $filename, $stat ) = @_;
    $self->{oldstats}{$filename} = $stat;
}

sub _deep_compare {
  my ( $self, $this, $that ) = @_;
  use Storable qw/freeze/;
  local $Storable::canonical = 1;
  return freeze( $this ) eq freeze( $that );
}

# Scan our target object
sub _get_files_info {
  my ( $self, $dir, $skip_dirs ) = @_;
  my %info;

  $skip_dirs ||= [];
  
  eval {
      if ( -d $dir ) {

          # Expand whole directory tree
          my @work = $self->_read_dir( $dir );
          while ( my $obj = shift @work ) {
              next              # // skip symlinks that have "../" (circular symlink)
                if ( -d $obj
                  && -l $obj
                  && readlink($obj) =~ m|\.\./| );
              if (-f $obj) {
                  my %objstat;
                  @objstat{@STAT_FIELDS} = stat ( $obj );
                  $info{ files }{ $obj } = \%objstat;
              }
              elsif ( -d $obj && ( !any { $obj =~ m/$_/; } @{$skip_dirs} ) ) {
                  # Depth first to simulate recursion
                  unshift @work, $self->_read_dir( $obj );
              }
          }
      }
  };

  $info{error} = $@;

  return \%info;
}

sub _read_dir {
  my $self = shift;
  my $dir  = shift;

  opendir( my $dh, $dir ) or LOGDIE "Can't read $dir ($!)";
  my @files = map { File::Spec->catfile( $dir, $_ ) }
   sort
   grep { $_ !~ /^[.]{1,2}$/ } readdir( $dh );
  closedir( $dh );

  return @files;
}


1;

=head1 NAME

CSS::Watcher::Monitor - Monitor files for changes.

=head1 SYNOPSIS

   use CSS::Watcher::Monitor;
   my $cm = CSS::Watcher::Monitor->new (dir => '/foo/bar');

   # return num of files modified
   $cm->scan(
             sub {
                 my $file = shift;
                 # process changed file or first scan new file
                 } );

   # Check does file changed since last $cm->scan
   say $cm->is_changed('/foo/bar/baz.txt');

   # clean old file stat cache
   $cm->make_dirty();

=head1 DESCRIPTION

Watch for changes, call callback sub. Call callback on first scan too.

=head1 SEE ALSO

File::Monitor - I get some patterns from there

=head1 AUTHOR

Olexandr Sydorchuk (olexandr.syd@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Olexandr Sydorchuk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
