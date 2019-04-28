#!perl -w

use strict;
use warnings;
use ExtUtils::Depends;

require './common.pl';
my $build_hash = get_build();

my $pkg = ExtUtils::Depends->new('Alien::HDF4');
my $eud_files = shift;
$pkg->set_inc($build_hash->{cflags});
$pkg->set_libs($build_hash->{libs});
$pkg->save_config($eud_files);
