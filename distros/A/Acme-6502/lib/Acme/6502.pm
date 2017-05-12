package Acme::6502;

use warnings FATAL => 'all';
use strict;
use Carp;

our $VERSION = '0.77';

# CPU flags
use constant {
  N => 0x80,
  V => 0x40,
  R => 0x20,
  B => 0x10,
  D => 0x08,
  I => 0x04,
  Z => 0x02,
  C => 0x01
};

use constant FLAGS => 'NVRBDIZC';

# Other CPU constants
use constant {
  STACK => 0x0100,
  BREAK => 0xFFFE
};

# Opcode to thunk into perlspace
use constant {
  ESCAPE_OP  => 0x0B,
  ESCAPE_SIG => 0xAD
};

BEGIN {
    for my $reg ( qw(a x y s p pc) ) {
        no strict 'refs';
        *{ __PACKAGE__ . "\::get_${reg}" } = sub {
            my $self = shift;
            return $self->{ reg }->{ $reg };
        };
        *{ __PACKAGE__ . "\::set_${reg}" } = sub {
            my ( $self, $v ) = @_;
            $self->{ reg }->{ $reg } = $v;
        };
    }
}

sub new {
    my $class = shift;
    my $self  = bless { }, $class;

    $self->_BUILD( @_ );

    return $self;
}

my @OP_CACHE;

sub _BUILD {
    my( $self, $args ) = @_;

    $args ||= {};

    $self->{ mem } = [ ( 0 ) x 65536 ];
    $self->{ reg } = {
        map { $_ => 0 } qw( a x y s p pc )
    };
    $self->{ os } = [ ];
    $self->{ jumptab } = $args->{ jumptab } || 0xFA00;
    $self->{ zn } = [ $self->Z, ( 0 ) x 127, ( $self->N ) x 128 ];

    my $bad_inst = $self->can( '_bad_inst' );

    @OP_CACHE = (
        _inst(    # 00 BRK
          _push( '($pc + 1) >> 8', '($pc + 1)' ),
          _push( '$p | B' ),
          '$p = $p | I | B & ~D;',
          _jmp_i( BREAK )
        ),
        _inst( _ora( _zpix() ) ),      # 01 ORA (zp, x)
        $bad_inst,                     # 02
        $bad_inst,                     # 03
        _inst( _tsb( _zp() ) ),        # 04 TSB zp
        _inst( _ora( _zp() ) ),        # 05 ORA zp
        _inst( _asl( _zp() ) ),        # 06 ASL zp
        $bad_inst,                     # 07
        _inst( _push( '$p | R' ) ),    # 08 PHP
        _inst( _ora( _imm() ) ),       # 09 ORA #imm
        _inst( _asl( _acc() ) ),       # 0A ASL A
        $bad_inst,                     # 0B
        _inst( _tsb( _abs() ) ),       # 0C TSB zp
        _inst( _ora( _abs() ) ),       # 0D ORA abs
        _inst( _asl( _abs() ) ),       # 0E ASL abs
        $bad_inst,                     # 0F BBR0 rel
        _inst( _bfz( _rel(), N ) ),    # 10 BPL rel
        _inst( _ora( _zpiy() ) ),      # 11 ORA (zp), y
        _inst( _ora( _zpi() ) ),       # 12 ORA (zp)
        $bad_inst,                     # 13
        _inst( _trb( _zpi() ) ),       # 14 TRB (zp)
        _inst( _ora( _zpx() ) ),       # 15 ORA zp, x
        _inst( _asl( _zpx() ) ),       # 16 ASL zp, x
        $bad_inst,                     # 17
        _inst( '$p &= ~C;' ),          # 18 CLC
        _inst( _ora( _absy() ) ),      # 19 ORA abs, y
        _inst( _inc( _acc() ) ),       # 1A INC A
        $bad_inst,                     # 1B
        _inst( _trb( _abs() ) ),       # 1C TRB abs
        _inst( _ora( _absx() ) ),      # 1D ORA abs, x
        _inst( _asl( _absx() ) ),      # 1E ASL abs, x
        $bad_inst,                     # 1F BBR1 rel
        _inst(                         # 20 JSR
          _push( '($pc + 1) >> 8', '($pc + 1)' ),
          _jmp()
        ),
        _inst( _and( _zpix() ) ),      # 21 AND (zp, x)
        $bad_inst,                     # 22
        $bad_inst,                     # 23
        _inst( _bit( _zp() ) ),        # 24 BIT zp
        _inst( _and( _zp() ) ),        # 25 AND zp
        _inst( _rol( _zp() ) ),        # 26 ROL zp
        $bad_inst,                     # 27
        _inst( _pop_p() ),             # 28 PLP
        _inst( _and( _imm() ) ),       # 29 AND  #imm
        _inst( _rol( _acc() ) ),       # 2A ROL A
        $bad_inst,                     # 2B
        _inst( _bit( _abs() ) ),       # 2C BIT abs
        _inst( _and( _abs() ) ),       # 2D AND abs
        _inst( _rol( _abs() ) ),       # 2E ROL abs
        $bad_inst,                     # 2F BBR2 rel
        _inst( _bfnz( _rel(), N ) ),   # 30 BMI rel
        _inst( _and( _zpiy() ) ),      # 31 AND (zp), y
        _inst( _and( _zpi() ) ),       # 32 AND (zp)
        $bad_inst,                     # 33
        _inst( _bit( _zpx() ) ),       # 34 BIT zp, x
        _inst( _and( _zpx() ) ),       # 35 AND zp, x
        _inst( _rol( _zpx() ) ),       # 36 ROL zp, x
        $bad_inst,                     # 37
        _inst( '$p |= C;' ),           # 38 SEC
        _inst( _and( _absy() ) ),      # 39 AND abs, y
        _inst( _dec( _acc() ) ),       # 3A DEC A
        $bad_inst,                     # 3B
        _inst( _bit( _absx() ) ),      # 3C BIT abs, x
        _inst( _and( _absx() ) ),      # 3D AND abs, x
        _inst( _rol( _absx() ) ),      # 3E ROL abs, x
        $bad_inst,                     # 3F BBR3 rel
        _inst( _rti() ),               # 40 RTI
        _inst( _eor( _zpix() ) ),      # 41 EOR (zp, x)
        $bad_inst,                     # 42
        $bad_inst,                     # 43
        $bad_inst,                     # 44
        _inst( _eor( _zp() ) ),        # 45 EOR zp
        _inst( _lsr( _zp() ) ),        # 46 LSR zp
        $bad_inst,                     # 47
        _inst( _push( '$a' ) ),        # 48 PHA
        _inst( _eor( _imm() ) ),       # 49 EOR imm
        _inst( _lsr( _acc() ) ),       # 4A LSR A
        $bad_inst,                     # 4B
        _inst( _jmp() ),               # 4C JMP abs
        _inst( _eor( _abs() ) ),       # 4D EOR abs
        _inst( _lsr( _abs() ) ),       # 4E LSR abs
        $bad_inst,                     # 4F BBR4 rel
        _inst( _bfz( _rel(), V ) ),    # 50 BVC rel
        _inst( _eor( _zpiy() ) ),      # 51 EOR (zp), y
        _inst( _eor( _zpi() ) ),       # 52 EOR (zp)
        $bad_inst,                     # 53
        $bad_inst,                     # 54
        _inst( _eor( _zpx() ) ),       # 55 EOR zp, x
        _inst( _lsr( _zpx() ) ),       # 56 LSR zp, x
        $bad_inst,                     # 57
        _inst( '$p &= ~I;' ),          # 58 CLI
        _inst( _eor( _absy() ) ),      # 59 EOR abs, y
        _inst( _push( '$y' ) ),        # 5A PHY
        $bad_inst,                     # 5B
        $bad_inst,                     # 5C
        _inst( _eor( _absx() ) ),      # 5D EOR abs, x
        _inst( _lsr( _absx() ) ),      # 5E LSR abs, x
        $bad_inst,                     # 5F BBR5 rel
        _inst( _rts() ),               # 60 RTS
        _inst( _adc( _zpix() ) ),      # 61 ADC (zp, x)
        $bad_inst,                     # 62
        $bad_inst,                     # 63
        _inst( _sto( _zp(), '0' ) ),   # 64 STZ zp
        _inst( _adc( _zp() ) ),        # 65 ADC zp
        _inst( _ror( _zp() ) ),        # 66 ROR zp
        $bad_inst,                     # 67
        _inst( _pop( '$a' ), _status( '$a' ) ),    # 68 PLA
        _inst( _adc( _imm() ) ),                   # 69 ADC  #imm
        _inst( _ror( _acc() ) ),                   # 6A ROR A
        $bad_inst,                                 # 6B
        _inst( _jmpi() ),                          # 6C JMP (abs)
        _inst( _adc( _abs() ) ),                   # 6D ADC abs
        _inst( _ror( _abs() ) ),                   # 6E ROR abs
        $bad_inst,                                 # 6F BBR6 rel
        _inst( _bfnz( _rel(), V ) ),               # 70 BVS rel
        _inst( _adc( _zpiy() ) ),                  # 71 ADC (zp), y
        _inst( _adc( _zpi() ) ),                   # 72 ADC (zp)
        $bad_inst,                                 # 73
        _inst( _sto( _zpx(), '0' ) ),              # 74 STZ zp, x
        _inst( _adc( _zpx() ) ),                   # 75 ADC zp, x
        _inst( _ror( _zpx() ) ),                   # 76 ROR zp, x
        $bad_inst,                                 # 77
        _inst( '$p |= I;' ),                       # 78 SEI
        _inst( _adc( _absy() ) ),                  # 79 ADC abs, y
        _inst( _pop( '$y' ), _status( '$y' ) ),    # 7A PLY
        $bad_inst,                                 # 7B
        _inst( _jmpix() ),                         # 7C JMP (abs, x)
        _inst( _adc( _absx() ) ),                  # 7D ADC abs, x
        _inst( _ror( _absx() ) ),                  # 7E ROR abs, x
        $bad_inst,                                 # 7F BBR7 rel
        _inst( _bra( _rel() ) ),                   # 80 BRA rel
        _inst( _sto( _zpix(), '$a' ) ),            # 81 STA (zp, x)
        $bad_inst,                                 # 82
        $bad_inst,                                 # 83
        _inst( _sto( _zp(), '$y' ) ),              # 84 STY zp
        _inst( _sto( _zp(), '$a' ) ),              # 85 STA zp
        _inst( _sto( _zp(), '$x' ) ),              # 86 STX zp
        $bad_inst,                                 # 87
        _inst( _dec( ( '', '$y' ) ) ),             # 88 DEY
        _inst( _bit( _imm() ) ),                   # 89 BIT  #imm
        _inst( '$a = $x;' . _status( '$a' ) ),     # 8A TXA
        $bad_inst,                                 # 8B
        _inst( _sto( _abs(), '$y' ) ),             # 8C STY abs
        _inst( _sto( _abs(), '$a' ) ),             # 8D STA abs
        _inst( _sto( _abs(), '$x' ) ),             # 8E STX abs
        $bad_inst,                                 # 8F BBS0 rel
        _inst( _bfz( _rel(), C ) ),                # 90 BCC rel
        _inst( _sto( _zpiy(), '$a' ) ),            # 91 STA (zp), y
        _inst( _sto( _zpi(),  '$a' ) ),            # 92 STA (zp)
        $bad_inst,                                 # 93
        _inst( _sto( _zpx(), '$y' ) ),             # 94 STY zp, x
        _inst( _sto( _zpx(), '$a' ) ),             # 95 STA zp, x
        _inst( _sto( _zpy(), '$x' ) ),             # 96 STX zp, y
        $bad_inst,                                 # 97
        _inst( '$a = $y;' . _status( '$a' ) ),     # 98 TYA
        _inst( _sto( _absy(), '$a' ) ),            # 99 STA abs, y
        _inst( '$s = $x;' ),                       # 9A TXS
        $bad_inst,                                 # 9B
        _inst( _sto( _abs(),  '0' ) ),             # 9C STZ abs
        _inst( _sto( _absx(), '$a' ) ),            # 9D STA abs, x
        _inst( _sto( _absx(), '0' ) ),             # 9E STZ abs, x
        $bad_inst,                                 # 9F BBS1 rel
        _inst( _lod( _imm(),  '$y' ) ),            # A0 LDY  #imm
        _inst( _lod( _zpix(), '$a' ) ),            # A1 LDA (zp, x)
        _inst( _lod( _imm(),  '$x' ) ),            # A2 LDX  #imm
        $bad_inst,                                 # A3
        _inst( _lod( _zp(), '$y' ) ),              # A4 LDY zp
        _inst( _lod( _zp(), '$a' ) ),              # A5 LDA zp
        _inst( _lod( _zp(), '$x' ) ),              # A6 LDX zp
        $bad_inst,                                 # A7
        _inst( '$y = $a;' . _status( '$y' ) ),     # A8 TAY
        _inst( _lod( _imm(), '$a' ) ),             # A9 LDA  #imm
        _inst( '$x = $a;' . _status( '$x' ) ),     # AA TAX
        $bad_inst,                                 # AB
        _inst( _lod( _abs(), '$y' ) ),             # AC LDY abs
        _inst( _lod( _abs(), '$a' ) ),             # AD LDA abs
        _inst( _lod( _abs(), '$x' ) ),             # AE LDX abs
        $bad_inst,                                 # AF BBS2 rel
        _inst( _bfnz( _rel(), C ) ),               # B0 BCS rel
        _inst( _lod( _zpiy(), '$a' ) ),            # B1 LDA (zp), y
        _inst( _lod( _zpi(),  '$a' ) ),            # B2 LDA (zp)
        $bad_inst,                                 # B3
        _inst( _lod( _zpx(), '$y' ) ),             # B4 LDY zp, x
        _inst( _lod( _zpx(), '$a' ) ),             # B5 LDA zp, x
        _inst( _lod( _zpy(), '$x' ) ),             # B6 LDX zp, y
        $bad_inst,                                 # B7
        _inst( '$p &= ~V;' ),                      # B8 CLV
        _inst( _lod( _absy(), '$a' ) ),            # B9 LDA abs, y
        _inst( '$x = $s;', _set_nz( '$x' ) ),      # BA TSX
        $bad_inst,                                 # BB
        _inst( _lod( _absx(), '$y' ) ),            # BC LDY abs, x
        _inst( _lod( _absx(), '$a' ) ),            # BD LDA abs, x
        _inst( _lod( _absy(), '$x' ) ),            # BE LDX abs, y
        $bad_inst,                                 # BF BBS3 rel
        _inst( _cmp( _imm(),  '$y' ) ),            # C0 CPY  #imm
        _inst( _cmp( _zpix(), '$a' ) ),            # C1 CMP (zp, x)
        $bad_inst,                                 # C2
        $bad_inst,                                 # C3
        _inst( _cmp( _zp(), '$y' ) ),              # C4 CPY zp
        _inst( _cmp( _zp(), '$a' ) ),              # C5 CMP zp
        _inst( _dec( _zp() ) ),                    # C6 DEC zp
        $bad_inst,                                 # C7
        _inst( _inc( ( '', '$y' ) ) ),             # C8 INY
        _inst( _cmp( _imm(), '$a' ) ),             # C9 CMP  #imm
        _inst( _dec( ( '', '$x' ) ) ),             # CA DEX
        $bad_inst,                                 # CB
        _inst( _cmp( _abs(), '$y' ) ),             # CC CPY abs
        _inst( _cmp( _abs(), '$a' ) ),             # CD CMP abs
        _inst( _dec( _abs() ) ),                   # CE DEC abs
        $bad_inst,                                 # CF BBS4 rel
        _inst( _bfz( _rel(), Z ) ),                # D0 BNE rel
        _inst( _cmp( _zpiy(), '$a' ) ),            # D1 CMP (zp), y
        _inst( _cmp( _zpi(),  '$a' ) ),            # D2 CMP (zp)
        $bad_inst,                                 # D3
        $bad_inst,                                 # D4
        _inst( _cmp( _zpx(), '$a' ) ),             # D5 CMP zp, x
        _inst( _dec( _zpx() ) ),                   # D6 DEC zp, x
        $bad_inst,                                 # D7
        _inst( '$p &= ~D;' ),                      # D8 CLD
        _inst( _cmp( _absy(), '$a' ) ),            # D9 CMP abs, y
        _inst( _push( '$x' ) ),                    # DA PHX
        $bad_inst,                                 # DB
        $bad_inst,                                 # DC
        _inst( _cmp( _absx(), '$a' ) ),            # DD CMP abs, x
        _inst( _dec( _absx() ) ),                  # DE DEC abs, x
        $bad_inst,                                 # DF BBS5 rel
        _inst( _cmp( _imm(), '$x' ) ),             # E0 CPX  #imm
        _inst( _sbc( _zpix(), '$a' ) ),            # E1 SBC (zp, x)
        $bad_inst,                                 # E2
        $bad_inst,                                 # E3
        _inst( _cmp( _zp(), '$x' ) ),              # E4 CPX zp
        _inst( _sbc( _zp() ) ),                    # E5 SBC zp
        _inst( _inc( _zp() ) ),                    # E6 INC zp
        $bad_inst,                                 # E7
        _inst( _inc( ( '', '$x' ) ) ),             # E8 INX
        _inst( _sbc( _imm() ) ),                   # E9 SBC  #imm
        _inst(),                                   # EA NOP
        $bad_inst,                                 # EB
        _inst( _cmp( _abs(), '$x' ) ),             # EC CPX abs
        _inst( _sbc( _abs() ) ),                   # ED SBC abs
        _inst( _inc( _abs() ) ),                   # EE INC abs
        $bad_inst,                                 # EF BBS6 rel
        _inst( _bfnz( _rel(), Z ) ),               # F0 BEQ rel
        _inst( _sbc( _zpiy() ) ),                  # F1 SBC (zp), y
        _inst( _sbc( _zpi() ) ),                   # F2 SBC (zp)
        $bad_inst,                                 # F3
        $bad_inst,                                 # F4
        _inst( _sbc( _zpx() ) ),                   # F5 SBC zp, x
        _inst( _inc( _zpx() ) ),                   # F6 INC zp, x
        $bad_inst,                                 # F7
        _inst( '$p |= D;' ),                       # F8 SED
        _inst( _sbc( _absy() ) ),                  # F9 SBC abs, y
        _inst( _pop( '$x' ), _status( '$x' ) ),    # FA PLX
        $bad_inst,                                 # FB
        $bad_inst,                                 # FC
        _inst( _sbc( _absx() ) ),                  # FD SBC abs, x
        _inst( _inc( _absx() ) ),                  # FE INC abs, x
        $bad_inst,                                 # FF BBS7 rel
    ) if !@OP_CACHE;
    $self->{ ops } = [ @OP_CACHE ];

    confess "Escape handler opcode not available"
       unless $self->{ ops }->[ ESCAPE_OP ] == $bad_inst;

    # Patch in the OS escape op handler
    $self->{ ops }->[ ESCAPE_OP ] = sub {
        my $self = shift;
        if ( $self->{ mem }->[ $self->{ reg }->{ pc } ] != ESCAPE_SIG ) {
            $bad_inst->( $self );
        }
        else {
            $self->{ reg }->{ pc } += 2;
            $self->call_os( $self->{ mem }->[ $self->{ reg }->{ pc } - 1 ] );
        }
    };
}

sub set_jumptab {
    my $self = shift;
    $self->{ jumptab } = shift;
}

sub get_state {
    my $self = shift;
    return @{ $self->{ reg } }{ qw( a x y s p pc ) };
}

sub get_xy {
    my $self = shift;
    return $self->get_x || ( $self->get_y << 8 );
}

sub set_xy {
    my $self = shift;
    my $v = shift;
    $self->set_x( $v & 0xFF );
    $self->set_y( ( $v >> 8 ) & 0xFF );
}

sub read_str {
    my $self = shift;
    my $addr = shift;
    my $str  = '';

    while ( $self->{ mem }->[ $addr ] != 0x0D ) {
        $str .= chr( $self->{ mem }->[ $addr++ ] );
    }

    return $str;
}

sub read_chunk {
    my $self = shift;
    my ( $from, $to ) = @_;

    return pack( 'C*', @{ $self->{ mem } }[ $from .. $to - 1 ] );
}

sub write_chunk {
    my $self = shift;
    my ( $addr, $chunk ) = @_;

    my $len = length( $chunk );
    splice @{ $self->{ mem } }, $addr, $len, unpack( 'C*', $chunk );
}

sub read_8 {
    my $self = shift;
    my $addr = shift;

    return $self->{ mem }->[ $addr ];
}

sub write_8 {
    my $self = shift;
    my( $addr, $val ) = @_;

    $self->{ mem }->[ $addr ] = $val;
}

sub read_16 {
    my $self = shift;
    my $addr = shift;

    return $self->{ mem }->[ $addr ] | ( $self->{ mem }->[ $addr + 1 ] << 8 );
}

sub write_16 {
    my $self = shift;
    my( $addr, $val ) = @_;

    $self->{ mem }->[ $addr ] = $val & 0xFF;
    $self->{ mem }->[ $addr + 1 ] = ( $val >> 8 ) & 0xFF;
}

sub read_32 {
    my $self = shift;
    my $addr = shift;

    return $self->{ mem }->[ $addr ]
        | ( $self->{ mem }->[ $addr + 1 ] << 8 )
        | ( $self->{ mem }->[ $addr + 2 ] << 16 )
        | ( $self->{ mem }->[ $addr + 3 ] << 32 );
}

sub write_32 {
    my $self = shift;
    my( $addr, $val ) = @_;

    $self->{ mem }->[ $addr ] = $val & 0xFF;
    $self->{ mem }->[ $addr + 1 ] = ( $val >> 8 ) & 0xFF;
    $self->{ mem }->[ $addr + 2 ] = ( $val >> 16 ) & 0xFF;
    $self->{ mem }->[ $addr + 3 ] = ( $val >> 24 ) & 0xFF;
}

sub poke_code {
    my $self = shift;
    my $addr = shift;

    $self->{ mem }->[ $addr++ ] = $_ for @_;
}

sub load_rom {
    my $self = shift;
    my ( $f, $a ) = @_;

    open my $fh, '<', $f or croak "Can't read $f ($!)\n";
    binmode $fh;
    my $sz = -s $fh;
    sysread $fh, my $buf, $sz or croak "Error reading $f ($!)\n";
    close $fh;

    $self->write_chunk( $a, $buf );
}

sub call_os {
  croak "call_os() not supported";
}

sub run {
    my $self = shift;
    my $ic = shift;
    my $cb = shift;

    while ( $ic-- > 0 ) {
        my( $a, $x, $y, $s, $p, $pc ) = $self->get_state;
        $cb->( $pc, $self->{ mem }->[ $pc ], $a, $x, $y, $s, $p ) if defined $cb;
        $self->set_pc( $pc + 1 );
        $self->{ ops }->[ $self->{ mem }->[ $pc ] ]->( $self );
    }
}

sub make_vector {
    my $self = shift;
    my ( $call, $vec, $func ) = @_;

    $self->{ mem }->[ $call ] = 0x6C;                   # JMP (indirect)
    $self->{ mem }->[ $call + 1 ] = $vec & 0xFF;
    $self->{ mem }->[ $call + 2 ] = ( $vec >> 8 ) & 0xFF;

    my $jumptab = $self->{ jumptab };
    my $addr    = $jumptab;
    $self->{ mem }->[ $jumptab++ ] = ESCAPE_OP;
    $self->{ mem }->[ $jumptab++ ] = ESCAPE_SIG;
    $self->{ mem }->[ $jumptab++ ] = $func;
    $self->{ mem }->[ $jumptab++ ] = 0x60;

    $self->set_jumptab( $jumptab );

    $self->{ mem }->[ $vec ] = $addr & 0xFF;
    $self->{ mem }->[ $vec + 1 ] = ( $addr >> 8 ) & 0xFF;
}

sub _inst {
    my $src = join( "\n", @_ );

    # registers
    $src    =~ s{\$(a|x|y|s|p|pc)\b}{\$self->{reg}->{$1}}g;

    # memory and zn access
    $src    =~ s{\$(mem|zn)\[}{\$self->{$1}->[}g;

    my $cr  = eval "sub { my \$self=shift; ${src} }";
    confess "$@" if $@;
    return $cr;
}

sub _bad_inst {
    my $self = shift;
    my $pc   = $self->get_pc;

    croak sprintf( "Bad instruction at &%04x (&%02x)\n",
      $pc - 1, $self->{ mem }->[ $pc - 1 ] );
}

# Functions that generate code fragments
sub _set_nz {
  return
     '$p &= ~(N|Z);' . 'if( '
   . $_[0]
   . ' & 0x80){ $p |= N }'
   . 'elsif( '
   . $_[0]
   . ' == 0 ){ $p |= Z }';
}

sub _push {
  my $r = '';
  for ( @_ ) {
    $r
     .= '$mem[STACK + $s] = (' 
     . $_
     . ') & 0xFF; $s = ($s - 1) & 0xFF;' . "\n";
  }
  return $r;
}

sub _pop {
  my $r = '';
  for ( @_ ) {
    $r .= '$s = ($s + 1) & 0xFF; ' . $_ . ' = $mem[STACK + $s];' . "\n";
  }
  return $r;
}

sub _pop_p {
  return '$s = ($s + 1) & 0xFF; $p = $mem[STACK + $s] | R; $p &= ~B;'
   . "\n";
}

# Addressing modes return a list containing setup code, lvalue
sub _zpix {
  return (
    'my $ea = $mem[$pc++] + $x; '
     . '$ea = $mem[$ea & 0xFF] | ($mem[($ea + 1) & 0xFF] << 8)' . ";\n",
    '$mem[$ea]'
  );
}

sub _zpi {
  return (
    'my $ea = $mem[$pc++]; '
     . '$ea = $mem[$ea & 0xFF] | ($mem[($ea + 1) & 0xFF] << 8)' . ";\n",
    '$mem[$ea]'
  );
}

sub _zpiy {
  return (
    'my $ea = $mem[$pc++]; '
     . '$ea = ($mem[$ea & 0xFF] | ($mem[($ea + 1) & 0xFF] << 8)) + $y'
     . ";\n",
    '$mem[$ea]'
  );
}

sub _zp {
  return ( 'my $ea = $mem[$pc++];' . "\n", '$mem[$ea]' );
}

sub _zpx {
  return ( 'my $ea = ($mem[$pc++] + $x) & 0xFF;' . "\n", '$mem[$ea]' );
}

sub _zpy {
  return ( 'my $ea = ($mem[$pc++] + $y) & 0xFF;' . "\n", '$mem[$ea]' );
}

sub _abs {
  return ( 'my $ea = $mem[$pc] | ($mem[$pc+1] << 8); $pc += 2;' . "\n",
    '$mem[$ea]' );
}

sub _absx {
  return (
    'my $ea = ($mem[$pc] | ($mem[$pc+1] << 8)) + $x; $pc += 2;' . "\n",
    '$mem[$ea]'
  );
}

sub _absy {
  return (
    'my $ea = ($mem[$pc] | ($mem[$pc+1] << 8)) + $y; $pc += 2;' . "\n",
    '$mem[$ea]'
  );
}

sub _imm {
  return ( 'my $v = $mem[$pc++];' . "\n", '$v' );
}

sub _acc {
  return ( '', '$a' );
}

sub _rel {
  # Doesn't return an lvalue
  return ( 'my $t = $mem[$pc++];' . "\n",
    '($pc + $t - (($t & 0x80) ? 0x100 : 0))' );
}

sub _status {
  my $reg = shift || '$a';
  return '$p = ($p & ~(N | Z) | $zn[' . $reg . ']);' . "\n";
}

sub _ora {
  return $_[0] . '$a |= ' . $_[1] . ";\n" . _status();
}

sub _and {
  return $_[0] . '$a &= ' . $_[1] . ";\n" . _status();
}

sub _eor {
  return $_[0] . '$a ^= ' . $_[1] . ";\n" . _status();
}

sub _bit {
  return
     $_[0]
   . '$p = ($p & ~(N|V)) | ('
   . $_[1]
   . ' & (N|V));' . "\n"
   . 'if (($a & '
   . $_[1]
   . ') == 0) { $p |= Z; } else { $p &= ~Z; }' . "\n";
}

sub _asl {
  return
     $_[0]
   . 'my $w = ('
   . $_[1]
   . ') << 1; ' . "\n"
   . 'if ($w & 0x100) { $p |= C; $w &= ~0x100; } else { $p &= ~C; }'
   . "\n"
   . _status( '$w' )
   . $_[1]
   . ' = $w;' . "\n";
}

sub _lsr {
  return
     $_[0]
   . 'my $w = '
   . $_[1] . ";\n"
   . 'if (($w & 1) != 0) { $p |= C; } else { $p &= ~C; }' . "\n"
   . '$w >>= 1;' . "\n"
   . _status( '$w' )
   . $_[1]
   . ' = $w;' . "\n";
}

sub _rol {
  return
     $_[0]
   . 'my $w = ('
   . $_[1]
   . ' << 1) | ($p & C);' . "\n"
   . 'if ($w >= 0x100) { $p |= C; $w -= 0x100; } else { $p &= ~C; };'
   . "\n"
   . _status( '$w' )
   . $_[1]
   . ' = $w;' . "\n";
}

sub _ror {
  return
     $_[0]
   . 'my $w = '
   . $_[1]
   . ' | (($p & C) << 8);' . "\n"
   . 'if (($w & 1) != 0) { $p |= C; } else { $p &= ~C; }' . "\n"
   . '$w >>= 1;' . "\n"
   . _status( '$w' )
   . $_[1]
   . ' = $w;' . "\n";
}

sub _sto {
  return $_[0] . "$_[1] = $_[2];\n";
}

sub _lod {
  return $_[0] . "$_[2] = $_[1];\n" . _status( $_[2] );
}

sub _cmp {
  return
     $_[0]
   . 'my $w = '
   . $_[2] . ' - '
   . $_[1] . ";\n"
   . 'if ($w < 0) { $w += 0x100; $p &= ~C; } else { $p |= C; }' . "\n"
   . _status( '$w' );
}

sub _tsb {
  return 'croak "TSB not supported\n";' . "\n";
}

sub _trb {
  return 'croak "TRB not supported\n";' . "\n";
}

sub _inc {
  return
     $_[0]
   . $_[1] . ' = ('
   . $_[1]
   . ' + 1) & 0xFF;' . "\n"
   . _status( $_[1] );
}

sub _dec {
  return
     $_[0]
   . $_[1] . ' = ('
   . $_[1]
   . ' + 0xFF) & 0xFF;' . "\n"
   . _status( $_[1] );
}

sub _adc {
  return
     $_[0]
   . 'my $w = '
   . $_[1] . ";\n"
   . 'if ($p & D) {' . "\n"
   . 'my $lo = ($a & 0x0F) + ($w & 0x0F) + ($p & C);' . "\n"
   . 'if ($lo > 9) { $lo += 6; }' . "\n"
   . 'my $hi = ($a >> 4) + ( $w >> 4) + ($lo > 15 ? 1 : 0);' . "\n"
   . '$a = ($lo & 0x0F) | ($hi << 4);' . "\n"
   . '$p = ($p & ~C) | ($hi > 15 ? C : 0);' . "\n"
   . '} else {' . "\n"
   . 'my $lo = $a + $w + ($p & C);' . "\n"
   . '$p &= ~(N | V | Z | C);' . "\n"
   . '$p |= (~($a ^ $w) & ($a ^ $lo) & 0x80 ? V : 0) | ($lo & 0x100 ? C : 0);'
   . "\n"
   . '$a = $lo & 0xFF;' . "\n"
   . _status() . '}' . "\n";
}

sub _sbc {
  return
     $_[0]
   . 'my $w = '
   . $_[1] . ";\n"
   . 'if ($p & D) {' . "\n"
   . 'my $lo = ($a & 0x0F) - ($w & 0x0F) - (~$p & C);' . "\n"
   . 'if ($lo & 0x10) { $lo -= 6; }' . "\n"
   . 'my $hi = ($a >> 4) - ($w >> 4) - (($lo & 0x10) >> 4);' . "\n"
   . 'if ($hi & 0x10) { $hi -= 6; }' . "\n"
   . '$a = ($lo & 0x0F) | ($hi << 4);' . "\n"
   . '$p = ($p & ~C) | ($hi > 15 ? 0 : C);' . "\n"
   . '} else {' . "\n"
   . 'my $lo = $a - $w - (~$p & C);' . "\n"
   . '$p &= ~(N | V | Z | C);' . "\n"
   . '$p |= (($a ^ $w) & ($a ^ $lo) & 0x80 ? V : 0) | ($lo & 0x100 ? 0 : C);'
   . "\n"
   . '$a = $lo & 0xFF;' . "\n"
   . _status() . '}' . "\n";
}

sub _bra {
  return $_[0] . '$pc = ' . $_[1] . ";\n";
}

sub _bfz {
  return
     $_[0]
   . 'if (($p & '
   . $_[2]
   . ') == 0) { $pc = '
   . $_[1] . '; }' . "\n";
}

sub _bfnz {
  return
     $_[0]
   . 'if (($p & '
   . $_[2]
   . ') != 0) { $pc = '
   . $_[1] . '; }' . "\n";
}

sub _jmp_i {
  my $a = shift;
  return '$pc = $mem[' . $a . '] | ($mem[' . $a . ' + 1] << 8);' . "\n";
}

sub _jmp_i_bug {
  my $a = shift;

  # this should emulate a page boundary bug:
  # JMP 0x80FF fetches from 0x80FF and 0x8000
  # instead of 0x80FF and 0x8100
  my $b = "($a & 0xFF00) | (($a + 1) & 0xFF)";
  return '$pc = $mem[' . $a . '] | ($mem[' . $b . '] << 8);' . "\n";
}

sub _jmp {
  return _jmp_i( '$pc' );
}

sub _jmpi {
  return 'my $w = $mem[$pc] | ($mem[$pc + 1] << 8); '
   . _jmp_i_bug( '$w' );
}

sub _jmpix {
  return 'my $w = ($mem[$pc] | ($mem[$pc + 1] << 8)) + $x; '
   . _jmp_i( '$w' );
}

sub _rti {
  return
     _pop( '$p' )
   . '$p |= R;'
   . 'my ($lo, $hi); '
   . _pop( '$lo' )
   . _pop( '$hi' )
   . '$pc = $lo | ($hi << 8);' . "\n";
}

sub _rts {
  return
     'my ($lo, $hi); '
   . _pop( '$lo' )
   . _pop( '$hi' )
   . '$pc = ($lo | ($hi << 8)) + 1;' . "\n";
}

1;
__END__

=head1 NAME

Acme::6502 - Pure Perl 65C02 simulator.

=head1 VERSION

This document describes Acme::6502 version 0.76

=head1 SYNOPSIS

    use Acme::6502;
    
    my $cpu = Acme::6502->new();
    
    # Set start address
    $cpu->set_pc(0x8000);
    
    # Load ROM image
    $cpu->load_rom('myrom.rom', 0x8000);
    
    # Run for 1,000,000 instructions then return
    $cpu->run(1_000_000);
  
=head1 DESCRIPTION

Imagine the nightmare scenario: your boss tells you about a legacy
system you have to support. How bad could it be? COBOL? Fortran? Worse:
it's an embedded 6502 system run by a family of squirrels (see Dilberts
passim). Fortunately there's a pure Perl 6502 emulator that works so
well the squirrels will never know the difference.

=head1 INTERFACE 

=over

=item C<new>

Create a new 6502 CPU.

=item C<call_os( $vec_number )>

Subclass to provide OS entry points. OS vectors are installed by calling
C<make_vector>. When the vector is called C<call_os()> will be called
with the vector number.

=item C<get_a()>

Read the current value of the processor A register (accumulator).

=item C<get_p()>

Read the current value of the processor status register.

=item C<get_pc()>

Read the current value of the program counter.

=item C<get_s()>

Read the current value of the stack pointer.

=item C<get_x()>

Read the current value of the processor X index register.

=item C<get_y()>

Read the current value of the processor X index register.

=item C<get_xy()>

Read the value of X and Y as a sixteen bit number. X forms the lower 8
bits of the value and Y forms the upper 8 bits.

=item C<get_state()>

Returns an array containing the values of the A, X, Y, S, P and SP.

=item C<set_a( $value )>

Set the value of the processor A register (accumulator).

=item C<set_p( $value )>

Set the value of the processor status register.

=item C<set_pc( $value )>

Set the value of the program counter.

=item C<set_s( $value )>

Set the value of the stack pointer.

=item C<set_x( $value )>

Set the value of the X index register.

=item C<set_y( $value )>

Set the value of the Y index register.

=item C<set_xy( $value )>

Set the value of the X and Y registers to the specified sixteen bit
number. X gets the lower 8 bits, Y gets the upper 8 bits.

=item C<set_jumptab( $addr )>

Set the address of the block of memory that will be used to hold the
thunk blocks that correspond with vectored OS entry points. Each thunk
takes four bytes.

=item C<load_rom( $filename, $addr )>

Load a ROM image at the specified address.

=item C<make_vector( $jmp_addr, $vec_addr, $vec_number )>

Make a vectored entry point for an emulated OS. C<$jmp_addr> is the
address where an indirect JMP instruction (6C) will be placed,
C<$vec_addr> is the address of the vector and C<$vec_number> will be
passed to C<call_os> when the OS call is made.

=item C<poke_code( $addr, @bytes )>

Poke code directly at the specified address.

=item C<read_8( $addr )>

Read a byte at the specified address.

=item C<read_16( $addr )>

Read a sixteen bit (low, high) word at the specified address.

=item C<read_32( $addr )>

Read a 32 bit word at the specified address.

=item C<read_chunk( $start, $end )>

Read a chunk of data from C<$start> to C<$end> - 1 into a string.

=item C<read_str( $addr )>

Read a carriage return terminated (0x0D) string from the
specified address.

=item C<run( $count [, $callback ] )>

Execute the specified number of instructions and return. Optionally a
callback may be provided in which case it will be called before each
instruction is executed:

    my $cb = sub {
        my ($pc, $inst, $a, $x, $y, $s, $p) = @_;
        # Maybe output trace info
    }
    
    $cpu->run(100, $cb);

=item C<write_8( $addr, $value )>

Write the byte at the specified address.

=item C<write_16( $addr, $value )>

Write a sixteen bit (low, high) value at the specified address.

=item C<write_32( $addr, $value )>

Write a 32 bit value at the specified address.

=item C<write_chunk( $addr, $string )>

Write a chunk of data to memory.

=back

=head1 DIAGNOSTICS

=over

=item C<< Bad instruction at %s (%s) >>

The emulator hit an illegal 6502 instruction.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Acme::6502 requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Doesn't have support for hardware emulation hooks - so memory mapped I/O
is out of the question until someone fixes it.

Please report any bugs or feature requests to
C<bug-acme-6502@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Brian Cassidy C<< <bricas@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2012, Andy Armstrong C<< <andy@hexten.net> >>. All
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
