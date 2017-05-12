#!/usr/bin/env perl

use lib 'lib';
use Code::CutNPaste;
use Test::Most;

ok my $cutnpaste = Code::CutNPaste->new(
    dirs         => 't/fixtures',
    renamed_vars => 1,
    renamed_subs => 1,
    noutf8       => 1,
);
$cutnpaste->find_dups;
my $duplicates = $cutnpaste->duplicates;
ok @$duplicates, 'We should be able to find duplicates';

foreach my $duplicate (@$duplicates) {
    my ( $left, $right )  = ($duplicate->left, $duplicate->right);
    explain sprintf <<'END', $left->file, $left->line, $right->file, $right->line;
Possible duplicate code found
Left:  %s line %d
Right: %s line %d

END
    explain $duplicate->report;
    explain "\n";
}

done_testing;
