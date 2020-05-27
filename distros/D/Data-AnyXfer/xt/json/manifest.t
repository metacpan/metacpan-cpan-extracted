#!/usr/bin/env perl

use Test::CheckManifest;

ok_manifest({ filter => [ qr/~$/ ] });


