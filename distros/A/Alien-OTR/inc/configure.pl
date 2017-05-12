#!/usr/bin/env perl

use strict;
use Alien::GCrypt;

my @cmd;
push @cmd, './configure';
push @cmd, '--with-libgcrypt-prefix='. Alien::GCrypt->dist_dir;
push @cmd, @ARGV;

system("@cmd");
