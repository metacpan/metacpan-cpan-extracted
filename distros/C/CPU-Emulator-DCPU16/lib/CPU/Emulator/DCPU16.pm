package CPU::Emulator::DCPU16;

use strict;
use warnings;

use CPU::Emulator::DCPU16::Assembler;
use CPU::Emulator::DCPU16::Disassembler;

use CPU::Emulator::DCPU16::Device::Console;

our $VERSION       = 0.3;
our $MAX_REGISTERS = 8;
our $MAX_MEMORY    = 65536; # 0x10000

=head1 NAME

CPU::Emulator::DCPU16 - an emulator for Notch's DCPU-16 virtual CPU for the game 0x10c

=head1 SYNOPSIS

    open(my $fh, ">:raw", $file) || die "Couldn't read file $file: $!";
    my $program = do { local $/=undef; <$fh> };
    $program    = CPU::Emulator::DCPU16::Assembler->assemble($program) if $file =~ /\.dasm(16)?$/;  

    # Create a new CPU and load a file
    my $cpu = CPU::Emulator::DCPU16->new();
    $cpu->load($program);
    
    # Run it ...
    $cpu->run;
    # ... which is basically the same as
    do { $cpu->step } until $cpu->halt;

=head1 DESCRIPTION 

DCPU-16 is a spec for a virtual CPU by Notch from Mojang (of Minecraft fame).

The spec is available here

http://0x10c.com/doc/dcpu-16.txt

=cut
    
    
=head1 METHODS

=cut

=head2 new

Create a new CPU.

=cut
sub new {
    my $class = shift;
    my %opts  = @_;
    return bless \%opts, $class;
}

sub _init {
    my $self = shift;
    $self->halt = 0;
    $self->pc   = 0;
    $self->sp   = 0xffff;
    $self->o    = 0;
    
    $self->{_devices}   = [];
    
    # TODO these could be done with scalars and bit masks
    $self->{_registers} = [(0x0000) x $MAX_REGISTERS],
    $self->{_memory}    = [(0x0000) x $MAX_MEMORY],
    
}

=head2 load <program> [opt[s]]

Load a program. Forces as re-init of the CPU.

You can also do

    my $cpu = CPU::Emulator::DCPU16->load($program, %opts);
    
which is exactly the same as

    my $cpu = CPU::Emulator::DCPU16->new(%opts);
    $cpu->load($program);

=cut
sub load {
    my $self  = shift;
    my $bytes = shift; 
    my %opts  = @_;
    $self     = $self->new(%opts) unless ref($self);
    $self->_init;
    my @bytes = $self->bytes_to_array($bytes);
    die "No program was loaded\n" unless @bytes;
    $self->{_program_top} = scalar(@bytes);
    splice(@{$self->{_memory}}, 0, scalar(@bytes), @bytes);
    return $self;
}

=head2 bytes_to_array <bytes>

Turn a scalar of bytes into an array of words

=cut
sub bytes_to_array {
    my $class = shift;
    my $bytes = shift;
    my @ret;
    while (my $word = substr($bytes, 0, 2, '')) {
        push @ret, ord($word) * 2**8 + ord(substr($word, 1, 1));
    }
    @ret;
}

=head2 map_device <class> <start address> <end address> [opt[s]]

Map a device of the given class to these addresses

=cut
sub map_device {
    my $self  = shift;
    my $dev   = shift;
    my $start = shift;
    my $end   = shift;
    my %opts  = @_;
    push @{$self->{_devices}}, $dev->new($self->{_memory}, $start, $end, %opts);
    $self->{_devices}->[-1];
}

=head2 run [opt[s]]

Run CPU until completion.

Options available are:

=over 4

=item debug 

Whether or not we should print debug information and at what level. 

Default is 0 (no debug output).

=item limit

Maxinum number of instructions to execute.

Default is 0 (no limit).

=item cycle_penalty

The time penalty for each instruction cycle in milliseconds.

Default is 0 (no penalty)

=item full_memory

Allow the PC to continue past the last instruction of the program (i.e the program_top). 

This would allow programs to rewrite themselves into a larger program.

Default is 0 (no access)

=back

=cut
sub run {
    my $self       = shift;
    my %opts       = @_;
    my $count      = 1;
    $opts{limit} ||= 0;
    $opts{debug} ||= 0;
    $self->_debug($self->_dump_header) if $opts{debug}>=1;
    
    do { 
        $self->step(%opts);
        $self->halt = 1 if $opts{limit}>0 and ++$count>$opts{limit};
        $self->halt = 1 if $self->pc >= $self->program_top && !$opts{full_memory};
    } until $self->halt;
}

=head2 step [opt[s]]

Run a single clock cycle of the CPU.

Takes the same options as C<run>.
    
=cut
sub step {
    my $self = shift;
    my %opts = @_;
    
    $opts{debug}         ||= 0;
    $opts{cycle_penalty} ||= 0;
    $self->_debug($self->_dump_state) if $opts{debug}>=1;
  
    my $pc   = $self->pc;
    my $word = $self->memory($self->pc);
    die "Unknown memory at PC ".sprintf("0x%04x",$self->pc)."\n" unless defined $word;
    my $op   = $word & 0x0F; 
    my $a    = ($word >> 4) & 0x3f;
    my $b    = ($word >> 10) & 0x3f;

    $self->pc  += 1;
    $self->o    = 0;
    
    my $cost = 0;
    
    my $meth;
    # Basic opcodes
    if ($op) {
        $meth = qw(NOOP _SET _ADD _SUB _MUL _DIV _MOD _SHL _SHR _AND _BOR _XOR _IFE _IFN _IFG _IFB)[$op];
        die "Illegal opcode $op\n" unless defined $meth;   
    # Defined non-basic opcodes
    } elsif ($a == 0x01) {
        $meth = "_JSR";
    # Reserved non-basic opcodes
    } else {
        die "Illegal extended opcode $a\n";
    }

    my $aa = $self->_get_value($a, \$cost);
    my $bb = $self->_get_value($b, \$cost);
    
    $self->$meth($aa, $bb, \$cost);
    select(undef, undef, undef, $cost*$opts{cycle_penalty}/1000) if $opts{cycle_penalty}>0;
    $_->tick for @{$self->{_devices}};
    return $cost;
}

=head1 METHODS TO GET THE STATE OF THE CPU

=head2 pc

The current program counter.

=cut
sub pc : lvalue { 
    my $self = shift;
    $self->{_pc} = shift if @_;
    $self->{_pc};
}

=head2 sp

The current stack pointer.

=cut
sub sp : lvalue { 
    my $self = shift;
    $self->{_sp} = shift if @_;
    $self->{_sp};
}

=head2 o

The current overflow.

=cut
sub o : lvalue { 
    my $self = shift;
    $self->{_o} = shift if @_;
    $self->{_o};
}

=head2 halt [halt state]

Halt the CPU or check to see whether it's halted.

=cut
sub halt : lvalue {
    my $self = shift;
    $self->{_halt} = shift if @_;
    $self->{_halt};
}

=head2 program_top

The address of the first memory location after the loaded program.

=cut
sub program_top : lvalue { 
    my $self = shift;
    $self->{_program_top} = shift if @_;
    $self->{_program_top};
}

=head2 register <location>

Get or set the value of a register.

=cut
sub register : lvalue {
    my $self = shift;
    return $self->{_registers} unless @_;
    my $loc  = shift; die "Invalid register $loc at pc ".$self->pc." (".sprintf("%02x", $self->pc).")\n" if $loc<0 || $loc>=$MAX_REGISTERS;
    $self->{_registers}[$loc] = shift if @_;
    $self->{_registers}[$loc];
}
# TODO ugly
sub _reg_ref {
    my $self = shift;
    my $loc  = shift; die "Invalid register $loc at pc ".$self->pc." (".sprintf("%02x", $self->pc).")\n" if $loc<0 || $loc>=$MAX_REGISTERS;
    \($self->{_registers}[$loc]);
}

=head2 memory <location>

Get or set the value of a memory location.

=cut
sub memory : lvalue {
    my $self = shift;
    return $self->{_memory} unless @_;
    my $loc  = shift; 
    die "Invalid memory $loc at pc ".$self->pc." (".sprintf("%02x", $self->pc).")\n" if $loc<0 || $loc>=$MAX_MEMORY;
    $self->{_memory}[$loc] = shift if @_;
    $self->{_memory}[$loc];
}
# TODO ugly
sub _mem_ref {
    my $self = shift;
    my $loc  = shift; 
    die "Invalid memory $loc at pc ".$self->pc." (".sprintf("%02x", $self->pc).")\n" if $loc<0 || $loc>=$MAX_MEMORY;
    \($self->{_memory}[$loc]);
}

sub _dump_header {
    "PC   SP   OV   A    B    C    X    Y    Z    I    J    Instruction\n".
    "---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- -----------";
}

sub _dump_state {
    my $self = shift;
    sprintf("%04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %04x %s",
        $self->pc, $self->sp, $self->o, 
        $self->register(0), $self->register(1), $self->register(2), $self->register(3),
        $self->register(4), $self->register(5), $self->register(6), $self->register(7),
        CPU::Emulator::DCPU16::Disassembler->disassemble($self->pc, @{$self->memory}));
}

sub _debug {
    my $self = shift;
    my $mess = shift;
    print "$mess\n";
}

sub _get_value {
    my $self  = shift;
    my $value = shift;
    my $cost  = shift;
    my $ret;
    if ($value < 0x08) {
        $ret = $self->_reg_ref($value);
    } elsif ($value < 0x10) {
        $ret = $self->_mem_ref($self->register($value & 7));
    } elsif ($value < 0x18) {
        $$cost += 1;
        my $next = $self->memory($self->pc++);
        $ret = $self->_mem_ref($next + $self->register($value & 7) & 0xffff);
    } elsif ($value == 0x18) {
        $ret = $self->_mem_ref($self->sp++);
    } elsif ($value == 0x19) {
        $ret = $self->_mem_ref($self->sp);
    } elsif ($value == 0x1A) {
        $ret = $self->_mem_ref($self->sp--);
    } elsif ($value == 0x1B) {
        $ret = \($self->{_sp});
    } elsif ($value == 0x1C) {
        $ret = \($self->{_pc});
    } elsif ($value == 0x1D) {
        $ret = \($self->{_o});
    } elsif ($value == 0x1E) {
        $$cost += 1;
        $ret = $self->_mem_ref($self->memory($self->pc++));
    } elsif ($value == 0x1F) {
        $$cost += 1;
        $ret = $self->_mem_ref($self->pc++);
    } else {
        $ret = ($value - 0x20)
    }
    return ref($ret) ? $ret : \$ret;
}

our %_skiptable = (0x10 => 1, 0x11 => 1, 0x12 => 1, 0x13 => 1, 0x14 => 1, 0x15 => 1, 0x1E => 1, 0x1F => 1);
sub _skip {
    my $self = shift;
    my $cost = shift;
    $$cost++;
    my $op   = $self->memory($self->pc++);
    $self->pc += $_skiptable{$op  >> 10};
    $self->pc += $_skiptable{($op >> 4) & 31} if (($op & 0x0F) == 0);
}

sub _NOOP {
    # Just what it says on the tin
}

sub _JSR {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;   
    $self->memory(--$self->sp) = $self->pc;
    $self->pc = $$b;

}

# 0x1: SET a, b - sets a to b
sub _SET {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 1; 
    $$a = $$b;   
}

# 0x2: ADD a, b - sets a to a+b, sets O to 0x0001 if there's an overflow, 0x0 otherwise
sub _ADD {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;    
    $$a += $$b;
    $self->o = $$a >> 16;
}

# 0x3: SUB a, b - sets a to a-b, sets O to 0xffff if there's an underflow, 0x0 otherwise
sub _SUB {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;    
    $$a -= $$b;
    $self->o = $$a >> 16;
}

# 0x4: MUL a, b - sets a to a*b, sets O to ((a*b)>>16)&0xffff
sub _MUL {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;
    $$a *= $$b;
    $self->o = $$a >> 16;     
}

# 0x5: DIV a, b - sets a to a/b, sets O to ((a<<16)/b)&0xffff. if b==0, sets a and O to 0 instead.
sub _DIV {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 3;
    if ($$b) {
        $$a /= $$b;
    } else {
        $$a = 0;
    }
    $self->o = $$a >> 16;
}

# 0x6: MOD a, b - sets a to a%b. if b==0, sets a to 0 instead.
sub _MOD {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 3;
    if ($$b) {
        $$a %= $$b;
    } else {
        $$a = 0;
    }
}

# 0x7: SHL a, b - sets a to a<<b, sets O to ((a<<b)>>16)&0xffff
sub _SHL {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;
    $$a <<= $$b;
    $self->o = $$a >> 16;    
}

# 0x8: SHR a, b - sets a to a>>b, sets O to ((a<<16)>>b)&0xffff
sub _SHR {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;    
    $$a >>= $$b;
    $self->o = $$a >> 16;
}

# 0x9: AND a, b - sets a to a&b
sub _AND {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 1;    
    $$a &= $$b;
}

# 0xa: BOR a, b - sets a to a|b
sub _BOR {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 1;
    $$a |= $b;
}

# 0xb: XOR a, b - sets a to a^b
sub _XOR {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 1; 
    $$a ^= $b;   
}

# 0xc: IFE a, b - performs next instruction only if a==b
sub _IFE {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;    
    $self->_skip($cost) unless $$a+0 == $$b+0;
}

# 0xd: IFN a, b - performs next instruction only if a!=b
sub _IFN {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2; 
    $self->_skip($cost) unless $$a+0 != $$b+0;
}

# 0xe: IFG a, b - performs next instruction only if a>b
sub _IFG {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;   
    $self->_skip($cost) unless $$a+0 > $$b+0;
}

# 0xf: IFB a, b - performs next instruction only if (a&b)!=0
sub _IFB {
    my ($self, $a, $b, $cost) = @_;
    $$cost += 2;   
    $self->_skip($cost) unless ($$a+0 & $$b+0) != 0; 
}


=head1 SEE ALSO

L<CPU::Emulator::DCPU16::Assembler>

L<CPU::Emulator::DCPU16::Disassembler>

=head1 ACKNOWLEDGEMENTS

Implementation inspiration came from:

=over 4

=item Matt Bell's Javascript implementation (https://github.com/mappum/DCPU-16)

=item Brian Swetland's C Implementation (https://github.com/swetland/dcpu16)

=item Jesse Luehrs's Perl Implementation (https://github.com/doy/games-emulation-dcpu16)

=back

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2011 - Simon Wistow

Released under the same terms as Perl itself.

=head1 DEVELOPMENT

Latest development version available from

https://github.com/simonwistow/CPU-Emulator-DCPU16

=cut

1;