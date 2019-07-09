#!perl

use strict;
use warnings;

use CPU::Z80::Disassembler;
use CPU::Z80::Assembler;
use Path::Tiny;
use Test::More;

# Bug report by Neal Crook <foofoobedoo@gmail.com> Jul 1, 2019, 11:04 PM
# Wrong disassembly of list of 16-bit words that may be labels
my $bin = z80asm(<<'END');
lab0:   nop
lab1:   nop
lab2:   nop
lab3:   nop
lab4:   nop
        jr lab0
 
        defw lab0, lab1, lab2, lab3, lab4
END
path("test.bin")->spew_raw($bin);
ok path("test.bin")->slurp_raw eq pack("C*", 
		0x00, 0x00, 0x00, 0x00, 0x00,
		0x18, 0xF9,
		0x00,0x00, 0x01,0x00, 0x02,0x00, 0x03,0x00, 0x04,0x00);


my $dis = CPU::Z80::Disassembler->new;
$dis->memory->load_file("test.bin", 0x0000);
$dis->write_dump("test.dump");
is path("test.dump")->slurp, <<'END';
0000 00         nop
0001 00         nop
0002 00         nop
0003 00         nop
0004 00         nop
0005 18F9       jr $0000
0007 00         nop
0008 00         nop
0009 010002     ld bc, $0200
000C 00         nop
000D 03         inc bc
000E 00         nop
000F 04         inc b
0010 00         nop
END


$dis->code(0,"ENTRY");
$dis->code(2,"LAB2");
$dis->defw(0x7,5);
$dis->write_asm("test.asm");
is path("test.asm")->slurp, <<'END';

        org $0000


ENTRY:
        nop
        nop

LAB2:
        nop
        nop
        nop
        jr ENTRY

        defw ENTRY, $0001, LAB2, $0003, $0004


; $0000 CCCCCCCWWWWWWWWW

; Labels
;
; $0000 => ENTRY        ENTRY => $0000
; $0002 => LAB2         LAB2  => $0002
END

ok unlink("test.bin");
ok unlink("test.dump");
ok unlink("test.asm");

done_testing;
