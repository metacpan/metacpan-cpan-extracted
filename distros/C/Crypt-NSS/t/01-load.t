#!/usr/bin/perl

use strict;

use Test::More tests => 8;
use File::Spec;

BEGIN { use_ok("Crypt::NSS"); }
is(Crypt::NSS->config_dir, ".");

my $config_dir = File::Spec->catdir(".", "db");

ok(Crypt::NSS->set_config_dir($config_dir));
is(Crypt::NSS->config_dir, $config_dir);

ok(!Crypt::NSS->is_initialized());
is(Crypt::NSS->initialize(), 0);
ok(Crypt::NSS->is_initialized());

ok(!Crypt::NSS->set_config_dir($config_dir));
