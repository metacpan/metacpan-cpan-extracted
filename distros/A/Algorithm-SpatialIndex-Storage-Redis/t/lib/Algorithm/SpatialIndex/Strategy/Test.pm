package Algorithm::SpatialIndex::Strategy::Test;
use strict;
use warnings;
use parent 'Algorithm::SpatialIndex::Strategy::2D';

our $InitStorageCalled;
our $InitCalled;

sub insert {} # noop

sub init_storage {
  $InitStorageCalled = 1;
}

sub init {
  $InitCalled = 1;
}

1;
