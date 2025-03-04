#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer asm_ok @r64 @immed32 iterate_mem_addr_combos );
use Test::More;

my (@asm, @out);
for my $reg (@r64) {
	push @asm, "push $reg\npop $reg";
	push @out, new_writer->push($reg)->pop($reg)->bytes;
}
iterate_mem_addr_combos(
	\@asm, sub { "push qword $_[0]" },
	\@out, sub { new_writer->push([@_], 64)->bytes }
);
for my $immed (@immed32) {
	push @asm, "push qword $immed";
	push @out, new_writer->push($immed, 64)->bytes;
}

asm_ok( \@out, \@asm, 'push / pop' );

done_testing;
