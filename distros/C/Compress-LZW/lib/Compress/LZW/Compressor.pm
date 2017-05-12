package Compress::LZW::Compressor;
# ABSTRACT: Scaling LZW compressor class
$Compress::LZW::Compressor::VERSION = '0.04';


use Compress::LZW qw(:const);

use Types::Standard qw( Bool Int );

use bytes;

use Moo;
use namespace::clean;

my $CHECKPOINT_BITS = 10_000;


has block_mode => (
  is      => 'ro',
  default => 1,
  isa     => Bool,
);


has max_code_size => ( # max bits
  is      => 'ro',
  default => 16,
  isa     => Type::Tiny->new(
    parent     => Int,
    constraint => sub { $_ >= $INIT_CODE_SIZE and $_ < $MASK_BITS },
    message    => sub { "$_ isn't between $INIT_CODE_SIZE and $MASK_BITS" },
  ),
);



sub compress {
  my $self = shift;
  my ( $str ) = @_;
  
  $self->reset;
  
  my $bytes_in;
  my ( $checkpoint, $last_ratio ) = ( 0, 0 );
 
  my $seen = '';

  for ( 0 .. length($str) ){
    my $char = substr($str, $_, 1);

    $bytes_in += 1;
    
    if ( exists $self->{code_table}{ $seen . $char } ){
      $seen .= $char;
    }
    else {      
      $self->_buf_write( $self->{code_table}{ $seen } );
      
      $self->_new_code( $seen . $char );
      
      $seen = $char;

      if ( $self->{at_max_code} and $self->block_mode ){
        if ( ! defined $checkpoint ){
          $checkpoint = $self->{buf_pos} + $CHECKPOINT_BITS;
        }
        elsif ( $bytes_in > $checkpoint ){
          my $ratio   = $bytes_in / ( $self->{buf_pos} / 8 );
          $last_ratio = 0 if !defined $last_ratio;

          
          if ( $ratio >= $last_ratio ){
            $last_ratio = $ratio;
            $checkpoint = $self->{buf_pos} + $CHECKPOINT_BITS;
          }
          elsif ( $ratio < $last_ratio ){
            # warn "Resetting code table ( $ratio < $last_ratio :: $self->{buf_pos} )";
            $self->_buf_write( $RESET_CODE );
            $self->_code_reset;

            undef $checkpoint;
            undef $last_ratio;
          }
        }
      }

    }
  }

  $self->_buf_write( $self->{code_table}{ $seen } );  #last bit of input
  # warn "final ratio: " . ($bytes_in / ($self->{buf_pos} / 8));
  
  return $self->{buf};
}



sub reset {
  my $self = shift;
  
  # replace buf with empty buffer after magic bytes
  $self->{buf}     = $MAGIC
    . chr( $self->max_code_size | ( $self->block_mode ? $MASK_BLOCK : 0 ) );

  $self->{buf_pos} = length($self->{buf}) * 8;
  
  $self->_code_reset;
}


sub _code_reset {
  my $self = shift;
  
  $self->{code_table} = {
    map { chr($_) => $_ } 0 .. 255
  };

  $self->{at_max_code}   = 0;
  $self->{code_size}     = $INIT_CODE_SIZE;
  $self->{next_code}     = $self->block_mode ? $BL_INIT_CODE : $NR_INIT_CODE;
  $self->{next_increase} = 2 ** $self->{code_size};

}

sub _new_code {
  my $self = shift;
  my ( $word ) = @_;

  if ( $self->{next_code} >= $self->{next_increase} ){

    if ( $self->{code_size} < $self->{max_code_size} ){
      $self->{code_size}     += 1;
      $self->{next_increase} *= 2;
    }
    else {
      $self->{at_max_code} = 1;
    }
  }
  
  if ( $self->{at_max_code} == 0 ){
    $self->{code_table}{ $word } = $self->{next_code};
    $self->{next_code} += 1;
  }

}

sub _buf_write {
  my $self = shift;
  my ( $code ) = @_;

  return unless defined $code;
  
  if ( $code > ( 2 ** $self->{code_size} ) ){
    die "Code value $code too high for current code size $self->{code_size}";
  }

  my $wpos = $self->{buf_pos};
  # if ( $code == $RESET_CODE ){
  #   warn "wrote a reset code ($RESET_CODE) at $wpos";
  # }
  #~ warn "write $code \tat $code_size bits\toffset $wpos (byte ".int($wpos/8) . ')';
  
  if ( $code == 1 ){
    vec( $self->{buf}, $wpos, 1 ) = 1;
  }
  else {
    for my $bit ( 0 .. ($self->{code_size} - 1) ){
      
      if ( ($code >> $bit) & 1 ){
        vec( $self->{buf}, $wpos + $bit, 1 ) = 1;
      }
    }
  }
  
  $self->{buf_pos} += $self->{code_size};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Compress::LZW::Compressor - Scaling LZW compressor class

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Compress::LZW::Compressor;
  
 my $c   = Compress::LZW::Compressor->new();
 my $lzw = $c->compress( $some_data );

=head1 ATTRIBUTES

=head2 block_mode

Default: 1

Block mode is a feature added to LZW by compress(1). Once the maximum code size
has been reached, if the compression ratio falls (NYI) the code table and code
size can be reset, and a code indicating this reset is embedded in the output
stream.

May be 0 or 1.

=head2 max_code_size

Default: 16

Maximum size in bits that code output may scale up to.  This value is stored in
byte 3 of the compressed output so the decompressor can also stop at the same
size automatically.  Maximum code size implies a maximum code table size of C<2
** max_code_size>, which can be emptied and restarted mid-stream in
L</block_mode>.

May be between 9 and 31, inclusive.  The default of 16 is the largest supported
by compress(1), but Compress::LZW can handle up to 31 bits.

=head1 METHODS

=head2 compress ( $input )

Compresses $input with the current settings and returns the result.

=head2 reset ()

Resets the compressor state for another round of compression. Automatically
called at the beginning of compress().

Resets the following internal state: Code table, next code number, code size,
output buffer, buffer position

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
