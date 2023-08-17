#!/usr/bin/env perl

use strict;
use warnings;

use Alien::libpopt;

print 'cflags: '.Alien::libpopt->cflags."\n";
print 'cflags_static: '.Alien::libpopt->cflags_static."\n";
print 'dist_dir: '.Alien::libpopt->dist_dir."\n";
print 'libs: '.Alien::libpopt->libs."\n";
print 'libs_static: '.Alien::libpopt->libs_static."\n";
print 'version: '.Alien::libpopt->version."\n";

# Output like (Debian 11.7 system popt library):
# cflags:  
# cflags_static:  
# dist_dir: /home/skim/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-libpopt
# libs: -L/usr/lib/x86_64-linux-gnu -lpopt 
# libs_static: -L/usr/lib/x86_64-linux-gnu -lpopt 
# version: 1.18