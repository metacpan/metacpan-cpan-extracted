package App::WRT::Mock::FileIO;

# Partially mock FileIO (the write operations - reads are still done as
# usual).

use strict;
use warnings;

use Carp;
use App::WRT::Util;

sub new {
  my $class = shift;

  my %params = (
    'io'            => App::WRT::FileIO->new(),
    'file_contents' => { },
  );

  my $self = \%params;
  bless $self, $class;
}

sub dir_list {
  my $self = shift;
  return $self->{io}->dir_list(@_);
}

sub file_put_contents {
  my $self = shift;
  my ($file, $contents) = @_;
  $self->{file_contents}->{$file} = $contents; 
}

sub file_get_contents {
  my $self = shift;
  return $self->{io}->file_get_contents(@_);
}

sub file_copy {
  my ($self, $source, $dest) = @_;
}

sub dir_make {
  my ($self, $path) = @_;
  my $path_err;
  return 1;
}

1;
