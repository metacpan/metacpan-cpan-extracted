#!/usr/bin/perl -T -w

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

sub permute3_att($$$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	my @result = ();

	#$basereg_sign = '+' if not defined $basereg_sign or $basereg_sign eq '';
	#$indexreg_sign = '+' if not defined $indexreg_sign or $indexreg_sign eq '';
	#$disp_sign = '+' if not defined $disp_sign or $disp_sign eq '';
	$basereg_sign = '' if not defined $basereg_sign;
	$indexreg_sign = '' if not defined $indexreg_sign;
	$disp_sign = '' if not defined $disp_sign;
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

			push @result, "$disp_sign$disp($basereg_sign$basereg, $indexreg_sign$indexreg, $scale)";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "$disp_sign$disp($basereg, $indexreg_sign$indexreg, $scale)";
				if ( $indexreg_sign eq '+' ) {

					push @result, "$disp_sign$disp($basereg, $indexreg, $scale)";
					if ( $disp_sign eq '+' ) {

						push @result, "$disp($basereg, $indexreg, $scale)";
					}
				}
				if ( $disp_sign eq '+' ) {

					push @result, "$disp($basereg, $indexreg_sign$indexreg, $scale)";
				}
			}
			if ( $indexreg_sign eq '+' ) {

				push @result, "$disp_sign$disp($basereg_sign$basereg, $indexreg, $scale)";
				if ( $disp_sign eq '+' ) {

					push @result, "$disp($basereg_sign$basereg, $indexreg, $scale)";
				}
			}
			if ( $disp_sign eq '+' ) {

				push @result, "$disp($basereg_sign$basereg, $indexreg_sign$indexreg, $scale)";
			}
		} else {
			# no scale given
			push @result, "$disp_sign$disp($basereg_sign$basereg, $indexreg_sign$indexreg)";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "$disp_sign$disp($basereg, $indexreg_sign$indexreg)";
				if ( $indexreg_sign eq '+' ) {

					push @result, "$disp_sign$disp($basereg, $indexreg)";
					if ( $disp_sign eq '+' ) {

						push @result, "$disp($basereg, $indexreg)";
					}
				}
				if ( $disp_sign eq '+' ) {

					push @result, "$disp($basereg, $indexreg_sign$indexreg)";
				}
			}
			if ( $indexreg_sign eq '+' ) {

				push @result, "$disp_sign$disp($basereg_sign$basereg, $indexreg)";
				if ( $disp_sign eq '+' ) {

					push @result, "$disp($basereg_sign$basereg, $indexreg)";
				}
			}
			if ( $disp_sign eq '+' ) {

				push @result, "$disp($basereg_sign$basereg, $indexreg_sign$indexreg)";
			}
		}
	}
	elsif ( defined $basereg and defined $indexreg and not defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "($basereg_sign$basereg, $indexreg_sign$indexreg, $scale)";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "($basereg, $indexreg_sign$indexreg, $scale)";
				if ( $indexreg_sign eq '+' ) {

					push @result, "($basereg, $indexreg, $scale)";
				}
			}
			if ( $indexreg_sign eq '+' ) {

				push @result, "($basereg_sign$basereg, $indexreg, $scale)";
			}
		} else {
			# no scale given
			push @result, "($basereg_sign$basereg, $indexreg_sign$indexreg)";

			if ( $basereg_sign eq '+' ) {
				# same thing, just skip the leading sign

				push @result, "($basereg, $indexreg_sign$indexreg)";
				if ( $indexreg_sign eq '+' ) {

					push @result, "($basereg, $indexreg)";
				}
			}
			if ( $indexreg_sign eq '+' ) {

				push @result, "($basereg_sign$basereg, $indexreg)";
			}
		}
	}
	elsif ( defined $basereg and not defined $indexreg and defined $disp ) {

		push @result, "$disp_sign$disp($basereg_sign$basereg)";

		if ( $basereg_sign eq '+' ) {
			# same thing, just skip the leading sign

			push @result, "$disp_sign$disp($basereg)";
			if ( $disp_sign eq '+' ) {

				push @result, "$disp($basereg)";
			}
		}
		if ( $disp_sign eq '+' ) {

			push @result, "$disp($basereg_sign$basereg)";
		}
	}
	elsif ( defined $basereg and not defined $indexreg and not defined $disp ) {

		push @result, "($basereg_sign$basereg)";

		if ( $basereg_sign eq '+' ) {
			# same thing, just skip the leading sign

			push @result, "($basereg)";
		}
	}
	elsif ( not defined $basereg and defined $indexreg and defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "$disp_sign$disp(, $indexreg_sign$indexreg, $scale)";

			if ( $indexreg_sign eq '+' ) {

				push @result, "$disp_sign$disp(, $indexreg, $scale)";
				if ( $disp_sign eq '+' ) {

					push @result, "$disp(, $indexreg, $scale)";
				}
			}
			if ( $disp_sign eq '+' ) {

				push @result, "$disp(, $indexreg_sign$indexreg, $scale)";
			}
		} else {
			# no scale given
			push @result, "$disp_sign$disp(, $indexreg_sign$indexreg)";

			if ( $indexreg_sign eq '+' ) {

				push @result, "$disp_sign$disp(, $indexreg)";
				if ( $disp_sign eq '+' ) {

					push @result, "$disp(, $indexreg)";
				}
			}
			if ( $disp_sign eq '+' ) {

				push @result, "$disp(, $indexreg_sign$indexreg)";
			}
		}
	}
	elsif ( not defined $basereg and defined $indexreg and not defined $disp ) {

		if ( defined $scale and $scale ne '' ) {

			push @result, "(, $indexreg_sign$indexreg, $scale)";

			if ( $indexreg_sign eq '+' ) {

				push @result, "(, $indexreg, $scale)";
			}
		} else {
			# no scale given
			push @result, "(, $indexreg_sign$indexreg)";

			if ( $indexreg_sign eq '+' ) {

				push @result, "(, $indexreg)";
			}
		}

	}
	elsif ( not defined $basereg and not defined $indexreg and defined $disp ) {

		push @result, "$disp_sign$disp(, 1)";

		if ( $disp_sign eq '+' ) {

			push @result, "$disp(, 1)";
		}
	}

	return @result;
}

sub permute_att_segreg($$$$$$$$) {

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

		my @res = permute3_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
		foreach (@res) {

			push @result, "$segreg:$_";
		}

	} # defined $segreg
	else {
		@result = permute3_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
	}

	return @result;
}

sub permute_att($$$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp_sign = shift;
	my $disp = shift;

	my @result = permute_att_segreg (undef, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);
	push @result, permute_att_segreg ('%ds', $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp_sign, $disp);

	return @result;
}

sub permute_disp_att($$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', $disp);
	if ( $disp ne '' ) {

		push @result, permute_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '-', $disp);
		push @result, permute_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', "-$disp");
	}

	return @result;
}

sub permute_disp_att_all($$$$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', '');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp);

	return @result;
}

sub permute_disp_att_segreg($$$$$$$) {

	my $segreg = shift;
	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_att_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', $disp);
	if ( $disp ne '' ) {

		push @result, permute_att_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '-', $disp);
		push @result, permute_att_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', "-$disp");
	}

	return @result;
}

sub permute_disp_att_segreg_all($$$$$$$) {

	my $segreg = shift;
	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_att_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, '', '');
	push @result, permute_disp_att_segreg ($segreg, $basereg_sign, $basereg, $indexreg_sign, $indexreg, $scale, $disp);

	return @result;
}

sub permute_two_reg32_invalid_att($$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;

	my @result = permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '%ebx');

	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%edx', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%edx', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%edx', '%ebx');

	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', '%ebx');

	return @result;	
}

sub permute_reg32_invalid_att($) {

	my $reg = shift;

	my @result = permute_two_reg32_invalid_att ('', '%eax', '', $reg);
	push @result, permute_two_reg32_invalid_att ('-', '%eax', '', $reg);
	push @result, permute_two_reg32_invalid_att ('', '%eax', '-', $reg);
	push @result, permute_two_reg32_invalid_att ('-', '%eax', '-', $reg);

	push @result, permute_two_reg32_invalid_att ('', '', '', $reg);
	push @result, permute_two_reg32_invalid_att ('', '', '-', $reg);
	push @result, permute_two_reg32_invalid_att ('', $reg, '', '');
	push @result, permute_two_reg32_invalid_att ('-', $reg, '', '');

	push @result, permute_two_reg32_invalid_att ('', $reg, '', '%eax');
	push @result, permute_two_reg32_invalid_att ('-', $reg, '', '%eax');
	push @result, permute_two_reg32_invalid_att ('', $reg, '-', '%eax');
	push @result, permute_two_reg32_invalid_att ('-', $reg, '-', '%eax');

	return @result;
}

sub permute_two_reg64_invalid_att($$$$) {

	my $basereg_sign = shift;
	my $basereg = shift;
	my $indexreg_sign = shift;
	my $indexreg = shift;

	my @result = permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '2', '%rbx');

	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%rdx', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%rdx', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%rdx', '%rbx');

	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', '1');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', 'varname');
	push @result, permute_disp_att ($basereg_sign, $basereg, $indexreg_sign, $indexreg, '%ds', '%rbx');

	return @result;	
}

sub permute_reg64_invalid_att($) {

	my $reg = shift;

	my @result = permute_two_reg64_invalid_att ('', '%rax', '', $reg);
	push @result, permute_two_reg64_invalid_att ('-', '%rax', '', $reg);
	push @result, permute_two_reg64_invalid_att ('', '%rax', '-', $reg);
	push @result, permute_two_reg64_invalid_att ('-', '%rax', '-', $reg);

	push @result, permute_two_reg64_invalid_att ('', '', '', $reg);
	push @result, permute_two_reg64_invalid_att ('', '', '-', $reg);
	push @result, permute_two_reg64_invalid_att ('', $reg, '', '');
	push @result, permute_two_reg64_invalid_att ('-', $reg, '', '');

	push @result, permute_two_reg64_invalid_att ('', $reg, '', '%rax');
	push @result, permute_two_reg64_invalid_att ('-', $reg, '', '%rax');
	push @result, permute_two_reg64_invalid_att ('', $reg, '-', '%rax');
	push @result, permute_two_reg64_invalid_att ('-', $reg, '-', '%rax');

	return @result;
}

sub permute_sign_disp_att_all($$$$) {

	my $basereg = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_disp_att_all ('', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_att_all ('', $basereg, '-', $indexreg, $scale, $disp);
	push @result, permute_disp_att_all ('-', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_att_all ('-', $basereg, '-', $indexreg, $scale, $disp);

	return @result;
}

sub permute_sign_disp_att_segreg_all($$$$$) {

	my $segreg = shift;
	my $basereg = shift;
	my $indexreg = shift;
	my $scale = shift;
	my $disp = shift;

	my @result = permute_disp_att_segreg_all ($segreg, '', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_att_segreg_all ($segreg, '', $basereg, '-', $indexreg, $scale, $disp);
	push @result, permute_disp_att_segreg_all ($segreg, '-', $basereg, '', $indexreg, $scale, $disp);
	push @result, permute_disp_att_segreg_all ($segreg, '-', $basereg, '-', $indexreg, $scale, $disp);

	return @result;
}

# ----------- 16-bit

my @valid16 = ();
my @invalid16 = ();

push @valid16, permute_att ('', '', '', '', '', '', '1');

foreach my $r1 ('%bx', '%si', '%di', '%bp') {

	foreach my $d ('1', 'varname', 'si') {

		push @valid16, permute_disp_att_all ('', $r1, '', '', '', $d);
	}
	push @invalid16, permute_disp_att_all ('', '', '', $r1, '', '3');

	push @invalid16, permute_disp_att_all ('-', $r1, '', '', '', '5');
	push @invalid16, permute_disp_att_all ('-', $r1, '', '', '', 'varname');

	push @invalid16, permute_disp_att_all ('', '', '', $r1, '2', '7');
	push @invalid16, permute_att ('', '2', '', $r1, '', '', '');
	push @invalid16, permute_att ('', '-2', '', $r1, '', '', '');

	foreach my $r2 ('%bx', '%si', '%di', '%bp') {

		if ( ($r1 =~ /^%b.$/io && $r2 =~ /^%b.$/io)
			|| ($r1 =~ /^%.i$/io && $r2 =~ /^%.i$/io)
		) {
			push @invalid16, permute_disp_att_all ('', $r1, '', $r2, '', '9');
		}
		else {
			push @valid16, permute_disp_att_all ('', $r1, '', $r2, '', '9');
		}

		push @invalid16, permute_disp_att_all ('-', $r1, '', $r2, '', '11');
		push @invalid16, permute_disp_att_all ('', $r1, '-', $r2, '', '13');
		push @invalid16, permute_disp_att ('', $r1, '', $r2, '', '%cx');
	}
	push @invalid16, permute_disp_att_all ('', '%cx', '', $r1, '', '15');
	push @invalid16, permute_disp_att_all ('', '%cx', '', $r1, '4', '17');
	push @invalid16, permute_disp_att_all ('-', '%cx', '', $r1, '', '19');
	push @invalid16, permute_disp_att_all ('-', '%cx', '', $r1, '8', '21');
}

foreach my $r1 ('%ax', '%cs', '%cl', '%eax', '%rax', '%mm0', '%xmm1', '%ymm2', '%zmm3', '%k1') {

	push @invalid16, permute_att ('', '', '', '', '', '', $r1);
	push @invalid16, permute_disp_att_all ('', $r1, '', '', '', '23');
	push @invalid16, permute_disp_att_all ('', $r1, '', '%si', '', '25');
	push @invalid16, permute_disp_att_all ('', '', '', $r1, '', '27');
	push @invalid16, permute_disp_att_all ('', '%bx', '', $r1, '', '29');
	push @invalid16, permute_disp_att_all ('', '%bp', '', $r1, '1', '31');
	push @invalid16, permute_disp_att_all ('-', $r1, '', '', '', '33');
	push @invalid16, permute_disp_att_all ('-', $r1, '', '%si', '', '35');
	push @invalid16, permute_disp_att_all ('-', $r1, '', '%si', '4', '37');
	push @invalid16, permute_disp_att ('', '%bx', '', '%si', '', $r1);
	push @invalid16, permute_disp_att ('', '%bx', '', '%si', '8', $r1);
}

push @invalid16, permute_disp_att_all ('', 'b%x', '', '', '', '1');
push @invalid16, permute_disp_att_all ('', '%bx', '', 's%i', '', '1');

push @invalid16, permute_att ('-', '%bx-%si', '', '', '', '', '');
push @invalid16, permute_att ('-', '%si-%ax', '', '', '', '', '');
push @invalid16, permute_att ('-', '%sc:%di', '', '', '', '', '');
push @invalid16, permute_att ('-', '3-%si', '', '', '', '', '');
push @invalid16, permute_att ('-', '-3-%si', '', '', '', '', '');

push @valid16, permute_att ('', '2', '', '', '', '', '');
push @invalid16, permute_att ('', '', '', '3', '', '', '');
push @invalid16, permute_att ('', '2', '', '3', '', '', '');

push @invalid16, permute_disp_att ('', 'zz', '', '', '', 'yy');

push @invalid16, permute_att ('', '1', '', '', '', '', '3');
push @valid16, permute_disp_att ('', '%si', '', '', '', 'br');
push @invalid16, permute_disp_att ('', '', '', '%si', '', 'br');

push @valid16, permute_att ('', '%bx', '', '', '', '', '+-1');
push @valid16, permute_att ('', '%bx', '', '', '', '', '--1');

push @valid16, permute_att ('', '', '', '', '', '', 'varname');

push @invalid16, permute_att ('', '%cx', '', '', '', '', '');
push @invalid16, permute_att ('', '', '', '%cx', '', '', '');
push @invalid16, permute_att ('', '%bx', '', '%cx', '', '', '');
push @invalid16, permute_att ('', '', '', '%cx', '2', '', '');
push @invalid16, permute_att ('', '%bx', '', '%cx', '2', '', '');
push @invalid16, permute_att ('', '', '', '%bx', '%cx', '', '');
push @invalid16, permute_att ('', '%bx', '', '', '', '', '%cx');

push @invalid16, permute_att ('', '%bx', '', '3', '', '', '1');
push @invalid16, permute_att ('', '3', '', '%bp', '', '', '1');
push @invalid16, permute_att ('', '3', '', '2', '', '', '1');
push @invalid16, permute_att ('', '3', '', '2', '', '-', '1');
push @invalid16, permute_att ('', '3', '', '', '', '-', '1');
push @valid16, permute_att ('', '', '', '', '', '-', '1');
push @valid16, permute_att ('', '', '', '', '', '', '+1');

push @invalid16, permute_att ('', '-si', '', '%bx', '', '', '1');

push @invalid16, permute_att ('', '%bx', '', '%cx', '', '', '');
push @invalid16, permute_att ('', '%bx', '', '%cx', '2', '', '');

push @invalid16, permute_disp_att_all ('', '%cx', '', '', '', '1');

push @invalid16, permute_att ('', '%bx', '-', '%cx', '', '', '');
push @invalid16, permute_att ('-', '%cx', '', '%si', '', '', '');
push @invalid16, permute_att ('-', '%cx', '', '%di', '', '', '');
push @invalid16, permute_att ('', '%bp', '-', '%cx', '', '', '');
push @invalid16, permute_disp_att_all ('-', '%cx', '', '', '', '1');

push @invalid16, permute_disp_att_all ('', '%cs', '', '', '', 'zzz');
push @invalid16, permute_disp_att_all ('', '%cx', '', '', '', 'zzz');
push @invalid16, permute_disp_att_all ('', '-%cx', '', '', '', 'zzz');
push @invalid16, permute_disp_att_all ('', '%ecx', '', '', '', 'zzz');
push @invalid16, permute_att ('', '1', '', '', '', '', 'zzz');

push @invalid16, permute_att_segreg ('ad', '', '%bx', '', '', '', '', '');
push @invalid16, permute_att_segreg ('sc', '', '%di', '', '', '', '', '');
push @invalid16, permute_att_segreg ('%ax', '', '%bx', '', '', '', '', '');
push @invalid16, permute_att_segreg ('%ax', '', '%bx', '', '%bx', '', '', '');
push @invalid16, permute_disp_att_segreg_all ('%ax', '', '%bx', '', '%si', '', '2');
push @invalid16, permute_disp_att_segreg_all ('%ax', '', '%bx', '', '%cs', '', '2');
push @invalid16, permute_att_segreg ('%ax', '', '', '', '', '', '', 'zzz');
push @invalid16, permute_disp_att_segreg_all ('%ax', '', '%cs', '', '', '', 'zzz');
push @invalid16, permute_disp_att_segreg_all ('%ax', '', '%cx', '', '', '', 'zzz');
push @invalid16, permute_disp_att_segreg_all ('%ax', '-', '%bx', '', '', '', 'zzz');

# impossible to generate
push @invalid16, '(,,-3,%si)';
push @invalid16, '%(cs:,,-3,%si)';
push @invalid16, '(%cs:,,-3,%si)';
push @invalid16, '(%es:2,%si)';

# ----------- 32-bit

my @valid32 = ();
my @invalid32 = ();

push @valid32, permute_disp_att_all ('', '%eax', '', '', '', '1');
push @invalid32, permute_att ('', 'e%ax', '', '', '', '', '');
push @invalid32, permute_att ('', '%beax', '', '', '', '', '');
push @invalid32, permute_att ('', '%eaxd', '', '', '', '', '');
push @invalid32, permute_att ('', '%ebx', '', 'e%ax', '', '', '');

foreach my $r1 ('%bx', '%si', '%di', '%bp') {

	push @valid32, permute_disp_att_all ('', $r1, '', '', '', '1');
	my $extreg = $r1;
	$extreg =~ s/\%/\%e/o;
	push @invalid32, permute_disp_att_all ('', '%bx', '', $extreg, '', '1');
	push @invalid32, permute_disp_att_all ('', $extreg, '', '%bx', '', '1');
}

foreach my $r1 ('%cx', '%cs', '%st0', '%cl', '%cr0', '%dr2', '%rax', '%r9d',
	'%mm0', '%xmm3', '%ymm2', '%zmm3', '%k1') {

	push @invalid32, permute_disp_att_all ('', $r1, '', '', '', '1');
	push @invalid32, permute_disp_att_all ('-', $r1, '', '', '', '1');
	push @invalid32, permute_disp_att_all ('', $r1, '', '%ebx', '', '1');
	push @invalid32, permute_disp_att_all ('', $r1, '', '%ebx', '2', '1');
	push @invalid32, permute_disp_att_all ('', '', '', $r1, '', '1');
	push @invalid32, permute_disp_att_all ('', '', '', $r1, '2', '1');
	push @invalid32, permute_disp_att_all ('', '%ebx', '', $r1, '', '1');
	push @invalid32, permute_disp_att_all ('', '%ebx', '', $r1, '2', '1');

	push @invalid32, permute_reg32_invalid_att ($r1);
}

push @valid32, permute_disp_att_all ('', '%eax', '', '', '', '1');
push @valid32, permute_disp_att_all ('', '%eax', '', '', '', 'varname');

foreach my $s ('', '1', '2', '4', '8') {

	push @valid32, permute_disp_att_all ('', '', '', '%eax', $s, '1');
	push @valid32, permute_disp_att_all ('', '%ebx', '', '%edi', $s, '1');
	push @valid32, permute_disp_att_all ('', '%ebx', '', '%edi', $s, 'varname');
}

push @invalid32, permute_disp_att_all ('-', '%eax', '', '', '', '1');
push @invalid32, permute_disp_att_all ('-', '%ebx', '', '%edi', '', '1');
push @invalid32, permute_disp_att ('', '%ebx', '', '', '', '%eax');
push @invalid32, permute_disp_att ('', '', '', '%edi', '', '%eax');
push @invalid32, permute_disp_att ('', '', '', '%edi', '2', '%eax');

foreach my $s ('', '2') {

	push @invalid32, permute_disp_att ('', '%ebx', '', '%edi', $s, '%eax');
	push @invalid32, permute_disp_att_all ('-', '%ebx', '', '%edi', $s, '%eax');
	push @invalid32, permute_disp_att_all ('', '%ebx', '-', '%edi', $s, '%eax');
	push @invalid32, permute_disp_att_all ('-', '%ebx', '-', '%edi', $s, '%eax');
}

push @valid32, permute_att ('', '', '', '', '', '', '1');
push @valid32, permute_att ('', '', '', '', '', '', 'varname');
push @valid32, permute_att ('', 'varname', '', '', '', '', '');
push @invalid32, permute_att ('', '', '', 'varname', '', '', '');
push @invalid32, permute_att ('', '', '', 'varname', '2', '', '');
push @invalid32, permute_att ('', '', '', 'varname', '2', '', 'varname');
push @invalid32, permute_att ('', 'varname', '', '', '', '', 'varname');
push @invalid32, permute_att ('', 'varname', '', 'varname', '2', '', '');
push @invalid32, permute_att ('', 'varname', '', 'varname', '2', '', 'varname');

foreach my $r1 ('%eax', '%ebp', '%ecx', '%esi') {

	push @valid32, permute_disp_att_all ('', '%ebx', '', $r1, '1', '3');
	push @invalid32, permute_disp_att_all ('-', '%ebx', '', $r1, '1', '7');
	push @invalid32, permute_disp_att_all ('', '%ebx', '-', $r1, '1', '9');
	push @invalid32, permute_disp_att_all ('-', '%ebx', '-', $r1, '1', '11');

	push @valid32, permute_disp_att_all ('', '', '', $r1, '1', '3');
	push @invalid32, permute_disp_att_all ('', '', '-', $r1, '1', '5');
}

push @invalid32, permute_disp_att_all ('', '', '', '1', '8', '29');
push @invalid32, permute_disp_att_all ('', '', '-', '1', '8', '29');

push @invalid32, permute_disp_att_all ('', '%ebx', '', '1', '8', '31');
push @invalid32, permute_disp_att_all ('', '%ebx', '-', '1', '8', '31');

push @invalid32, permute_att ('', '%ebx', '', '1', '8', '', '%eax');
push @invalid32, permute_att ('', '%ebx', '-', '1', '8', '', '%eax');

push @invalid32, permute_disp_att_all ('', '3', '', '%ebx', '8', '33');
push @invalid32, permute_disp_att_all ('', '3', '-', '%ebx', '8', '33');

push @invalid32, permute_att ('', '%ebx*2', '', '%eax', '8', '', '');

push @valid32, permute_disp_att_all ('', '%esp', '', '%ecx', '', '11');
push @valid32, permute_disp_att_all ('', '%esp', '', '%ecx', '1', '11');
push @valid32, permute_disp_att_all ('', '%esp', '', '%ebp', '1', '11');

push @invalid32, permute_sign_disp_att_all ('%esp', '2', '1', '%eax');

foreach my $s ('', '1', 'z', '2') {

	push @invalid32, permute_disp_att_all ('', '', '', '%esp', $s, '11');
	push @invalid32, permute_disp_att_all ('', '%ecx', '', '%esp', $s, '11');
}

push @invalid32, permute_disp_att_all ('', '', '', '%eax', '5', '17');
push @invalid32, permute_disp_att_all ('', '', '-', '%eax', '5', '17');

push @invalid32, permute_sign_disp_att_all ('%ebx', '%eax', '5', '17');

push @invalid32, permute_disp_att_all ('', '', '', '%eax', '%edx', '19');
push @invalid32, permute_disp_att_all ('', '', '-', '%eax', '%edx', '19');

push @invalid32, permute_sign_disp_att_all ('%ebx', '%eax', '%edx', '19');

push @invalid32, permute_disp_att_segreg_all ('%ax', '', '%ebx', '', '', '', '20');
push @invalid32, permute_disp_att_segreg_all ('%ax', '-', '%ebx', '', '', '', '20');
push @invalid32, permute_disp_att_segreg_all ('%ax', '', '', '', '', '', 'varname');

foreach my $s ('', '2') {

	push @invalid32, permute_disp_att_segreg_all ('%ax', '', '', '', '%edi', $s, '21');
	push @invalid32, permute_disp_att_segreg_all ('%ax', '', '', '-', '%edi', $s, '22');

	push @invalid32, permute_sign_disp_att_segreg_all ('%ax', '%ebx', '%edi', $s, '23');
	push @invalid32, permute_sign_disp_att_segreg_all ('%ax', '%cs', '%ebx', $s, '24');
	push @invalid32, permute_sign_disp_att_segreg_all ('%ax', '%ebx', '%cs', $s, '25');
}

push @invalid32, permute_disp_att_segreg_all ('%ax', '', '%cs', '', '', '', '24');
push @invalid32, permute_disp_att_segreg_all ('%ax', '-', '%cs', '', '', '', '24');

push @invalid32, permute_att ('', '', '', '', '', '', '%cx');
push @invalid32, permute_att ('', '%eax', '', '', '', '', '%cx');
push @invalid32, permute_att ('', '%eax', '', '%ebx', '', '', '%cx');
push @invalid32, permute_att ('', '%eax', '', '%ebx', '2', '', '%cx');
push @invalid32, permute_att ('', '', '', '%ebx', '2', '', '%cx');

push @invalid32, permute_disp_att_all ('', '', '', 'varname', '2', '6');

push @invalid32, permute_disp_att_all ('', '%eebx', '', '', '', '6');
push @invalid32, permute_disp_att_all ('', '%eebx', '', '%cx', '', '6');
push @invalid32, permute_disp_att_all ('', '%eebx', '', '%ecx', '', '6');
push @invalid32, permute_disp_att_all ('', '%cx', '', '%eebx', '', '6');
push @invalid32, permute_disp_att_all ('', '%ecx', '', '%eebx', '', '6');
push @invalid32, permute_disp_att_all ('', '%cx', '', '%si', '', '6');
push @invalid32, permute_disp_att_all ('', '%eax -', '', '', '', '6');
push @invalid32, permute_disp_att_all ('', '%eax -', '', '%ebx', '', '6');
push @invalid32, permute_disp_att_all ('', '%eax -', '', '%ebx', '4', '6');
push @invalid32, permute_disp_att_all ('', 'bsi', '', '%cx', '2', '6');
push @invalid32, permute_disp_att_all ('', '%si', '', 'bcx', '2', '6');
push @invalid32, permute_disp_att_all ('-', '%bx', '', '', '', '');

# ----------- 64-bit

my @valid64 = ();
my @invalid64 = ();

push @invalid64, permute_att ('', 'r%ax', '', '', '', '', '');
push @invalid64, permute_att ('', '%brax', '', '', '', '', '');
push @invalid64, permute_att ('', '%raxd', '', '', '', '', '');
push @invalid64, permute_att ('', '%rbx', '', 'r%ax', '', '', '');

foreach my $r1 ('%bx', '%si', '%di', '%bp') {

	push @invalid64, permute_disp_att_all ('', $r1, '', '', '', '1');
}

foreach my $r1 ('%cx', '%cs', '%st0', '%cl', '%cr0', '%dr2', '%mm0', '%xmm3',
	'%ymm2', '%zmm3', '%k1') {

	push @invalid64, permute_disp_att_all ('', $r1, '', '', '', '1');
	push @invalid64, permute_disp_att_all ('-', $r1, '', '', '', '1');
	push @invalid64, permute_disp_att_all ('', $r1, '', '%rbx', '', '1');
	push @invalid64, permute_disp_att_all ('', $r1, '', '%rbx', '2', '1');
	push @invalid64, permute_disp_att_all ('', '', '', $r1, '', '1');
	push @invalid64, permute_disp_att_all ('', '', '', $r1, '2', '1');
	push @invalid64, permute_disp_att_all ('', '%rbx', '', $r1, '', '1');
	push @invalid64, permute_disp_att_all ('', '%rbx', '', $r1, '2', '1');

	push @invalid64, permute_reg64_invalid_att ($r1);
}

foreach my $s ('', '1', '2', '4', '8') {

	push @valid64, permute_disp_att_all ('', '', '', '%rax', $s, '1');
	push @valid64, permute_disp_att_all ('', '%rbx', '', '%rdi', $s, '1');
	push @valid64, permute_disp_att_all ('', '%rbx', '', '%rdi', $s, 'varname');
}

push @valid64, permute_disp_att_all ('', '%rax', '', '', '', '1');
push @valid64, permute_disp_att_all ('', '%rax', '', '', '', 'varname');

push @valid64, permute_disp_att_all ('', '%eax', '', '', '', '1');
push @valid64, permute_disp_att_all ('', '%r9d', '', '', '', '1');

foreach my $r1 ('%r9d', '%ecx') {

	foreach my $s ('',  '2') {

		push @invalid64, permute_disp_att_all ('', '%rbx', '', $r1, $s, '1');
		push @invalid64, permute_disp_att_all ('', '%rbx', '', $r1, $s, 'varname');

		push @invalid64, permute_disp_att_all ('', $r1, '', '%rbx', $s, '1');
		push @invalid64, permute_disp_att_all ('', $r1, '', '%rbx', $s, 'varname');
	}
}

foreach my $s ('',  '4') {

	push @valid64, permute_disp_att_all ('', '', '', '%r9d', $s, '1');
	push @valid64, permute_disp_att_all ('', '', '', '%eax', $s, '1');
	push @valid64, permute_disp_att_all ('', '%eax', '', '%r9d', $s, '1');
	push @valid64, permute_disp_att_all ('', '%r9d', '', '%eax', $s, '1');
}

push @invalid64, permute_disp_att_all ('-', '%rax', '', '', '', '1');
push @invalid64, permute_disp_att_all ('-', '%rbx', '', '%rdi', '', '1');
push @invalid64, permute_disp_att ('', '%rbx', '', '', '', '%rax');
push @invalid64, permute_disp_att ('', '', '', '%rdi', '', '%rax');
push @invalid64, permute_disp_att ('', '', '', '%rdi', '2', '%rax');

foreach my $s ('', '2') {

	push @invalid64, permute_disp_att ('', '%rbx', '', '%rdi', $s, '%rax');
	push @invalid64, permute_disp_att_all ('-', '%rbx', '', '%rdi', $s, '%rax');
	push @invalid64, permute_disp_att_all ('', '%rbx', '-', '%rdi', $s, '%rax');
	push @invalid64, permute_disp_att_all ('-', '%rbx', '-', '%rdi', $s, '%rax');
}

push @valid64, permute_att ('', '', '', '', '', '', '1');
push @valid64, permute_att ('', '', '', '', '', '', 'varname');
push @valid64, permute_att ('', 'varname', '', '', '', '', '');
push @invalid64, permute_att ('', '', '', 'varname', '', '', '');
push @invalid64, permute_att ('', '', '', 'varname', '', '', '2');
push @invalid64, permute_att ('', '', '', 'varname', '2', '', '');
push @invalid64, permute_att ('', '', '', 'varname', '2', '', 'varname');
push @invalid64, permute_att ('', 'varname', '', '', '', '', 'varname');
push @invalid64, permute_att ('', 'varname', '', 'varname', '2', '', '');
push @invalid64, permute_att ('', 'varname', '', 'varname', '2', '', 'varname');

foreach my $r1 ('%rax', '%rbp', '%rcx', '%rsi') {

	push @valid64, permute_disp_att_all ('', '%rbx', '', $r1, '1', '3');
	push @invalid64, permute_disp_att_all ('-', '%rbx', '', $r1, '1', '7');
	push @invalid64, permute_disp_att_all ('', '%rbx', '-', $r1, '1', '9');
	push @invalid64, permute_disp_att_all ('-', '%rbx', '-', $r1, '1', '5');
	push @valid64, permute_disp_att_all ('', '', '', $r1, '1', '3');
	push @invalid64, permute_disp_att_all ('', '', '-', $r1, '1', '5');
}

push @invalid64, permute_disp_att_all ('', '', '', '1', '8', '29');
push @invalid64, permute_disp_att_all ('', '', '-', '1', '8', '29');

push @invalid64, permute_disp_att_all ('', '%rbx', '', '1', '8', '31');
push @invalid64, permute_disp_att_all ('', '%rbx', '-', '1', '8', '31');

push @invalid64, permute_att ('', '%rbx', '', '1', '8', '', '%rax');
push @invalid64, permute_att ('', '%rbx', '-', '1', '8', '', '%rax');

push @invalid64, permute_disp_att_all ('', '3', '', '%rbx', '8', '33');
push @invalid64, permute_disp_att_all ('', '3', '-', '%rbx', '8', '33');

push @invalid64, permute_att ('', '%rbx*2', '', '%rax', '8', '', '');

foreach my $r1 ('%rsp', '%rip') {

	foreach my $s ('', '1', 'z', '2') {

		push @invalid64, permute_disp_att_all ('', '', '', $r1, $s, '17');
		push @invalid64, permute_disp_att_all ('', '%rcx', '', $r1, $s, '19');
	}
	push @invalid64, permute_sign_disp_att_all ($r1, '2', '1', '%rax');
}

push @valid64, permute_disp_att_all ('', '%rsp', '', '%rcx', '', '11');
push @valid64, permute_disp_att_all ('', '%rsp', '', '%rcx', '1', '13');
push @valid64, permute_disp_att_all ('', '%rsp', '', '%rbp', '1', '15');

push @invalid64, permute_disp_att_all ('', '%rip', '', '%rcx', '', '11');
push @invalid64, permute_disp_att_all ('', '%rip', '', '%rcx', '1', '13');
push @invalid64, permute_disp_att_all ('', '%rip', '', '%rbp', '1', '15');

push @invalid64, permute_disp_att_all ('', '', '', '%rax', '5', '17');
push @invalid64, permute_disp_att_all ('', '', '-', '%rax', '5', '17');
push @invalid64, permute_sign_disp_att_all ('%rbx', '%rax', '5', '17');

push @invalid64, permute_disp_att_all ('', '', '', '%rax', '%rdx', '19');
push @invalid64, permute_disp_att_all ('', '', '-', '%rax', '%rdx', '19');

push @invalid64, permute_sign_disp_att_all ('%rbx', '%rax', '%rdx', '19');

push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '', '', '', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', 'varname', '', '', '', '');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '%rbx', '', '', '', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '%rbx', '', '%rsi', '', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '', '%rsi', '', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '%rbx', '', '%rsi', '2', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '', '%rsi', '2', 'varname');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '-', '%rsi', '2', 'varname');

push @invalid64, permute_disp_att_segreg_all ('%ax', '-', '%rbx', '', '', '', '1');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '', '%rdi', '', '23');
push @invalid64, permute_disp_att_segreg_all ('%ax', '', '', '-', '%rdi', '', '23');

foreach my $s ('', '2') {

	push @invalid64, permute_sign_disp_att_segreg_all ('%ax', '%rbx', '%rdi', $s, '23');
	push @invalid64, permute_sign_disp_att_segreg_all ('%ax', '%cs', '%rbx', $s, '25');
	push @invalid64, permute_sign_disp_att_segreg_all ('%ax', '%rbx', '%cs', $s, '27');
}

push @invalid64, permute_disp_att_segreg_all ('%ax', '', '%cs', '', '', '', '25');
push @invalid64, permute_disp_att_segreg_all ('%ax', '-', '%cs', '', '', '', '25');

push @invalid64, permute_att ('', '', '', '', '', '', '%cx');
push @invalid64, permute_att ('', '%rax', '', '', '', '', '%cx');
push @invalid64, permute_att ('', '%si', '', '', '', '', '%cx');
push @invalid64, permute_att ('', '%rax', '', '%rbx', '', '', '%cx');
push @invalid64, permute_att ('', '%rax', '', '%rbx', '2', '', '%cx');
push @invalid64, permute_att ('', '', '', '%rbx', '2', '', '%cx');

push @invalid64, permute_disp_att_all ('', '', '', 'varname', '2', '6');
push @invalid64, permute_disp_att_all ('', '%rax', '', 'varname', '2', '6');
push @invalid64, permute_disp_att_all ('', 'varname', '', '%rax', '', '6');
push @invalid64, permute_disp_att_all ('', 'varname', '', '%rax', '2', '6');

push @invalid64, permute_disp_att_all ('', '%eebx', '', '', '', '6');
push @invalid64, permute_disp_att_all ('', '%eebx', '', '%cx', '', '6');
push @invalid64, permute_disp_att_all ('', '%cx', '', '%eebx', '', '6');
push @invalid64, permute_disp_att_all ('', '%erbx', '', '', '', '6');
push @invalid64, permute_disp_att_all ('', '%erbx', '', '%cx', '', '6');
push @invalid64, permute_disp_att_all ('', '%erbx', '', '%rcx', '', '6');
push @invalid64, permute_disp_att_all ('', '%cx', '', '%erbx', '', '6');
push @invalid64, permute_disp_att_all ('', '%rcx', '', '%erbx', '', '6');
push @invalid64, permute_disp_att_all ('', '%cx', '', '%si', '', '6');
push @invalid64, permute_disp_att_all ('', '%si', '', '%cx', '', '6');
push @invalid64, permute_disp_att_all ('', '%cx', '', '%si', '8', '6');
push @invalid64, permute_disp_att_all ('', '%si', '', '%cx', '8', '6');
push @invalid64, permute_disp_att_all ('', '%rax -', '', '', '', '6');
push @invalid64, permute_disp_att_all ('', '%rax -', '', '%rbx', '', '6');
push @invalid64, permute_disp_att_all ('', '%rax -', '', '%rbx', '4', '6');
push @invalid64, permute_disp_att_all ('', 'bsi', '', '%cx', '2', '6');
push @invalid64, permute_disp_att_all ('', '%si', '', 'bcx', '2', '6');
push @invalid64, permute_disp_att_all ('-', '%bx', '', '', '', 'varname');

# ----------- mixed

my @valid_mixed = ();
my @invalid_mixed = ();

push @invalid_mixed, '(%ebx, %ax)';
push @invalid_mixed, '(%si, %eax)';
push @invalid_mixed, '2(%ebx,%ax)';
push @invalid_mixed, '(-%cx,%ebx,2)';
push @invalid_mixed, '(%si,%esi,8)';
push @invalid_mixed, '(%edi,%sp)';
push @invalid_mixed, '(%rax,%ebx)';
push @invalid_mixed, '(%rbx,%r8d)';
push @invalid_mixed, '(%ecx,%rsi)';
push @invalid_mixed, '(%rsi,%ecx,2)';
push @valid_mixed, '+-1(%ecx,%edx)';
push @invalid_mixed, '+-1(%ecx,%rdx)';
push @invalid_mixed, '+-1(%rdx,%ecx,8)';
push @invalid_mixed, '-1(%esi,%rax)';
push @invalid_mixed, '-%rcx(%esi)';
push @invalid_mixed, '(-%rcx, %esi)';
push @invalid_mixed, '(%esi, -%rcx)';
push @invalid_mixed, '-%rcx(,1)';
push @invalid_mixed, '-1(-%rcx)';
push @invalid_mixed, '1(-%rcx)';
push @invalid_mixed, '12(%rax,%rsp)';
push @valid_mixed, '%cs:5(%ecx,%esi)';
push @valid_mixed, '%ss:(%bp,%si)';

# -----------

# Test::More:
plan tests => @valid16 + 3 + @invalid16 + 2
	+ @valid32 + 3 + @invalid32 + 2
	+ @valid64 + 3 + @invalid64 + 2
	+ @valid_mixed + 2 + @invalid_mixed + 2;

foreach (@valid16) {
	is ( is_valid_16bit_addr_att ($_), 1, "'$_' is a valid 16-bit AT&T addressing scheme" );
}
is ( is_valid_16bit_addr_intel ($valid16[0]), 0, "'$valid16[0]' is not a valid 16-bit Intel addressing scheme" );
is ( is_valid_16bit_addr ($valid16[0]), 1, "'$valid16[0]' is a valid 16-bit addressing scheme" );
is ( is_valid_addr ($valid16[0]), 1, "'$valid16[0]' is a valid addressing scheme" );

foreach (@invalid16) {
	is ( is_valid_16bit_addr_att ($_), 0, "'$_' is not a valid 16-bit AT&T addressing scheme" );
}
is ( is_valid_16bit_addr_intel ($invalid16[0]), 0, "'$invalid16[0]' is not a valid 16-bit Intel addressing scheme" );
is ( is_valid_16bit_addr ($invalid16[0]), 0, "'$invalid16[0]' is not a valid 16-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid32) {
	is ( is_valid_32bit_addr_att ($_), 1, "'$_' is a valid 32-bit AT&T addressing scheme" );
}
is ( is_valid_32bit_addr_intel ($valid32[0]), 0, "'$valid32[0]' is not a valid 32-bit Intel addressing scheme" );
is ( is_valid_32bit_addr ($valid32[0]), 1, "'$valid32[0]' is a valid 32-bit addressing scheme" );
is ( is_valid_addr ($valid32[0]), 1, "'$valid32[0]' is a valid addressing scheme" );

foreach (@invalid32) {
	is ( is_valid_32bit_addr_att ($_), 0, "'$_' is not a valid 32-bit AT&T addressing scheme" );
}
is ( is_valid_32bit_addr_intel ($invalid32[0]), 0, "'$invalid32[0]' is not a valid 32-bit Intel addressing scheme" );
is ( is_valid_32bit_addr ($invalid32[0]), 0, "'$invalid32[0]' is not a valid 32-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid64) {
	is ( is_valid_64bit_addr_att ($_), 1, "'$_' is a valid 64-bit AT&T addressing scheme" );
}
is ( is_valid_64bit_addr_intel ($valid64[0]), 0, "'$valid64[0]' is not a valid 64-bit Intel addressing scheme" );
is ( is_valid_64bit_addr ($valid64[0]), 1, "'$valid64[0]' is a valid 64-bit addressing scheme" );
is ( is_valid_addr ($valid64[0]), 1, "'$valid64[0]' is a valid addressing scheme" );

foreach (@invalid64) {
	is ( is_valid_64bit_addr_att ($_), 0, "'$_' is not a valid 64-bit AT&T addressing scheme" );
}
is ( is_valid_64bit_addr_intel ($invalid64[0]), 0, "'$invalid64[0]' is not a valid 64-bit Intel addressing scheme" );
is ( is_valid_64bit_addr ($invalid64[0]), 0, "'$invalid64[0]' is not a valid 64-bit addressing scheme" );
# NOTE: no test for is_valid_addr() here, because addresses valid in other modes are present

foreach (@valid_mixed) {
	is ( is_valid_addr_att ($_), 1, "'$_' is a valid AT&T addressing scheme" );
}
is ( is_valid_addr_intel ($valid_mixed[0]), 0, "'$valid_mixed[0]' is not a valid Intel addressing scheme" );
is ( is_valid_addr ($valid_mixed[0]), 1, "'$valid_mixed[0]' is a valid addressing scheme" );

foreach (@invalid_mixed) {
	is ( is_valid_addr_att ($_), 0, "'$_' is not a valid AT&T addressing scheme" );
}
is ( is_valid_addr_intel ($invalid_mixed[0]), 0, "'$invalid_mixed[0]' is not a valid Intel addressing scheme" );
is ( is_valid_addr ($invalid_mixed[0]), 0, "'$invalid_mixed[0]' is not a valid addressing scheme" );
