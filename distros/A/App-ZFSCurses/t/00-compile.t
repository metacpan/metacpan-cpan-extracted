#!/usr/bin/env perl
use strict;
use warnings;

use Capture::Tiny qw#capture#;
use Test::More;

my @module_files = qw{
  App/ZFSCurses/UI.pm
  App/ZFSCurses/Text.pm
  App/ZFSCurses/Backend.pm
  App/ZFSCurses/WidgetFactory.pm
};

my @warnings = ();

for my $lib (@module_files) {
    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Mblib', '-e', qq{require qq[$lib]});
    };
    is($?, 0, "$lib loaded ok");
    warn $stderr if $stderr;
    push @warnings, $stderr if $stderr;
}

is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};

done_testing;
