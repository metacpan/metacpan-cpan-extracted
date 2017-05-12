#!/usr/bin/perl

use strict;
use warnings;
use Alien::MSYS;
use File::Basename qw( dirname );
use File::Spec;

my $sh_script = File::Spec->catfile(dirname(__FILE__), 'libtoolize');

msys { exec $sh_script, @ARGV };
