#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok('Alien::ggml') }

diag "Alien::ggml version: $Alien::ggml::VERSION";
diag "Install type: " . Alien::ggml->install_type;
diag "cflags: " . Alien::ggml->cflags;
diag "libs: " . Alien::ggml->libs;

# Check that we have cflags and libs
my $cflags = Alien::ggml->cflags;
ok(defined $cflags, 'cflags is defined');
like($cflags, qr/-I/, 'cflags contains -I');

my $libs = Alien::ggml->libs;
ok(defined $libs, 'libs is defined');
like($libs, qr/-lggml/, 'libs contains -lggml');

done_testing();
