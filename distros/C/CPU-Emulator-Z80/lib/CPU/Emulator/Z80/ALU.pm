# $Id: ALU.pm,v 1.9 2008/02/24 23:52:05 drhyde Exp $

package CPU::Emulator::Z80::ALU;

use strict;
use warnings;

use base qw(Exporter);
use vars qw(@EXPORT);

{   # find and export ALU_*
    no strict 'refs';
    while(my($k, $v) = each(%{__PACKAGE__.'::'})) {
        push @EXPORT, $k if(defined(&{$v}) && $k =~ /^ALU_/);
    }
}

=head1 NAME

CPU::Emulator::Z80::ALU

=head1 DESCRIPTION

This mix-in provides functions for addition and subtraction on a
Z80, settings flags and doing twos-complement jibber-jabber.

=head1 FUNCTIONS

All functions are
exported.  They all take a
reference to the Flags register as the first parameter in addition
to the parameters listed, unless otherwise stated:

=head2 ALU_add8/ALU_add16

Takes two 8/16-bit values and returns their 8/16-bit sum, and for
add16, a
third parameter indicating whether this was really called as ADC.

add16 doesn't frob the S, Z or P flags unless that extra parameter
is true.

=cut

sub ALU_add8 {
    my($flags, $op1, $op2) = @_;
    my $halfcarry = (($op1 & 0b00001111) + ($op2 & 0b00001111)) & 0x10;
    my $carry6to7 = (($op1 & 0b01111111) + ($op2 & 0b01111111)) & 0x80;
    my $result = $op1 + $op2;
    $flags->setC($result & 0x100);
    $result &= 0xFF;
    $flags->resetN();
    $flags->setZ($result == 0);
    $flags->set3($result & 0b1000);
    $flags->setH($halfcarry);
    $flags->set5($result & 0b100000);
    $flags->setS($result & 0b10000000);
    $flags->setP(
        (!$flags->getC() &&  $carry6to7) ||
        ($flags->getC()  && !$carry6to7)
    );
    return $result;
}
sub ALU_add16 {
    my($flags, $op1, $op2, $adc) = @_;
    my $halfcarry = (($op1 & 0x0FFF) + ($op2 & 0x0FFF)) & 0x1000;
    my $result = $op1 + $op2;
    $flags->setC($result & 0x10000);
    $result &= 0xFFFF;
    $flags->resetN();
    $flags->set3($result & 0x800);
    $flags->setH($halfcarry);
    $flags->set5($result & 0x2000);

    if($adc) { # only update these if this is really ADC
        my $carry14to15 =
            (($op1 & 0b0111111111111111) + ($op2 & 0b0111111111111111)) &
            0b1000000000000000;
        $flags->setP(
            (!$flags->getC() &&  $carry14to15) ||
            ($flags->getC()  && !$carry14to15)
        );
        $flags->setZ($result == 0);
        $flags->setS($result & 0x8000);
    }
    return $result;
}

=head2 ALU_sub8/ALU_sub16

Takes two 8/16-bit values and subtracts the second from the first,
returning the result.

=cut

sub ALU_sub8 {
    my($flags, $op1, $op2) = @_;
    my $result = ($op1 - $op2) & 0xFF;
    $flags->setN();
    $flags->setZ($result == 0);
    $flags->setC($op2 > $op1);
    $flags->set3($result & 0b1000);
    $flags->setH(($op2 & 0b1111) > ($op1 & 0b1111));
    $flags->setP(
        (!$flags->getC() && (($op2 & 0b1111111) > ($op1 & 0b1111111))) ||
        ($flags->getC()  && !(($op2 & 0b1111111) > ($op1 & 0b1111111)))
    );
    $flags->set5($result & 0b100000);
    $flags->setS($result & 0b10000000);
    return $result;
}

sub ALU_sub16 {
    my($flags, $op1, $op2) = @_;
    my $result = ($op1 - $op2) & 0xFFFF;
    $flags->setN();
    $flags->setZ($result == 0);
    $flags->setC($op2 > $op1);
    $flags->set3($result & 0b100000000000);
    $flags->setH(($op2 & 0b111111111111) > ($op1 & 0b111111111111));
    $flags->setP(
        (!$flags->getC() && (($op2 & 0b111111111111111) > ($op1 & 0b111111111111111))) ||
        ($flags->getC()  && !(($op2 & 0b111111111111111) > ($op1 & 0b111111111111111)))
    );
    $flags->set5($result & 0b10000000000000);
    $flags->setS($result & 0b1000000000000000);
    return $result;
}

=head2 ALU_inc8/ALU_dec8

Take a single 8-bit value and incremement/decrement it, returning
the result.  They're just wrappers around add8/sub8 that preserve
the C flag.

=cut

sub ALU_dec8 {
    my($flags, $op) = @_;
    my $c = $flags->getC();
    my $s = $op & 0x80;
    my $result = ALU_sub8($flags, $op, 1);
    $flags->setC($c);
    $flags->setP($s && !($result & 0x80));
    return $result;
}
sub ALU_inc8 {
    my($flags, $op) = @_;
    my $c = $flags->getC();
    my $s = $op & 0x80;
    my $result = ALU_add8($flags, $op, 1);
    $flags->setC($c);
    #$flags->setP(!$s && ($result & 0x80));
    return $result;
}

=head2 ALU_parity

Returns the parity of its operand.  No flags register is passed,
as this does *not* update the register.

=cut

sub ALU_parity {
    my($v, $p) = (@_, 1);
    $p = !$p foreach(grep { $v & 2**$_ } 0 .. 15);
    $p;
}

=head2 ALU_getsigned

Takes two parameters, a value and a number of bits.  Decodes
the value 2s-complement-ly for the appropriate number of bits,
returning a signed value.  undef is turned into 0.

No flags reigster needed

=cut

sub ALU_getsigned {
    my($value, $bits) = @_;
    $value ||= 0; # turn undef into 0
    # if MSB == 0, just return the value
    return $value unless($value & (2 ** ($bits - 1)));
    # algorithm is:
    #   flip all bits
    #   add 1
    #   negate
    return -1 * (($value ^ ((2 ** $bits) - 1)) + 1);
}

=head1 BUGS/WARNINGS/LIMITATIONS

None known

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism and bug reports. The best bug reports include files that I can add to the test suite, which fail with the current code in CVS and will pass once I've fixed the bug.

Feature requests are far more likely to get implemented if you submit a patch yourself.

=head1 CVS

L<http://drhyde.cvs.sourceforge.net/drhyde/perlmodules/CPU-Emulator-Z80/>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2008 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
