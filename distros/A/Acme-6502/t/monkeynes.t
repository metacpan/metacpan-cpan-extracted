use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
  use_ok( 'Acme::6502' );
}

my %test_lut = (
  m => sub {
    return shift->read_8( hex shift );
  },
  ps => sub {
    return shift->get_p;
  },
  pc => sub {
    return shift->get_pc;
  },
  sp => sub {
    return shift->get_s;
  },
  acc => sub {
    return shift->get_a;
  },
  ix => sub {
    return shift->get_x;
  },
  iy => sub {
    return shift->get_y;
  },
  s => sub {
    return $_[0]->get_p & $_[0]->N ? 1 : 0;
  },
  v => sub {
    return $_[0]->get_p & $_[0]->V ? 1 : 0;
  },
  b => sub {
    return $_[0]->get_p & $_[0]->B ? 1 : 0;
  },
  d => sub {
    return $_[0]->get_p & $_[0]->D ? 1 : 0;
  },
  i => sub {
    return $_[0]->get_p & $_[0]->I ? 1 : 0;
  },
  z => sub {
    return $_[0]->get_p & $_[0]->Z ? 1 : 0;
  },
  c => sub {
    return $_[0]->get_p & $_[0]->C ? 1 : 0;
  },
);

my %regset_lut = (
  ps => sub {
    shift->set_p( shift );
  },
  pc => sub {
    shift->set_pc( shift );
  },
  sp => sub {
    shift->set_s( shift );
  },
  acc => sub {
    shift->set_a( shift );
  },
  ix => sub {
    shift->set_x( shift );
  },
  iy => sub {
    shift->set_y( shift );
  },
  s => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->N );
    $_[0]->set_p( $_[0]->get_p | $_[0]->N ) if $_[1];
  },
  v => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->V );
    $_[0]->set_p( $_[0]->get_p | $_[0]->V ) if $_[1];
  },
  b => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->B );
    $_[0]->set_p( $_[0]->get_p | $_[0]->B ) if $_[1];
  },
  d => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->D );
    $_[0]->set_p( $_[0]->get_p | $_[0]->D ) if $_[1];
  },
  i => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->I );
    $_[0]->set_p( $_[0]->get_p | $_[0]->I ) if $_[1];
  },
  z => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->Z );
    $_[0]->set_p( $_[0]->get_p | $_[0]->Z ) if $_[1];
  },
  c => sub {
    $_[0]->set_p( $_[0]->get_p & ~$_[0]->C );
    $_[0]->set_p( $_[0]->get_p | $_[0]->C ) if $_[1];
  },
);

my $glob = $ENV{TEST_OP} || '*';
my @files = glob( "t/monkeynes/script_${glob}.txt" );

for my $file ( @files ) {
  open( my $script, $file ) || die qq(cannot load test script "$file");
  _diag( qq(Running script "$file") );
  my @lines = <$script>;
  chomp( @lines );
  run_script( @lines );
  close( $script );
}

sub run_script {
  my $cpu;
  for ( @_ ) {
    chomp;
    next if m{^\s*$};
    next if m{^save};
    if ( m{^# (.+)} ) {
      _diag( $1 );
    }
    elsif ( $_ eq 'clear' ) {
      next;
    }
    elsif ( $_ eq 'power on' ) {
      $cpu = Acme::6502->new();
      $cpu->set_s( 255 );
      $cpu->set_p( $cpu->get_p | $cpu->R );
      isa_ok( $cpu, 'Acme::6502' );
    }
    elsif ( $_ eq 'memclear' ) {
      $cpu->poke_code( 0, ( 0 ) x 65536 );
      _diag( 'Mem cleared' );
    }
    elsif ( $_ eq 'step' ) {
      _diag( 'Running next instruction...' );
      $cpu->run( 1 );
    }
    elsif ( m{^regset (.+) (.+)} ) {
      $regset_lut{ lc $1 }->( $cpu, hex $2 );
      _diag( "$1 set to $2" );
    }
    elsif ( m{^regs(?: (.+))?} ) {
      diag_regs( $cpu, $1 );
    }
    elsif ( m{^memset (.+) (.+)} ) {
      $cpu->write_8( hex $1, hex $2 );
      is( $cpu->read_8( hex $1 ), hex $2, "Mem[$1] set to $2" );
    }
    elsif ( m{^test (.+) (.+) (.+)} ) {
      my ( $op, @args ) = split( /:/, $1 );
      my $cmp = $2;
      $cmp = '==' if $cmp eq '=';
      cmp_ok( $test_lut{ lc $op }->( $cpu, @args ),
        $cmp, hex $3, "$1 $2 $3" );
    }
    elsif ( m{^op (.+)} ) {
      my ( $op, $args_hex ) = split( ' ', $1 );
      _diag( "OP: $1" );
      $args_hex = '' unless defined $args_hex;
      my @args = ( $args_hex =~ m{(..)}g );
      my $pc = hex( 8000 );
      $cpu->poke_code(
        $pc,
        map { hex( $_ || 0 ) } $op,
        @args[ 0 .. 1 ]
      );
      $cpu->set_pc( $pc );
      $cpu->run( 1 );
    }
    else {
      use Data::Dumper;
      warn Dumper $_;
    }
  }
}

sub diag_regs {
  my $cpu = shift;
  my $reg = uc( defined $_[0] ? $_[0] : '' );

  _diag( 'CPU Registers' ) if !$reg;
  _diag( sprintf '  PC:    $%X', $cpu->get_pc )
   if !$reg || $reg eq 'PC';
  _diag( sprintf '  SP:    $%X', $cpu->get_s ) if !$reg || $reg eq 'SP';
  _diag( sprintf '  ACC:   $%X', $cpu->get_a )
   if !$reg || $reg eq 'ACC';
  _diag( sprintf '  IX:    $%X', $cpu->get_x ) if !$reg || $reg eq 'IX';
  _diag( sprintf '  IY:    $%X', $cpu->get_y ) if !$reg || $reg eq 'IY';
  # this should be fixed to handle just one flag at a time
  _diag( '  Flags  S V - B D I Z C' )
   if !$reg || $reg =~ m{^(PS|[SVBDIZC])$};
  _diag(
    sprintf '  PS:    %d %d %d %d %d %d %d %d',
    split( //, sprintf( '%08b', $cpu->get_p ) )
  ) if !$reg || $reg =~ m{^(PS|[SVBDIZC])$};
}

sub _diag {
  return unless $ENV{DIAG_6502};
  diag( @_ );
}
