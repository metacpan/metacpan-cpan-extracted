#!/usr/bin/env perl

use strict;
use Alien::GPG::Error;

my @cmd;
push @cmd, './configure';
push @cmd, '--with-gpg-error-prefix='. Alien::GPG::Error->dist_dir;
push @cmd, @ARGV;

system("@cmd");
