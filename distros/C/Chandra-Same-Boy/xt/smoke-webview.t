#!perl
# Manual webview smoke test: actually opens a window and plays a ROM.
#
# A webview cannot run headless, so this never runs in CI. To use it:
#
#   SAMEBOY_MANUAL=1 SAMEBOY_ROM=/path/to/game.gbc perl -Ilib xt/smoke-webview.t
#
# It opens the emulator window; close it to finish. Requires Same::Boy >= 0.03.
use strict;
use warnings;
use Test::More;

plan skip_all => 'manual: set SAMEBOY_MANUAL=1 and SAMEBOY_ROM=<rom> to run'
    unless $ENV{SAMEBOY_MANUAL} && $ENV{SAMEBOY_ROM} && -f $ENV{SAMEBOY_ROM};

require Chandra::Same::Boy::App;

Chandra::Same::Boy::App->new(
    title => 'Same::Boy smoke test',
    rom   => $ENV{SAMEBOY_ROM},
    scale => 3,
)->run;

pass('webview window closed cleanly');
done_testing;
