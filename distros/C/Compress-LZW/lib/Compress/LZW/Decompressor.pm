package Compress::LZW::Decompressor;
# ABSTRACT: Scaling LZW decompressor class
$Compress::LZW::Decompressor::VERSION = '0.04';

use Compress::LZW qw(:const);

use Types::Standard qw( Bool Int );

use Moo;
use namespace::clean;


sub decompress {
  my $self = shift;
  my ( $data ) = @_;

  $self->reset;

  $self->{data}     = \$data;
  $self->{data_pos} = 0;

  $self->_read_magic;
  $self->{data_pos} = 24;

  $self->_str_reset;

  my $next_increase = 2 ** $self->{code_size};

  my $seen = $self->_read_code;
  my $buf  = $self->{str_table}{$seen};

  while ( defined( my $code = $self->_read_code ) ){

    if ( $self->{block_mode} and $code == $RESET_CODE ){
      # warn sprintf('reset table (%s, %s) at %s', $seen, $code, $self->{data_pos} - $self->{code_size});
      #reset table, next code, and code size
      $self->_str_reset;
      $next_increase = 2 ** $self->{code_size};

      $seen = $self->_read_code;
      $buf .= $self->{str_table}{$seen};
      
      next;
    }
    
    if ( defined ( my $word = $self->{str_table}{ $code } ) ){

      $buf .= $word;

      $self->{str_table}{ $self->{next_code} } = $self->{str_table}{ $seen } . substr($word,0,1);

    }
    elsif ( $code == $self->{next_code} ){
      
      my $word = $self->{str_table}{$seen};
           
      $self->{str_table}{$code} = $word . substr( $word, 0, 1 );
      
      $buf .= $self->{str_table}{$code};

    }
    else {
      die "($code != ". $self->{next_code} . ") input may be corrupt before bit $self->{data_pos}";
    }

    $seen = $code;
    
    # if next code expected will require a larger bit size
    if ( $self->{next_code} + 1 >= $next_increase ){
      if ( $self->{code_size} < $self->{max_code_size} ){
        # warn "decode up to $self->{code_size} bits at bit $self->{data_pos}";
        $self->{code_size} += 1;
        $next_increase     *= 2;
      }
      else {
        $self->{at_max_code} = 1;
      }
    }

    if ( $self->{at_max_code} == 0 ){
      $self->{next_code} += 1;
    }
    
  }
  return $buf;
}


sub reset {
  my $self = shift;
 
  $self->{data}        = undef;
  $self->{data_pos}    = 0;

  $self->_str_reset;
}

sub _str_reset {
  my $self = shift;
  
  $self->{str_table} = {
    map { $_ => chr($_) } 0 .. 255
  };
  
  $self->{code_size}   = $INIT_CODE_SIZE;
  $self->{next_code}   = $self->{block_mode} ? $BL_INIT_CODE : $NR_INIT_CODE;
  $self->{at_max_code} = 0;
}

sub _read_magic {
  my $self = shift;
  
  my $magic = substr( ${ $self->{data} }, 0, 3 );

  if ( length($magic) != 3 or substr($magic,0, 2) ne $MAGIC ){
    die "Invalid compress(1) header";
  }

  my $bits = ord( substr( $magic, 2, 1 ) );

  $self->{max_code_size} = $bits & $MASK_BITS;
  $self->{block_mode}    = ( $bits & $MASK_BLOCK ) >> 7;
}

sub _read_code {
  my $self = shift;

  if ( $self->{data_pos} > length( ${$self->{data}} ) * 8 ){
    # warn "bailing at $self->{data_pos} + $self->{code_size} > " . length( ${$self->{data}} ) *8;
    return undef;
  }
  
  my $code = 0;
  for ( 0 .. ($self->{code_size} - 1) ){
    $code |=
      vec( ${$self->{data}}, $self->{data_pos} + $_ , 1) << $_;
  }
  
  $self->{data_pos} += $self->{code_size};
  
  return undef if $code == 0 and $self->{data_pos} > length( ${$self->{data}} ) * 8;
  return $code;
  
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Compress::LZW::Decompressor - Scaling LZW decompressor class

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Compress::LZW::Decompressor;
  
 my $d    = Compress::LZW::Decompressor->new();
 my $orig = $d->decompress( $lzw );

=head1 METHODS

=head2 decompress ( $input )

Decompress $input with the current settings and returns the result.

=head2 reset ()

Resets the decompressor state for another round of input. Automatically
called at the beginning of ->decompress.

Resets the following internal state: code table, next code number, code
size, output buffer

=head1 AUTHOR

Meredith Howard <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Meredith Howard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
