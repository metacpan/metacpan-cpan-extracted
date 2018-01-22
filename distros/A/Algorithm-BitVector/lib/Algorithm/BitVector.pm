package Algorithm::BitVector;

#!/usr/bin/perl -w

#------------------------------------------------------------------------------------
# Copyright (c) 2018 Avinash Kak. All rights reserved.  This program is free
# software.  You may modify and/or distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# Algorithm::BitVector is a Perl module for creating a memory efficient packed
# representation of bit arrays and for logical and numerical operations on such
# arrays.
# -----------------------------------------------------------------------------------

#use 5.10.0;
use strict;
use warnings;
use Carp;
use List::Util qw(pairmap min max reduce any);
use Math::BigInt;
use Math::Random;
use Fcntl 'SEEK_CUR';

our $VERSION = '1.26';

use overload  '+'        =>    '_join',
              '""'       =>    '_str',
              '0+'       =>    '_int',
              '~'        =>    '_invert',
              '|'        =>    '_or',
              '&'        =>    '_and',
              '^'        =>    '_xor',
              '<=>'      =>    '_compare',
              '<<'       =>    '_lshift',
              '>>'       =>    '_rshift',
              '<>'       =>    '_iter',
              'fallback' =>    1;

sub _readblock {
    my $blocksize = shift;
    my $bitvector = shift;
    my $block;
    my $more_to_read;
    my $i = 0;
    my $byte_as_bits;
    my $bitstring = '';
    while ( $i < $blocksize / 8 ) {
        $i++;
        my $num_bytes_read = sysread($bitvector->{FILEIN}, my $byte, 1);
        unless ($num_bytes_read) {
            if (length($bitstring) < $blocksize) { 
                $bitvector->{more_to_read} = 0;
                $more_to_read = 0;
            }
            return $bitstring;
        } else {
            my $bits_as_string = sprintf "%vb", $byte;
            $bits_as_string = '0' x (8 - length($bits_as_string)) . $bits_as_string;
            $bitstring .= $bits_as_string;
        }
    }
    my $file_pos = tell $bitvector->{FILEIN};
    # peek at the next byte; moves file position only if a
    # byte is read
    my $num_bytes_read = sysread($bitvector->{FILEIN}, my $next_byte, 1);
    if ($num_bytes_read) {
        # pretend we never read the byte
        sysseek $bitvector->{FILEIN}, $file_pos - 1, SEEK_CUR;
    } else {
        $bitvector->{more_to_read} = 0;
    }
    return $bitstring;
}

# Constructor:
sub new { 
    my ($class, %args) = @_;
    my @params = keys %args;
    croak "\nYou have used a wrong name for a keyword argument " .
          "--- perhaps a misspelling\n" 
          if _check_for_illegal_params(@params) == 0;
    my $self = {
        filename                          =>   $args{filename},
        size                              =>   $args{size},
        intVal                            =>   $args{intVal},
        bitlist                           =>   $args{bitlist},
        bitstring                         =>   $args{bitstring},
        hexstring                         =>   $args{hexstring},
        textstring                        =>   $args{textstring},
    };
    bless $self, $class;
    if ( $self->{filename} )  {
        die "When using the `filename' option in the constructor call, you cannot use any " .
            "other option at the same time: $!" 
            if $self->{intVal} or $self->{size} or $self->{bitlist} 
               or $self->{bitstring} or $self->{hexstring} or $self->{textstring};
        open $self->{FILEIN}, "< $self->{filename}" 
                            or die "unable to open file $self->{filename}: $!";
        $self->{more_to_read} = 1;
        return $self;
    } elsif ( defined $self->{intVal} )  {
        die "When using the `intVal' option in the constructor call, you CANNOT use `filename', " .
            "`bitlist', 'bitstring', `hexstring', or `textstring' options: $!" 
            if $self->{filename}  or $self->{bitlist} or $self->{bitstring} 
               or $self->{hexstring} or $self->{textstring};
        if ($self->{intVal} == 0 && ! defined $self->{size}) {
            $self->{bitlist} = [0];
            $self->{size} = 1;
        } else {
            my @bitarray;
#            if (ref($self->{intVal}) eq 'Math::BigInt') {
            if (ref($self->{intVal}) eq 'Math::BigInt' && ! defined $self->{size}) {
                my $bitlist_str = $self->{intVal}->as_bin();
                $bitlist_str =~ s/^0b//;
                @bitarray = split //, $bitlist_str;
            } elsif (ref($self->{intVal}) eq 'Math::BigInt' && defined $self->{size}) {   #new<<<<<<<<<<<<<
                my $bitlist_str = $self->{intVal}->as_bin();
                $bitlist_str =~ s/^0b//;
                croak "\nThe value specified for size must be at least as large as for the " .
                      "smallest bitvector possible for the intVal integer: $!" 
                      if $self->{size} < length $bitlist_str;
                @bitarray = split //, $bitlist_str;
                my $n = $self->{size} - @bitarray;
                my $extended_bitlist_str = '0' x $n . $bitlist_str;
                @bitarray = split //, $extended_bitlist_str;
            } else {
                my $bitlist_str = sprintf "%b", $self->{intVal};
                if (defined $self->{size}) {
                    croak "\nThe value specified for size must be at least as large as for the " .
                          "smallest bitvector possible for the intVal integer: $!" 
                          if $self->{size} < length $bitlist_str;
                    my $n = $self->{size} - length $bitlist_str;
                    my $extended_bitlist_str = '0' x $n . $bitlist_str;
                    @bitarray = split //, $extended_bitlist_str;
                } else {
                    @bitarray = split //, $bitlist_str;
                }
            }
            $self->{bitlist} = \@bitarray;
            $self->{size} = scalar @{$self->{bitlist}};
        }
    } elsif (defined $self->{size}) {
        die "When using the `size' option in the constructor call, you CANNOT use `filename', " .
            "`bitlist', 'bitstring', `hexstring', or `textstring' options: $!" 
            if $self->{filename} or $self->{intVal} or $self->{bitlist} 
               or $self->{bitstring} or $self->{hexstring} or $self->{textstring};
        my $bitstring = "0" x $self->{size};   
        my @bitlist_from_bitstring  = split '', $bitstring;
        $self->{bitlist} = \@bitlist_from_bitstring;
    } elsif ($self->{bitlist}) {
        die "When using the `bitlist' option in the constructor call, you cannot use any " .
            "other option at the same time: $!" 
            if $self->{filename} or $self->{intVal} or $self->{size} 
               or $self->{bitstring} or $self->{hexstring} or $self->{textstring};
        $self->{size} = scalar @{$self->{bitlist}};
    } elsif (defined $self->{bitstring}) {
        die "When using the `bitstring' option in the constructor call, you cannot use any " .
            "other option at the same time: $!" 
            if $self->{filename} or $self->{intVal} or $self->{size} 
               or $self->{bitlist} or $self->{hexstring} or $self->{textstring};
        my @bitlist_from_bitstring = split //, $self->{bitstring};
        $self->{bitlist} = \@bitlist_from_bitstring;
        $self->{size} = scalar @{$self->{bitlist}};
    } elsif (defined $self->{textstring}) {
        die "When using the `textstring' option in the constructor call, you cannot use any " .
            "other option at the same time: $!" 
            if $self->{filename} or $self->{intVal} or $self->{size} 
               or $self->{bitlist} or $self->{hexstring} or $self->{bitstring};
        my $bitstring_from_text = join '', map {length($_) == 8 ? $_ 
                                   : ('0' x (8 - length($_))) . $_} map {sprintf "%b", $_} 
                                   map ord, split //, $self->{textstring};
        my @bitlist_from_text = split //, $bitstring_from_text;
        $self->{bitlist} = \@bitlist_from_text;
        $self->{size} = scalar @{$self->{bitlist}};
    } elsif (defined $self->{hexstring}) {
        die "When using the `hexstring' option in the constructor call, you cannot use any " .
            "other option at the same time: $!" 
            if $self->{filename} or $self->{intVal} or $self->{size} 
               or $self->{bitlist} or $self->{textstring} or $self->{bitstring};
        my $bitstring_from_hex = join '', map {length($_) == 4 ? $_ 
                                 : ('0' x (4 - length($_))) . $_} map {sprintf "%b", $_} 
                                 map {hex $_} split //, $self->{hexstring};
        my @bitlist_from_hex = split //, $bitstring_from_hex;
        $self->{bitlist} = \@bitlist_from_hex;
        $self->{size} = scalar @{$self->{bitlist}};
    }
    my $shorts_needed = int( (@{$self->{bitlist}} + 15) / 16 );
    @{$self->{_vector}} = map {unpack "n", pack("n", 0)} 0 .. $shorts_needed-1;
    my @interleaved = (0..$self->{size}-1, @{$self->{bitlist}}) 
                          [map {$_,$_+$self->{size}} (0 .. $self->{size}-1)];
    pairmap {$self->set_bit($a,$b)} @interleaved;
    $self->{bitlist} = undef;
    return $self;
}

##  Set the bit at the designated position to the value shown
sub set_bit {
    my $self = shift;
    my $posn = shift;
    my $val = shift;
    croak "incorrect value for a bit" unless $val =~ /\d/ &&  ($val == 0 or $val == 1);
    die "index range error" if  ($posn >= $self->{size}) or ($posn < - $self->{size});
    $posn = $self->{size} + $posn  if $posn < 0;
    my $block_index = int($posn / 16);
    my $shift = $posn & 0xF;
    my $cv = $self->{_vector}->[$block_index];
    if ( ( ( $cv >> $shift ) & 1 ) != $val) {
        $self->{_vector}->[$block_index] = $cv ^ (1 << $shift);
    }
}

##  Get the bit from the designated position. This method can also return a slice of a
##  bitvector.  HOWEVER, NOTE THAT THE SLICE IS RETURNED AS A LIST OF THE BITS IN THE
##  INDEX RANGE YOU SPECIFIED. You can either easily convert the list of bits returned
##  into a bitvector in your own code or, starting with Version 1.26, you can call the
##  get_slice() method.
sub get_bit {
    my $self = shift;
    my $pos = shift;
    unless (ref($pos) eq "ARRAY") {
        die "index range error" if  ($pos >= $self->{size}) or ($pos < - $self->{size});
        $pos = $self->{size} + $pos if $pos < 0;
        return ( $self->{_vector}->[int($pos/16)] >> ($pos&15) ) & 1;
    } 
#    my @slice = map $self->get_bit($_), (@$pos)[0..@$pos-1];
    my @slice = map $self->get_bit($_), (@$pos)[0..@$pos-2];
    return \@slice;
}

##  Get the slice of bits from the bitvector corresponding to the index range specified
##  by the argument.  The slice is returned as an instance of Algorithm::BitVector
sub get_slice {
    my $self = shift;
    my $index_range = shift;
    my $slice_bv =  Algorithm::BitVector->new( size => @$index_range - 1 );
    map $slice_bv->set_bit($_ - $index_range->[0], $self->get_bit($_)), @$index_range[0..@$index_range-2];
    return $slice_bv;
}

##  Set a slice of a BitVector from the bits in the argument BitVector object:
sub set_slice {
    my $self = shift;
    my $index_range = shift;
    my $values_bv = shift;
    die "the width of the index range for slice setting does not equal the size of the values array"
           unless @$index_range - 1 == $values_bv->length();
#           unless @$index_range == $values_bv->length();
    map $self->set_bit($_, $values_bv->get_bit($_ - $index_range->[0])), @$index_range[0..@$index_range-2];
}

##  Overloading of the string conversion operator.  Return the string representation
##  of a bitvector.
sub _str {
    my $self = shift;
    return join '', map $self->get_bit($_), 0 .. $self->{size}-1;
}

##  Overloading of the `+' operator. Concatenate the argument bitvectors. Return the
##  concatenated bitvector as a new BitVector instance.
sub _join {
    my ($bv1, $bv2) = @_;
    croak "Abort: The concatenation operator invoked with either undefined " .
        "or wrong types of operands: $!"
        unless UNIVERSAL::isa( $bv1, 'Algorithm::BitVector') and
        UNIVERSAL::isa( $bv2, 'Algorithm::BitVector');
    my $allbits = $bv1->_str() . $bv2->_str();
    return Algorithm::BitVector->new( bitstring => $allbits );
}

sub _compare {
    my ($bv1, $bv2) = @_;
    croak "Abort: The comparison operator invoked with either undefined " .
        "or wrong types of operands: $!"
        unless UNIVERSAL::isa( $bv1, 'Algorithm::BitVector') and
        UNIVERSAL::isa( $bv2, 'Algorithm::BitVector');
    my $bigint1 = Math::BigInt->from_bin( "$bv1" );
    my $bigint2 = Math::BigInt->from_bin( "$bv2" );
    return $bigint1->bcmp($bigint2);
}

sub deep_copy {
    my $self = shift;
    my $result_bv = Algorithm::BitVector->new( size => $self->{size} );
    foreach my $i (0..@{$result_bv->{_vector}}-1) {
        $result_bv->{_vector}->[$i] = $self->{_vector}->[$i];
    }
    return $result_bv;
}

## Invert the bits in the bitvector on which the method is invoked
## and return the result as a new bitvector.
sub _invert {
    my $self = shift;
    die "Abort: The operator '~' for bit inversion invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $result_bv = $self->deep_copy();
    foreach my $i (0..@{$result_bv->{_vector}}-1) {
        # The unary `~' operator may assume a 32-bit wide field:
        $result_bv->{_vector}->[$i] = ~ $result_bv->{_vector}->[$i] & 0x0000FFFF;
    }
    return $result_bv;
}

## Take a bitwise 'OR' of two bitvectors. Return the result as a new bitvector.  If
## the two bitvectors are not of the same size, pad the shorter one with zeros from
## the left.
sub _or {
    my ($bv1, $bv2) = @_;    
    croak "Abort: The `|' operator invoked with either undefined " .
        "or wrong types of operands: $!"
        unless UNIVERSAL::isa( $bv1, 'Algorithm::BitVector') and
        UNIVERSAL::isa( $bv2, 'Algorithm::BitVector');
    my ($bv3, $bv4);
    if ( $bv1->{size} < $bv2->{size} ) {
        $bv3 = $bv1->_resize_pad_from_left($bv2->{size} - $bv1->{size});
        $bv4 = $bv2;
    } elsif ( $bv1->{size} > $bv2->{size} ) {
        $bv3 = $bv1;
        $bv4 = $bv2->_resize_pad_from_left($bv1->{size} - $bv2->{size});
    } else {
        $bv3 = $bv1;
        $bv4 = $bv2;
    }
    my $result_bv = Algorithm::BitVector->new( size => $bv3->{size} );
    foreach my $i (0..@{$result_bv->{_vector}}-1) {
        # The binary `|' operator may assume 32-bit wide fields:
        $result_bv->{_vector}->[$i] = ($bv3->{_vector}->[$i] | $bv4->{_vector}->[$i] ) & 0x0000FFFF;
    }
    return $result_bv;
}

##  Resize a bitvector by padding with n 0's from the left. Return the result as a
##  new bitvector.
sub _resize_pad_from_left {
    my $self = shift;
    my $n = shift;
    my $new_str = '0' x $n . "$self";
    return Algorithm::BitVector->new( bitstring => $new_str );
}

##  Take a bitwise 'AND' of the bitvector on which the method is invoked with
##  the argument bitvector.  Return the result as a new bitvector.  If the two
##  bitvectors are not of the same size, pad the shorter one with zeros from the
##  left.
sub _and {
    my ($bv1, $bv2) = @_;    
    croak "Abort: The concatenation operator invoked with either undefined " .
        "or wrong types of operands: $!"
        unless UNIVERSAL::isa( $bv1, 'Algorithm::BitVector') and
        UNIVERSAL::isa( $bv2, 'Algorithm::BitVector');
    my ($bv3, $bv4);
    if ( $bv1->{size} < $bv2->{size} ) {
        $bv3 = $bv1->_resize_pad_from_left($bv2->{size} - $bv1->{size});
        $bv4 = $bv2;
    } elsif ( $bv1->{size} > $bv2->{size} ) {
        $bv3 = $bv1;
        $bv4 = $bv2->_resize_pad_from_left($bv1->{size} - $bv2->{size});
    } else {
        $bv3 = $bv1;
        $bv4 = $bv2;
    }
    my $result_bv = Algorithm::BitVector->new( size => $bv3->{size} );
    foreach my $i (0..@{$result_bv->{_vector}}-1) {
        # The binary bitwise `&' operator may assume 32-bit wide fields:
        $result_bv->{_vector}->[$i] = ($bv3->{_vector}->[$i] & $bv4->{_vector}->[$i] ) & 0x0000FFFF;
    }
    return $result_bv;
}

##  Take a bitwise 'XOR' of the bitvector on which the method is invoked with
##  the argument bitvector.  Return the result as a new bitvector.  If the two
##  bitvectors are not of the same size, pad the shorter one with zeros from the
##  left.
sub _xor {
    my ($bv1, $bv2) = @_;    
    croak "Abort: The xor operator invoked with either undefined " .
        "or wrong types of operands: $!"
        unless UNIVERSAL::isa( $bv1, 'Algorithm::BitVector') and
        UNIVERSAL::isa( $bv2, 'Algorithm::BitVector');
    my ($bv3, $bv4);
    if ( $bv1->{size} < $bv2->{size} ) {
        $bv3 = $bv1->_resize_pad_from_left($bv2->{size} - $bv1->{size});
        $bv4 = $bv2;
    } elsif ( $bv1->{size} > $bv2->{size} ) {
        $bv3 = $bv1;
        $bv4 = $bv2->_resize_pad_from_left($bv1->{size} - $bv2->{size});
    } else {
        $bv3 = $bv1;
        $bv4 = $bv2;
    }
    my $result_bv = Algorithm::BitVector->new( size => $bv3->{size} );
    foreach my $i (0..@{$result_bv->{_vector}}-1) {
        # The binary bitwise `^' operator may assume 32-bit wide fields:
        $result_bv->{_vector}->[$i] = ($bv3->{_vector}->[$i] ^ $bv4->{_vector}->[$i] ) & 0x0000FFFF;
    }
    return $result_bv;
}

# For the overloading of the iterator '<>' operator:
sub _iter {
    my $self = shift;
    my $pos = 0;
    $self->{_iterator} = BitVecIterator->new($self, $pos) unless $self->{_iter_called};
    &{$self->{_iterator}->next()};
}

{
    # This inner class needed for implementing iterator overloading:
    package BitVecIterator;
    sub new {
        my $self = [ $_[1], $_[2] ];
        bless $self, $_[0];
        $_[1]->{_iter_called} = 1;
        return $self;
    }
    sub next {
        my $self = shift;
        my $bitvec = $self->[0];
        # The anonymous subroutine that follows is a closure over the variables
        # incorporated in it:
        return sub { 
            if ($self->[1] >= $bitvec->{size}) {
                delete $bitvec->{_iter_called};
                return;
            }
            my $bit = $bitvec->get_bit($self->[1]); 
            $self->[1] =  $self->[1] + 1;
            return $bit;
        } 
    }
}

# for the overloading of the numification operator:
sub _int {
    my $self = shift;
    return $self->int_value();
}

##  Divides an even-sized bitvector into two and returns the two halves as a
##  list of two bitvectors.
sub divide_into_two {
    my $self = shift;
    die "Abort: The divide_into_two() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    die "The bitvector to be divided must have even number of bits: $!"
        if $self->{size} % 2;
    my @outlist1 = ();
    foreach my $i (0..$self->{size} / 2 - 1) {
        push @outlist1, $self->get_bit($i);
    }
    my @outlist2 = ();
    foreach my $i ( ($self->{size} / 2) .. ($self->{size} - 1) ) {
        push @outlist2, $self->get_bit($i);
    }
    return Algorithm::BitVector->new( bitlist => \@outlist1 ), 
           Algorithm::BitVector->new( bitlist => \@outlist2 );
}

##  Permute a bitvector according to the indices shown in the second argument list.
##  Return the permuted bitvector as a new bitvector.
sub permute {
    my $self = shift;
    die "Abort: The permute() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $permute_list = shift;
    die "Bad permutation index in your permutation list" 
        if max(@$permute_list) > $self->{size} - 1;
    my @outlist = ();
    foreach my $index (@$permute_list) { 
        push @outlist, $self->get_bit($index);
    }
    return Algorithm::BitVector->new( bitlist => \@outlist );
}

##  Unpermute the bitvector according to the permutation list supplied as the
##  second argument.  If you first permute a bitvector by using permute() and
##  then unpermute() it using the same permutation list, you will get back the
##  original bitvector.
sub unpermute {
    my $self = shift;
    die "Abort: The unpermute() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $permute_list = shift;
    die "Bad permutation index in your permutation list: $!" 
        if max(@$permute_list) > $self->{size} - 1;
    die "Size of the permute list for unpermuting not consistent with the size of the bet vector:$!"
        unless $self->{size} == @$permute_list;
    my $out_bv = Algorithm::BitVector->new( size => $self->{size} );
    foreach my $i (0..@$permute_list-1) {
        $out_bv->set_bit( $permute_list->[$i], $self->get_bit($i) );
    }
    return $out_bv;
}

##  Write the bitvector to the file object file_out.  (A file object is returned
##  by a call to open()). Since all file I/O is byte oriented, the bitvector must
##  be multiple of 8 bits. Each byte treated as MSB first (0th index).
sub  write_to_file {
    my $self = shift;
    die "Abort: The write_to_file() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $file_out = shift;
    my $err_str = "Only a bitvector whose length is a multiple of 8 can " .
                  "be written to a file.  Use the padding functions to satisfy " .
                  "this constraint.";
    $self->{FILEOUT} = $file_out unless $self->{FILEOUT};
    die $err_str if $self->{size} % 8;
    for my $byte (0..$self->{size}/8 - 1){
        my $value = 0;
        foreach my $bit (0..7) {
            $value += $self->get_bit( $byte*8+(7 - $bit) ) << $bit;
        }
        syswrite $file_out, chr($value), 1;
    }
}

##  For closing a file object that was used for reading the bits into one or more
##  BitVector objects.
sub close_file_handle {
    my $self = shift;
    die "Abort: The close_file_handle() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    die "No open file currently associated with the file handle: $!" 
        unless $self->{FILEIN};
    close $self->{FILEIN};
}

## Return the integer value of a bitvector.  If the original integer from which the
## bitvector was constructed is a Math::BigInt object, then return the string
## representation of the integer value.
sub int_value {
    my $self = shift;
    die "Abort: The int() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $int_value;
    if (defined($self->{intVal}) && (ref($self->{intVal}) eq 'Math::BigInt')) {
        $int_value = $self->{intVal}->bstr();      
    } else {
        $int_value = 0;
        foreach my $i (0..$self->{size}-1) {
            $int_value += $self->get_bit($i) * ( 2 ** ( $self->{size} - $i - 1 ) );
        }
    }
    return $int_value;
}

##  Return the text string formed by dividing the bitvector into bytes from the
##  left and replacing each byte by its ASCII character (this is a useful thing
##  to do only if the length of the vector is an integral multiple of 8 and every
##  byte in your bitvector has a print representation)
sub get_bitvector_in_ascii {
    my $self = shift;
    die "Abort: The get_bitvector_in_ascii() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    die "\nThe bitvector for get_text_from_bitvector() must be an integral multiple of 8 bits: $!"
        if $self->{size} % 8;
    my $ascii = '';
    for (my $i=0; $i < $self->{size}; $i += 8) {
#        $ascii .= chr oct "0b". join '', @{$self->get_bit([$i..$i+7])};
        $ascii .= chr oct "0b". join '', @{$self->get_bit([$i..$i+8])};
    }
    return $ascii;
}

# for backward compatibility:
sub get_text_from_bitvector {
    my $self = shift;
    $self->get_bitvector_in_ascii(@_);
}

##  Return a string of hex digits by scanning the bits from the left and
##  replacing each sequence of 4 bits by its corresponding hex digit (this is a
##  useful thing to do only if the length of the vector is an integral multiple
##  of 4)
#sub get_hex_string_from_bitvector {
sub get_bitvector_in_hex {
    my $self = shift;
    die "Abort: The get_bitvector_in_hex() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    die "\nThe bitvector for get_hex_from_bitvector() must be a multiple of 4 bits: $!" 
        if $self->{size} % 4;
    my $hex = '';
    for (my $i=0; $i < $self->{size}; $i += 4) {
#        $hex .= sprintf "%x", oct "0b". join '', @{$self->get_bit([$i..$i+3])};
        $hex .= sprintf "%x", oct "0b". join '', @{$self->get_bit([$i..$i+4])};
    }
    return $hex;
}

# for backward compatibility:
sub get_hex_string_from_bitvector {
    my $self = shift;
    $self->get_bitvector_in_hex(@_);    
}

##  Read blocksize bits from a disk file and return a BitVector object containing
##  the bits.  If the file contains fewer bits than blocksize, construct the
##  BitVector object from however many bits there are in the file.  If the file
## contains zero bits, return a BitVector object of size attribute set to 0.
sub read_bits_from_file {
    my $self = shift;
    die "Abort: The read_bits_from_file() method invoked on an object that is " .
        "not of type Algorithm::BitVector"
        unless UNIVERSAL::isa( $self, 'Algorithm::BitVector');
    my $blocksize = shift;
    my $error_str = "You need to first construct a BitVector object with a filename as  argument";
    die "$error_str" unless $self->{filename};
    die "block size must be a multiple of 8" if $blocksize % 8;
    my $bitstr = _readblock( $blocksize, $self );
    if (length $bitstr == 0) {
        return Algorithm::BitVector->new( size => 0 );
        print "file has no bits\n";       
    } else {
        return Algorithm::BitVector->new( bitstring => $bitstr );
    }
}

##  For an in-place left circular shift by n bit positions
sub _lshift {
    my $self = shift;
    my $n = shift;
    die "Circular shift of an empty vector makes no sense" unless $self->{size};
    return $self >> abs($n) if $n < 0;
    foreach my $i (0..$n-1) {
        $self->_circular_rotate_left_by_one();
    }
    return $self;
}

##  For an in-place right circular shift by n bit positions
sub _rshift {
    my $self = shift;
    my $n = shift;
    die "Circular shift of an empty vector makes no sense" unless $self->{size};
    return $self << abs($n) if $n < 0;
    foreach my $i (0..$n-1) {
        $self->_circular_rotate_right_by_one();
    }
    return $self;
}

##  For a one-bit in-place left circular shift
sub _circular_rotate_left_by_one {
    my $self = shift;
    my $max_index = int( ($self->{size} - 1)  / 16 );
    my $left_most_bit = $self->{_vector}->[0] & 1;
    $self->{_vector}->[0] = $self->{_vector}->[0] >> 1;
    foreach my $i (1 .. $max_index) {
        my $left_bit = $self->{_vector}->[$i] & 1;
        $self->{_vector}->[$i] = $self->{_vector}->[$i] >> 1;
        $self->{_vector}->[$i-1] |= $left_bit << 15;
    }
    $self->set_bit($self->{size} - 1, $left_most_bit);
}

##  For a one-bit in-place right circular shift
sub _circular_rotate_right_by_one {
    my $self = shift;
    my $max_index = int( ($self->{size} - 1)  / 16 );
    my $right_most_bit = $self->get_bit( $self->{size} - 1);
    $self->{_vector}->[$max_index] &= ~0x8000;
    $self->{_vector}->[$max_index] = $self->{_vector}->[$max_index] << 1;
    for (my $i=$max_index-1; $i > -1; $i -= 1) {
        my $right_bit = $self->{_vector}->[$i] & 0x8000;
        $self->{_vector}->[$i] &= ~0x8000;
        $self->{_vector}->[$i] = $self->{_vector}->[$i] << 1;
        $self->{_vector}->[$i+1] |= $right_bit >> 15;
    }
    $self->set_bit(0, $right_most_bit);
}

## Pad a bitvector with n zeros from the left
sub pad_from_left {
    my $self = shift;
    my $n = shift;
    die "a negative value for index positions not allowed for padding from left" if $n < 0;
    my $new_str = ('0' x $n) . "$self";
    my $new_bitvec = Algorithm::BitVector->new( bitstring => $new_str );
    $self->{size} = length $new_str;
    $self->{_vector} = $new_bitvec->{_vector};
    return $self;
}

## Pad a bitvector with n zeros from the right
sub pad_from_right {
    my $self = shift;
    my $n = shift;
    my $new_str = "$self" . ('0' x $n);
    my $new_bitvec = Algorithm::BitVector->new( bitstring => $new_str );
    $self->{size} = length $new_str;
    $self->{_vector} = $new_bitvec->{_vector};
    return $self;
}

##  Resets a previously created BitVector to either all zeros or all ones                  
##  depending on the argument val. 
sub reset {
    my $self = shift;
    my $val = shift;
    die "Incorrect argument to reset(): $!" unless ($val == 0) or ($val == 1);
    my $reset_bv = Algorithm::BitVector->new( bitstring => ("$val" x $self->{size}) );
    $self->{_vector} = $reset_bv->{_vector};
}

## Return the number of bits set in a BitVector instance.                                 
sub count_bits {
    my $self = shift;
    return reduce {$a + $b} split //, "$self";
}

##  Changes the bit pattern associated with a previously constructed BitVector             
##  instance.  The allowable modes for changing the internally stored bit pattern          
##  are the same as for the constructor.                                                   
sub set_value {
    my $self = shift;
    my $reset_bv = Algorithm::BitVector->new( @_ );
    $self->{_vector} = $reset_bv->{_vector};
    $self->{size} = $reset_bv->{size};
}


##  This method for counting the set bits is much faster for sparse bitvectors.
##  Note, however, that count_bits() may work much faster for dense-packed
##  bitvectors.
sub count_bits_sparse {
    my $self = shift;
    my $num = 0;
    foreach my $intval (@{$self->{_vector}}) {
        next if $intval == 0;
        my ($c, $iv) = (0, $intval);
        while ($iv > 0) {
            $iv = $iv & ($iv - 1);
            $c++;
        }
        $num += $c;
    }
    return $num;
}

##  Computes the Jaccard similarity coefficient between two bitvectors                    
sub jaccard_similarity {
    my $self = shift;
    my $other = shift;
    die "Jaccard called on two zero vectors --- NOT ALLOWED: $!" 
        if (int($self) == 0) && (int($other) == 0);
    die "Jaccard called on vectors of unequal size --- NOT ALLOWED: $!"
        if $self->{size} != $other->{size};
    my $intersection = $self & $other;
    my $union = $self | $other;
    return $intersection->count_bits_sparse() / $union->count_bits_sparse();
}

##  Computes the Jaccard distance between two bitvectors                                  
sub jaccard_distance {
    my $self = shift;
    my $other = shift;
    die "Jaccard called on vectors of unequal size --- NOT ALLOWED: $!"
        if $self->{size} != $other->{size};
    return 1 - $self->jaccard_similarity( $other );
}

##  Computes the Hamming distance between two bitvectors                                  
sub hamming_distance {
    my $self = shift;
    my $other = shift;
    die "hamming_distance() called on vectors of unequal size --- NOT ALLOWED: $!"
        if $self->{size} != $other->{size};
    my $diff = $self ^ $other;
    return $diff->count_bits_sparse();
}

##  This method calculates the position of the next set bit at or after the current
##  position index. It returns -1 if there is no next set bit.  Logic based on the
##  contributions by Jason Allum and John Gleeson to the Python version of this
##  module.
sub next_set_bit {
    my $self = shift;
    my $from_index = shift || 0;
    die "The from_index must be nonnegative: $!" unless $from_index >= 0;
    my $i = $from_index;
    my $v = $self->{_vector};
    my $l = scalar @$v;
    my $o = $i >> 4;
    my $s = $i & 0x0F;
    $i = $o << 4;
    while ($o < $l) {
        my $h = $v->[$o];
        if ($h) {
            $i += $s;
            my $m = 1 << $s;
            while ($m != (1 << 0x10)) {
                return $i if $h & $m;
                $m <<= 1;
                $i += 1;
            }
        } else {
            $i += 0x10;
        }
        $s = 0;
        $o += 1;
    }
    return -1;
}

##  For a bit that is set at the argument 'position', this method returns how many
##  bits are set to the left of that bit.  For example, in the bit pattern
##  000101100100, a call to this method with position set to 9 will return 4.
sub rank_of_bit_set_at_index {
    my $self = shift;    
    my $position = shift;
    die "The bitvector has no bits set at the position in the call to rank_of_bit_set_at_index(): $!"
        unless $self->get_bit($position);          
    my $bv_slice = Algorithm::BitVector->new( bitlist => $self->get_bit([0..$position]) );
    return $bv_slice->count_bits();
}

##  Determines whether the integer value of a bitvector is a power of 2.     
sub is_power_of_2 {
    my $self = shift;    
    return 0 if int($self) == 0;
    my $bv = $self & Algorithm::BitVector->new( intVal => int($self) - 1);
    return 1 if int($bv) == 0;
    return 0;
}

##  Faster version of is_power_of2() for sparse bitvectors  
sub is_power_of_2_sparse {
    my $self = shift;      
    return 1 if $self->count_bits_sparse() == 1;
    return 0;
}

##  Returns a new bitvector by reversing the bits in the bitvector on which the          
##  method is invoked.                                                                     
sub reverse {
    my $self = shift;
    my @reverseList = ();
    for (my $i=1; $i < $self->{size} + 1; $i++) {
        push @reverseList, $self->get_bit( -$i );
    }
    return Algorithm::BitVector->new( bitlist => \@reverseList );
}

##  Using Euclid's Algorithm, returns the greatest common divisor of the integer           
##  value of the bitvector on which the method is invoked and the integer value           
##  of the argument bitvector.                                                            
sub  gcd {
    my $self = shift;
    my $other = shift;
    my ($a,$b) = (int($self), int($other));
    ($a,$b) = ($b,$a) if $a < $b;
    while ($b != 0) {
        ($a, $b) = ($b, $a % $b);
    }
    return Algorithm::BitVector->new( intVal => $a );
}

##  Calculates the multiplicative inverse of the bitvector on which the method is
##  invoked modulo the bitvector that is supplied as the argument. Code based on
##  Extended Euclid's Algorithm.
sub multiplicative_inverse {
    my $self = int( shift );
    my $modulus = int( shift );
    my ($mod, $num) = ($modulus, $self);
    my ($x, $x_old) = (0, 1);
    my ($y, $y_old) = (1, 0);
    while ($mod) {
        my $quotient = int($num / $mod);
        ($num, $mod) = ($mod, $num % $mod);
        ($x, $x_old) = ($x_old - $x * $quotient, $x);
        ($y, $y_old) = ($y_old - $y * $quotient, $y);
    }
    if ($num != 1) {
        return 0;
    } else {
        my $MI = ($x_old + $modulus) % $modulus;
        return Algorithm::BitVector->new( intVal => $MI );
    }
}

##  For a one-bit in-place left non-circular shift.  Note that the bitvector size
##  does not change.  The leftmost bit that moves past the first element of the
##  bitvector is discarded and rightmost bit of the returned vector is set to zero.
sub _shift_left_by_one {
    my $self = shift;
    my $size = @{$self->{_vector}};
    my @left_most_bits = map {$_ & 1} @{$self->{_vector}};
    push @left_most_bits, $left_most_bits[0];
    shift @left_most_bits;
    @{$self->{_vector}} = map {$_ >> 1} @{$self->{_vector}};
    my @a = @{$self->{_vector}};
    my @b = map {$_ << 15} @left_most_bits;
    my @interleaved =  ( @a, @b )[ map { $_, $_ + @a } ( 0 .. $#a ) ];
    @{$self->{_vector}} = pairmap {$a | $b} @interleaved;
    $self->set_bit(-1,0);
}

##  For an in-place left non-circular shift by n bit positions.  The bits shifted
##  out at the left are discarded. The new bit positions on the right are filled with
##  zeros
sub shift_left {
    my $self = shift;
    my $n = shift;
    foreach my $i (0..$n-1) {
        $self->_shift_left_by_one();
    }
    return $self;
}

##  For a one-bit in-place right non-circular shift.  Note that bitvector size does
##  not change.  The rightmost bit that moves past the last element of the bitvector
##  on the right is discarded and the leftmost bit of the returned vector is set to
##  zero.
sub _shift_right_by_one {
    my $self = shift;
    my $size = @{$self->{_vector}};
    my @right_most_bits = map {$_ & 0x8000} @{$self->{_vector}};
    @{$self->{_vector}} = map { $_ & ~0x8000 } @{$self->{_vector}};
    unshift @right_most_bits, 0;
    pop @right_most_bits;
    @{$self->{_vector}} = map {$_ << 1} @{$self->{_vector}};
    my @a = @{$self->{_vector}};
    my @b = map {$_ >> 15} @right_most_bits;
    my @interleaved =  ( @a, @b )[ map { $_, $_ + @a } ( 0 .. $#a ) ];
    @{$self->{_vector}} = pairmap {$a | $b} @interleaved;
    $self->set_bit(0,0);
}

##  For an in-place right non-circular shift by n bit positions.  The n bits that
##  move past the last element of the bitvector on the right are discarded and
##  leftmost new n bit positions filled with zeros.
sub shift_right {
    my $self = shift;
    my $n = shift;
    foreach my $i (0..$n-1) {
        $self->_shift_right_by_one();
    }
    return $self;
}

##  In the set of polynomials defined over GF(2), multiplies the bitvector on which
##  the method is invoked with the argument bitvector.  Returns the product
##  bitvector.  Note that this method carries out straight polynomial multiplication
##  as opposed to modulo polynomial multiplication. As a result, the highest power of
##  the result polynomial will ALWAYS be greater than the highest powers of the
##  argument polynomials for non-trivial multiplications.
sub gf_multiply {
    my $self = shift;
    my $b = shift;
    my $a = $self->deep_copy();
    my $b_copy = $b->deep_copy();
    my $a_highest_power = $a->{size} - $a->next_set_bit(0) - 1;
    my $b_highest_power = $b->{size} - $b_copy->next_set_bit(0) - 1;
    my $result = Algorithm::BitVector->new( size => $a->{size} + $b_copy->{size} );
    $a->pad_from_left( $result->{size} - $a->{size} );
    $b_copy->pad_from_left( $result->{size} - $b_copy->{size} );
    my @b_list = split //, "$b_copy"; 
    my @enum = (0..@b_list-1, @b_list) [map {$_, $_+ @b_list} (0 .. @b_list - 1)];
    for (my $i=0; $i < @enum-1; $i = $i + 2) {
        if ($enum[$i+1]) {
            my $power = $b_copy->{size} - $enum[$i] - 1;
            my $a_copy = $a->deep_copy();
            $a_copy->shift_left( $power );
            $result ^=  $a_copy;
        }
    }
    return $result;
}

##  Carries out modular division of a bitvector by the modulus bitvector mod in            
##  GF(2^n) finite field.  Returns both the quotient and the remainder.                    
sub gf_divide_by_modulus {
    my $num = shift;    
    my $mod = shift;
    my $n = shift;
    die "Modulus bit pattern too long" if $mod->{size} > $n + 1;
    my $quotient = Algorithm::BitVector->new( intVal => 0, size => $num->{size} );
    my $remainder = $num->deep_copy();
    for (my $i=0; $i < $num->{size}; $i++) {
        my $mod_highest_power = $mod->{size} - $mod->next_set_bit(0) - 1;
        my $remainder_highest_power;
        if ($remainder->next_set_bit(0) == -1) {
            $remainder_highest_power = 0;
        } else {
            $remainder_highest_power = $remainder->{size} - $remainder->next_set_bit(0) - 1;
        }
        if (($remainder_highest_power < $mod_highest_power) or (int($remainder) == 0)) {
            last;
        } else {
            my $exponent_shift = $remainder_highest_power - $mod_highest_power;
            $quotient->set_bit($quotient->{size} - $exponent_shift - 1, 1);
            my $quotient_mod_product = $mod->deep_copy();
            $quotient_mod_product->pad_from_left($remainder->{size} - $mod->{size});
            $quotient_mod_product->shift_left($exponent_shift);
            $remainder ^= $quotient_mod_product;
        }
    }
    if ($remainder->{size} > $n) {
        $remainder = Algorithm::BitVector->new( 
#           bitlist => $remainder->get_bit([$remainder->{size}-$n .. $remainder->{size}-1]));
           bitlist => $remainder->get_bit([$remainder->{size}-$n .. $remainder->{size}]));
    }
    return ($quotient, $remainder);
}

##  Multiplies a bitvector with the bitvector b in GF(2^n) finite field with the           
##  modulus bit pattern set to mod                                                         
sub gf_multiply_modular {
    my $self = shift; 
    my $b = shift;
    my $mod = shift;
    my $n = shift;
    my $a_copy = $self->deep_copy();
    my $b_copy = $b->deep_copy();
    my $product = $a_copy->gf_multiply($b_copy);
    my ($quotient, $remainder) = $product->gf_divide_by_modulus($mod, $n);
    return $remainder
}

##  Returns the multiplicative inverse of a vector in the GF(2^n) finite field             
##  with the modulus polynomial set to mod                                                 
sub  gf_MI {
    my $num = shift;
    my $mod = shift;
    my $n = shift;
    my ($NUM, $MOD) = ($num->deep_copy(), $mod->deep_copy());
    my $x = Algorithm::BitVector->new( size => $mod->{size} );
    my $x_old = Algorithm::BitVector->new( intVal => 1, size => $mod->{size} );
    my $y = Algorithm::BitVector->new( intVal => 1, size => $mod->{size} );
    my $y_old = Algorithm::BitVector->new( size => $mod->{size} );
    my ($quotient, $remainder);
    while (int($mod)) {
        ($quotient, $remainder) = $num->gf_divide_by_modulus($mod, $n);
        ($num, $mod) = ($mod, $remainder);
        ($x, $x_old) = ($x_old ^ $quotient->gf_multiply($x), $x);
        ($y, $y_old) = ($y_old ^ $quotient->gf_multiply($y), $y);
    }
    if (int($num) != 1) {
        return "NO MI. However, the GCD of $NUM and $MOD is $num\n";
    } else {
        my $z = $x_old ^ $MOD;
        ($quotient, $remainder) = $z->gf_divide_by_modulus($MOD, $n);
        return $remainder;
    }
}

##  Returns a list of the consecutive runs of 1's and 0's in the bitvector.               
##  Each run is either a string of all 1's or a string of all 0's.                         
sub runs {
    my $self = shift; 
    die "An empty vector has no runs" if $self->{size} == 0;
    my @allruns = ();
    my $run = '';
    my $previous_bit = $self->get_bit(0);
    if ($previous_bit == 0) {
        $run = '0';
    } else {
        $run = '1';
    }
    my @bitlist = split //, "$self";
    shift @bitlist;
    foreach my $bit (@bitlist) {
        if (($bit == 0) && ($previous_bit == 0)) {
            $run .= '0';
        } elsif (($bit == 1) && ($previous_bit == 0)) {
            push @allruns, $run;
            $run = '1';
        } elsif (($bit == 0) && ($previous_bit == 1)) {
            push @allruns, $run;
            $run = '0';
        } else {
            $run .= '1';
        }
        $previous_bit = $bit;
    }
    push @allruns, $run;
    return @allruns
}

##  This method returns the "canonical" form of a BitVector instance that is obtained by
##  circularly rotating the bit pattern through all possible shifts and returning the
##  pattern with the maximum number of leading zeros.  This is also the minimum int value
##  version of a bit pattern.  This method is useful in the "Local Binary Pattern"
##  algorithm for characterizing image textures.  If you are curious as to how, see my
##  tutorial on "Measuring Texture and Color in Images."
sub min_canonical {
    my $self = shift; 
    my @intvals_for_circular_shifts = map {int($self << 1)} 0 .. $self->length();
    my $min_int_val = min @intvals_for_circular_shifts;
    return Algorithm::BitVector->new( intVal => $min_int_val, size => $self->length() );
}

##  Check if the integer value of the bitvector is a prime through the Miller-Rabin
##  probabilistic test of primality.  If not found to be a composite, estimate the
##  probability of the bitvector being a prime using this test.
sub test_for_primality {
    my $p = int(shift);
    die "\nThe primality test method test_for_primality() is intended for only " .
        "small integers --- integers that are relatively small in relation to " .
        "the largest integer that can fit Perl's 4-byte int representation:$!"
        if $p > 0x7f_ff_ff_ff;
    return "is NOT a prime" if $p == 1;
    my @probes = (2,3,5,7,11,13,17);
    foreach my $a (@probes) {
        return "is a prime" if $a == $p;
    }
    return "is NOT a prime" if any {$p % $_ == 0} @probes;
    my ($k, $q) = (0, $p-1);
    while (! ($q & 1)) {
        $q >>= 1;
        $k++;
    }
    foreach my $a (@probes) {
        my $a_raised_to_q = _powmod_small_ints($a, int($q), $p);
        next if $a_raised_to_q == 1 or $a_raised_to_q == $p - 1;
        my $a_raised_to_jq = $a_raised_to_q;
        my $primeflag = 0;
        foreach my $j (0..$k-1) {
            $a_raised_to_jq = _powmod_small_ints($a_raised_to_jq, 2, $p);
            if ($a_raised_to_jq == $p-1) {
                $primeflag = 1;
                last;
            }
        }
        return "is NOT a prime" unless $primeflag;
    }
    my $probability_of_prime = 1 - 1.0/(4 ** @probes);
    return "is a prime with probability $probability_of_prime";
}

##  This routine is for modular exponentiation of small integers, meaning the
##  integers that can be accommodated (before and after exponentiation) in the native
##  4-byte int representation.  For larger integers, a call to this function should
##  be replaced by a call to modular exponentiation of the Math::BigInt module.
sub _powmod_small_ints {
    my $base = shift;
    my $exponent = shift;
    my $mod = int(shift);
    warn "This is just a warning: The modular exponentiation method is not meant for very large numbers (IMPORTANT: This is just a very rough check on the size of the numbers involved)"
        if any {$_ > 0x0f_ff_ff_ff} (int($base), int($exponent), int($mod));
    my $result = 1;
    my $a = int($base);
    my $b = $exponent;
    while (int($b) > 0) {
        $result = ($result * $a) % $mod if int($b) & 1;
        $b = $b >> 1;
        $a = ($a * $a) % $mod;        
    }
    return $result;
}

##  This method is for a generating a bit pattern of a given size with random bits.
sub gen_random_bits {
    my $self = shift;
    my $width = shift;
    my $candidate_bits = "0b" . join '', Math::Random::random_uniform_integer($width, 0, 1);
    my $candidate = oct $candidate_bits;
    $candidate |= 1;
    $candidate |= (1 << $width-1);
    $candidate |= (2 << $width-3);
    return Algorithm::BitVector->new( intVal => $candidate );
}

sub length {
    my $self = shift;
    return $self->{size};
}

sub _check_for_illegal_params {
    my @params = @_;
    my @legal_params = qw / filename
                            size
                            intVal
                            bitlist
                            bitstring
                            hexstring
                            textstring
                          /;
    my $found_match_flag;
    foreach my $param (@params) {
        foreach my $legal (@legal_params) {
            $found_match_flag = 0;
            if ($param eq $legal) {
                $found_match_flag = 1;
                last;
            }
        }
        last if $found_match_flag == 0;
    }
    return $found_match_flag;
}

1;


=pod

=head1 NAME

Algorithm::BitVector --- A memory efficient packed representation of arbitrary sized
bit arrays and for logical and arithmetic operations on such arrays.

=head1 SYNOPSIS

    use Algorithm::BitVector;

    # Constructing a given sized bitvector of all zeros:
    $bv = Algorithm::BitVector->new( size => 7 );
    print "$bv\n";                                   # 0000000

    # Constructing a bitvector whose integer value is specified:
    $bv = Algorithm::BitVector->new( intVal => 123456 );
    print "$bv\n";                                    # 11110001001000000                          
    print int($bv);                                   # 123456

    # Constructing a bitvector from a very large integer:
    use Math::BigInt;
    $x = Math::BigInt->new('12345678901234567890123456789012345678901234567890');
    $bv = Algorithm::BitVector->new( intVal => $x );
         
    # Constructing a bitvector from a given bit string:
    $bv = Algorithm::BitVector->new( bitstring => '00110011' );
       
    # Constructing a bitvector from an ASCII text string:
    $bv = Algorithm::BitVector->new( textstring => "hello\njello" );

    # Constructing a bitvector from a hex string:
    $bv = Algorithm::BitVector->new( hexstring => "68656c6c6f" );

    # Constructing a bitvector from a bit list passed as an anonymous array:
    $bv = Algorithm::BitVector->new( bitlist => [1, 1, 0, 1] );

    # Constructing a bitvector from the contents of a disk file:
    $bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
    $bv1 = $bv->read_bits_from_file(64);         # bitvector from the first 64 bits
                                                 # and so on


=head1 CHANGES

Version 1.26 incorporates the following changes: (1) It allows you to carry out
slice-based set and get operations on a BitVector object. The two new methods for
these operations are named C<get_slice()> and C<set_slice()>. (2) It includes a new
method named C<min_canonical()> that returns a circularly rotated version of a
BitVector with the least integer value.  For obvious reasons, this version would also
have the largest number of leading zeros. And (3) It fixes a bug in the
implementation of the method C<gf_divide_by_modulus()>.

Version 1.25 incorporates bugfix for the case when you try to construct a bitvector
of a specified length from a large integer that is supplied to the module constructor
as a C<Math::BigInt> object.

Version 1.24 includes in the C<Makefile.PL> file the minimum version restriction on
the C<List::Util> module that is imported.

Version 1.23 mentions the required modules in the C<Makefile.PL> file but with no
minimum version numbers.  Additionally, the documentation associated with the methods
was significantly upgraded in this version.

Version 1.22 removes the Perl version restriction from the module and the
C<Makefile.PL> files and the C<PREREQ_PM> restrictions from the C<Makefile.PL> file.

Version 1.21 fixes a bug in the code for the Miller-Rabin primality test function
C<test_for_primality()>.  This version also places a hard limit on the size of the
integers that are allowed to be tested for primality.

Version 1.2 fixes an important bug in creating bitvectors from the contents of a disk
file.  This version also includes corrections for some of the documentation errors
discovered.

Version 1.1 incorporates additional type checking on the operands for the overloaded
operators.  Also fixed some minor documentation formatting issues.

=head1 DESCRIPTION

My main motivation for creating this module was to provide the students at Purdue and
elsewhere with a Perl class whose API is the same as that of my Python based
C<BitVector> module that appears to have become popular for prototyping algorithms
for cryptography and hash functions.

This module stores the bits of a bitvector in 16-bit unsigned shorts.  As you can see
in the constructor code for C<new()>, after resolving the arguments with which the
constructor is called, the very first thing the constructor does is to figure out how
many of those 2-byte shorts it needs for the bits. That does not imply that the size
of a bit array that is stored in a bitvector must be a multiple of 16.  B<A bitvector
can be of any size whatsoever.> The C<Algorithm::BitVector> class keeps track of the
number of bits through its C<size> instance variable.

Note that, except for one case, the constructor must be called with a single keyword
argument, which determines how the bitvector will be constructed.  The single
exception to this rule is for the keyword argument C<intVal> which you would normally
use for constructing a bitvector from an integer.  The additional option you can
supply with C<intVal> is C<size>.  When both C<intVal> and C<size> are specified in a
constructor call, you get a bitvector of the specified size provided the value
supplied for C<size> is larger than what it takes to accommodate the bits for the
C<intVal> integer.

In addition to constructing bitvectors from integers, this module can also construct
bitvectors from bit strings, from ASCII text strings, from hex strings, from a list
of bits, and from the contents of a file.  With regards to constructing bitvectors
from integers, the module can construct very large bitvectors from very large
integers stored as C<Math::BigInt> objects.

=head1 OVERLOADED OPERATORS

The following C<use overload> declaration in the module gives the list of the
overloaded operators. Since C<fallback> is set to 1, several other operators become
overloaded by autogeneration from those shown below.  For example, overloading of the
3-way numerical comparison operator C<< <=> >> automatically overloads the C<< < >>,
C<< <= >>, C<< > >>, C<< >= >>, C<< == >>, and C<< != >> operators.

    use overload  '+'        =>    '_add',
                  '""'       =>    '_str',
                  '0+'       =>    '_int',
                  '~'        =>    '_invert',
                  '|'        =>    '_or',
                  '&'        =>    '_and',
                  '^'        =>    '_xor',
                  '<=>'      =>    '_compare',
                  '<<'       =>    '_lshift',
                  '>>'       =>    '_rshift',
                  '<>'       =>    '_iter',
                  'fallback' =>    1;

It is B<important> to remember that the overloadings for the `C<<< << >>>' and `C<<<
>> >>>' operators are for B<circular> left and right shifts (their usual meaning as
bitwise operators is for non-circular shifts).  This was done because the
applications for which this module is intended is more likely to use circular shifts
of bit fields than non-circular shifts.  You can still carry out non-circular shifts
by calling the methods C<shift_left()> and C<shift_right()> as illustrated elsewhere
in this documentation.

Another B<important> thing to bear in mind is the overloading of the `C<+>' operator.
It is B<NOT> addition.  On the other hand, it is a concatenation of the two operand
bitvectors.  This was done to keep the usage of this operator the same as in the
Python version of this module.

By virtue of how the operators are overloaded, you can make the calls listed in the
rest of this section.  To illustrate these calls, I will use the following two bit
vectors:

    $bv1 = Algorithm::BitVector->new( bitstring => "111000" );
    $bv2 = Algorithm::BitVector->new( bitstring => "000101000" );

These two bitvectors are intentionally of different lengths to illustrate what role
the size differences play in how the various operators work.

=over 4

=item B<Concatenating two bitvectors:>

    $bv3 = $bv1 + $bv2;                          # 111000000101000

The concatenation of two bitvectors is returned as a new bitvector. This is made
possible by the overload definition for the C<+> operator.

Note that the following also works:

    print $bv1 . "hello";                        # 111000hello

In this case, Perl implicitly converts the left operand of the `.' operator into a
string (which is made possible by the overloading for the stringification operator in
this module) and then returns the result as a string.

=item B<Creating the string representation of a bitvector:>

    print "$bv1";                                # 111000   

This is made possible for the overload definition for the C<""> operator.

=item B<Converting a bitvector to its integer value:>

    print int($bv1);                             # 56

This is made possible by the overload definition for the C<0+> operator.

=item B<Inverting a bitvector>

    $bv3 = ~ $bv1;
    print $bv3;                                  # 000111

This is made possible by the overload definition for the C<~> operator.  The original
bitvector on which this unary operator is invoked remains unchanged.

=item B<Taking logical OR of two bitvectors:>

    $bv3 = $bv1 | $bv2;                          # 000111000 

When two bitvectors are of unequal length (as is the case here), the shorter vector
is zero-padded on the left to equalize their lengths before the application of the
logical operation.  If this auto-padding property is not something you want, you
should check the lengths of the argument bitvectors in your own script before
invoking this operator. The result of the logical OR operation is returned as a new
bitvector.  The two operand bitvectors remain unchanged.

=item B<Taking logical AND of two bitvectors:>

    $bv3 = $bv1 & $bv2;                          # 000101000

When two bitvectors are of unequal length (as is the case here), the shorter vector
is zero-padded on the left to equalize their lengths before the application of the
logical operation. If this auto-padding property is not something you want, you
should check the lengths of the argument bitvectors in your own script before
invoking this operator.  The result of the logical AND operation is returned as a new
bitvector.  The two operand bitvectors remain unchanged.


=item B<Taking logical XOR of two bitvectors:>

    $bv3 = $bv1 ^ $bv2;                          # 000010000

When two bitvectors are of unequal length (as is the case here), the shorter vector
is zero-padded on the left to equalize their lengths before the application of the
logical operation. If this auto-padding property is not something you want, you
should check the lengths of the argument bitvectors in your own script before
invoking this operator.  The result of the logical XOR operation is returned as a new
bitvector.  The two operand bitvectors remain unchanged.


=item B<Comparing bitvectors:>

    $bv1 < $bv2 ?  print "yes\n"  :  print "no\n";        # no

    $bv1 > $bv2 ?  print "yes\n"  :  print "no\n";        # yes

    $bv1 <= $bv2 ?  print "yes\n"  :  print "no\n";       # no

    $bv1 >= $bv2 ?  print "yes\n"  :  print "no\n";       # yes

    $bv1 == $bv2 ?  print "yes\n"  :  print "no\n";       # no

    $bv1 != $bv2 ?  print "yes\n"  :  print "no\n";       # yes

The overload definitions for all these operators are autogenerated from the overload
definition for the 3-way numerical comparison operator 'C<< <=> >>'.  B<The
bitvectors are compared on the basis of their integer values.> That is, C<$bv1> is
less than C<$bv2> if C<int($bv1)> is less than C<int($bv2)>.

=item B<In-place circular shifting:>

    $n = 3;

    $bv1 << $n;                                           # $bv1 is now 000111
    $bv1 >> $n;                                           # $bv1 is now 111000

Since Perl does not expect these two operators to be invoked in a void context, such
statements in your code will elicit a warning from Perl to that effect. If these
warnings annoy you, you can turn them off by surrounding such statements with C<no
warnings "void";> and C<use warnings;> directives.  The other option is to invoke
such statements in the following manner:

    $bv1 = $bv1 << $n;
    $bv2 = $bv1 >> $n; 

That works because the overload definitions for these bit shift operators return the
bitvector object on which they are invoked.  As it turns out, this also allows for
chained invocation of these operators, as in

    $bv1 = $bv1 << 3 << 1 >> 2;                          # 100011

    $bv1 = $bv1 << 2 >> 1 >> 3;                          # 111000

=item B<Iterating over a bitvector:>

    while (<$bv1>) {
        print "$_  ";
    }                                                    # 1  1  1  0  0  0

This is made possible by the overload definition for the C<< <> >> operator. The
C<Algorithm::BitVector> class includes an inner class C<BitVecIterator> for this
purpose.

=back


=head1 CONSTRUCTING BITVECTORS

=over 4

=item B<Constructing an empty bitvector:>

    $bv = Algorithm::BitVector->new( size => 0 );

    print "$bv\n";                                                   # no output

=item B<Constructing a given sized bitvector of all zeros:>

    $bv = Algorithm::BitVector->new( size => 13 );                   # 0000000000000

=item B<Constructing a bitvector from an integer value:>

    $bv = Algorithm::BitVector->new( intVal => 5006 );               # 1001110001110 

The module returns the smallest possible bitvector that would accommodate the
integer value provided with the C<intVal> option.  

=item B<Constructing a bitvector by specifying both the size and the integer values:>

As mentioned, with the C<intVal> option, you get the smallest possible bitvector
that can be generated from that integer.  If you want a I<larger> bitvector, you can
also supply the C<size> option as shown below:

    $bv = Algorithm::BitVector->new( intVal => 5006, size => 16 );   # 0001001110001110  

If the value supplied for the C<size> option in such a call is not larger than the
smallest bit array that represents the C<intVal> value, the constructor will throw an
exception.

=item B<Constructing a bitvector from a very large integer:>

    use Math::BigInt;
    $x = Math::BigInt->new('12345678901234567890123456789012345678901234567890');
    $bv = Algorithm::BitVector->new( intVal => $x );
                   #1000011100100111111101100011011010011010101011111000001111001010000\
                   #10101000000100110011101000111101011111000110001111111000110010110110\
                   #01110001111110000101011010010

=item B<Constructing a bitvector from a bit string:>

    $bv = Algorithm::BitVector->new( bitstring => '00110011' );     # 00110011

=item B<Constructing a bitvector from an ASCII text string:>

    $bv = Algorithm::BitVector->new( textstring => "hello\n" );  
                                       # 011010000110010101101100011011000110111100001010

=item B<Constructing a bitvector from a hex string:>

    $bv = Algorithm::BitVector->new( hexstring => "68656c6c6f" );
                                       # 0110100001100101011011000110110001101111

=item B<Constructing a bitvector from a bit list:>

    $bv = Algorithm::BitVector->new( bitlist => [1, 1, 0, 1] );       # 1101

=item B<Constructing a bitvector from the contents of a disk file:>

    $bv = Algorithm::BitVector->new( filename => 'testinput1.txt' );

    print "$bv\n";                               # Nothing to show yet

    $bv1 = $bv->read_bits_from_file(64);         # Now you have a bitvector from the
                                                 #   first 64 bits

Note that it takes two calls to create bitvectors from the contents of a file.  The
first merely creates an empty bitvector just to set the necessary file handle for
reading the file.  It is the second call in which you invoke the method
C<read_bits_from_file()> that actually returns a bitvector from the bits read from
the file.  Each call to C<read_bits_from_file()> in this manner spits out a new bit
vector.

=back

=head1 METHODS

=head3 close_file_handle()

=over 4

When you construct bitvectors by block scanning a disk file, after you are done, you
can call this method to close the file handle that was created to read the file:

    $bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
    ## your code to read bit blocks for constructing bitvectors goes here
    $bv->close_file_handle();

The constructor call in the first statement opens a file handle for reading the bits.
It is this file handle that is closed by calling C<close_file_handle()>,

=back

=head3 count_bits()

=over 4

    $bv = Algorithm::BitVector->new( intVal => 45, size => 16 );
    print $bv->count_bits();                       # 4

This method returns an integer value which is the number of bits set to 1 in the
bitvector on which the method is invoked.

=back

=head3 count_bits_sparse()

=over 4

Say you have a bitvector with two million bits:

    $bv = Algorithm::BitVector->new( size => 2000000 );     

and you happen to set its individual bits by

    $bv->set_bit(345234, 1);
    $bv->set_bit(233, 1);
    $bv->set_bit(243, 1);
    $bv->set_bit(18, 1);
    $bv->set_bit(785, 1);

The following call returns the number of bits set in the bitvector:

    print $bv->count_bits_sparse();               # 5   

For very long bitvectors, as in the example here, this method will work much faster
than the C<count_bits()> method.  However, for dense bitvectors, I expect
C<count_bits()> to work faster.

=back

=head3 deep_copy()

=over 4

    $bv_copy = $bv->deep_copy();

Subsequently, any alterations to the bitvectors pointed to by either C<$bv> or
C<$bv_copy> will not affect the other.

=back

=head3 divide_into_two()

=over 4

    ($bv1, $bv2) = $bv->divide_into_two();              # say $bv = 0000000000101101
    print "$bv1\n";                                     # 00000000                                 
    print "$bv2\n";                                     # 00101101  

Divides an even sized bitvector into two bitvectors, each of size half of the
bitvector on which this method is invoked. Throws an exception when invoked on a
bitvector that is not even sized.

=back

=head3 gcd()

=over 4

This method uses the Euclid's algorithm to return the Greatest Common Divisor of the
integer values represented by the two bitvectors.  The following example shows a call
to C<gcd()> returning the GCD of the integer values of the bitvectors C<$bv1> and
C<$bv2>.

    $bv1 = Algorithm::BitVector->new( bitstring => '01100110' );   # 102                           
    $bv2 = Algorithm::BitVector->new( bitstring => '011010' );     # 26                            
    $gcd = $bv1->gcd( $bv2 );                                      # 10
    print int($gcd);                                               # 2

The result returned by C<gcd()> is a bitvector.

=back

=head3 gen_random_bits()

=over 4

    $bv = Algorithm::BitVector->new( intVal => 0 );
    $bv = $bv->gen_random_bits(16);                        # 1100111001010101

The call to C<gen_random_bits()> returns a bitvector whose bits are randomly
generated.  The number of bits in the returned bitvector equals the argument integer.

=back

=head3 get_bit()

=over 4

This method gives you array-like access to the individual bits of a bitvector.

    $bv = Algorithm::BitVector->new( bitstring => '10111' );
    print $bv->get_bit(0);                           # 1   (the first bit)
    print $bv->get_bit(1);                           # 0                                           
    print $bv->get_bit(4);                           # 1   (the last bit) 

Negative values for the index scan a bitvector from right to left, with the C<-1>
index standing for the last (meaning the right-most) bit in the vector:

    print $bv->get_bit(-1);                          # 1   (the last bit)                          
    print $bv->get_bit(-2);                          # 1                           
    print $bv->get_bit(-5);                          # 1   (the first bit)

The C<get_bit()> can also return a slice of a bitvector if the argument to the
method is an anonymous array of the index range you desire, as in the second 
statement below:

    $bv = Algorithm::BitVector->new( bitstring => "10111011");
    my $arr = $bv->get_bit( [3..7] );
    print "@$arr\n";                                 # 1 1 0 1 1 

In this example, we want C<get_bit()> to return all bits at positions indexed 3
through 7, both ends inclusive.  Note that the slice is returned as an array of bits.


=back

=head3 get_bitvector_in_ascii()

=over 4

    $bv = Algorithm::BitVector->new( textstring => "hello" );
    print "$bv\n";                              # 0110100001100101011011000110110001101111 
    print $bv->get_bitvector_in_ascrii();                           # hello                        

The method returns a string of ASCII characters by converting successive 8-bit slices
of the bitvector into an ASCII character. It throws an exception if the size of the
bit pattern is not a multiple of 8.  Calling this method to create a text-based print
representation of a bit vector makes sense only if you don't expect to see any
unprintable characters in the successive 8-bit slices of the bitvector.  Let's say
you have created a bitvector from a text string using the appropriate constructor
call.  Subsequently, you encrypted this text string.  Next, you or someone else
decrypts the encrypted bit stream.  Since what comes out at the decryption end must
be the original text string, it would make sense to invoke this method to recover the
original text.

=back

=head3 get_bitvector_in_hex()

=over 4

Assuming that length of your bitvector is a multiple of 4, this methods returns a
hex representation of the bit pattern:

    $bv = Algorithm::BitVector->new(bitstring => "0110100001100101011011000110110001101111");
    print $bv->get_bitvector_in_hex();             # 68656c6c6f

The hex representation is returned in the form if a string of hex characters.  This
method throws an exception if the size of the bitvector is not a multiple of 4.

=back

=head3 get_slice()

=over 4

You can use this method to get a slice of a BitVector that is within a specified range.
You can specify the index range with the usual range operator in Perl.  If the index 
range is, say, '5..11', the method will return all bits at index values 5 through 10.

    my $bv9 = Algorithm::BitVector->new( intVal => 63437, size => 16 );
    print "BitVector for testing get_slice(): $bv9\n";     # 1111011111001101                          
    my $slice_bv = $bv9->get_slice( [5..11] );
    print "slice BitVector for index values 5 through 10: $slice_bv\n";    # 111110    

Note that the method returns the slice in the form of a BitVector object.

=back

=head3 gf_divide_by_modulus()

=over 4

This method is for modular division in the Galois Field C<GF(2^n)>.  You must specify
the modulus polynomial through a bit pattern and also the value of the integer C<n>:

    $mod = Algorithm::BitVector->new( bitstring => '100011011' );   # AES modulus                  
    $n = 8;
    $a = Algorithm::BitVector->new( bitstring => '11100010110001' );
    ($quotient, $remainder) = $a->gf_divide_by_modulus($mod, $n);
    print "$quotient\n";                           # 00000000111010                            
    print "$remainder\n";                          # 10001111 

What this example illustrates is dividing the bitvector C<$a> by the modulus bit
vector C<$mod>.  For a more general division of one bitvector C<$a> by another bit
vector C<$b>, you would carry out a multiplication of C<$a> by the MI of C<$b>, where
MI stands for "multiplicative inverse" as returned by a call to the method
C<gf_MI()>.  A call to C<gf_divide_by_modulus()> returns two bitvectors, one for the
quotient and the other for the remainder.

=back

=head3 gf_MI()

=over 4

This method returns the multiplicative inverse of a bit pattern in the Galois Field
C<GF(2^n)>.  You must specify both the modulus polynomial through its bit pattern and
the value of C<n>:

    $modulus = Algorithm::BitVector->new( bitstring => '100011011' );     # AES modulus            
    $n = 8;
    $a = Algorithm::BitVector->new( bitstring => '00110011' );
    print $a->gf_MI($modulus, $n);                     # 01101100                                  

Note that the multiplicative inverse is returned as a bitvector.

=back

=head3 gf_multiply()

=over 4

This method returns a product of two bit patterns in the Galois Field C<GF(2)> field.
That is, given any two polynomials with their coefficients drawn from the 0 and 1
values in C<GF(2)>, this method returns the product polynomial.  

    $a = Algorithm::BitVector->new( bitstring => '0110001' );
    $b = Algorithm::BitVector->new( bitstring => '0110' );
    print $a->gf_multiply($b);                                #00010100110

As you would expect, in general, the bit pattern returned by this method will be
longer than the lengths of the two operand bitvectors.  The result returned by the
method is in the form of a bitvector.

=back

=head3 gf_multiply_modular()

=over 4

This method carries out modular multiplication in the Galois Field C<GF(2^n)>.  You
must supply it the bitvector for the modulus polynomial and the value of C<n>.
 
    $modulus = Algorithm::BitVector->new( bitstring => '100011011' );     # AES modulus            
    $n = 8;
    $a = Algorithm::BitVector->new( bitstring => '0110001' );
    $b = Algorithm::BitVector->new( bitstring => '0110' );
    print $a->gf_multiply_modular($b, $modulus, $n);         # 10100110                            

This example returns the product of the bit patterns C<$a> and C<$b> modulo the bit
pattern C<$modulus> in C<GF(2^8)>.  The result returned by the method is in the form
of a bitvector.

=back

=head3 hamming_distance()

=over 4

Hamming distance is commonly used to measure dissimilarity between two bitvectors of
the same size.

    $bv1 = Algorithm::BitVector->new( bitstring => '11111111' );
    $bv2 = Algorithm::BitVector->new( bitstring => '00101011' );
    print $bv1->hamming_distance( $bv2 );                            # 4

This distance returns the number of bit positions in which two the bit patterns
differ.  The method throws an exception if the two bitvectors are not of the same
length.  The value returned is an integer.

=back

=head3 int_value()

=over 4

You can find the integer value of a bitvector by

    $bv = Algorithm::BitVector->new( intVal => 5678 );
    print $bv3->int_value();                             # 5678

or, even more simply by

    print int($bv);                                      # 5678

which works on account of the overloading of the C<0+> operator.

=back

=head3 is_power_of_2()

=over 4

You can use this predicate to test if the integer value of a bitvector is a power of
2:

    $bv = Algorithm::BitVector->new( bitstring => '10000000001110' );
    print int($bv);                                        # 826                                   
    print $bv->is_power_of_2();                            # 0   

The predicate returns 1 for true and 0 for false.

=back

=head3 is_power_of_2_sparse()

=over 4

This does the same thing as the C<is_power_of_2()> method but in a way that makes it
faster for large bitvectors with very few bits set.

    $bv = Algorithm::BitVector->new( size => 2000000 );
    $bv->set_bit(345234, 1);
    print $bv->is_power_of_2_sparse();                    # 1

=back

=head3 jaccard_distance()

=over 4

The Jaccard distance between two bitvectors is 1 minus the Jaccard similarity
coefficient:

    $bv1 = Algorithm::BitVector->new( bitstring => '11111111' );
    $bv2 = Algorithm::BitVector->new( bitstring => '10101011' );
    print $bv1->jaccard_distance( $bv2 );                         # 0.375

The value returned by the method is a floating point number between 0 and 1.

=back

=head3 jaccard_similarity()

=over 4

This method returns the Jaccard similarity coefficient between the two bitvectors
pointed to by C<$bv1> and C<$bv2>:

    $bv1 = Algorithm::BitVector->new( bitstring => '11111111' );
    $bv2 = Algorithm::BitVector->new( bitstring => '10101011' );
    print $bv1->jaccard_similarity( $bv2 );                       # 0.675

The value returned by the method is a floating point number between 0 and 1.

=back

=head3 length()

=over 4

This method returns the total number of bits in a bitvector:

    $bv = Algorithm::BitVector->new( intVal => 5678 );
    print $bv;                                                    # 1011000101110
    print $bv->length();                                          # 13  

Note that what C<length()> returns is the total size of a bitvector, including any
leading zeros.

=back

=head3 min_canonical()

=over 4

This method returns the min-int-value circularly rotated version of a BitVector. I refer
to this form of a BitVector as its "min canonical form".

    $bv = Algorithm::BitVector->new( bitstring => "00011100010010" );
    print $bv->min_canonical();                                   # 00001110001001

=back

=head3 multiplicative_inverse()

=over 4

This method calculates the multiplicative inverse using normal integer arithmetic.
For multiplicative inverses in a Galois Field C<GF(2^n)>, use the method C<gf_MI()>
described earlier in this API.

    $modulus = Algorithm::BitVector->new( intVal => 32 );
    $bv = Algorithm::BitVector->new( intVal => 17 );
    $result = $bv->multiplicative_inverse( $modulus );
    if ($result) {
        print $result;                                                # 10001
    } else {
        print "No multiplicative inverse in this case\n";
    }

What this example says is that the multiplicative inverse of 17 modulo 32 is 17. That
is because 17 times 17 in modulo 32 arithmetic equals 1.  When using this method, you
must test the value returned for 0.  If the returned value is 0, that means that the
number corresponding to the bitvector on which this method is invoked does not
possess a multiplicative inverse with respect to the modulus.

=back

=head3 next_set_bit()

=over 4

Starting from a given bit position, this method returns the index of the next bit
that is set in a bitvector:

    $bv = Algorithm::BitVector->new( bitstring => '00000000000001' );
    print $bv->next_set_bit(5);                                  # 13                              

In this example, we are asking the method to return the index of the bit that is set
after the bit position indexed 5.  The method returns -1 if there is no next set bit.

=back

=head3 pad_from_left()

=over 4

You can pad a bitvector from the left with a designated number of zeros:

    $bv = Algorithm::BitVector->new( bitstring => '101010' );
    print $bv->pad_from_left( 4 );                               # 0000101010

The method returns the bitvector on which it is invoked.  So you can think of it as
an in-place extension of a bitvector (although, under the hood, the extension is
carried out by giving a new longer C<_vector> attribute to the bitvector object).

=back

=head3 pad_from_right()

=over 4

You can pad a bitvector from the right with a designated number of zeros:

    $bv = Algorithm::BitVector->new( bitstring => '101010' );
    print $bv->pad_from_right( 4 );                              # 1010100000

The method returns the bitvector on which it is invoked.  So you can think of it as
an in-place extension of a bitvector (although, under the hood, the extension is
carried out by giving a new longer C<_vector> attribute to the bitvector object).


=back

=head3 permute()

=over 4

You can permute the bits in a bitvector with a permutation list as shown below:

    $bv1 = Algorithm::BitVector->new( intVal => 203, size => 8 );
    print $bv1;                                                   # 11001011                       
    $bv2 =  $bv1->permute( [3, 2, 1, 0, 7, 6, 5, 4] );
    print $bv2;                                                   # 00111101

The method returns a new bitvector with permuted bits.

=back

=head3 rank_of_bit_set_at_index()

=over 4

You can measure the "rank" of a bit that is set at a given index.  Rank is the number
of bits that are set up to the argument position, as in

    $bv = Algorithm::BitVector->new( bitstring => '01010101011100' );
    print $bv->rank_of_bit_set_at_index( 10 );                    # 6

The value 6 returned by this call to C<rank_of_bit_set_at_index()> is the number of
bits set up to the position indexed 10 (including that position).  The method throws
an exception if there is no bit set at the argument position.

=back

=head3 read_bits_from_file()

=over 4

Constructing bitvectors from the contents of a disk file takes two steps: First you
must make the call shown in the first statement below. The purpose of this call is to
create a file handle that is associated with the variable C<$bv> in this case.
Subsequent invocations of C<read_bits_from_file($n)> on this variable will read
blocks of C<$n> bits and return a bitvector for each block thus read.  The variable
C<$n> must be a multiple of 8 for this to work.

    $bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
    $bv1 = $bv->read_bits_from_file(64);
    $bv2 = $bv->read_bits_from_file(64);
    ...
    ...
   $bv->close_file_handle();

When reading a file as shown above, you can test the attribute C<more_to_read> of the
bitvector object in order to find out if there is more to be read in the file.  The
C<while> loop shown below reads all of a file in 64-bit blocks. 

    $bv = Algorithm::BitVector->new( filename => 'testinput.txt' );
    while ($bv->{more_to_read}) {
        my $bv_read = $bv->read_bits_from_file( 64 );
        print "$bv_read\n";
    }
    $bv->close_file_handle();

The size of the last bitvector constructed from a file corresponds to how many bytes
remain unread in the file at that point.  It is your responsibility to zero-pad the
last bitvector appropriately if, say, you are doing block encryption of the whole
file.

=back

=head3 reset()

=over 4

You can reset a previously constructed bitvector all either all 1's or all 0's by
calling this method:

    $bv = Algorithm::BitVector->new( intVal => 203, size => 8 );
    print $bv;                                                  # 11001011                         
    $bv->reset(1);
    print $bv;                                                  # 11111111                         
    $bv->reset(0);
    print $bv;                                                  # 00000000  

What the method accomplishes can be thought of as in-place resetting of the bits. The
method does not return anything.

=back

=head3 reverse()

=over 4

Given a bitvector, you can construct a bitvector with all the bits reversed, in the
sense that what was left-to-right earlier now becomes right-to-left, as in

    $bv = Algorithm::BitVector->new( bitstring => '01100001' );
    print $bv->reverse();                                       # 10000110                         

A call to this method returns a new bitvector whose bits are in reverse order in
relation to the bits in the bitvector on which the method is called.

=back

=head3 runs()

=over 4

This method returns an array of runs of 1's and 0's in a bitvector:

    $bv = Algorithm::BitVector->new( bitlist => [1,1,1,0,0,1] );
    my @bvruns = $bv->runs();
    print "@bvruns\n";                                     # 111  00  1   

Each element of the array that is returned by C<runs()> is a string of either 1's or
0's.

=back

=head3 set_bit()

=over 4

With array-like indexing, you can use this method to set the individual bits of a
previously constructed bitvector.  Both positive and negative values are allowed for
the bit position index.  The method takes two explicit arguments, the first for the
position of the bit you want to set and the second for the value of the bit.

    $bv = Algorithm::BitVector->new( bitstring => '1111' );
    $bv->set_bit(0,0);                                # set the first bit to 0
    $bv->set_bit(1,0);                                # set the next bit to 0
    print $bv;                                        # 0011                                       
    $bv->set_bit(-1,0);                               # set the last bit to 0
    $bv->set_bit(-2,0);                               # set the bit before the last bit to 0
    print $bv;                                        # 0000       

=back

=head3 set_slice()

=over 4

You can set a slice in a given BitVector by calling this method.  It takes two
arguments, with the first argument as the range of the position index values at which
you want to set the bits and the second argument the bit values at those positions.

    $bv =  Algorithm::BitVector->new( intVal => 63437, size => 16 );
    $values_bv = Algorithm::BitVector->new( bitlist => [1,1,1,1] );
    $bv->set_slice( [4..8], $values_bv );
    print "BitVector after set_slice():  $bv\n";     # 1111111111001101

When specifying the index values with the range operator in the form C<i..j>, you
would be setting the bits at the positions C<i> through C<j-1>.

=back

=head3 set_value()

=over 4

This method can be used to change the bit pattern associated with a previously
constructed bitvector:

    $bv = Algorithm::BitVector->new( intVal => 7, size => 16 );
    print $bv;                                 # 0000000000000111                                  
    $bv->set_value( intVal => 45 );
    print $bv;                                 # 101101    

You can think of this method as carrying out an in-place resetting of the bit array
in a bitvector.  The method does not return anything.

=back

=head3 shift_left()

=over 4

If you want to shift a bitvector non-circularly to the left, this is the method to
call:

    $bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
    $bv->shift_left(3);
    print $bv;                                                  # 001000
    $bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
    $bv->shift_left(3)->shift_right(3);
    print $bv;                                                  # 000001 

As the bitvector is shifted non-circularly to the left, the exposed bit positions on
the right are filled with zeros.  Note that the method returns the bitvector object
on which it is invoked.  That is the reason why the chained invocation of the method
in the fifth statement above works.

=back

=head3 shift_right()

=over 4

If you want to shift a bitvector non-circularly to the right, this is the method to
call:

    $bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
    $bv->shift_right(3);
    print $bv;                                                  # 000111                           
    $bv = Algorithm::BitVector->new( bitlist => [1,1, 1, 0, 0, 1] );
    $bv->shift_right(3)->shift_right(2);
    print $bv;                                                  # 000001 

As the bitvector is shifted non-circularly to the right, the exposed bit positions on
the left are filled with zeros.  Note that the method returns the bitvector object
on which it is invoked.  That is the reason why the chained invocation of the method
in the fifth statement above works.

=back

=head3 test_for_primality()

=over 4

If the integer value of a bitvector is small (meaning smaller than C<< 0x7f_ff_ff_ff >>),
you can use this method to test it for its primality through the Miller-Rabin
probabilistic test:

    $p = 7417;
    $bv = Algorithm::BitVector->new( intVal => $p );
    $check = $bv->test_for_primality();
    print "The primality test for $p: $check\n";
            # The primality test for 7417: is a prime with probability 0.99993896484375 

The method returns one of two strings: If the primality test succeeds, the method
returns a string like "C<is a prime with probability xxxxx>".  And if the test fails,
the method returns the string "C<is NOT a prime>".

=back

=head3 unpermute()

=over 4

This method reverses the permutation carried out by a call to the C<permute()> method
as shown below:

    $bv1 = Algorithm::BitVector->new( intVal => 203, size => 8 );
    print $bv1;                                                   # 11001011                       
    $bv2 =  $bv1->permute( [3, 2, 1, 0, 7, 6, 5, 4] );
    print $bv2;                                                   # 00111101
    $bv3 = $bv2->unpermute( [3, 2, 1, 0, 7, 6, 5, 4] );
    print $bv3;                                                   # 11001011

The method returns a new bitvector with unpermuted bits.  Also note that the method
throws an exception if the permutation list is not as long as the size of the
bitvector on which the method is invoked.

=back

=head3 write_to_file()

=over 4

This method writes the bitvectors in your program to a disk file:

    $bv1 = Algorithm::BitVector->new( bitstring => '00001010' );
    open my $FILEOUT, ">test.txt";
    $bv1->write_to_file( $FILEOUT );
    close $FILEOUT;

The size of a bitvector must be a multiple of 8 for this write method to work.  If
this condition is not met, the method will throw an exception.

B<Important for Windows Users:> When writing an internally generated bitvector out
to a disk file, it may be important to open the file in the binary mode, since
otherwise the bit pattern `00001010' ('\n') in your bitstring will be written out as
0000110100001010 ('\r\n') which is the line break on Windows machines.

=back

=head1 REQUIRED

This module imports the following modules:

    Math::BigInt
    List::Util
    Math::Random
    Fcntl


=head1 THE C<Examples> DIRECTORY

The C<Examples> directory contains the following script that invokes all of the
functionality of this module:

    BitVectorDemo.pl

In case there is any doubt about how exactly to invoke a method or how to use an
operator, please look at the usage in this script.

=head1 EXPORT

None by design.

=head1 BUGS

Please notify the author if you encounter any bugs.  When sending email, please place
the string 'BitVector' in the subject line.

=head1 INSTALLATION

Download the archive from CPAN in any directory of your choice.  Unpack the archive
with a command that on a Linux machine would look like:

    tar zxvf Algorithm-BitVector-1.26.tar.gz

This will create an installation directory for you whose name will be
C<Algorithm-BitVector-1.26>.  Enter this directory and execute the following commands
for a standard install of the module if you have root privileges:

    perl Makefile.PL
    make
    make test
    sudo make install

If you do not have root privileges, you can carry out a non-standard install the
module in any directory of your choice by:

    perl Makefile.PL prefix=/some/other/directory/
    make
    make test
    make install

With a non-standard install, you may also have to set your PERL5LIB environment
variable so that this module can find the required other modules. How you do that
would depend on what platform you are working on.  In order to install this module in
a Linux machine on which I use tcsh for the shell, I set the PERL5LIB environment
variable by

    setenv PERL5LIB /some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/

If I used bash, I'd need to declare:

    export PERL5LIB=/some/other/directory/lib64/perl5/:/some/other/directory/share/perl5/


=head1 THANKS

The bug in the primality test function, whose fix resulted in Version 1.21, was
reported by Dana Jacobsen in a bug report filed at C<rt.cpan.org>.  Thanks Dana!

The restriction on the Perl version was removed on Slaven Rezic's recommendation.  He
says the module runs fine with Perl 5.8.9.  Thanks Slaven!

Austin Nobis reported a documentation error in Version 1.24 which was fixed in Version
1.25.  Thanks Austin!

=head1 AUTHOR

The author, Avinash Kak, recently finished a 17-years long "Objects Trilogy Project"
with the publication of the book "Designing with Objects" by John-Wiley. If
interested, visit his web page at Purdue to find out what this project was all
about. You might like "Designing with Objects" especially if you enjoyed reading
Harry Potter as a kid (or even as an adult, for that matter).

For all issues related to this module, contact the author at kak@purdue.edu

If you send email, please place the string "BitVector" in your subject line to get
    past the author's spam filter.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

 Copyright 2018 Avinash Kak

=cut

