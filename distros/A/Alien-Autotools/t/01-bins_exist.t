#!/usr/bin/env perl

use Test::More tests => 3;
use strict;
use warnings FATAL => "all";
use Alien::Autotools qw(autoconf_dir automake_dir libtool_dir);
use File::Spec::Functions qw(catfile);

ok -x catfile( autoconf_dir(), "autoconf" ), "autoconf found and is executable";
ok -x catfile( automake_dir(), "automake" ), "automake found and is executable";
ok -x catfile( libtool_dir(), "libtool" ), "libtool found and is executable";
