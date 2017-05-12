# $Id: Z80.pm,v 1.56 2008/06/13 14:42:08 drhyde Exp $

package CPU::Emulator::Z80;

use strict;
use warnings;

use vars qw($VERSION %INSTR_LENGTHS %INSTR_DISPATCH);

$VERSION = '1.0';

$SIG{__WARN__} = sub {
    warn(__PACKAGE__.": $_[0]\n");
};

use Carp;
use Scalar::Util qw(blessed reftype);
use Tie::Hash::Vivify;
use Carp qw(confess);
use Data::Dumper;

use CPU::Emulator::Memory::Banked;
use CPU::Emulator::Z80::Register8;
use CPU::Emulator::Z80::Register8F;
use CPU::Emulator::Z80::Register8R;
use CPU::Emulator::Z80::Register16;
use CPU::Emulator::Z80::Register16SP;
use CPU::Emulator::Z80::ALU; # import add/subtract methods

my @REGISTERS16 = qw(PC SP IX IY HL);          # 16 bit registers
# NB W and Z aren't programmer-accesible, for internal use only!
my @REGISTERS8  = qw(A B C D E F R W Z I);     # 8 bit registers
my @ALTREGISTERS = qw(A B C D E F HL);         # those which have alt.s
my @REGISTERS   = (@REGISTERS16, @REGISTERS8); # all registers

=head1 NAME

CPU::Emulator::Z80 - a Z80 emulator

=head1 SYNOPSIS

    # create a CPU with 64K of zeroes in RAM
    my $cpu = CPU::Emulator::Z80->new();

    # set a breakpoint
    $cpu->memory()->poke16(0xF000, 0xDDDD); # STOP instruction
    $cpu->memory()->poke(0xF002, 0x00);

    $cpu->memory()->poke(0, 0xC3);     # JP 0xC000
    $cpu->memory()->poke16(1, 0xC000);

    # run until we hit a breakpoint ie RST 1
    eval { $cpu->run(); }
    print $cpu->format_registers();

=head1 DESCRIPTION

This class provides a virtual Z80 micro-processor written in pure perl.
You can program it in Z80 machine code.  Machine code is fast!  This will
make your code faster!

=head1 METHODS

=head2 new

The constructor returns an object representing a Z80 CPU.  It takes
several optional parameters:

=over

=item memory

can be either an object inheriting from CPU::Emulator::Memory, or a string
of data with which to initialise RAM.  If a string is passed, then a
CPU::Emulator::Memory::Banked is created of the appropriate size.  If not
specified at all, then a CPU::Emulator::Memory::Banked is created with
64K of zeroes.

=item ports

can be either 256 or 65536 (no other values are permitted) and defaults
to 65536.  This is the number of I/O ports that can be addressed.
If set to 65536, the entire address bus is used to determine what
port I/O instructions tickle.  If 256, then the most significant 8
bits are ignored.

=item init_PC, init_A, init_B ...

For each of A B C D E F R HL IX IY PC SP, an integer, the starting
value for that register, defaulting to 0.

=item init_A_, init_B_, ...

For each of A B C D E F HL, an integer for the starting value for that
register in the alternate set, defaulting to 0.  Note that contrary to
normal Z80 custom these are named as X_ instead of X'.  This is just for
quoting convenience.

=back

=cut

sub new {
    my($class, %args) = @_;
    if(exists($args{memory})) {
        if(blessed($args{memory})) {
            die("memory must be a CPU::Emulator::Memory")
                unless($args{memory}->isa('CPU::Emulator::Memory'));
        } elsif(!ref($args{memory})) {
            $args{memory} = CPU::Emulator::Memory::Banked->new(
                bytes => $args{memory},
                size  => length($args{memory})
            );
        } else {
            die("memory must be a string or an object\n");
        }
    } else {
        $args{memory} = CPU::Emulator::Memory::Banked->new();
    }

    if(exists($args{ports})) {
        die("$args{ports} is a stupid number of ports\n")
            unless($args{ports} == 256 || $args{ports} == 65536);
    } else {
        $args{ports} = 65536;
    }

    foreach my $register (@REGISTERS, map { "${_}_" } @ALTREGISTERS) {
        $args{"init_$register"} = 0
            if(!exists($args{"init_$register"}));
    }

    # bless early so we can close over it ...
    my $self;
    $self = bless {
        iff1        => 0,
        iff2        => 0,
        ports       => $args{ports},
        inputs      => {},
        outputs     => {},
        memory      => $args{memory},
        registers => Tie::Hash::Vivify->new(sub { confess("No auto-vivifying registers!\n".Dumper(\@_)) }),
        hw_registers => Tie::Hash::Vivify->new(sub { confess("No auto-vivifying hw_registers!\n".Dumper(\@_)) }),
        derived_registers => Tie::Hash::Vivify->new(sub { confess("No auto-vivifying derived_registers!\n".Dumper(\@_)) }),
    }, $class;

    $self->{hw_registers}->{$_} = CPU::Emulator::Z80::Register8->new(
        cpu => $self, value => $args{"init_$_"}
    ) foreach(@REGISTERS8);

    $self->{hw_registers}->{$_} = CPU::Emulator::Z80::Register16->new(
        cpu => $self, value => $args{"init_$_"}
    ) foreach(@REGISTERS16);

    $self->{hw_registers}->{$_.'_'} = blessed($self->{hw_registers}->{$_})->new(
        cpu => $self, value => $args{"init_$_"}
    ) foreach(@ALTREGISTERS);

    bless $self->{hw_registers}->{$_}, 'CPU::Emulator::Z80::Register8F'
        foreach(qw(F F_));
    bless $self->{hw_registers}->{R}, 'CPU::Emulator::Z80::Register8R';
    bless $self->{hw_registers}->{SP}, 'CPU::Emulator::Z80::Register16SP';


    $self->{derived_registers}->{AF}  = $self->_derive_register16(qw(A F));
    $self->{derived_registers}->{AF_} = $self->_derive_register16(qw(A_ F_));
    $self->{derived_registers}->{BC}  = $self->_derive_register16(qw(B C));
    $self->{derived_registers}->{BC_}  = $self->_derive_register16(qw(B_ C_));
    $self->{derived_registers}->{DE}  = $self->_derive_register16(qw(D E));
    $self->{derived_registers}->{DE_}  = $self->_derive_register16(qw(D_ E_));
    $self->{derived_registers}->{WZ}  = $self->_derive_register16(qw(W Z));
    $self->{derived_registers}->{H}   = $self->_derive_register8(qw(HL high));
    $self->{derived_registers}->{H_}   = $self->_derive_register8(qw(HL_ high));
    $self->{derived_registers}->{L}   = $self->_derive_register8(qw(HL low));
    $self->{derived_registers}->{L_}   = $self->_derive_register8(qw(HL_ low));
    $self->{derived_registers}->{HIX} = $self->_derive_register8(qw(IX high));
    $self->{derived_registers}->{LIX} = $self->_derive_register8(qw(IX low));
    $self->{derived_registers}->{HIY} = $self->_derive_register8(qw(IY high));
    $self->{derived_registers}->{LIY} = $self->_derive_register8(qw(IY low));

    $self->{registers}->{$_} = $self->{hw_registers}->{$_}
        foreach(keys %{$self->{hw_registers}});
    $self->{registers}->{$_} = $self->{derived_registers}->{$_}
        foreach(keys %{$self->{derived_registers}});

    return $self;
}

# create a 16-bit register-pair from two real 8-bit registers
sub _derive_register16 {
    my($self, $high, $low) = @_;
    return CPU::Emulator::Z80::Register16->new(
        get => sub {
                   return 256 * $self->register($high)->get() +
                                $self->register($low)->get()
               },
        set => sub {
                   my $value = shift;
                   $self->register($high)->set($value >>8);
                   $self->register($low)->set($value & 0xFF);
               },
        cpu => $self
    );
}
# create an 8-bit pseudo-register from a 16-bit register
sub _derive_register8 {
    my($self, $pair, $half) = @_;
    return CPU::Emulator::Z80::Register8->new(
        get => sub {
                   my $r = $self->register($pair)->get();
                   return ($half eq 'high')
                       ? $r >> 8
                       : $r & 0xFF
               },
        set => sub {
                   my $value = shift;
                   $self->register($pair)->set(
                       ($half eq 'high')
                           ? ($self->register($pair)->get() & 0xFF) |
                             ($value << 8)
                           : ($self->register($pair)->get() & 0xFF00) | $value
                   );
               },
        cpu => $self
    );
}

=head2 add_input_device

Takes two named parameters, 'address' and 'function', and creates an
input port at that address.  Reading from the port will call the
function with no parameters,
returning whatever the function returns.

In 256-port mode, the port is effectively replicated 256 times.

=cut

sub add_input_device {
    my($self, %params) = @_;
    my $address = $params{address} & ($self->{ports} - 1);
    die(sprintf("Device already exists at %#06x", $address))
        if(exists($self->{inputs}->{$address}));
    $self->{inputs}->{$address} = $params{function};
}

sub _get_from_input {
    my($self, $addr) = @_;
    $addr  = $addr & ($self->{ports} - 1);
    if(exists($self->{inputs}->{$addr})) {
        return $self->{inputs}->{$addr}->();
    } else {
        die(sprintf("No such port %#06x", $addr));
    }
}

=head2 add_output_device

Takes two named parameters, 'address' and 'function', and creates an
output port at that address.  Writing to the port simply calls that
function with the byte to be written as its only parameter.

In 256-port mode, the port is effectively replicated 256 times.

=cut

sub add_output_device {
    my($self, %params) = @_;
    my $address = $params{address} & ($self->{ports} - 1);
    die(sprintf("Device already exists at %#06x", $address))
        if(exists($self->{outputs}->{$address}));
    $self->{outputs}->{$address} = $params{function};
}

sub _put_to_output {
    my($self, $addr, $byte) = @_;
    $addr  = $addr & ($self->{ports} - 1);
    if(exists($self->{outputs}->{$addr})) {
        $self->{outputs}->{$addr}->($byte);
    } else {
        carp(sprintf("No such port %#06x", $addr));
    }
}

=head2 memory

Return a reference to the object that represent's the system's memory.

=cut

sub memory {
    my $self = shift;
    return $self->{memory};
}

=head2 register

Return the object representing a specified register.  This can be any
of the real registers (eg D or D_) or a derived register (eg DE or L).
For (HL) it returns the private internal DON'T TOUCH THIS 'W' register,
for evil twisty internals reasons.

=cut

sub register {
    my($self, $r) = @_;
    return $self->{registers}->{($r eq '(HL)') ? 'W' : $r};
}

=head2 status

Return a scalar representing the entire state of the CPU or, if passed
a scalar, attempt to initialise the CPU to the status it represents.

=cut

sub status {
    my $self = shift;
    if(@_) { $self->_status_load(@_); }
    return
        join('', map {
            chr($self->register($_)->get())
        } qw(A B C D E F A_ B_ C_ D_ E_ F_ R I))
       .join('', map {
            chr($self->register($_)->get() >> 8),
            chr($self->register($_)->get() & 0xFF),
        } qw(SP PC IX IY HL HL_));
}
sub _status_load {
    my($self, $status) = @_;
    my @regs = split(//, $status);
    $self->register($_)->set(ord(shift(@regs)))
        foreach(qw(A B C D E F A_ B_ C_ D_ E_ F_ R I));
    $self->register($_)->set(256 * ord(shift(@regs)) + ord(shift(@regs)))
        foreach(qw(SP PC IX IY HL HL_));
}

=head2 registers

Return a hashref of all the real registers and their values.

=head2 format_registers

A convenient method for getting all the registers in a nice
printable format.  It mostly exists to help me with debuggering,
but if you promise to be good you can use it too.  Just don't
rely on the format remaining unchanged.

=cut

sub registers {
    my $self = shift;
    return {
        map {
            $_ => $self->register($_)->get()
        } grep { $_ !~ /^(W|Z)$/ } keys %{$self->{hw_registers}}
    }
}

sub format_registers {
    my $self = shift;
    sprintf("#
#              SZ5H3PNC                             SZ5H3PNC
# A:  0x%02X F:  %08b HL:  0x%04X    A_: 0x%02X F_: %08b HL_: 0x%04X
# B:  0x%02X C:  0x%02X                    B_: 0x%02X C_: 0x%02X
# D:  0x%02X E:  0x%02X                    D_: 0x%02X E_: 0x%02X
# 
# IX: 0x%04X IY: 0x%04X SP: 0x%04X PC: 0x%04X
#
# R:  0x%02X I:  0x%02X
# W:  0x%02X Z:  0x%02X (internal use only)
", map { $self->register($_)->get(); } qw(A F HL A_ F_ HL_ B C B_ C_ D E D_ E_ IX IY SP PC R I W Z));
}

=head2 interrupt

Attempt to raise an interrupt.  Whether any attention is paid to it or not
depends on whether you've enabled interrupts or not in your Z80 code.
Because only IM 1 is implemented, this will generate a RST 0x38 if
interrupts are enabled.  Note that interrupts are disabled at power-on.

This returns true if the interrupt will be acted upon, false otherwise.
That is, it returns true if interrupts are enabled.

=head2 nmi

Raise a non-maskable interrupt.  This generates a CALL 0x0066 as the
next instruction.a  This also disables interrupts.  Interrupts are
restored to their previous state by a RETN instruction.

=head2 run

Start the CPU running from whatever the Program Counter (PC) is set to.
This will by default run for ever.  However, it takes an optional
parameter telling the CPU to run that number of instructions.

This returns either when that many instructions have been executed, or
when a STOP instruction executed - see 'Extra Instructions' below.

On return, the PC will point at the next instruction to execute so that
you can resume where you left off.

=head2 stopped

Returns true if the CPU has STOPped, false otherwise.  You can use this
to easily determine why the run() method returned.

=cut

# SEE http://www.z80.info/decoding.htm
#     http://www.z80.info/z80sflag.htm
# NB when decoding, x == first 2 bits, y == next 3, z == last 3
#                   p == first 2 bits of y, q == last bit of y
my @TABLE_R   = (qw(B C D E H L (HL) A));
my @TABLE_RP  = (qw(BC DE HL SP));
my @TABLE_RP2 = (qw(BC DE HL AF));
my @TABLE_CC  = (qw(NZ Z NC C PO PE P M));
my @TABLE_ALU = (
    \&_ADD_r8_r8, \&_ADC_r8_r8, \&_SUB_r8_r8, \&_SBC_r8_r8,
    \&_AND_r8_r8, \&_XOR_r8_r8, \&_OR_r8_r8, \&_CP_r8_r8
);
my @TABLE_ROT = (
    \&_RLC, \&_RRC, \&_RL, \&_RR, \&_SLA, \&_SRA, \&_SLL, \&_SRL
);
my @TABLE_BLI = (
    [\&_LDI, \&_CPI, \&_INI, \&_OUTI],
    [\&_LDD, \&_CPD, \&_IND, \&_OUTD],
    [\&_LDIR, \&_CPIR, \&_INIR, \&_OTIR],
    [\&_LDDR, \&_CPDR, \&_INDR, \&_OTDR],
);

# NB order is important in these tables
%INSTR_LENGTHS = (
    (map { $_ => 'UNDEFINED' } (0 .. 255)),
    # un-prefixed instructions
    # x=0, z=0
    (map { ($_ << 3) => 1 } (0, 1)), # NOP; EX AF, AF'
    (map { ($_ << 3) => 2 } (2 .. 7)), # DJNZ d; JR d; JR X, d
    # x=0, z=1
    (map { 0b00000001 | ($_ << 4 ) => 3 } (0 .. 3)), # LD rp[p], nn
    (map { 0b00001001 | ($_ << 4 ) => 1 } (0 .. 3)), # ADD HL, rp[p]
    # x=0, z=2
    (map { 0b00000010 | ($_ << 3) => 1 } (0 .. 3)), # LD (BC/DE), A; LD A, (BC/DE)
    (map { 0b00000010 | ($_ << 3) => 3 } (4 .. 7)), #  LD (nn), HL/A, LD HL/A, (nn)
    # x=0, z=3
    (map { 0b00000011 | ($_ << 3) => 1 } (0 .. 7)), # INC/DEC rp
    # x=0, z=4
    (map { 0b00000100 | ($_ << 3) => 1 } (0 .. 7)), # INC r[y]
    # x=0, z=5
    (map { 0b00000101 | ($_ << 3) => 1 } (0 .. 7)), # DEC r[y]
    # x=0, z=6
    (map { 0b00000110 | ($_ << 3) => 2 } (0 .. 7)), # LD r[y], n
    # x=0, z=7: RLCA, RRCA, RLA, RRA, DAA, CPL, SCF, CCF
    (map { 0b00000111 | ($_ << 3) => 1 } (0 .. 7)),
    # x=1
    (map { 0b01000000 + $_ => 1 } (0 .. 63)), # LD r[y], r[z], HALT
    # x=2
    (map { 0b10000000 + $_ => 1 } (0 .. 63)), # alu[y] on A and r[z]
    # x=3, z=0
    (map { 0b11000000 | ($_ << 3) => 1 } (0 .. 7)), # RET cc[y]
    (map { 0b11000001 | ($_ << 3) => 1 } (0 .. 7)), # POP rp2[p]/RET/EXX/JP HL/LD SP, HL
    (map { 0b11000010 | ($_ << 3) => 3 } (0 .. 7)), # JP cc[y], nn
    (map { 0b11000100 | ($_ << 3) => 3 } (0 .. 7)), # CALL cc[y], nn
    (map { 0b11000101 | ($_ << 4) => 1 } (0 .. 3)), # PUSH rp2[p]
    (map { 0b11000110 | ($_ << 3) => 2 } (0 .. 7)), # ALU[y] A, n
    (map { 0b11000111 | ($_ << 3) => 1 } (0 .. 7)), # RST y*8
    (map { 0b11000011 | ($_ << 3) => 1 } (4 .. 7)), # EX(SP), HL/EX DE, HL/DI/EI
    0b11010011 => 2, # OUT (n), A
    0b11011011 => 2, # IN A, (n)
    0xC3 => 3, # JP nn
    0xCD => 3, # CALL nn

    0xCB, { (map { $_ => 1 } (0 .. 255)) }, # roll/shift/bit/res/set
    0xED, {
            (map { 0b01000000 | ($_ << 3) => 1 } (0 .. 7)), # IN r[y],(C)
            (map { 0b01000001 | ($_ << 3) => 1 } (0 .. 7)), # OUT (C),r[y]/OUT (C), 0
            (map { 0b01000010 | ($_ << 3) => 1 } (0 .. 7)), # ADC/SBC HL, rp[p]
            (map { 0b01000011 | ($_ << 3) => 3 } (0 .. 7)), # LD (nn), rp[p]/LD rp[p], (nn)
            (map { 0b01000100 | ($_ << 3) => 1 } (0 .. 7)), # NEG
            (map { 0b01000101 | ($_ << 3) => 1 } (0 .. 7)), # RETI/RETN
            (map { 0b01000110 | ($_ << 3) => 1 } (0 .. 7)), # IM im[y]
            (map { 0b01000111 | ($_ << 3) => 1 } (0 .. 7)), # LD I/R,A;LD A,I/R;RRD;RLD;NOP
            (map { 0b10000000 | $_ => 1 } (0 .. 63)), # block instrs
            # invalid instr, equiv to NOP
            (map { $_ => 1 } ( 0b00000000 .. 0b00111111,
                               0b11000000 .. 0b11111111)),
          },
);
$INSTR_LENGTHS{0xDD} = $INSTR_LENGTHS{0xFD} = {
    # NB lengths in here do *not* include the prefix
    (map { $_ => $INSTR_LENGTHS{$_} } (0 .. 255)),
    0x34 => 2, # INC (IX + d)
    0x35 => 2, # DEC (IX + d)
    0x36 => 3, # LD (IX + d), n
    0x46 => 2, # LD B, (IX + n)
    0x4E => 2, # LD C, (IX + n)
    0x56 => 2, # LD D, (IX + n)
    0x5E => 2, # LD E, (IX + n)
    0x66 => 2, # LD H, (IX + n)
    0x6E => 2, # LD L, (IX + n)
    0x7E => 2, # LD A, (IX + n)
    0x70 => 2, # LD (IX + n), B
    0x71 => 2, # LD (IX + n), C
    0x72 => 2, # LD (IX + n), D
    0x73 => 2, # LD (IX + n), E
    0x74 => 2, # LD (IX + n), H
    0x75 => 2, # LD (IX + n), L
    0x77 => 2, # LD (IX + n), A
    0x86 => 2, # ADD A, (IX + n)
    0x8E => 2, # ADC A, (IX + n)
    0x96 => 2, # SUB A, (IX + n)
    0x9E => 2, # SBC A, (IX + n)
    0xA6 => 2, # AND (IX + n)
    0xAE => 2, # XOR (IX + n)
    0xB6 => 2, # OR  (IX + n)
    0xBE => 2, # CP  (IX + n)
    0xED => 1, # NOP
    0xCB => { map { $_ => 2 } (0 .. 255) },
    0xDD => { map { $_ => 1 } (0 .. 255) }, # magic
    0xFD => { map { $_ => 1 } (0 .. 255) }, # magic
};

# these are all passed a list of parameter bytes
%INSTR_DISPATCH = (
    # un-prefixed instructions
    0          => \&_NOP,
    0b00001000 => sub { _swap_regs(shift(), qw(AF AF_)); },
    0b00010000 => \&_DJNZ,
    0b00011000 => \&_JR_unconditional,
    (map { my $y = $_; ($_ << 3) => sub {
        _check_cond($_[0], $TABLE_CC[$y - 4]) &&
        _JR_unconditional(@_);
    } } (4 .. 7)),
    (map { my $p = $_; 0b00000001 | ($p << 4 ) => sub {
        _LD_r16_imm(shift(), $TABLE_RP[$p], @_) # LD rp[p], nn
    } } (0 .. 3)),
    (map { my $p = $_; 0b00001001 | ($_ << 4 ) => sub {
        _ADD_r16_r16(shift(), 'HL', $TABLE_RP[$p]) # ADD HL, rp[p]
    } } (0 .. 3)),
    0b00000010 => sub { _LD_indr16_r8($_[0], 'BC', 'A'); }, # LD (BC), A
    0b00001010 => sub { _LD_r8_indr16($_[0], 'A', 'BC'); }, # LD A, (BC)
    0b00010010 => sub { _LD_indr16_r8($_[0], 'DE', 'A'); }, # LD (DE), A
    0b00011010 => sub { _LD_r8_indr16($_[0], 'A', 'DE'); }, # LD A, (DE)
    0b00100010 => sub { _LD_ind_r16(shift(), 'HL', @_); }, # LD (nn), HL
    0b00101010 => sub { _LD_r16_ind(shift(), 'HL', @_); }, #LD HL, (nn)
    0b00110010 => sub { _LD_ind_r8(shift(), 'A', @_); }, # LD (nn), A
    0b00111010 => sub { _LD_r8_ind(shift(), 'A', @_); }, #LD A, (nn)
    (map {
        my($p, $q) = (($_ & 0b110) >> 1, $_ & 0b1);
        0b00000011 | ($_ << 3) => sub {
            $q ? _DEC($_[0], $TABLE_RP[$p]) # DEC rp[p]
               : _INC($_[0], $TABLE_RP[$p]) # INC rp[p]
        }
    } (0 .. 7)),
    (map { my $y = $_; 0b00000100 | ($_ << 3) => sub {
        _INC($_[0], $TABLE_R[$y], $_[1]) # INC r[y] or INC(IX/Y + d)
    } } (0 .. 7)),
    (map { my $y = $_; 0b00000101 | ($_ << 3) => sub {
        _DEC($_[0], $TABLE_R[$y], $_[1]) # DEC r[y] or DEC(IX/Y + d)
    } } (0 .. 7)),
    (map { my $y = $_; 0b00000110 | ($_ << 3) => sub {
        _LD_r8_imm(shift(), $TABLE_R[$y], @_) # LD r[y], n
    } } (0 .. 7)),
    0b00000111 => \&_RLCA,
    0b00001111 => \&_RRCA,
    0b00010111 => \&_RLA,
    0b00011111 => \&_RRA,
    0b00100111 => \&_DAA,
    0b00101111 => \&_CPL,
    0b00110111 => \&_SCF,
    0b00111111 => \&_CCF,
    (map { my $y = $_ >> 3; my $z = $_ & 0b111; 0b01000000 + $_ => sub {
        _LD_r8_r8(shift(), $TABLE_R[$y], $TABLE_R[$z], shift()); # LD r[y], r[z]
    } } (0 .. 0b111111)),
    0b01110110 => \&_HALT,
    (map { my $y = $_ >> 3; my $z = $_ & 0b111; 0b10000000 + $_ => sub {
        $TABLE_ALU[$y]->(shift(), 'A', $TABLE_R[$z], shift()); # alu[y] A, r[z]
    } } (0 .. 0b111111)),
    (map { my $y = $_; 0b11000110 | ($_ << 3) => sub {
        _LD_r8_imm($_[0], 'W', $_[1]);       # alu[y] A, n
        $TABLE_ALU[$y]->(shift(), 'A', 'W', shift());
    } } (0 .. 7)),
    (map { my $y = $_; 0b11000000 | ($_ << 3) => sub {
        _check_cond($_[0], $TABLE_CC[$y]) && # RET cc[y]
        _POP(shift(), 'PC');
    } } (0 .. 7)),
    (map { my $p = $_; 0b11000001 | ($_ << 4) => sub {
        _POP(shift(), $TABLE_RP2[$p]); # POP rp2[p]
    } } (0 .. 3)),
    (map { my $y = $_; 0b11000010 | ($_ << 3) => sub {
        _check_cond($_[0], $TABLE_CC[$y]) && # JP cc[y], nn
        _JP_unconditional(@_);
    } } (0 .. 7)),
    (map { my $y = $_; 0b11000100 | ($_ << 3) => sub {
        _check_cond($_[0], $TABLE_CC[$y]) && # CALL cc[y], nn
        _CALL_unconditional(@_);
    } } (0 .. 7)),
    (map { my $y = $_; 0b11000111 | ($_ << 3) => sub {
        _CALL_unconditional(shift(), $y * 8, 0); # RST y*8
    } } (0 .. 7)),
    0xC3 => \&_JP_unconditional,
    0b11010011 => \&_OUT_n_A, # OUT (n), A
    0b11011011 => \&_IN_A_n, # IN A, (n)
    0b11100011 => sub { # EX (SP), HL
        my $self = shift;
        _POP($self, 'WZ'); _PUSH($self, 'HL');
        _LD_r16_r16($self, 'HL', 'WZ');
    },
    0b11101011 => sub { _swap_regs(shift(), qw(DE HL)); },
    0b11110011 => \&_DI,
    0b11111011 => \&_EI,
    (map { my $p = $_; 0b11000101 | ($_ << 4) => sub {
        _PUSH(shift(), $TABLE_RP2[$p]); # PUSH rp2[p]
    } } (0 .. 3)),
    0xCD => \&_CALL_unconditional,
    0b11001001 => sub { _POP(shift(), 'PC'); }, # RET
    0b11011001 => \&_EXX,
    0b11101001 => sub { _LD_r16_r16($_[0], 'PC', 'HL'); }, # JP HL
    0b11111001 => sub { _LD_r16_r16($_[0], 'SP', 'HL'); }, # LD SP, HL

    # and finally,  prefixed instructions
    0xED, {
        (map { $_ => \&_NOP } ( 0b00000000 .. 0b00111111,
                                0b11000000 .. 0b11111111)),
        (map { my $y = $_; 0b01000000 | ($_ << 3) => sub {
            _IN_r_C(shift(), $TABLE_R[$y]); # IN r[y], (C)
        } } (0 .. 7)),
        (map { my $y = $_; 0b01000001 | ($_ << 3) => sub {
            _OUT_C_r(shift(), $TABLE_R[$y]); # OUT (C), r[y]
        } } (0 .. 5, 7)),
        0b01110001 => \&_OUT_C_0, # OUT (C), 0
        (map { my $p = $_; 0b01000010 | ($_ << 4) => sub {
            _SBC_r16_r16(shift(), 'HL', $TABLE_RP[$p]); # SBC HL, rp[p]
        } } (0 .. 3)),
        (map { my $p = $_; 0b01001010 | ($_ << 4) => sub {
            _ADC_r16_r16(shift(), 'HL', $TABLE_RP[$p]); # ADC HL, rp[p]
        } } (0 .. 3)),
        (map { my $p = $_; 0b01000011 | ($_ << 4) => sub {
            _LD_ind_r16(shift(), $TABLE_RP[$p], @_); # LD (nn), rp[p]
        } } (0 .. 3)),
        (map { my $p = $_; 0b01001011 | ($_ << 4) => sub {
            _LD_r16_ind(shift(), $TABLE_RP[$p], @_); # LD rp[p], (nn)
        } } (0 .. 3)),
        (map { 0b01000100 | ($_ << 3) => \&_NEG } (0 .. 7)), # NEG
        (map { 0b01000101 | ($_ << 3) => ($_== 1 ? \&_RETI : \&_RETN) }
            (0 .. 7)),
        (map { my $y = $_; 0b01000110 | ($_ << 3) => sub {
            _IM(shift(), $y); # IM im[y]
        } } (0 .. 7)),
        0b01000111 => sub { _LD_r8_r8(shift(), 'I', 'A'); }, # LD I, A
        0b01001111 => sub { _LD_r8_r8(shift(), 'R', 'A'); }, # LD R, A
        0b01010111 => \&_LD_A_I, # LD A, I
        0b01011111 => \&_LD_A_R, # LD A, R
        0b01100111 => \&_RRD,
        0b01101111 => \&_RLD,
        0b01110111 => \&_NOP,
        0b01111111 => \&_NOP,
        # x=1 is all invalid ...
        (map { 0b10000000 | $_ => \&_NOP } (0 .. 63)),
        # ... except for z = 0,1,2,3 and y = 4,5,6,7
        (map {
            my $y = $_; (map {
                my $z = $_;
                0b10000000 | ($y << 3) | $z => sub {
                    $TABLE_BLI[$y - 4]->[$z]->(@_)
                }
            } (0 .. 3))
        } (4 .. 7)),

    },
    0xCB, {
        (map { my $y = $_ >> 3; my $z = $_ & 7; 0b00000000 | $_ => sub {
                $TABLE_ROT[$y]->($_[0], $TABLE_R[$z], $_[1]);
        } } (0 .. 63)),
        (map { my $y = $_ >> 3; my $z = $_ & 7; 0b01000000 | $_ => sub {
                _BIT($_[0], $y, $TABLE_R[$z], $_[1]);
        } } (0 .. 63)),
        (map { my $y = $_ >> 3; my $z = $_ & 7; 0b10000000 | $_ => sub {
                _RES($_[0], $y, $TABLE_R[$z], $_[1]);
        } } (0 .. 63)),
        (map { my $y = $_ >> 3; my $z = $_ & 7; 0b11000000 | $_ => sub {
                _SET($_[0], $y, $TABLE_R[$z], $_[1]);
        } } (0 .. 63)),
    },
    0xDD, {
        (map { my $i = $_; $_ => sub {
               $INSTR_DISPATCH{$i}->(@_);
        } } (0 .. 255)),
        0xED => \&_NOP,
        0xDD => {
            0b00000000 => sub { $_[0]->{STOPREACHED} = 1 },
        },
        0xFD => {
            map { my $i = $_; $_ => sub {
                $INSTR_DISPATCH{0xDD}->{0xDD}->{$i}->(@_)
            } } (0 .. 255)
        },
        0xCB => {
            # these are all DD CB offset OPCODE. Yuck
            # the dispatcher calls DD->CB->offset passing the opcode
            # as a param.  This fixes things.
            map { my $d = $_; $_ => sub {
                $INSTR_DISPATCH{0xCB}->{$_[1]}->($_[0], $d)
            } } (0 .. 255)
        },
    },
    0xFD, {
        (map{my $i=$_; $_=>sub {$INSTR_DISPATCH{$i}->(@_)}} (0 .. 255)),
        0xED => \&_NOP,
        0xDD => {
            map { my $i = $_; $_ => sub {
                $INSTR_DISPATCH{0xDD}->{0xDD}->{$i}->(@_)
            } } (0 .. 255)
        },
        0xFD => {
            map { my $i = $_; $_ => sub {
                $INSTR_DISPATCH{0xDD}->{0xDD}->{$i}->(@_)
            } } (0 .. 255)
        },
        0xCB => {
            map { my $i = $_; $_ => sub {
                $INSTR_DISPATCH{0xDD}->{0xCB}->{$i}->(@_)
            } } (0 .. 255)
        }
    },
);

sub nmi {
    my $self = shift;
    $self->{iff2} = $self->{iff1};
    $self->{iff1} = 0;
    $self->{NMI} = 1;
}
sub interrupt {
    my $self = shift;
    if(_interrupts_enabled($self)) {
        $self->{INTERRUPT} = 1;
        _DI($self);
        return 1;
    }
    return 0;
}
sub _interrupts_enabled {
    my($self, $toggle) = @_;
    return $self->{iff1} if(!defined($toggle));
    $self->{iff1} = $self->{iff2} = $toggle;
}

sub run {
    my $self = shift;
    my $instrs_to_execute = -1;
    $instrs_to_execute = shift() if(@_);

    RUNLOOP: while($instrs_to_execute) {
        delete $self->{STOPREACHED};
        $instrs_to_execute--;
        $self->{instr_length_table} = \%INSTR_LENGTHS;
        $self->{instr_dispatch_table} = \%INSTR_DISPATCH;
        $self->{prefix_bytes} = [];
        if($self->{NMI}) {
            delete $self->{NMI};
            _DI($self);
            _CALL_unconditional($self, 0x66, 0x00);
        } elsif($self->{INTERRUPT}) {
            delete $self->{INTERRUPT};
            _DI($self);
            $self->_execute(0xFF);
        } else { $self->_execute($self->_fetch()); }
        delete $self->{instr_length_table};
        delete $self->{instr_dispatch_table};
        delete $self->{prefix_bytes};
        if($self->{STOPREACHED}) {
            last RUNLOOP;
        }
    }
}

sub stopped {
    my $self = shift;
    return exists($self->{STOPREACHED});
}

# fetch all the bytes for an instruction and return them
sub _fetch {
    my $self = shift;
    my $pc = $self->register('PC')->get();
    
    $self->register('R')->inc() # don't inc for DDCB and FDCB
        unless(
            $self->_got_prefix(0xCB) &&
            ($self->_got_prefix(0xDD) || $self->_got_prefix(0xFD))
        );
    my $byte = $self->memory()->peek($pc);
    my @bytes = ($byte);

    # prefix byte
    if(ref($self->{instr_length_table}->{$byte})) {
        # printf("Found prefix byte %#04x\n", $byte);
        $self->{instr_dispatch_table} = $self->{instr_dispatch_table}->{$byte};
        $self->{instr_length_table} = $self->{instr_length_table}->{$byte};
        push @{$self->{prefix_bytes}}, $byte;
        $self->register('PC')->inc(); # set($pc + 1);
        return $self->_fetch();
    }

    my $bytes_to_fetch = $self->{instr_length_table}->{$byte};
    
    die(sprintf(
        "_fetch: Unknown instruction 0x%02X at 0x%04X with prefix bytes ["
          .join(' ', map { "0x%02X" } @{$self->{prefix_bytes}})
          ."]\n", $byte, $pc, @{$self->{prefix_bytes}}
    )) if($bytes_to_fetch eq 'UNDEFINED');

    push @bytes, map { $self->memory()->peek($pc + $_) } (1 .. $bytes_to_fetch - 1);
    $self->register('PC')->set($pc + $bytes_to_fetch);
    return @bytes;
}

# execute an instruction. NB, the PC already points at the next instr
sub _execute {
    my($self, $instr) = (shift(), shift());
    if(
        exists($self->{instr_dispatch_table}->{$instr}) &&
        ref($self->{instr_dispatch_table}->{$instr}) &&
        reftype($self->{instr_dispatch_table}->{$instr}) eq 'CODE'
    ) {
        _swap_regs($self, qw(HL IX)) if($self->_got_prefix(0xDD));
        _swap_regs($self, qw(HL IY)) if($self->_got_prefix(0xFD));
        $self->{instr_dispatch_table}->{$instr}->($self, @_);
        _swap_regs($self, qw(HL IY)) if($self->_got_prefix(0xFD));
        _swap_regs($self, qw(HL IX)) if($self->_got_prefix(0xDD));
    } else {
        die(sprintf(
            "_execute: No entry in dispatch table for instr "
              .join(' ', map { "0x%02x" } (@{$self->{prefix_bytes}}, $instr))
              ." of known length, near addr 0x%04x\n",
            @{$self->{prefix_bytes}}, $instr, $self->register('PC')->get()
        ));
    }
}

sub _got_prefix {
    my($self, $prefix) = @_;
    return grep { $_ == $prefix } @{$self->{prefix_bytes}}
}

sub _check_cond {
    my($self, $cond) = @_;
    my $f = $self->register('F');
    return
           $cond eq 'NC' ? !$f->getC() :
           $cond eq 'C'  ?  $f->getC() :
           $cond eq 'NZ' ? !$f->getZ() :
           $cond eq 'Z'  ?  $f->getZ() :
           $cond eq 'PO' ? !$f->getP() :
           $cond eq 'PE' ?  $f->getP() :
           $cond eq 'P'  ? !$f->getS() :
                            $f->getS()
}

sub _ADD_r16_r16 {
    my($self, $r1, $r2, $c) = @_;
    # $c is defined if this is really SBC
    my $adc = 0 + defined($c);
    $c ||= 0;
    $self->register($r1)->add($self->register($r2)->get() + $c, $adc);
}
sub _ADC_r16_r16 {
    # ADC also frobs S, Z and P, unlike ADD. argh. the magic $c
    # will communicate that
    _ADD_r16_r16(@_, $_[0]->register('F')->getC());
}
sub _ADC_r8_r8 { _ADD_r8_r8(@_[0..3], $_[0]->register('F')->getC()); }
sub _ADD_r8_r8 {
    my($self, $r1, $r2, $d, $c) = @_;
    # $c is defined if this is really ADC
    $c ||= 0;
    _LD_r8_indHL($self, 'W', $d) if($r2 eq '(HL)');
    $self->register($r1)->add($self->register($r2)->get() + $c);
}
sub _RES { _RES_SET($_[0], 0, @_[1 .. $#_]); }
sub _SET { _RES_SET($_[0], 1, @_[1 .. $#_]); }
sub _RES_SET {
    my($self, $value, $bit, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') { # weirdo DDCB*
        my $realr = $r;
        $realr .= $self->_got_prefix(0xDD) ? 'IX' : 'IY'
            if($realr =~ /^[HL]$/);
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d);
        $self->register($r)->set(            # RES by default
            $self->register($r)->get() & (255 - 2**$bit)
        );
        $self->register($r)->set(            # SET if asked to
             $self->register($r)->get() | (2**$bit)
        ) if($value);
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d);
        $self->register($r)->set(            # RES by default
            $self->register($r)->get() & (255 - 2**$bit)
        );
        $self->register($r)->set(            # SET if asked to
             $self->register($r)->get() | (2**$bit)
        ) if($value);
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

}
sub _BIT {
    my($self, $bit, $r, $d) = @_; # $d is for DDCB/FFCB - NYI
    
    my $realr = $r;
    $r = '(HL)' if(defined($d));

    _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');

    my $f = $self->register('F');
    $f->setZ(!($self->register($r)->get() & 2**$bit));
    $f->setH();
    $f->resetN();
    $f->setS($bit == 7 && $self->register($r)->get() & 0x80);
    $f->setP($self->register('F')->getZ());
    $f->set5($self->register($r)->get() & 0b100000);
    $f->set3($self->register($r)->get() & 0b1000);
    if(defined($d)) {
        $f->set5(((ALU_getsigned($d, 8) + $self->register('HL')->get()) >> 8) & 0b100000);
        $f->set3(((ALU_getsigned($d, 8) + $self->register('HL')->get()) >> 8) & 0b1000);
    }
}

sub _binop {
    my($self, $r1, $r2, $d, $op) = @_;
    # $r1 is always A, $r2 is A/B/C/D/EH/L/(HL)/W/Z
    _LD_r8_indHL($self, 'W', $d) if($r2 eq '(HL)');
    # if($r2 eq '(HL)') {
    #     my @addr = map { $self->register($_)->get()} qw(L H);
    #     _LD_r8_ind($self, 'W', @addr);
    #     $r2 = 'W';
    # }
    $self->register($r1)->set(eval
        '$self->register($r1)->get() '.$op.' $self->register($r2)->get()'
    );
    die($@) if($@);
    $self->register('F')->setS($self->register($r1)->get() & 0x80);
    $self->register('F')->setZ($self->register($r1)->get() == 0);
    $self->register('F')->set5($self->register($r1)->get() & 0b100000);
    $self->register('F')->setH($op eq '&');
    $self->register('F')->set3($self->register($r1)->get() & 0b1000);
    $self->register('F')->setP(ALU_parity($self->register($r1)->get()));
    $self->register('F')->resetN();
    $self->register('F')->resetC();
}
sub _AND_r8_r8 { _binop(@_, '&'); }
sub _OR_r8_r8  { _binop(@_, '|'); }
sub _XOR_r8_r8 { _binop(@_, '^'); }
sub _SBC_r8_r8 { _SUB_r8_r8(@_[0 .. 3], $_[0]->register('F')->getC()); }
sub _SBC_r16_r16 { _SUB_r16_r16(@_, $_[0]->register('F')->getC()); }
sub _SUB_r8_r8 {
    my($self, $r1, $r2, $d, $c) = @_;
    # $c is defined if this is really SBC
    $c ||= 0;
    die("Can't SUB with Z reg") if($r2 eq 'Z');
    _LD_r8_indHL($self, 'W', $d) if($r2 eq '(HL)');
    $self->register($r1)->sub($self->register($r2)->get() + $c);
}
sub _SUB_r16_r16 {
    my($self, $r1, $r2, $c) = @_;
    # $c is defined if this is really SBC
    $c ||= 0;
    $self->register($r1)->sub($self->register($r2)->get() + $c);
}
sub _CP_r8_r8 {
    # $r1 is always A, $r2 is A/B/C/D/EH/L/(HL)/W
    my($self, $r1, $r2, $d) = @_;

    # bleh, CP uses the *operand* to set flags 3 and 5, instead of
    # the result, so wrap SUB and correct afterwards.
    # this is why we can't SUB with the Z reg
    _LD_r8_r8($self, 'Z', $r1); # preserve r1
    _SUB_r8_r8($self, $r1, $r2, $d);
    # put result into Z - this is used by CPI
    _swap_regs($self, $r1, 'Z'); # restore r1, result into Z
    $self->register('F')->set5($self->register($r2)->get() & 0b100000);
    $self->register('F')->set3($self->register($r2)->get() & 0b1000);
}
sub _DEC {
    my($self, $r, $d) = @_;
    _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
    $self->register($r)->dec();
    _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    # my($self, $r) = @_;
    # if($r eq '(HL)') {
    #     my @addr = map { $self->register($_)->get()} qw(L H);
    #     _LD_r8_ind($self, 'W', @addr);
    #     $self->register('W')->dec();
    #     _LD_ind_r8($self, 'W', @addr);
    # } else {
    #     $self->register($r)->dec();
   #  }
}
sub _EXX {
    my $self = shift;
    _swap_regs($self, qw(BC BC_));
    _swap_regs($self, qw(DE DE_));
    _swap_regs($self, qw(HL HL_));

}
sub _DJNZ {
    my($self, $offset) = @_;

    _LD_r8_r8($self, 'W', 'F');          # preserve flags

    $self->register('B')->dec();         # decrement B and ...
    if($self->register('B')->get()) {    # jump if not zero
        $self->register('PC')->set(
            $self->register('PC')->get() +
            ALU_getsigned($offset, 8)
        );
    }
    _LD_r8_r8($self, 'F', 'W');          # restore flags
}
sub _HALT { shift()->register('PC')->dec(); select(undef, undef, undef, 0.01) }
sub _INC {
    my($self, $r, $d) = @_;
    _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
    $self->register($r)->inc();
    _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
}
sub _LDI {
    my $self = shift;
    my $f = $self->register('F');
    _LD_r8_indr16($self, 'W', 'HL'); # get from (HL);
    _LD_indr16_r8($self, 'DE', 'W'); # put to (DE);
    $self->register('DE')->inc();
    $self->register('HL')->inc();
    $self->register('BC')->dec();
    $f->set5(($self->register('A')->get() + $self->register('W')->get()) & 2);
    $f->set3(($self->register('A')->get() + $self->register('W')->get()) & 8);
    $f->setP($self->register('BC')->get() != 0);
    $f->resetN();
    $f->resetH();
}
sub _LDIR {
    my $self = shift;
    _LDI($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('BC')->get());
}
sub _LDD {
    my $self = shift;
    _LDI($self); # cheat, do an LDI then correct HL and DE
    _swap_regs($self, qw(W F));
    $self->register('DE')->sub(2);
    $self->register('HL')->sub(2);
    _swap_regs($self, qw(W F));
}
sub _LDDR {
    my $self = shift;
    _LDD($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('BC')->get());
}
sub _CPI {
    my $self = shift;
    my $f = $self->register('F');
    my $c = $f->getC();
    _CP_r8_r8($self, 'A', '(HL)');   # Z = A - (HL), S/Z/H now set OK
    $self->register('HL')->inc();
    $self->register('BC')->dec();
    $f->setP($self->register('BC')->get() != 0);
    $f->setC($c);
    $f->setN();
    $f->set5(
        ($self->register('Z')->get() - $f->getH()) & 0b10
    );
    $f->set3(
        ($self->register('Z')->get() - $f->getH()) & 0b1000
    );
}
sub _CPIR {
    my $self = shift;
    _CPI($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('BC')->get() && $self->register('Z')->get());
    
}
sub _CPD {
    my $self = shift;
    _CPI($self); # cheat, do a CPI then correct HL
    _swap_regs($self, qw(W F));
    $self->register('HL')->sub(2);
    _swap_regs($self, qw(W F));
}
sub _CPDR {
    my $self = shift;
    _CPD($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('BC')->get() && $self->register('Z')->get());
}
sub _RLD {
    my $self = shift;
    my($a, $f, $w, $z) = map { $self->register($_) } (qw(A F W Z));
    _LD_r8_indHL($self, 'W');                         # get (HL)
    $z->set($a->get() & 0x0F);
    $a->set(($a->get() & 0xF0) | ($w->get() & 0xF0) >> 4);# A now kosher
    $w->set(($w->get() <<  4)  | $z->get());          # W now correct
    _LD_indHL_r8($self, 'W');                         # (HL) now correct
    $f->setS($a->get() & 0x80);
    $f->setZ($a->get() == 0);
    $f->set5($a->get() & 0b100000);
    $f->set3($a->get() & 0b1000);
    $f->setP(ALU_parity($a->get()));
    $f->resetH();
    $f->resetN();
}
sub _RRD {
    my $self = shift;
    my($a, $f, $w, $z) = map { $self->register($_) } (qw(A F W Z));
    _LD_r8_indHL($self, 'W');                         # get (HL)
    $z->set($a->get() << 4);
    $a->set(($a->get() & 0xF0) | ($w->get() & 0x0F)); # A now correct
    $w->set(($w->get() >> 4)   | $z->get());          # W now correct
    _LD_indHL_r8($self, 'W');                         # (HL) now correct
    $f->setS($a->get() & 0x80);
    $f->setZ($a->get() == 0);
    $f->set5($a->get() & 0b100000);
    $f->set3($a->get() & 0b1000);
    $f->setP(ALU_parity($a->get()));
    $f->resetH();
    $f->resetN();
}
sub _JR_unconditional {
    my($self, $offset) = @_;
    $self->register('PC')->set(
        $self->register('PC')->get() +
        ALU_getsigned($offset, 8)
    );
}
sub _JP_unconditional {
    _LD_r16_imm(shift(), 'PC', @_);
}
sub _CALL_unconditional {
    _PUSH($_[0], 'PC');
    _JP_unconditional(@_);
}
sub _LD_ind_r16 {
    my($self, $r16, @bytes) = @_;
    $self->memory()->poke16($bytes[0] + 256 * $bytes[1], $self->register($r16)->get())
}
sub _LD_ind_r8 {
    my($self, $r8, @bytes) = @_;
    $self->memory()->poke($bytes[0] + 256 * $bytes[1], $self->register($r8)->get())
}
sub _LD_indHL_r8 {
    my($self, $r8, $d) = @_;
    $d = ALU_getsigned($d || 0, 8);
    $self->memory()->poke($d + $self->register('HL')->get(), $self->register($r8)->get())
}
sub _LD_indr16_r8 {
    my($self, $r16, $r8) = @_;
    $self->memory()->poke($self->register($r16)->get(), $self->register($r8)->get());
}
sub _LD_r16_imm {
    # self, register, lo, hi
    my $self = shift;
    $self->register(shift())->set(shift() + 256 * shift());
}
sub _LD_r8_imm {
    # self, register, data
    my($self, $r, $d, $byte) = @_;
    # yuck, (IX+d) puts d first
    ($d, $byte) = ($byte, $d) if(!defined($byte));
    $self->register($r)->set($byte);
    _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
}
sub _LD_r16_ind {
    my($self, $r16, @bytes) = @_;
    $self->register($r16)->set($self->memory()->peek16($bytes[0] + 256 * $bytes[1]));
}
sub _LD_r8_indr16 {
    my($self, $r8, $r16) = @_;
    $self->register($r8)->set($self->memory()->peek($self->register($r16)->get()));
}
sub _LD_r8_ind {
    my($self, $r8, @bytes) = @_;
    $self->register($r8)->set($self->memory()->peek($bytes[0] + 256 * $bytes[1]));
}
sub _LD_r8_indHL {
    my($self, $r8, $d) = @_;
    $d = ALU_getsigned($d || 0, 8);
    $self->register($r8)->set($self->memory()->peek($d + $self->register('HL')->get()));
}
sub _LD_r16_r16 {
    my($self, $r1, $r2) = @_;
    $self->register($r1)->set($self->register($r2)->get());
}
sub _LD_r8_r8 {
    my($self, $r1, $r2, $d) = @_;
    # print "_LD_r8_r8 $r1, $r2 $d\n" if($d);
    if(defined($d) && $r2 eq '(HL)' && $r1 =~ /^[HL]$/) { # LD H/L, (IX/IY+d)
        $r1 .= $self->_got_prefix(0xDD) ? 'IX' : 'IY';
    } elsif(defined($d) && $r1 eq '(HL)' && $r2 =~ /^[HL]$/) { # LD (IX/IY+d), H/L
        $r2 .= $self->_got_prefix(0xDD) ? 'IX' : 'IY';
    }
    my $addr = $self->register('HL')->get() + ALU_getsigned($d, 8);
    my @addr = ($addr & 0xFF, $addr >> 8);
    if($r2 eq '(HL)') {
        _LD_r8_ind($self, 'W', @addr);
        $r2 = 'W';
    }
    if($r1 eq '(HL)') {
        _LD_ind_r8($self, $r2, @addr);
    } else {
        $self->register($r1)->set($self->register($r2)->get());
    }
}
# special casesof LD_r8_r8 which also frob some flags
sub _LD_A_R { _LD_A_IR(shift(), 'R'); }
sub _LD_A_I { _LD_A_IR(shift(), 'I'); }
sub _LD_A_IR {
    my($self, $r2) = @_;
    my($a, $f) = map { $self->register($_) } qw(A F);
    _LD_r8_r8($self, 'A', $r2);
    $f->resetH();
    $f->resetN();
    $f->set5($a->get() & 0b100000);
    $f->set3($a->get() & 0b1000);
    $f->setS($a->get() & 0x80);
    $f->setZ($a->get() == 0);
    $f->setP($self->{iff2});
}
sub _NEG {
    my $self = shift();
    _LD_r8_imm($self, 'W', 0);
    _SUB_r8_r8($self, 'W', 'A');
    _LD_r8_r8($self, 'A', 'W');
}
sub _NOP { }
sub _RLCA {
    my $self = shift;
    $self->register('A')->set(
        (($self->register('A')->get() & 0b01111111) << 1) |
        (($self->register('A')->get() & 0b10000000) >> 7)
    );
    $self->register('F')->resetH();
    $self->register('F')->resetN();
    $self->register('F')->set5($self->register('A')->get() & 0b100000);
    $self->register('F')->set3($self->register('A')->get() & 0b1000);
    $self->register('F')->setC($self->register('A')->get() & 1);
}
sub _RRCA {
    my $self = shift;
    $self->register('A')->set(
        (($self->register('A')->get() & 0b11111110) >> 1) |
        (($self->register('A')->get() & 1) << 7)
    );
    $self->register('F')->resetH();
    $self->register('F')->resetN();
    $self->register('F')->set5($self->register('A')->get() & 0b100000);
    $self->register('F')->set3($self->register('A')->get() & 0b1000);
    $self->register('F')->setC($self->register('A')->get() & 0x80);
}
sub _RLA {
    my $self = shift;
    my $msb = $self->register('A')->get() & 0b10000000;
    $self->register('A')->set(
        (($self->register('A')->get() & 0b01111111) << 1) |
        $self->register('F')->getC()
    );
    $self->register('F')->setC($msb);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
sub _RRA {
    my $self = shift;
    my $lsb = $self->register('A')->get() & 1;
    my $c = $self->register('F')->getC();
    $self->register('A')->set(
        (($self->register('A')->get() & 0b11111110) >> 1) |
        ($c << 7)
    );
    $self->register('F')->setC($lsb);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
# generic wrapper for CB prefixed ROTs - wrap around A-reg version
# and also diddle P/S/Z flags
sub _cb_rot {
    my($self, $fn, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') {
        $r .= $self->_got_prefix(0xDD) ? 'IX' : 'IY' if($r =~ /^[HL]$/);
        my $realr = $r;
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        _swap_regs($self, $r, 'A') if($r ne 'A'); # preserve A, mv r to A
        $fn->($self);
        _swap_regs($self, $r, 'A') if($r ne 'A'); # swap back again
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        _swap_regs($self, $r, 'A') if($r ne 'A'); # preserve A, mv r to A
        $fn->($self);
        _swap_regs($self, $r, 'A') if($r ne 'A'); # swap back again
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

    # now frob extra flags
    $self->register('F')->setP(ALU_parity($self->register($r)->get()));
    $self->register('F')->setS($self->register($r)->get() & 0x80);
    $self->register('F')->setZ($self->register($r)->get() == 0);
}
sub _RLC {
    my($self, $r, $d) = @_;
    $self->_cb_rot(\&_RLCA, $r, $d);
}
sub _RRC {
    my($self, $r, $d) = @_;
    _cb_rot($self, \&_RRCA, $r, $d);
}
sub _RL {
    my($self, $r, $d) = @_;
    _cb_rot($self, \&_RLA, $r, $d);

    # extra flags not done by _cb_rot
    $r .= $self->_got_prefix(0xDD) ? 'IX' :
          $self->_got_prefix(0xFD) ? 'IY' : ''
        if($r =~ /^[HL]$/);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
}
sub _RR {
    my($self, $r, $d) = @_;
    _cb_rot($self, \&_RRA, $r, $d);
    $r .= $self->_got_prefix(0xDD) ? 'IX' :
          $self->_got_prefix(0xFD) ? 'IY' : ''
        if($r =~ /^[HL]$/);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
}
sub _SLA {
    my($self, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') { # weirdo DDCB*
        my $realr = $r;
        $realr .= $self->_got_prefix(0xDD) ? 'IX' : 'IY'
            if($realr =~ /^[HL]$/);
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d);
        $self->register('F')->setC($self->register($r)->get() & 0x80);
        $self->register($r)->set($self->register($r)->get() << 1);
        _LD_indHL_r8($self, 'W', $d);
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        $self->register('F')->setC($self->register($r)->get() & 0x80);
        $self->register($r)->set($self->register($r)->get() << 1);
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

    $self->register('F')->setZ($self->register($r)->get() == 0);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
    $self->register('F')->setP(ALU_parity($self->register($r)->get()));
    $self->register('F')->setS($self->register($r)->get() & 0x80);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
sub _SLL {
    my($self, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') { # weirdo DDCB*
        my $realr = $r;
        $realr .= $self->_got_prefix(0xDD) ? 'IX' : 'IY'
            if($realr =~ /^[HL]$/);
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d);
        $self->register('F')->setC($self->register($r)->get() & 0x80);
        $self->register($r)->set($self->register($r)->get() << 1);
        $self->register($r)->set($self->register($r)->get() | 1);
        _LD_indHL_r8($self, 'W', $d);
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        $self->register('F')->setC($self->register($r)->get() & 0x80);
        $self->register($r)->set($self->register($r)->get() << 1);
        $self->register($r)->set($self->register($r)->get() | 1);
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

    $self->register('F')->setZ($self->register($r)->get() == 0);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
    $self->register('F')->setP(ALU_parity($self->register($r)->get()));
    $self->register('F')->setS($self->register($r)->get() & 0x80);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
sub _SRA {
    my($self, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') { # weirdo DDCB*
        my $realr = $r;
        $realr .= $self->_got_prefix(0xDD) ? 'IX' : 'IY'
            if($realr =~ /^[HL]$/);
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d);
        $self->register('F')->setC($self->register($r)->get() & 1);
        $self->register($r)->set(
            ($self->register($r)->get() & 0x80) |
            ($self->register($r)->get() >> 1)
        );
        _LD_indHL_r8($self, 'W', $d);
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        $self->register('F')->setC($self->register($r)->get() & 1);
        $self->register($r)->set(
            ($self->register($r)->get() & 0x80) |
            ($self->register($r)->get() >> 1)
        );
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

    $self->register('F')->setZ($self->register($r)->get() == 0);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
    $self->register('F')->setP(ALU_parity($self->register($r)->get()));
    $self->register('F')->setS($self->register($r)->get() & 0x80);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
sub _SRL {
    my($self, $r, $d) = @_;

    if(defined($d) && $r ne '(HL)') { # weirdo DDCB*
        my $realr = $r;
        $realr .= $self->_got_prefix(0xDD) ? 'IX' : 'IY'
            if($realr =~ /^[HL]$/);
        $r = '(HL)';
        _LD_r8_indHL($self, 'W', $d);
        $self->register('F')->setC($self->register($r)->get() & 1);
        $self->register($r)->set(
            ($self->register($r)->get() & 0x80) |
            ($self->register($r)->get() >> 1)
        );
        $self->register($r)->set($self->register($r)->get() & 0x7F);
        _LD_indHL_r8($self, 'W', $d);
        _LD_r8_r8($self, $realr, 'W');
    } else {
        _LD_r8_indHL($self, 'W', $d) if($r eq '(HL)');
        $self->register('F')->setC($self->register($r)->get() & 1);
        $self->register($r)->set(
            ($self->register($r)->get() & 0x80) |
            ($self->register($r)->get() >> 1)
        );
        $self->register($r)->set($self->register($r)->get() & 0x7F);
        _LD_indHL_r8($self, 'W', $d) if($r eq '(HL)');
    }

    $self->register('F')->setZ($self->register($r)->get() == 0);
    $self->register('F')->set5($self->register($r)->get() & 0b100000);
    $self->register('F')->set3($self->register($r)->get() & 0b1000);
    $self->register('F')->setP(ALU_parity($self->register($r)->get()));
    $self->register('F')->setS($self->register($r)->get() & 0x80);
    $self->register('F')->resetH();
    $self->register('F')->resetN();
}
sub _DAA {
    my $self = shift;
    my $a = $self->register('A');
    my $f = $self->register('F');
    my($n, $h, $lo, $hi) =
        ($f->getN(), $f->getH(),
         $a->get() & 0x0F, ($a->get() >> 4) & 0x0F);
    my $table = [
        # NB this table comes from Sean Young's "The Undocumented
        # Z80 Documented".  Zaks is wrong.
        # http://www.z80.info/zip/z80-documented.pdf
        #   C high   H low add Cafter
        [qw(0 0-9    0 0-9 0   0)],
        [qw(0 0-9    1 0-9 6   0)],
        [qw(0 0-8    . a-f 6   0)],
        [qw(0 a-f    0 0-9 60  1)],
        [qw(1 0-9a-f 0 0-9 60  1)],
        [qw(1 0-9a-f 1 0-9 66  1)],
        [qw(1 0-9a-f . a-f 66  1)],
        [qw(0 9a-f   . a-f 66  1)],
        [qw(0 a-f    1 0-9 66  1)],
    ];
    foreach my $row (@{$table}) {
        my @row = @{$row};
        if(
            $f->getC() == $row[0] &&
            ($row[2] eq '.' || $f->getH() == $row[2]) &&
            sprintf('%x', ($a->get() >> 4) & 0x0F) =~ /^[$row[1]]$/ &&
            sprintf('%x', $a->get() & 0x0F) =~ /^[$row[3]]$/
        ) {
            $f->getN() ? $a->set(ALU_sub8($f, $a->get(), hex($row[4])))
                       : $a->set(ALU_add8($f, $a->get(), hex($row[4])));
            $f->setC($row[5]);
            last;
        }
    }
    $f->setH($lo > 9) if(!$n);
    $f->resetH()      if($n && !$h);
    $f->setH($lo < 6) if($n && $h);
    $f->set3($a->get() & 0b1000);
    $f->set5($a->get() & 0b100000);
    $f->setP(ALU_parity($a->get()));
}
sub _CPL {
    my $self = shift;
    $self->register('A')->set(~ $self->register('A')->get());
    $self->register('F')->setH();
    $self->register('F')->setN();
    $self->register('F')->set3($self->register('A')->get() & 0b1000);
    $self->register('F')->set5($self->register('A')->get() & 0b100000);
}
sub _SCF {
    my $self = shift();
    my $f = $self->register('F');
    my $a = $self->register('A');
    $f->setC();
    $f->resetH();
    $f->resetN();
    $f->set5($a->get() & 0b100000);
    $f->set3($a->get() & 0b1000);
}
sub _CCF {
    my $self = shift;
    my $f = $self->register('F');
    my $a = $self->register('A');
    $f->setH($f->getC());
    $f->setC(!$f->getC());
    $f->resetN();
    $f->set5($a->get() & 0b100000);
    $f->set3($a->get() & 0b1000);
}
sub _POP {
    my($self, $r) = @_;
    $self->register($r)->set(
        $self->memory()->peek16($self->register('SP')->get())
    );
    $self->register('SP')->add(2);
}
sub _PUSH {
    my($self, $r) = @_;
    $self->register('SP')->sub(2);
    $self->memory()->poke16(
        $self->register('SP')->get(),
        $self->register($r)->get()
    );
}
sub _IN_A_n {
    my($self, $lobyte) = @_;
    $self->register('A')->set(
        $self->_get_from_input(($self->register('A')->get() << 8) + $lobyte)
    );
}
sub _IN_r_C {
    my($self, $r) = @_;
    $r = $self->register($r); # for (HL) this is W and magically correct!
    $r->set($self->_get_from_input($self->register('BC')->get()));
    
    my $f = $self->register('F');
    $f->setS($r->get() & 0x80);
    $f->setZ($r->get() == 0);
    $f->set5($r->get() & 0b100000);
    $f->resetH();
    $f->set3($r->get() & 0b1000);
    $f->setP(ALU_parity($r->get()));
}

sub _OUT_n_A { # output A to B<<8 + n
    my($self, $n) = @_;
    $self->_put_to_output(
        ($self->register('B')->get() << 8) + $n,
        $self->register('A')->get()
    );
}
sub _OUT_C_r {
    my($self, $r) = @_;
    $self->_put_to_output(
        $self->register('BC')->get(),
        $self->register($r)->get()
    );
}
sub _OUT_C_0 {
    my $self = shift();
    $self->register('W')->set(0);
    _OUT_C_r($self, 'W');
}
sub _IND {
    my $self = shift;
    _IN_r_C($self, '(HL)');
    _LD_indHL_r8($self, 'W', 0);
    $self->register($_)->dec() foreach(qw(HL B));
}
sub _INI {
    my $self = shift;
    _IN_r_C($self, '(HL)');
    _LD_indHL_r8($self, 'W');
    $self->register('HL')->inc();
    $self->register('B')->dec();
}
sub _INDR {
    my $self = shift;
    _IND($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('B')->get());
}
sub _INIR {
    my $self = shift;
    _INI($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('B')->get());
}
sub _OUTD {
    my $self = shift;
    $self->register('B')->dec();
    $self->_put_to_output(
        $self->register('BC')->get(),
        $self->memory()->peek($self->register('HL')->get())
    );
    $self->register('HL')->dec();
}
sub _OUTI {
    my $self = shift;
    $self->register('B')->dec();
    $self->_put_to_output(
        $self->register('BC')->get(),
        $self->memory()->peek($self->register('HL')->get())
    );
    $self->register('HL')->inc();
}
sub _OTDR {
    my $self = shift;
    _OUTD($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('B')->get());
}
sub _OTIR {
    my $self = shift;
    _OUTI($self);
    $self->register('PC')->set($self->register('PC')->get() - 2)
        if($self->register('B')->get());
}

sub _IM {} # everything is IM 1

sub _RETI {
    _POP(shift(), 'PC');
}
sub _RETN {
    my $self = shift();
    $self->{iff1} = $self->{iff2};
    _POP($self, 'PC');
}
sub _DI {
    my $self = shift;
    _interrupts_enabled($self, 0);
}
sub _EI {
    my $self = shift;
    _interrupts_enabled($self, 1);
}
sub _swap_regs {
    my($self, $r1, $r2) = @_;
    my $temp = $self->register($r1)->get();
    $self->register($r1)->set($self->register($r2)->get());
    $self->register($r2)->set($temp);
}

=head1 EXTRA INSTRUCTIONS

Whenever any combination of two of the 0xDD and 0xFD prefixes are
met, behaviour deviates from that of a normal Z80 and instead
depends on the following byte:

=head2 0x00 - STOP

The run() method stops, even if the desired number of instructions
has not yet been reached.

=head2 anything else

Fatal error.

=head1 PROGRAMMING THE Z80

I recommend "Programming the Z80" by Rodnay Zaks.  This excellent
book is unfortunately out of print, but may be available through
abebooks.com
L<http://www.abebooks.com/servlet/SearchResults?an=zaks&tn=programming+the+z80>.

=head1 BUGS/WARNINGS/LIMITATIONS

Claims about making your code faster may not be true in all realities.

I assume you're using a twos-complement machine.  I *think* that
that's true of anything perl runs on.

Only interrupt mode 1 is implemented.  All interrupts are serviced
by a RST 0x38 instruction.

The DDFD- and FDDD-prefixed instructions (the "use this index
register - no, wait, I meant the other one" prefixes) and the DDDD-
and FDFD-prefixed instructions (the "use this index register, no
really, I mean it, pleeeeease" prefixes) are silly,
and have been replaced - see "Extra Instructions" above.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in CVS and will
pass once I've fixed the bug.

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 SEE ALSO

L<Acme::6502>

L<CPU::Z80::Assembler>

The FUSE Free Unix Spectrum Emulator: L<http://fuse-emulator.sourceforge.net/>

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
