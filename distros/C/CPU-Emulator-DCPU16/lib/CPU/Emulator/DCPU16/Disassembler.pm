package CPU::Emulator::DCPU16::Disassembler;
use strict;
use CPU::Emulator::DCPU16;

=head1 NAME

CPU::Emulator::DCPU16::Disassembler -  a disassembler for DCPU-16 bytecode

=head1 SYNOPSIS
    
    # Disassemble a single instruction
    my $instruction = CPU::Emulator::DCPU16::Disassembler->disassemble($pc, @memory);

    # Dump a whole program
    my $asm         = CPU::Emulator::DCPU16::Disassembler->dump($bytes);

=cut



our @OPCODES   = qw(NOOP SET ADD SUB MUL DIV MOD SHL SHR AND BOR XOR IFE IFN IFG IFB);
our @REGISTERS = qw(A B C X Y Z I J);


sub _get_operand {
    my $n    = shift;
    my $pc   = shift;
    my @mem  = @_;
    if ($n < 0x08) {
        sprintf("%s", $REGISTERS[$n & 7]);
    } elsif ($n < 0x10) {
        sprintf("[%s]", $REGISTERS[$n & 7]);
    } elsif ($n < 0x18) {
        sprintf("[0x%04x+%s]", $mem[$$pc++], $REGISTERS[$n & 7]);
    } elsif ($n  == 0x18) {
        "POP"
    } elsif ($n  == 0x19) {
        "PEEK"
    } elsif ($n  == 0x1A) {
        "PUSH"
    } elsif ($n  == 0x1B) {
        "SP"
    } elsif ($n  == 0x1C) {
        "PC"
    } elsif ($n  == 0x1D) {
        "O"
    } elsif ($n  == 0x1E) {
        sprintf("[0x%04x]", $mem[$$pc++]);
    } elsif ($n  == 0x1F) {
        sprintf("0x%04x", $mem[$$pc++]);
    } else {
        ($n - 0x20);
    } 
}

=head2 disassemble <pc> <memory>

Given a program counter and an array of memory words will dissassemble the current instruction.

=cut
sub disassemble {
    my $class = shift;
    my $pc    = shift;
    my @mem   = @_;
    my $word  = $mem[$pc++];
    my $op    = $word & 0xF;
    my $a     = ($word >> 4) & 0x3F;
    my $b     = ($word >> 10);
    
    my $ret   = "";
    if ($op > 0) {
        $ret .= $OPCODES[$op]." ";
        $ret .= _get_operand($a, \$pc, @mem);
        $ret .= ", ";
        $ret .= _get_operand($b, \$pc, @mem);
    } elsif ($a == 0x01) {
        $ret .= "JSR "._get_operand($b, \$pc, @mem);
    } else {
        $ret .= sprintf("UNK[%02x] ", $a)._get_operand($b, \$pc, @mem);
    }
    wantarray ? ($ret, $pc) : $ret;
}

=head2 dump <words>

Given an scalar containing program bytecode will return a string representing the assembler.

=cut
our $CODE_INDENT = 10;
sub dump {
    my $class = shift;
    my $bytes = shift;
    
    my @words  = CPU::Emulator::DCPU16->bytes_to_array($bytes);
    my $pc     = 0;
    my %labels = ();
    my %lines  = ();
    
    while ($pc < scalar(@words)) {
        my ($tmp, $new_pc) = $class->disassemble($pc, @words);
        if ($tmp =~ /^(JSR|SET PC,)\s*(.+)$/) {
            my $addr = "$2";
            # TODO potentially replace faux address labels with generated ones
            $labels{hex($addr)} = $addr if $addr =~ /^0x/; 
        }
        $lines{$pc} = $tmp;
        $pc         = $new_pc;
    }
    my $indent = 0;
    my $ret    = "";
    foreach $pc (sort { $a <=> $b } keys %lines) {
        my $line = $lines{$pc};
        #$ret .= sprintf "%d (0x%04x) ", $pc, $pc;
        if ($labels{$pc}) {
            $ret .= ":".$labels{$pc} . " " ." "x ($CODE_INDENT-length($labels{$pc})-2);
        } else {
            $ret .= " "x$CODE_INDENT;
        }
        $ret .= "  " x $indent;
        $ret .= "$line\n";
        if ($line =~ /^IF/) {
            $indent++;
        } elsif ($indent) {
            $indent--;
        }
    }
    return $ret;
}
1;