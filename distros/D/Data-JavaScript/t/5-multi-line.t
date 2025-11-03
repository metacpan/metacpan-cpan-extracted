#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered/;

use Data::JavaScript qw(:all);

my $input = <<'EOF',
This is a multi-line entry.
See? I have two lines.
Now there are three lines!
EOF

my $expected = qq/var multiline = "This is a multi-line entry.\\nSee? I have two lines.\\nNow there are three lines!\\n";\n/;

is
  jsdump( 'multiline', $input ),
  $expected,
  'Multi-line jsdump()';

done_testing;
