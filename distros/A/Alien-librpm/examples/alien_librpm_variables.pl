#!/usr/bin/env perl

use strict;
use warnings;

use Alien::librpm;

print 'cflags: '.Alien::librpm->cflags."\n";
print 'cflags_static: '.Alien::librpm->cflags_static."\n";
print 'dist_dir: '.Alien::librpm->dist_dir."\n";
print 'libs: '.Alien::librpm->libs."\n";
print 'libs_static: '.Alien::librpm->libs_static."\n";
print 'version: '.Alien::librpm->version."\n";

# Output like:
# TODO