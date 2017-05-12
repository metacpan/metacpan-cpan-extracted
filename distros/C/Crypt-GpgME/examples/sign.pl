#!/usr/bin/env perl

use strict;
use warnings;
use Crypt::GpgME;

my $ctx = Crypt::GpgME->new;

$ctx->set_passphrase_cb(sub { q/foo/ });

my $plain = q/test test test/;
my $signed = $ctx->sign($plain, 'clear');

print while <$signed>;
