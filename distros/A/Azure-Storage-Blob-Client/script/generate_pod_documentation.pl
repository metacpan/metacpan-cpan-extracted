#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Markdown::Pod;


my $readme = 'README.md';
my $content = do {
  local $/ = undef;
  open my $fh, '<', $readme
    or die "Could not open $readme: $!";
  <$fh>;
};

say Markdown::Pod->new->markdown_to_pod(
  markdown => $content,
);
