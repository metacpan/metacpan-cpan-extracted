#!/usr/bin/perl

use strict;
use warnings;
use Alien::MSYS;
use File::Basename qw( dirname );
use File::Spec;

print "hello libtool! ARGV: @ARGV";

#my $sh_script = File::Spec->catfile(dirname(__FILE__), 'libtool');
#
#msys { exec $sh_script, @ARGV };
