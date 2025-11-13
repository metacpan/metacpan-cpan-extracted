#!/usr/bin/perl -w
# Asm::X86 - a test for intel-syntax addressing modes.
#
#	Copyright (C) 2008-2025 Bogdan 'bogdro' Drozdowski,
#	  bogdro (at) users . sourceforge . net
#	  bogdro /at\ cpan . org
#
# This file is part of Project Asmosis, a set of tools related to assembly
#  language programming.
# Project Asmosis homepage: https://asmosis.sourceforge.io/
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

use strict;
use warnings;

use Test::More;
use Asm::X86 qw(
	is_valid_16bit_addr_intel
	is_valid_32bit_addr_intel
	is_valid_64bit_addr_intel
	is_valid_addr_intel
	is_valid_16bit_addr_att
	is_valid_32bit_addr_att
	is_valid_64bit_addr_att
	is_valid_addr_att
	is_valid_16bit_addr
	is_valid_32bit_addr
	is_valid_64bit_addr
	is_valid_addr
	);

sub permute3_intel($$$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	my @result = ();

	$basereg_sign = '+' if not defined $basereg_sign or $basereg_sign eq '';
	$indexreg_sign = '+' if not defined $indexreg_sign or $indexreg_sign eq '';
	$disp_sign = '+' if not defined $disp_sign or $disp_sign eq '';
	if ( ! defined $basereg or $basereg eq '' ) {

		$basereg = undef;
	}
	if ( ! defined $indexreg or $indexreg eq '' ) {

		$indexreg = undef;
	}
	if ( ! defined $disp or $disp eq '' ) {

		$disp = undef;
	}

	if ( defined $basereg and defined $indexreg and defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "[$basereg_sign$basereg $indexreg_sign$indexreg * $scale $disp_sign$disp]";
			push @result, "[$basereg_sign$basereg $indexreg_sign$scale * $indexreg $disp_sign$disp]";

			push @result, "[$basereg_sign$basereg $disp_sign$disp $indexreg_sign$indexreg * $scale]";
			push @result, "[$basereg_sign$basereg $disp_sign$disp $indexreg_sign$scale * $indexreg]";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$basereg $indexreg_sign$indexreg * $scale $disp_sign$disp]";
				push @result, "[$basereg $indexreg_sign$scale * $indexreg $disp_sign$disp]";

				push @result, "[$basereg $disp_sign$disp $indexreg_sign$indexreg * $scale]";
				push @result, "[$basereg $disp_sign$disp $indexreg_sign$scale * $indexreg]";
			}

			push @result, "[$indexreg_sign$indexreg * $scale $basereg_sign$basereg $disp_sign$disp]";
			push @result, "[$indexreg_sign$scale * $indexreg $basereg_sign$basereg $disp_sign$disp]";

			push @result, "[$indexreg_sign$indexreg * $scale $disp_sign$disp $basereg_sign$basereg]";
			push @result, "[$indexreg_sign$scale * $indexreg $disp_sign$disp $basereg_sign$basereg]";

			if ( $indexreg_sign eq '+' ) {

				push @result, "[$indexreg * $scale $basereg_sign$basereg $disp_sign$disp]";
				push @result, "[$scale * $indexreg $basereg_sign$basereg $disp_sign$disp]";

				push @result, "[$indexreg * $scale $disp_sign$disp $basereg_sign$basereg]";
				push @result, "[$scale * $indexreg $disp_sign$disp $basereg_sign$basereg]";
			}

			push @result, "[$disp_sign$disp $basereg_sign$basereg $indexreg_sign$indexreg * $scale]";
			push @result, "[$disp_sign$disp $basereg_sign$basereg $indexreg_sign$scale * $indexreg]";

			push @result, "[$disp_sign$disp $indexreg_sign$indexreg * $scale $basereg_sign$basereg]";
			push @result, "[$disp_sign$disp $indexreg_sign$scale * $indexreg $basereg_sign$basereg]";

			if ( $disp_sign eq '+' ) {

				push @result, "[$disp $basereg_sign$basereg $indexreg_sign$indexreg * $scale]";
				push @result, "[$disp $basereg_sign$basereg $indexreg_sign$scale * $indexreg]";

				push @result, "[$disp $indexreg_sign$indexreg * $scale $basereg_sign$basereg]";
				push @result, "[$disp $indexreg_sign$scale * $indexreg $basereg_sign$basereg]";
			}
		} else {
			# no scale given
			push @result, "[$basereg_sign$basereg $indexreg_sign$indexreg $disp_sign$disp]";

			push @result, "[$basereg_sign$basereg $disp_sign$disp $indexreg_sign$indexreg]";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$basereg $indexreg_sign$indexreg $disp_sign$disp]";

				push @result, "[$basereg $disp_sign$disp $indexreg_sign$indexreg]";
			}

			push @result, "[$indexreg_sign$indexreg $basereg_sign$basereg $disp_sign$disp]";

			push @result, "[$indexreg_sign$indexreg $disp_sign$disp $basereg_sign$basereg]";

			if ( $indexreg_sign eq '+' ) {

				push @result, "[$indexreg $basereg_sign$basereg $disp_sign$disp]";

				push @result, "[$indexreg $disp_sign$disp $basereg_sign$basereg]";
			}
			push @result, "[$disp_sign$disp $basereg_sign$basereg $indexreg_sign$indexreg]";

			push @result, "[$disp_sign$disp $indexreg_sign$indexreg $basereg_sign$basereg]";

			if ( $disp_sign eq '+' ) {

				push @result, "[$disp $basereg_sign$basereg $indexreg_sign$indexreg]";

				push @result, "[$disp $indexreg_sign$indexreg $basereg_sign$basereg]";
			}
		}
	}
	elsif ( defined $basereg and defined $indexreg and not defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "[$basereg_sign$basereg $indexreg_sign$indexreg * $scale]";
			push @result, "[$basereg_sign$basereg $indexreg_sign$scale * $indexreg]";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$basereg $indexreg_sign$indexreg * $scale]";
				push @result, "[$basereg $indexreg_sign$scale * $indexreg]";
			}

			push @result, "[$indexreg_sign$indexreg * $scale $basereg_sign$basereg]";
			push @result, "[$indexreg_sign$scale * $indexreg $basereg_sign$basereg]";

			if ( $indexreg_sign eq '+' ) {

				push @result, "[$indexreg * $scale $basereg_sign$basereg]";
				push @result, "[$scale * $indexreg $basereg_sign$basereg]";
			}
		} else {
			# no scale given
			push @result, "[$basereg_sign$basereg $indexreg_sign$indexreg]";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$basereg $indexreg_sign$indexreg]";
			}
			push @result, "[$indexreg_sign$indexreg $basereg_sign$basereg]";

			if ( $indexreg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$indexreg $basereg_sign$basereg]";
			}
		}
	}
	elsif ( defined $basereg and not defined $indexreg and defined $disp ) {

		push @result, "[$basereg_sign$basereg $disp_sign$disp]";

		if ( $basereg_sign eq '+' ) {
			# same thing, just skip the leading sign

			push @result, "[$basereg $disp_sign$disp]";
		}

		push @result, "[$disp_sign$disp $basereg_sign$basereg]";

		if ( $disp_sign eq '+' ) {

			push @result, "[$disp $basereg_sign$basereg]";
		}
	}
	elsif ( defined $basereg and not defined $indexreg and not defined $disp ) {

		push @result, "[$basereg_sign$basereg]";

		if ( $basereg_sign eq '+' ) {
			# same thing, just skip the leading sign

			push @result, "[$basereg]";
		}
	}
	elsif ( not defined $basereg and defined $indexreg and defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "[$indexreg_sign$indexreg * $scale $disp_sign$disp]";
			push @result, "[$indexreg_sign$scale * $indexreg $disp_sign$disp]";

			if ( $indexreg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$indexreg * $scale $disp_sign$disp]";
				push @result, "[$scale * $indexreg $disp_sign$disp]";
			}

			push @result, "[$disp_sign$disp $indexreg_sign$indexreg * $scale]";
			push @result, "[$disp_sign$disp $indexreg_sign$scale * $indexreg]";

			if ( $disp_sign eq '+' ) {

				push @result, "[$disp $indexreg_sign$indexreg * $scale]";
				push @result, "[$disp $indexreg_sign$scale * $indexreg]";
			}
		} else {
			# no scale given
			push @result, "[$indexreg_sign$indexreg $disp_sign$disp]";

			if ( $indexreg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$indexreg $disp_sign$disp]";
			}

			push @result, "[$disp_sign$disp $indexreg_sign$indexreg]";

			if ( $disp_sign eq '+' ) {

				push @result, "[$disp $indexreg_sign$indexreg]";
			}
		}
	}
	elsif ( not defined $basereg and defined $indexreg and not defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "[$indexreg_sign$indexreg * $scale]";
			push @result, "[$indexreg_sign$scale * $indexreg]";

			if ( $indexreg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$indexreg * $scale]";
				push @result, "[$scale * $indexreg]";
			}
		} else {
			# no scale given
			push @result, "[$indexreg_sign$indexreg]";
			if ( $indexreg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "[$indexreg]";
			}
		}
	}
	elsif ( not defined $basereg and not defined $indexreg and defined $disp ) {

		push @result, "[$disp_sign$disp]";
		if ( $disp_sign eq '+' ) {
			# same thing, just skip the leading sign

			push @result, "[$disp]";
		}
	}

	return @result;
}

sub permute_intel_segreg($$$$$$$$) {

	my $segreg = shift;
	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	my @result = ();

	if ( defined $segreg and $segreg ne '' ) {

		my @res = permute3_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
		foreach (@res) {

			push @result, "$segreg:$_";
			my $repl = $_;
			$repl =~ s/\[/[$segreg:/;
			push @result, $repl;
		}

	} # defined $segreg
	else {
		@result = permute3_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
	}

	return @result;
}

sub permute_intel($$$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	my @result = permute_intel_segreg (undef, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
	push @result, permute_intel_segreg ('ds', $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);

	return @result;
}

sub permute_disp_intel($$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = ();

	push @result, permute_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', $disp);
	if ( $disp ne '' ) {

		push @result, permute_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '-', $disp);
		push @result, permute_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', "-$disp");
	}

	return @result;
}

sub permute_disp_intel_all($$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = ();

	push @result, permute_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', '');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp);

	return @result;
}

sub permute_disp_intel_segreg($$$$$$$) {

	my $segreg = shift;
	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = ();

	push @result, permute_intel_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', $disp);
	if ( $disp ne '' ) {

		push @result, permute_intel_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '-', $disp);
		push @result, permute_intel_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', "-$disp");
	}

	return @result;
}

sub permute_disp_intel_segreg_all($$$$$$$) {

	my $segreg = shift;
	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = ();

	push @result, permute_intel_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', '');
	push @result, permute_disp_intel_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp);

	return @result;
}

sub permute_two_reg32_invalid_intel($$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;

	my @result = ();

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', 'ebx');

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'edx', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'edx', 'ebx');

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'ds', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'ds', 'ebx');

	return @result;	
}

sub permute_reg32_invalid_intel($) {

	my $reg = shift;
	my @result = ();

	push @result, permute_two_reg32_invalid_intel ('', 'eax', '', $reg);
	push @result, permute_two_reg32_invalid_intel ('-', 'eax', '', $reg);
	push @result, permute_two_reg32_invalid_intel ('', 'eax', '-', $reg);
	push @result, permute_two_reg32_invalid_intel ('-', 'eax', '-', $reg);

	push @result, permute_two_reg32_invalid_intel ('', '', '', $reg);
	push @result, permute_two_reg32_invalid_intel ('', '', '-', $reg);
	push @result, permute_two_reg32_invalid_intel ('', $reg, '', '');
	push @result, permute_two_reg32_invalid_intel ('-', $reg, '', '');

	push @result, permute_two_reg32_invalid_intel ('', $reg, '', 'eax');
	push @result, permute_two_reg32_invalid_intel ('-', $reg, '', 'eax');
	push @result, permute_two_reg32_invalid_intel ('', $reg, '-', 'eax');
	push @result, permute_two_reg32_invalid_intel ('-', $reg, '-', 'eax');

	return @result;
}

sub permute_two_reg64_invalid_intel($$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;

	my @result = ();

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', 'rbx');

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'rdx', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'rdx', 'rbx');

	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'ds', '1');
	push @result, permute_disp_intel ($basereg_sign, $basereg, $indexreg_sign, $indexreg, 'ds', 'rbx');

	return @result;	
}

sub permute_reg64_invalid_intel($) {

	my $reg = shift;
	my @result = ();

	push @result, permute_two_reg64_invalid_intel ('', 'rax', '', $reg);
	push @result, permute_two_reg64_invalid_intel ('-', 'rax', '', $reg);
	push @result, permute_two_reg64_invalid_intel ('', 'rax', '-', $reg);
	push @result, permute_two_reg64_invalid_intel ('-', 'rax', '-', $reg);

	push @result, permute_two_reg64_invalid_intel ('', '', '', $reg);
	push @result, permute_two_reg64_invalid_intel ('', '', '-', $reg);
	push @result, permute_two_reg64_invalid_intel ('', $reg, '', '');
	push @result, permute_two_reg64_invalid_intel ('-', $reg, '', '');

	push @result, permute_two_reg64_invalid_intel ('', $reg, '', 'rax');
	push @result, permute_two_reg64_invalid_intel ('-', $reg, '', 'rax');
	push @result, permute_two_reg64_invalid_intel ('', $reg, '-', 'rax');
	push @result, permute_two_reg64_invalid_intel ('-', $reg, '-', 'rax');

	return @result;
}

sub permute_sign_disp_intel_all($$$$) {

	my $basereg = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_disp_intel_all ('', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_all ('', $basereg, '-', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_all ('-', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_all ('-', $basereg, '-', $indexreg, $scale, $disp);

	return @result;
}

sub permute_sign_disp_intel_segreg_all($$$$$) {

	my $segreg = shift;
	my $basereg = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_disp_intel_segreg_all ($segreg, '', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_segreg_all ($segreg, '', $basereg, '-', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_segreg_all ($segreg, '-', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_intel_segreg_all ($segreg, '-', $basereg, '-', $indexreg, $scale, $disp);

	return @result;
}

# ----------- 16-bit

my @valid16 = ();
my @invalid16 = ();

foreach my $r1 ('bx', 'si', 'di', 'bp') {

	if ( $r1 =~ /^b.$/io ) {

		push @valid16, permute_disp_intel_all ('', $r1, '', '', '', '1');
		push @valid16, permute_disp_intel_all ('', $r1, '', '', '', 'varname');
		push @invalid16, permute_disp_intel_all ('-', $r1, '', '', '', '3');
	}
	else {
		push @valid16, permute_disp_intel_all ('', '', '', $r1, '', '5');
		push @valid16, permute_disp_intel_all ('', '', '', $r1, '', 'varname');
		push @invalid16, permute_disp_intel_all ('', '', '-', $r1, '', '7');
		push @invalid16, permute_disp_intel_all ('', 'cx', '', $r1, '', '7');
	}

	foreach my $r2 ('bx', 'si', 'di', 'bp') {

		if ( ($r1 =~ /^b.$/io && $r2 =~ /^b.$/io)
			|| ($r1 =~ /^.i$/io && $r2 =~ /^.i$/io)
		) {
			push @invalid16, permute_disp_intel_all ('', $r1, '', $r2, '', '9');
		}
		else {
			push @valid16, permute_disp_intel_all ('', $r1, '', $r2, '', '9');
		}

		push @invalid16, permute_disp_intel_all ('-', $r1, '', $r2, '', '11');
		push @invalid16, permute_disp_intel_all ('', $r1, '-', $r2, '', '13');
		push @invalid16, permute_disp_intel ('', $r1, '', $r2, '', $r1);
		push @invalid16, permute_disp_intel ('', $r1, '', $r2, '', 'cx');
	}
	push @invalid16, permute_disp_intel_all ('', 'cx', '', $r1, '', '15');
	push @invalid16, permute_disp_intel_all ('', 'cx', '', $r1, '4', '17');
	push @invalid16, permute_disp_intel_all ('-', 'cx', '', $r1, '', '19');
	push @invalid16, permute_disp_intel_all ('-', 'cx', '', $r1, '8', '21');
	push @invalid16, permute_disp_intel_all ('', $r1, '', 'cx', '', '23');
	push @invalid16, permute_disp_intel_all ('', $r1, '', 'cx', '2', '25');
	push @invalid16, permute_disp_intel_all ('', $r1, '-', 'cx', '', '23');
	push @invalid16, permute_disp_intel_all ('', $r1, '-', 'cx', '2', '25');
}

push @valid16, permute_intel ('', '', '', '', '', '', '1');
push @valid16, permute_intel ('', '1', '', '', '', '', '3');
push @valid16, permute_intel ('', '', '', 'si', '', '', 'br');

push @valid16, permute_intel ('', 'bx', '', '', '', '', '+-1');
push @valid16, permute_intel ('', 'bx', '', '', '', '', '--1');

push @valid16, permute_intel ('', 'bx', '', '3', '', '', '1');
push @valid16, permute_intel ('', '3', '', 'bp', '', '', '1');
push @invalid16, permute_intel ('', '3', '-', 'bp', '', '', '1');
push @valid16, permute_intel ('', '3', '', '2', '', '', '1');
push @valid16, permute_intel ('', '3', '', '2', '', '-', '1');
push @valid16, permute_intel ('', '3', '', '2', '', '', 'bx');
push @invalid16, permute_intel ('', '3', '', '2', '', '-', 'bx');
push @valid16, permute_intel ('', '3', '', '', '', '-', '1');
push @valid16, permute_intel ('', '', '', '', '', '-', '1');
push @valid16, permute_intel ('', '', '', '', '', '', '+1');

push @invalid16, permute_intel ('', 'cx', '', '', '', '', '1');
push @invalid16, permute_intel ('-', 'cx', '', '', '', '', '1');

foreach my $r1 ('ax', 'cs', 'cl', 'eax', 'rax', 'mm0', 'xmm1',
	'ymm2', 'zmm3', 'k1') {

	push @invalid16, permute_intel ('', '', '', '', '', '', $r1);
	push @invalid16, permute_disp_intel_all ('', $r1, '', '', '', '23');
	push @invalid16, permute_disp_intel_all ('', $r1, '', 'si', '', '25');
	push @invalid16, permute_disp_intel_all ('', '', '', $r1, '', '27');
	push @invalid16, permute_disp_intel_all ('', 'bx', '', $r1, '', '29');
	push @invalid16, permute_disp_intel_all ('', 'bp', '', $r1, '1', '31');
	push @invalid16, permute_disp_intel_all ('-', $r1, '', '', '', '33');
	push @invalid16, permute_disp_intel_all ('-', $r1, '', 'si', '', '35');
	push @invalid16, permute_disp_intel_all ('-', $r1, '', 'si', '4', '37');
	push @invalid16, permute_disp_intel ('', 'bx', '', 'si', '', $r1);
	push @invalid16, permute_disp_intel ('', 'bx', '', 'si', '8', $r1);
}

push @invalid16, permute_intel_segreg ('ad', '', 'bx', '', '', '', '', '');
push @invalid16, permute_intel_segreg ('sc', '', 'di', '', '', '', '', '');
push @invalid16, permute_intel_segreg ('ax', '', 'bx', '', '', '', '', '');
push @invalid16, permute_intel_segreg ('ax', '', 'bx', '', 'bx', '', '', '');
push @invalid16, permute_intel_segreg ('ax', '', 'bx', '', 'si', '', '', '2');

# ----------- 32-bit

my @valid32 = ();
my @invalid32 = ();

push @valid32, permute_intel ('', 'eax', '', '', '', '', '');
push @valid32, permute_intel ('', 'beax', '', '', '', '', '');
push @valid32, permute_intel ('', 'eaxd', '', '', '', '', '');

push @invalid32, permute_intel ('-', 'eax', '', '', '', '', '');

foreach my $r1 ('cx', 'cs', 'st0', 'cl', 'cr0', 'dr2', 'rax', 'r9d', 'mm0',
	'xmm3', 'ymm2', 'zmm3', 'k1') {

	push @invalid32, permute_disp_intel_all ('', $r1, '', '', '', '1');
	push @invalid32, permute_disp_intel_all ('-', $r1, '', '', '', '1');
	push @invalid32, permute_disp_intel_all ('', $r1, '', 'ebx', '', '1');
	push @invalid32, permute_disp_intel_all ('', $r1, '', 'ebx', '2', '1');
	push @invalid32, permute_disp_intel_all ('', '', '', $r1, '', '1');
	push @invalid32, permute_disp_intel_all ('', '', '', $r1, '2', '1');
	push @invalid32, permute_disp_intel_all ('', 'ebx', '', $r1, '', '1');
	push @invalid32, permute_disp_intel_all ('', 'ebx', '', $r1, '2', '1');

	push @invalid32, permute_reg32_invalid_intel ($r1);
}

foreach my $s ('', '1', '2', '4', '8') {

	push @valid32, permute_disp_intel_all ('', '', '', 'eax', $s, '1');
	push @valid32, permute_disp_intel_all ('', 'ebx', '', 'edi', $s, '1');
	push @valid32, permute_disp_intel_all ('', 'ebx', '', 'edi', $s, 'varname');
}

push @valid32, permute_disp_intel_all ('', 'eax', '', '', '', '1');

push @invalid32, permute_intel ('-', 'eax', '', '', '', '', '1');
push @invalid32, permute_intel ('-', 'eax', '', '', '', '', '-1');

foreach my $s ('', '2') {

	push @invalid32, permute_disp_intel ('', 'ebx', '', 'edi', $s, 'eax');
	push @invalid32, permute_disp_intel_all ('-', 'ebx', '', 'edi', $s, 'eax');
	push @invalid32, permute_disp_intel_all ('', 'ebx', '-', 'edi', $s, 'eax');
	push @invalid32, permute_disp_intel_all ('-', 'ebx', '-', 'edi', $s, 'eax');
}

push @invalid32, permute_disp_intel_all ('-', 'ebx', '', 'edi', '', '1');

foreach my $r1 ('eax', 'ebp', 'ecx', 'esi') {

	push @valid32, permute_disp_intel_all ('', 'ebx', '', $r1, '1', '3');
	push @invalid32, permute_disp_intel_all ('-', 'ebx', '', $r1, '1', '7');
	push @invalid32, permute_disp_intel_all ('', 'ebx', '-', $r1, '1', '9');
	push @invalid32, permute_disp_intel_all ('-', 'ebx', '-', $r1, '1', '11');

	push @valid32, permute_disp_intel_all ('', '', '', $r1, '1', '3');
	push @invalid32, permute_disp_intel_all ('', '', '-', $r1, '1', '5');
}

push @valid32, permute_disp_intel_all ('', '', '', '1', '8', '29');
push @valid32, permute_disp_intel_all ('', '', '-', '1', '8', '29');

push @valid32, permute_disp_intel_all ('', 'ebx', '', '1', '8', '31');
push @valid32, permute_disp_intel_all ('', 'ebx', '-', '1', '8', '31');

push @valid32, permute_intel ('', 'ebx', '', '1', '8', '', 'eax');
push @valid32, permute_intel ('', 'ebx', '-', '1', '8', '', 'eax');

push @valid32, permute_disp_intel_all ('', '3', '', 'ebx', '8', '33');
push @invalid32, permute_disp_intel_all ('', '3', '-', 'ebx', '8', '33');

push @invalid32, permute_intel ('', 'ebx*2', '', 'eax', '8', '', '');

push @valid32, permute_disp_intel_all ('', 'esp', '', 'ecx', '1', '11');
push @valid32, permute_disp_intel_all ('', 'esp', '', 'ebp', '1', '11');

push @valid32, permute_intel ('', 'esp', '', '2', '1', '', '');
push @valid32, permute_intel ('', 'esp', '', '2', '1', '', 'eax');
push @invalid32, permute_intel ('', 'esp', '', '2', '1', '-', 'eax');
push @invalid32, permute_intel ('', 'esp', '', '2', '1', '', '-eax');
push @valid32, permute_intel ('', 'esp', '-', '2', '1', '', '');
push @valid32, permute_intel ('', 'esp', '-', '2', '1', '', 'eax');
push @invalid32, permute_intel ('', 'esp', '-', '2', '1', '-', 'eax');
push @invalid32, permute_intel ('', 'esp', '-', '2', '1', '', '-eax');
push @invalid32, permute_disp_intel_all ('-', 'esp', '', '2', '1', 'eax');
push @invalid32, permute_disp_intel_all ('-', 'esp', '-', '2', '1', 'eax');

foreach my $s ('', '1', 'z') {

	push @valid32, permute_disp_intel_all ('', '', '', 'esp', $s, '11');
	push @valid32, permute_disp_intel_all ('', 'ecx', '', 'esp', $s, '11');
}

push @invalid32, permute_disp_intel_all ('', '', '', 'esp', '2', '11');
push @invalid32, permute_disp_intel_all ('', 'ecx', '', 'esp', '2', '11');

push @invalid32, permute_disp_intel_all ('', '', '', 'eax', '5', '17');
push @invalid32, permute_disp_intel_all ('', '', '-', 'eax', '5', '17');
push @invalid32, permute_sign_disp_intel_all ('ebx', 'eax', '5', '17');

push @invalid32, permute_disp_intel_all ('', '', '', 'eax', 'edx', '19');
push @invalid32, permute_disp_intel_all ('', '', '-', 'eax', 'edx', '19');

push @invalid32, permute_sign_disp_intel_all ('ebx', 'eax', 'edx', '19');

push @invalid32, permute_disp_intel_segreg_all ('ax', '', 'ebx', '', '', '', '20');
push @invalid32, permute_disp_intel_segreg_all ('ax', '-', 'ebx', '', '', '', '20');

foreach my $s ('', '2') {

	push @invalid32, permute_disp_intel_segreg_all ('ax', '', '', '', 'edi', $s, '21');
	push @invalid32, permute_disp_intel_segreg_all ('ax', '', '', '-', 'edi', $s, '21');

	push @invalid32, permute_sign_disp_intel_segreg_all ('ax', 'ebx', 'edi', $s, '22');
	push @invalid32, permute_sign_disp_intel_segreg_all ('ax', 'cs', 'ebx', $s, '24');
	push @invalid32, permute_sign_disp_intel_segreg_all ('ax', 'ebx', 'cs', $s, '26');
}

push @invalid32, permute_disp_intel_segreg_all ('ax', '', 'cs', '', '', '', '24');
push @invalid32, permute_disp_intel_segreg_all ('ax', '-', 'cs', '', '', '', '24');

# ----------- 64-bit

my @valid64 = ();
my @invalid64 = ();

push @valid64, permute_intel ('', 'brax', '', '', '', '', '');
push @valid64, permute_intel ('', 'raxd', '', '', '', '', '');

push @valid64, permute_disp_intel_all ('', 'rax', '', '', '', '1');
push @invalid64, permute_intel ('-', 'rax', '', '', '', '', '');
push @valid64, permute_intel ('', 'eax', '', '', '', '', '');

foreach my $r1 ('cx', 'cs', 'st0', 'cl', 'cr0', 'dr2', 'mm0', 'xmm3',
	'ymm2', 'zmm3', 'k1') {

	push @invalid64, permute_disp_intel_all ('', $r1, '', '', '', '1');
	push @invalid64, permute_disp_intel_all ('-', $r1, '', '', '', '1');
	push @invalid64, permute_disp_intel_all ('', $r1, '', 'rbx', '', '1');
	push @invalid64, permute_disp_intel_all ('', $r1, '', 'rbx', '2', '1');
	push @invalid64, permute_disp_intel_all ('', '', '', $r1, '', '1');
	push @invalid64, permute_disp_intel_all ('', '', '', $r1, '2', '1');
	push @invalid64, permute_disp_intel_all ('', 'rbx', '', $r1, '', '1');
	push @invalid64, permute_disp_intel_all ('', 'rbx', '', $r1, '2', '1');

	push @invalid64, permute_reg64_invalid_intel ($r1);
}

foreach my $r1 ('r9d', 'ebx') {

	foreach my $s ('',  '2') {

		push @invalid64, permute_disp_intel_all ('', 'rbx', '', $r1, $s, '1');
		push @invalid64, permute_disp_intel_all ('', 'rbx', '', $r1, $s, 'varname');
		push @invalid64, permute_disp_intel_all ('', 'rbx', '', $r1, $s, 'rax');

		push @invalid64, permute_disp_intel_all ('', $r1, '', 'rbx', $s, '1');
		push @invalid64, permute_disp_intel_all ('', $r1, '', 'rbx', $s, 'varname');
	}
}


push @valid64, permute_disp_intel_all ('', 'r9d', '', '', '', '1');
push @valid64, permute_disp_intel_all ('', '', '', 'r9d', '2', '1');

push @invalid64, permute_disp_intel_all ('', '', '', 'ebx', 'rbx', '1');

push @invalid64, permute_disp_intel ('-', 'rax', '', '', '',  '1');
push @invalid64, permute_disp_intel_all ('-', 'rbx', '', 'rdi', '', '1');

foreach my $s ('', '2') {

	push @invalid64, permute_disp_intel ('', 'rbx', '', 'rdi', $s, 'rax');
	push @invalid64, permute_disp_intel_all ('-', 'rbx', '', 'rdi', $s, 'rax');
	push @invalid64, permute_disp_intel_all ('', 'rbx', '-', 'rdi', $s, 'rax');
	push @invalid64, permute_disp_intel_all ('-', 'rbx', '-', 'rdi', $s, 'rax');
	push @valid64, permute_disp_intel_all ('', 'eax', '', 'ebx', $s, '1');
	push @valid64, permute_disp_intel_all ('', '', '', 'ebx', $s, '1');
}

foreach my $s ('', '1', '2', '4', '8') {

	push @valid64, permute_disp_intel_all ('', '', '', 'rax', $s, '3');
	push @valid64, permute_disp_intel_all ('', 'rbx', '', 'rax', $s, '3');
}

foreach my $r1 ('rax', 'rbp', 'rcx', 'rsi') {

	push @valid64, permute_disp_intel_all ('', 'rbx', '', $r1, '1', '3');
	push @invalid64, permute_disp_intel_all ('-', 'rbx', '', $r1, '1', '7');
	push @invalid64, permute_disp_intel_all ('', 'rbx', '-', $r1, '1', '9');
	push @invalid64, permute_disp_intel_all ('-', 'rbx', '-', $r1, '1', '5');
	push @valid64, permute_disp_intel_all ('', '', '', $r1, '1', '3');
	push @invalid64, permute_disp_intel_all ('', '', '-', $r1, '1', '5');
}

push @valid64, permute_disp_intel_all ('', '', '', '1', '8', '29');
push @valid64, permute_disp_intel_all ('', '', '-', '1', '8', '29');

push @valid64, permute_disp_intel_all ('', 'rbx', '', '1', '8', '31');
push @valid64, permute_disp_intel_all ('', 'rbx', '-', '1', '8', '31');

push @valid64, permute_intel ('', 'rbx', '', '1', '8', '', 'rax');
push @valid64, permute_intel ('', 'rbx', '-', '1', '8', '', 'rax');

push @valid64, permute_disp_intel_all ('', '3', '', 'rbx', '8', '33');
push @invalid64, permute_disp_intel_all ('', '3', '-', 'rbx', '8', '33');

push @invalid64, permute_intel ('', 'rbx*2', '', 'rax', '8', '', '');

foreach my $r1 ('rsp', 'rip') {

	push @valid64, permute_disp_intel_all ('', $r1, '', 'rcx', '1', '11');
	push @valid64, permute_disp_intel_all ('', $r1, '', 'rbp', '1', '11');

	push @valid64, permute_disp_intel_all ('', '', '', $r1, '1', '11');
	push @valid64, permute_disp_intel_all ('', '', '', $r1, 'z', '13');
	push @invalid64, permute_disp_intel_all ('', '', '', $r1, '2', '15');

	push @valid64, permute_disp_intel_all ('', 'rcx', '', $r1, '1', '11');
	push @valid64, permute_disp_intel_all ('', 'rcx', '', $r1, 'z', '13');
	push @invalid64, permute_disp_intel_all ('', 'rcx', '', $r1, '2', '15');

	push @valid64, permute_intel ('', $r1, '', '2', '1', '', 'rax');
	push @valid64, permute_intel ('', $r1, '-', '2', '1', '', 'rax');
	push @invalid64, permute_intel ('', $r1, '', '2', '1', '-', 'rax');
	push @invalid64, permute_intel ('', $r1, '', '2', '1', '', '-rax');
	push @invalid64, permute_intel ('', $r1, '-', '2', '1', '-', 'rax');
	push @invalid64, permute_intel ('', $r1, '-', '2', '1', '', '-rax');
	push @invalid64, permute_disp_intel_all ('-', $r1, '', '2', '1', 'rax');
	push @invalid64, permute_disp_intel_all ('-', $r1, '-', '2', '1', 'rax');
}

push @invalid64, permute_disp_intel_all ('', '', '', 'rax', '5', '17');
push @invalid64, permute_disp_intel_all ('', '', '-', 'rax', '5', '17');
push @invalid64, permute_sign_disp_intel_all ('rbx', 'rax', '5', '17');

push @invalid64, permute_disp_intel_all ('', '', '', 'rax', 'rdx', '19');
push @invalid64, permute_disp_intel_all ('', '', '-', 'rax', 'rdx', '19');

push @invalid64, permute_sign_disp_intel_all ('rbx', 'rax', 'rdx', '19');

push @invalid64, permute_disp_intel_segreg_all ('ax', '', 'rbx', '', '', '', '20');
push @invalid64, permute_disp_intel_segreg_all ('ax', '-', 'rbx', '', '', '', '20');

foreach my $s ('', '4') {

	push @invalid64, permute_sign_disp_intel_segreg_all ('ax', 'rbx', 'rdi', $s, '23');
	push @invalid64, permute_sign_disp_intel_segreg_all ('ax', 'cs', 'rbx', $s, '25');
	push @invalid64, permute_sign_disp_intel_segreg_all ('ax', 'rbx', 'cs', $s, '27');
}

push @invalid64, permute_disp_intel_segreg_all ('ax', '', '', '', 'rdi', '4', '21');
push @invalid64, permute_disp_intel_segreg_all ('ax', '', '', '-', 'rdi', '4', '21');

push @invalid64, permute_disp_intel_segreg_all ('ax', '', 'cs', '', '', '', '24');
push @invalid64, permute_disp_intel_segreg_all ('ax', '-', 'cs', '', '', '', '24');

# ----------- mixed

my @valid_mixed = ();
my @invalid_mixed = ();

push @invalid_mixed, '[ebx+ax]';
push @invalid_mixed, '[si+eax]';
push @invalid_mixed, '[ebx+2+ax]';
push @invalid_mixed, '[2*ebx-cx]';
push @invalid_mixed, '[esi*8+si]';
push @invalid_mixed, '[edi+sp]';
push @invalid_mixed, '[rax+ebx]';
push @invalid_mixed, '[rbx+r8d]';
push @invalid_mixed, '[ecx+rsi]';
push @invalid_mixed, '[ecx*2+rsi]';
push @valid_mixed, '[+-1+ecx+edx]';
push @invalid_mixed, '[+-1+ecx+rdx]';
push @invalid_mixed, '[+-1+ecx*8+rdx]';
push @invalid_mixed, '[+-1+rdx+ecx*8]';
push @invalid_mixed, '[esi+-1+rax]';
push @invalid_mixed, '[esi-rcx]';
push @invalid_mixed, '[+1-rcx]';
push @invalid_mixed, '[-1-rcx]';
push @valid_mixed, '[rax+6*2+rsp]';
push @valid_mixed, '[cs:5+ecx+esi]';
push @valid_mixed, '[ss:bp+si]';

# -----------

# Test::More:
plan tests => @valid16 + 3 + @invalid16 + 2
	+ @valid32 + 3 + @invalid32 + 2
	+ @valid64 + 3 + @invalid64 + 2
	+ @valid_mixed + 2 + @invalid_mixed + 2;

foreach (@valid16) {
	is ( is_valid_16bit_addr_intel ($_), 1, "'$_' is a valid 16-bit Intel addressing scheme" );
}
is ( is_valid_16bit_addr_att ($valid16[0]), 0, "'$valid16[0]' is not a valid 16-bit AT&T addressing scheme" );
is ( is_valid_16bit_addr ($valid16[0]), 1, "'$valid16[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($valid16[0]), 1, "'$valid16[0]' is a valid addressing scheme" );

foreach (@invalid16) {
	is ( is_valid_16bit_addr_intel ($_), 0, "'$_' is not a valid 16-bit Intel addressing scheme" );
}
is ( is_valid_16bit_addr_att ($invalid16[0]), 0, "'$invalid16[0]' is not a valid 16-bit AT&T addressing scheme" );
is ( is_valid_16bit_addr ($invalid16[0]), 0, "'$invalid16[0]' is not a valid 16-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid32) {
	is ( is_valid_32bit_addr_intel ($_), 1, "'$_' is a valid 32-bit Intel addressing scheme" );
}
is ( is_valid_32bit_addr_att ($valid32[0]), 0, "'$valid32[0]' is not a valid 16-bit AT&T addressing scheme" );
is ( is_valid_32bit_addr ($valid32[0]), 1, "'$valid32[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($valid32[0]), 1, "'$valid32[0]' is a valid addressing scheme" );

foreach (@invalid32) {
	is ( is_valid_32bit_addr_intel ($_), 0, "'$_' is not a valid 32-bit Intel addressing scheme" );
}
is ( is_valid_32bit_addr_att ($invalid32[0]), 0, "'$invalid32[0]' is not a valid 32-bit AT&T addressing scheme" );
is ( is_valid_32bit_addr ($invalid32[0]), 0, "'$invalid32[0]' is not a valid 32-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid64) {
	is ( is_valid_64bit_addr_intel ($_), 1, "'$_' is a valid 64-bit Intel addressing scheme" );
}
is ( is_valid_64bit_addr_att ($valid64[0]), 0, "'$valid64[0]' is not a valid 16-bit AT&T addressing scheme" );
is ( is_valid_64bit_addr ($valid64[0]), 1, "'$valid64[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($valid64[0]), 1, "'$valid64[0]' is a valid addressing scheme" );

foreach (@invalid64) {
	is ( is_valid_64bit_addr_intel ($_), 0, "'$_' is not a valid 64-bit Intel addressing scheme" );
}
is ( is_valid_64bit_addr_att ($invalid64[0]), 0, "'$invalid64[0]' is not a valid 64-bit AT&T addressing scheme" );
is ( is_valid_64bit_addr ($invalid64[0]), 0, "'$invalid64[0]' is not a valid 64-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid_mixed) {
	is ( is_valid_addr_intel ($_), 1, "'$_' is a valid Intel addressing scheme" );
}
is ( is_valid_addr_att ($valid_mixed[0]), 0, "'$valid_mixed[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($valid_mixed[0]), 1, "'$valid_mixed[0]' is a valid addressing scheme" );

foreach (@invalid_mixed) {
	is ( is_valid_addr_intel ($_), 0, "'$_' is not a valid Intel addressing scheme" );
}
is ( is_valid_addr_att ($invalid_mixed[0]), 0, "'$invalid_mixed[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($invalid_mixed[0]), 0, "'$invalid_mixed[0]' is a valid addressing scheme" );
