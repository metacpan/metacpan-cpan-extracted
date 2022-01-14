package Data::Tubes::Util::Cache;
use strict;
use warnings;
use English qw< -no_match_vars >;
use 5.010;
our $VERSION = '0.738';
use File::Path qw< mkpath >;

use File::Spec::Functions qw< splitpath catpath >;
use Storable qw< nstore retrieve >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Mo qw< default >;
has repository => (default => sub { return {} });
has __filenames => (default => sub { return undef });
has max_items => (default => 0);

sub _path {
   my ($dir, $filename) = @_;
   my ($v, $d) = splitpath($dir, 'no-file');
   return catpath($v, $d, $filename);
}

sub get {
   my ($self, $key) = @_;
   my $repo = $self->repository();
   if (ref($repo) eq 'HASH') {
      return unless exists $repo->{$key};
      return $repo->{$key};
   }
   my $path = _path($repo, $key);
   return retrieve($path) if -r $path;
   return;
} ## end sub get

sub _filenames {
   my $self = shift;
   if (my $retval = $self->__filenames()) {
      return $retval;
   }
   my $repo = $self->repository();
   my ($v, $d) = splitpath($repo, 'no-file');
   opendir my $dh, $repo or return;
   my @filenames = map { catpath($v, $d, $_) } readdir $dh;
   closedir $dh;
   $self->__filenames(\@filenames);
   return \@filenames;
}

sub purge {
   my $self = shift;
   my $max  = $self->max_items() or return;
   my $repo = $self->repository();

   if (ref($repo) eq 'HASH') {
      my $n = scalar keys %$repo;
      delete $repo->{(keys %$repo)[0]} while $n-- > $max;
      return;
   }

   my $filenames = $self->_filenames() or return;
   while (@$filenames > $max) {
      my $filename = shift @$filenames;
      unlink $filename;
   }
   return;
} ## end sub purge

sub set {
   my ($self, $key, $data) = @_;
   my $repo = $self->repository();
   return $repo->{$key} = $data if ref($repo) eq 'HASH';
   eval {
      mkpath($repo) unless -d $repo;
      nstore($data, _path($repo, $key));
      1;
   } or LOGWARN $EVAL_ERROR;
   return $data;
}
