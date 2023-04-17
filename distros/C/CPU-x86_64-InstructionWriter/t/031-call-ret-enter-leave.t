#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest call => \&call;
sub call {
	my (@asm, @out);

	# Forward call
	push @asm, "call label0\nnop\nlabel0: nop\n";
	push @out, new_writer->call_label("label0")->nop->label("label0")->nop->bytes;

	# Backward call
	push @asm, "label1: nop\nnop\nnop\ncall label1\n";
	push @out, new_writer->label("label1")->nop(3)->call_label("label1")->bytes;

	# Call to numeric offset
	# I can't get micro-examples to assemble correctly with nasm, so no reference to go by...
	#for my $imm (-1, 0, 1) {
	#	#my $nasm_ofs= $imm + 5; # Nasm counts from start of instruction for some reason?
	#	push @asm, "mov rax, 0xFFFFFFFF; call $imm; mov rax, 0xFFFFFFFF;";
	#	push @out, new_writer->mov64_reg_imm('rax', 0xFFFFFFFF)
	#		->call_rel($imm)
	#		->mov64_reg_imm('rax', 0xFFFFFFFF)
	#		->mov64_reg_imm('rax', 0xFFFFFFFF)
	#		->bytes;
	#}

	# Call to absolute from register
	for my $reg (@r64) {
		push @asm, "call $reg";
		push @out, new_writer->call_abs_reg($reg)->bytes;
	}

	# Call to absolute addr in mem
	iterate_mem_addr_combos(
		\@asm, sub { "call $_[0]" },
		\@out, sub { new_writer->call_abs_mem([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'call' );
}

subtest ret => \&ret;
sub ret {
	my (@asm, @out);
	# Ret, and ret with number bytes to discard
	for my $bytes ('', 1, 0x7F) {
		push @asm, "ret $bytes";
		push @out, new_writer->ret($bytes)->bytes;
	}
	asm_ok( \@out, \@asm, 'ret' );
}

subtest enter => \&enter;
sub enter {
	my (@asm, @out);
	for my $bytes (@immed16) {
		for my $nest (0, 1, 8, 31) {
			push @asm, "enter $bytes, $nest";
			push @out, new_writer->enter($bytes, $nest)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'enter' );
}

subtest leave => \&leave;
sub leave {
	my (@asm, @out);
	# Leave
	push @asm, "leave";
	push @out, new_writer->leave->bytes;

	asm_ok( \@out, \@asm, 'leave' );
}

subtest push_ => \&push_;
sub push_ {
	my (@asm, @out);
	
	for my $reg (@r64) {
		push @asm, "push $reg";
		push @out, new_writer->push_reg($reg)->bytes;
	}
	for my $imm (@immed32) {
		push @asm, "push qword $imm";
		push @out, new_writer->push_imm($imm)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "push qword $_[0]" },
		\@out, sub { new_writer->push_mem([@_])->bytes }
	);
	
	asm_ok( \@out, \@asm, 'push' );
}

subtest pop_ => \&pop_;
sub pop_ {
	my (@asm, @out);
	
	for my $reg (@r64) {
		push @asm, "pop $reg";
		push @out, new_writer->pop_reg($reg)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "pop qword $_[0]" },
		\@out, sub { new_writer->pop_mem([@_])->bytes }
	);
	
	asm_ok( \@out, \@asm, 'push' );
}

done_testing;
