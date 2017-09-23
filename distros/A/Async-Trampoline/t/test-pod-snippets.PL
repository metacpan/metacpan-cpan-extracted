#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use feature 'say';

use Test::Pod::Snippets;

my @files = qw(
    lib/Async/Trampoline.pm
);

my $compiler = Test::Pod::Snippets->new(
    preserve_lines => 1,
);

for my $file (@files) {
    my $slug = $file;
    s|^lib/||, s/\.pm$//, s/[^\w]+/-/g, s/^-|-$//g for $slug;
    my $output = "t/podsnippets-$slug.t";

    say "extracting tests from $file";

    $compiler->generate_test_file(
        file => $file,
        output => $output,
        standalone => 1,
    );
}
