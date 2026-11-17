#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Alien;
use Env qw( @PATH );
use Alien::gettext;

alien_ok 'Alien::gettext';

# bin_dir is an empty list on a system install (the tools are already on PATH)
# and the share dir's bin/ on a share install.
unshift @PATH, Alien::gettext->bin_dir;

for my $tool (qw( msgfmt xgettext )) {
  run_ok([ $tool, '--version' ], "$tool --version runs")
    ->success
    ->out_like(qr/^\Q$tool\E \(GNU gettext-tools\) \d+\.\d+/m);
}

done_testing;
