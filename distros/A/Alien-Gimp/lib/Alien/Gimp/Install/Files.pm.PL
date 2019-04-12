#!perl -w

use strict;
use warnings;

require './common.pl';
my $build_hash = ag_getbuild();

my $pkg = ExtUtils::Depends->new('Alien::Gimp');
my $eud_files = shift;
$pkg->set_inc($build_hash->{cflags});
$pkg->set_libs($build_hash->{pluginlibs});
$pkg->save_config($eud_files);
