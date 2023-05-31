#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture';
use Path::Tiny;

use_ok 'CPU::Z80::Assembler';

path("foo.asm")->spew(<<'END');
ORG 0x0000
LD A, (foo)

ORG 0x1000
foo:
NOP
END

my($stdout, $stderr, $exit) = capture {
	system($^X, "-Iblib/lib", "blib/script/z80masm", "foo.asm", "foo.bin");
};

is norm($stdout), norm(<<'END');
0x0000: ORG 0x0000                             | 
0x0000: LD A, (foo)                            | 3A 00 10 
0x0000:                                        | 
0x0000: ORG 0x1000                             | 
0x1000: foo:                                   | 
0x1000: NOP                                    | 00 
END

is $stderr, <<"END";
CPU::Z80::Assembler - z80masm v$CPU::Z80::Assembler::VERSION

END
is $exit, 0;

is unpack("H*", path("foo.bin")->slurp_raw), 
   unpack("H*", pack("C*", 0x3a, 0x00, 0x10, (0xff) x (0x1000-3), 0x00));

unlink "foo.asm", "foo.bin";

done_testing;

sub norm {
	my($text) = @_;
	$text =~ s/\r\n/\n/g;
	return $text;
}
