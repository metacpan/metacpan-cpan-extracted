#!/usr/bin/env perl
# Undo stack: push operations as strings, pop to undo
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Stack::Shared;
$| = 1;

my $undo = Data::Stack::Shared::Str->new(undef, 50, 128);

# simulate operations
for my $op ("create file.txt", "write 100 bytes", "chmod 644", "rename to file.bak") {
    $undo->push($op);
    printf "do: %s\n", $op;
}
printf "\nstack size: %d\n\n", $undo->size;

# undo last 2
for (1..2) {
    my $op = $undo->pop;
    printf "undo: %s\n", $op;
}
printf "remaining: %d operations to undo\n", $undo->size;
