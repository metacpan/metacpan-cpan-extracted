#
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use warnings;
use strict;

use InlineX::C2XS qw( c2xs );

my $module    = 'Comedi::Lib';
my $pkg       = $module;
my $options   = {
   VERSION           => '0.24',
   TYPEMAPS          => 'map/typemap',
   WRITE_MAKEFILE_PL => 1,
   LIBS              => '-lcomedi',
   WRITE_PM          => 1
};

c2xs( $module, $pkg, $options);
