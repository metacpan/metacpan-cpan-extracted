package Alien::Base::ModuleBuild::Cabinet;

use strict;
use warnings;

our $VERSION = '1.03';

use Sort::Versions qw( versioncmp );

sub new {
  my $class = shift;
  my $self = ref $_[0] ? shift : { @_ };

  bless $self, $class;

  return $self;
}

sub files { shift->{files} }

sub add_files {
  my $self = shift;
  push @{ $self->{files} }, @_;
  return $self->files;
}

sub sort_files {
  my $self = shift;

  $self->{files} = [
    sort { $b->has_version <=> $a->has_version || ($a->has_version ? versioncmp($b->version, $a->version) : versioncmp($b->filename, $a->filename)) }
    @{ $self->{files} }
  ];

  ## split files which have versions and those which don't (sorted on filename)
  #my ($name, $version) = part { $_->has_version } @{ $self->{files} };
  #
  ## store the sorted lists of versioned, then non-versioned
  #my @sorted;
  #push @sorted, sort { versioncmp( $b->version,  $a->version  ) } @$version if $version;
  #push @sorted, sort { versioncmp( $b->filename, $a->filename ) } @$name    if $name;
  #
  #$self->{files} = \@sorted;

  return;
}

1;

