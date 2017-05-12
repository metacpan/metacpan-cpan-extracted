package Acme::6502::Tube;

use warnings;
use strict;
use Carp;
use Time::HiRes qw(time);
use Term::ReadKey ();
use base qw(Acme::6502);

our $VERSION = '0.77';

use constant ERROR => 0xF800;

use constant {
  PAGE  => 0x0800,
  HIMEM => 0x8000
};

use constant {
  OSRDRM => 0xFFB9,
  OSEVEN => 0xFFBF,
  GSINIT => 0xFFC2,
  GSREAD => 0xFFC5,
  NVWRCH => 0xFFC8,
  NVRDCH => 0xFFCB,
  OSFIND => 0xFFCE,
  OSGBPB => 0xFFD1,
  OSBPUT => 0xFFD4,
  OSBGET => 0xFFD7,
  OSARGS => 0xFFDA,
  OSFILE => 0xFFDD,
  OSASCI => 0xFFE3,
  OSNEWL => 0xFFE7,
  OSWRCH => 0xFFEE,
  OSRDCH => 0xFFE0,
  OSWORD => 0xFFF1,
  OSBYTE => 0xFFF4,
  OSCLI  => 0xFFF7
};

sub _BUILD {
  my ( $self, $args ) = @_;

  $self->SUPER::_BUILD( $args );

  $self->{ time_base } = time();

  # Inline OSASCI code
  $self->poke_code( OSASCI,
    0xC9, 0x0D,          # CMP #&0D
    0xD0, 0x07,          # BNE +7
    0xA9, 0x0A,          # LDA #&0A
    0x20, 0xEE, 0xFF,    # JSR &FFEE
    0xA9, 0x0D           # LDA #&0D
  );

  # BRK handler. The interrupt handling is bogus - so don't
  # generate any interrupts before fixing it :)
  $self->poke_code(
    0xFF00, 0x85, 0xFC, 0x68, 0x58, 0x29, 0x10, 0xF0,
    0x17,   0x8A, 0x48, 0xBA, 0x38, 0xBD, 0x02, 0x01,
    0xE9,   0x01, 0x85, 0xFD, 0xBD, 0x03, 0x01, 0xE9,
    0x00,   0x85, 0xFE, 0x68, 0xAA, 0x6C, 0x02, 0x02,
    0x6C,   0x04, 0x02
  );

  $self->write_16( $self->BREAK, 0xFF00 );

  $self->make_vector( 'OSCLI',  0x208, \&_oscli );
  $self->make_vector( 'OSBYTE', 0x20A, \&_osbyte );
  $self->make_vector( 'OSWORD', 0x20C, \&_osword );
  $self->make_vector( 'OSWRCH', 0x20E, \&_oswrch );
  $self->make_vector( 'OSRDCH', 0x210, \&_osrdch );
  $self->make_vector( 'OSFILE', 0x212, \&_osfile );
  $self->make_vector( 'OSARGS', 0x214, \&_osargs );
  $self->make_vector( 'OSBGET', 0x216, \&_osbget );
  $self->make_vector( 'OSBPUT', 0x218, \&_osbput );
  $self->make_vector( 'OSGBPB', 0x21A, \&_osgbpb );
  $self->make_vector( 'OSFIND', 0x21C, \&_osfind );

  $self->set_jumptab( 0xFA00 );
}

sub _oscli {
  my $self = shift;
  my $blk = $self->get_xy();
  my $cmd = '';
  CH: for ( ;; ) {
    my $ch = $self->read_8( $blk++ );
    last CH if $ch < 0x20;
    $cmd .= chr( $ch );
  }
  $cmd =~ s/^[\s\*]+//g;
  if ( lc( $cmd ) eq 'quit' ) {
    exit;
  }
  else {
    system( $cmd );
  }
}

sub _osbyte {
  my $self = shift;
  my $a = $self->get_a();
  if ( $a == 0x7E ) {
    # Ack escape
    $self->write_8( 0xFF, 0 );
    $self->set_x( 0xFF );
  }
  elsif ( $a == 0x82 ) {
    # Read m/c high order address
    $self->set_xy( 0 );
  }
  elsif ( $a == 0x83 ) {
    # Read OSHWM (PAGE)
    $self->set_xy( PAGE );
  }
  elsif ( $a == 0x84 ) {
    # Read HIMEM
    $self->set_xy( HIMEM );
  }
  elsif ( $a == 0xDA ) {
    $self->set_xy( 0x0900 );
  }
  else {
    die sprintf( "OSBYTE %02x not handled\n", $a );
  }
}

sub _set_escape {
  my $self = shift;
  $self->write_8( 0xFF, 0xFF );
}

sub _osword {
  my $self = shift;
  my $a   = $self->get_a();
  my $blk = $self->get_xy();

  if ( $a == 0x00 ) {
    # Command line input
    my $buf = $self->read_16( $blk );
    my $len = $self->read_8( $blk + 2 );
    my $min = $self->read_8( $blk + 3 );
    my $max = $self->read_8( $blk + 4 );
    my $y   = 0;
    if ( defined( my $in = <> ) ) {
      my @c = map ord, split //, $in;
      while ( @c && $len-- > 1 ) {
        my $c = shift @c;
        if ( $c >= $min && $c <= $max ) {
          $self->write_8( $buf + $y++, $c );
        }
      }
      $self->write_8( $buf + $y++, 0x0D );
      $self->set_y( $y );
      $self->set_p( $self->get_p() & ~$self->C );
    }
    else {
      # Escape I suppose...
      $self->set_p( $self->get_p() | $self->C );
    }
  }
  elsif ( $a == 0x01 ) {
    # Read clock
    my $now = int( ( time() - $self->{ time_base } ) * 100 );
    $self->write_32( $blk, $now );
    $self->write_8( $blk + 4, 0 );
  }
  elsif ( $a == 0x02 ) {
    # Set clock
    my $tm = $self->read_32( $blk );
    $self->{ time_base } = time() - ( $tm * 100 );
  }
  else {
    die sprintf( "OSWORD %02x not handled\n", $a );
  }
}

sub _oswrch {
  my $self = shift;
  printf( "%c", $self->get_a() );
}

sub _osrdch {
  my $self = shift;
  Term::ReadKey::ReadMode( 4 );
  eval {
    my $k = ord( Term::ReadKey::ReadKey( 0 ) );
    $k = 0x0D if $k == 0x0A;
    $self->set_a( $k );
    if ( $k == 27 ) {
      $self->set_escape;
      $self->set_p( $self->get_p() | $self->C );
    }
    else {
      $self->set_p( $self->get_p() & ~$self->C );
    }
  };
  Term::ReadKey::ReadMode( 0 );
  die $@ if $@;
}

sub _osfile {
  my $self = shift;
  my $a     = $self->get_a();
  my $blk   = $self->get_xy();
  my $name  = $self->read_str( $self->read_16( $blk ) );
  my $load  = $self->read_32( $blk + 2 );
  my $exec  = $self->read_32( $blk + 6 );
  my $start = $self->read_32( $blk + 10 );
  my $end   = $self->read_32( $blk + 14 );

  # printf("%-20s %08x %08x %08x %08x\n", $name, $load, $exec, $start, $end);
  if ( $a == 0x00 ) {
    # Save
    open my $fh, '>', $name or die "Can't write $name\n";
    binmode $fh;
    my $buf = $self->read_chunk( $start, $end );
    syswrite $fh, $buf or die "Error writing $name\n";
    $self->set_a( 1 );
  }
  elsif ( $a == 0xFF ) {
    # Load
    if ( -f $name ) {
      open my $fh, '<', $name or die "Can't read $name\n";
      binmode $fh;
      my $len = -s $fh;
      sysread $fh, my $buf, $len or die "Error reading $name\n";
      $load = PAGE if $exec & 0xFF;
      $self->write_chunk( $load, $buf );
      $self->write_32( $blk + 2,  $load );
      $self->write_32( $blk + 6,  0x00008023 );
      $self->write_32( $blk + 10, $len );
      $self->write_32( $blk + 14, 0x00000000 );
      $self->set_a( 1 );
    }
    elsif ( -d $name ) {
      $self->set_a( 2 );
    }
    else {
      $self->set_a( 0 );
    }
  }
  else {
    die sprintf( "OSFILE %02x not handled\n", $a );
  }
}

sub _osargs {
  die "OSARGS not handled\n";
}

sub _osbget {
  die "OSBGET not handled\n";
}

sub _osbput {
  die "OSBPUT not handled\n";
}

sub _osgbpb {
  die "OSGBPB not handled\n";
}

sub _osfind {
  die "OSFIND not handled\n";
}

sub make_vector {
    my( $self, $name, $vec, $code ) = @_;

    my $addr = $self->$name;
    my $vecno = scalar @{ $self->{ os } };
    push @{ $self->{ os } }, [ $code, $name ];

    $self->SUPER::make_vector( $addr, $vec, $vecno );
}

sub call_os {
  my $self = shift;
  my $vecno = shift;

  eval {
    my $call = $self->{ os }->[ $vecno ] || die "Bad OS call $vecno\n";
    $call->[ 0 ]->( $self );
  };

  if ( $@ ) {
    my $err = $@;
    $self->write_16( ERROR, 0x7F00 );
    $err =~ s/\s+/ /;
    $err =~ s/^\s+//;
    $err =~ s/\s+$//;
    warn $err;
    my $ep = ERROR + 2;
    for ( map ord, split //, $err ) {
      $self->write_8( $ep++, $_ );
    }
    $self->write_8( $ep++, 0x00 );
    $self->set_pc( ERROR );
  }
}

1;
__END__

=head1 NAME

Acme::6502::Tube - Acorn 65C02 Second Processor Simulator

=head1 VERSION

This document describes Acme::6502::Tube version 0.76

=head1 SYNOPSIS

    use Acme::6502::Tube;

    my $cpu = Acme::6502::Tube->new();

    # Load BBC Basic
    $cpu->load_rom('BASIC2.rom', 0x8000);

    # Init registers
    $cpu->set_pc(0x8000);
    $cpu->set_a(0x01);
    $cpu->set_s(0xFF);
    $cpu->set_p(0x22);

    # Run
    $cpu->run(2000_000) while 1;
  
=head1 DESCRIPTION

Emulates an Acorn BBC Micro 6502 Tube second processor. You'll need
to find your own language ROM to load and it's only been tested with
BBC Basic II.

=head1 INTERFACE 

See L<Acme::6502>. C<Acme::6502::Tube> is an C<Acme::6502> instance that
has been initialised with a skeleton Tube OS.

=head1 CONFIGURATION AND ENVIRONMENT
  
Acme::6502 requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Acme::6502>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Tube OS emulation is very minimal - just enough to run BBC Basic II. If
you extend it let me know.

I've included the HCCS Forth ROM in the distribution (I used to work for
HCCS and did a little work on the Forth ROM - although Joe Brown wrote
it). Unfortunately it doesn't currently work with C<Acme::6502::Tube> -
so that'll have to wait for another day.

Once the Forth ROM works I'll use it to write some tests.

Please report any bugs or feature requests to
C<bug-acme-6502@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

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
