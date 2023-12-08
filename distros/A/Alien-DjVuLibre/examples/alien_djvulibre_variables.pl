#!/usr/bin/env perl

use strict;
use warnings;

use Alien::DjVuLibre;

print 'cflags: '.Alien::DjVuLibre->cflags."\n";
print 'cflags_static: '.Alien::DjVuLibre->cflags_static."\n";
print 'dist_dir: '.Alien::DjVuLibre->dist_dir."\n";
print 'libs: '.Alien::DjVuLibre->libs."\n";
print 'libs_static: '.Alien::DjVuLibre->libs_static."\n";
print 'version: '.Alien::DjVuLibre->version."\n";

# Output like:
# cflags: -pthread
# cflags_static: -pthread
# dist_dir: ~/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-DjVuLibre
# libs: -ldjvulibre
# libs_static: -ldjvulibre -ljpeg -lpthread -lm
# version: 3.5.28