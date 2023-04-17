#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest forward => \&forward;
sub forward {
	my (@asm, @out);
	my $label= 0;
	for my $op (qw( jmp je jne ja jae jb jbe jl jle jg jge js jns jo jno jpe jpo jrcxz loop loopz loopnz )) {
		++$label;
		my $asm= "$op label$label\nnop\nlabel$label: nop\n";
		my $writer= new_writer->$op("label$label")->nop->label("label$label")->nop;
		# Test far jumps for all but the CX conditional jumps which can only be 8-bit
		unless ($op =~ /cx|loop/) {
			$asm .= "$op far_label$label\n" . ("nop\n" x 128) . "far_label$label: nop\n";
			$writer->$op("far_label$label")->nop(128)->label("far_label$label")->nop;
		}
		push @asm, $asm;
		push @out, $writer->bytes;
	}
	asm_ok( \@out, \@asm, 'conditional jump' );
	done_testing;
}

subtest backward => \&backward;
sub backward {
	my (@asm, @out);
	my $label= 0;
	for my $op (qw( jmp je jne ja jae jb jbe jl jle jg jge js jns jo jno jpe jpo jrcxz loop loopz loopnz )) {
		++$label;
		my $asm= "label$label: nop\n$op label$label\n";
		my $writer= new_writer->label("label$label")->nop->$op("label$label");
		# Test far jumps for all but the CX conditional jumps which can only be 8-bit
		unless ($op =~ /cx|loop/) {
			$asm .= ("nop\n" x 128) . "$op label$label\n";
			$writer->nop(128)->$op("label$label")->bytes;
		}
		push @asm, $asm;
		push @out, $writer->bytes;
	}
	asm_ok( \@out, \@asm, 'conditional jump' );
	done_testing;
}

subtest jmp_abs_reg => \&jmp_abs_reg;
sub jmp_abs_reg {
	my (@asm, @out);
	for my $reg (@r64) {
		push @asm, "jmp $reg";
		push @out, new_writer->jmp_abs_reg($reg)->bytes;
	}
	asm_ok( \@out, \@asm, 'jmp REG' );
	
	done_testing;
}

subtest jmp_abs_mem => \&jmp_abs_mem;
sub jmp_abs_mem {
	my (@asm, @out);
	iterate_mem_addr_combos(
		\@asm, sub { "jmp $_[0]" },
		\@out, sub { new_writer->jmp_abs_mem([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'jmp [MEM...]' );
	
	done_testing;
}

done_testing;
