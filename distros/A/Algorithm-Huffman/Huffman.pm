package Algorithm::Huffman;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.09';

use Heap::Fibonacci;
use Tree::DAG_Node;
use List::Util qw/max min first/;

sub new {
    my ($proto, $count_hash) = @_;
    my $class = ref($proto) || $proto;
    
    __validate_counting_hash($count_hash);
    my $heap = Heap::Fibonacci->new;
    
    my $size = 0;
    while (my ($str, $count) = each %$count_hash) {
        croak "The count for each character/substring must be a number"
            unless $count =~ /^(-)?\d+(\.\d+)?$/;
        croak "The count for each character/substring must be positive (>= 0)," .
              "but found counting '$count' for the string '$str'"
            unless $count >= 0;
        my $leaf = Tree::DAG_Node->new({name => $str});
        $leaf->attribute->{bit} = "";
        $heap->add( KeyValuePair->new( $leaf, $count ) );
        $size++;
    }
    
    while ($size-- >= 2) {        
        my $right = $heap->extract_minimum;
        my $left  = $heap->extract_minimum;
        $right->key->attribute->{bit} = 1;
        $left->key->attribute->{bit}  = 0;
        my $new_node = Tree::DAG_Node->new({daughters => [$left->key, $right->key]});
        $new_node->attribute->{bit} = "";
        my $new_count = $left->value + $right->value;
        $heap->add( KeyValuePair->new( $new_node, $new_count ) );
    }
    
    my $root = $heap->extract_minimum->key;
    
    my %encode;
    my %decode;
    foreach my $leaf ($root->leaves_under) {
        my @bit = reverse map {$_->attribute->{bit}} ($leaf, $leaf->ancestors);
        my $bitstr = join "", @bit;
        $encode{$leaf->name} = $bitstr;
        $decode{$bitstr}     = $leaf->name;
    }
    
    my $self = {
        encode => \%encode,
        decode => \%decode,
        max_length_encoding_key => max( map length, keys %encode ),
        max_length_decoding_key => max( map length, keys %decode ),
        min_length_decoding_key => min( map length, keys %decode )
    };
    
    bless $self, $class;
}

sub encode_hash {
    my $self = shift;
    $self->{encode};
}

sub decode_hash {
    my $self = shift;
    $self->{decode};
}

sub encode_bitstring {
    my ($self, $string) = @_;
    my $max_length_encoding_key = $self->{max_length_encoding_key};
    my %encode_hash = %{$self->encode_hash};

    my $bitstring = "";
    my ($index, $max_index) = (0, length($string)-1);
    while ($index <= $max_index) {
        for (my $l = $max_length_encoding_key; $l > 0; $l--) {
            if (my $bits = $encode_hash{substr($string, $index, $l)}) {
                $bitstring .= $bits;
                $index     += $l;
                last;
            }
        }
    }
    return $bitstring;
}

sub encode {
    my ($self, $string) = @_;
    my $max_length_encoding_key = $self->{max_length_encoding_key};
    my %encode_hash = %{$self->encode_hash};

    my $bitvector = "";
    my $offset = 0;
    my ($index, $max_index) = (0, length($string)-1);
    while ($index <= $max_index) {
        for (my $l = $max_length_encoding_key; $l > 0; $l--) {
            if (my $bits = $encode_hash{substr($string, $index, $l)}) {
                vec($bitvector, $offset++, 1) = $_ for split //, $bits;
                $index     += $l;
                last;
            }
        }
    }
    return $bitvector;
}

sub decode_bitstring {
    my ($self, $bitstring) = @_;
    
    my $max_length_decoding_key = $self->{max_length_decoding_key};
    my $min_length_decoding_key = $self->{min_length_decoding_key};
    my %decode_hash = %{$self->decode_hash};
    
    my $string = "";
    my ($index, $max_index) = (0, length($bitstring)-1);
    while ($index < $max_index) {
        my $decode = undef;
        foreach my $l ($min_length_decoding_key .. $max_length_decoding_key) {
            if ($decode = $decode_hash{substr($bitstring,$index,$l)}) {
                $string .= $decode;
                $index  += $l;
                last;
            }
        }
        defined $decode
            or die "Unknown bit sequence starting at index $index in the bitstring";
    }
    return $string;
}

sub decode {
    my ($self, $bitvector) = @_;
    
    my $max_length_decoding_key = $self->{max_length_decoding_key};
    my $min_length_decoding_key = $self->{min_length_decoding_key};
    my %decode_hash = %{$self->decode_hash};
    
    my $string = "";
    my ($offset, $max_offset) = (0, 8 * (length($bitvector)-1));
    while ($offset < $max_offset) {
        my $decode = undef;
        my $bitpattern = "";
        my $last_offset_ok = $offset;
        foreach my $l (1 .. $max_length_decoding_key) {
            $bitpattern .= vec($bitvector,$offset++,1);
            if ($decode = $decode_hash{$bitpattern}) {
                $string .= $decode;
                last;
            }
        }
        defined $decode
            or die "Unknown bit sequence starting at offset $last_offset_ok in the bitstring";
    }
    return $string;
}


sub __validate_counting_hash {
    my $c = shift;
    my $error_msg = undef;
    defined $c        
        or croak "Undefined counting hash";
    ref($c) eq 'HASH' 
        or croak "The argument for the counting hash is not a hash reference, as expected";
    scalar(keys %$c) >= 2
        or croak "The counting hash must have at least 2 keys";
}

1;

package KeyValuePair;

use Heap::Elem;

require Exporter;

our @ISA = qw/Exporter Heap::Elem/;

sub new {
   my ($proto, $key, $value) = @_;
   my $class = ref($proto) || $proto;

   my $self = $class->SUPER::new;

   $self->{"KeyValuePair::key"}   = $key;
   $self->{"KeyValuePair::value"} = $value;
   
   return $self;
}

sub cmp {
   my ($self, $other) = @_;
   $self->{"KeyValuePair::value"} <=> $other->{"KeyValuePair::value"};
}

sub key {
    my $self = shift;
    return $self->{"KeyValuePair::key"};
}

sub value {
    my $self = shift;
    return $self->{"KeyValuePair::value"};
}

1;


__END__

=head1 NAME

Algorithm::Huffman - Perl extension that implements the Huffman algorithm

=head1 SYNOPSIS

  use Algorithm::Huffman;

  my %char_counting = map {$_ => int rand(100)} ('a' .. 'z', 'A' .. 'Z');
  # or better the real counting for your characters
  # as the huffman algorithm doesn't work good with random data :-)) 

  my $huff = Algorithm::Huffman->new(\%char_counting);
  my $encode_hash = $huff->encode_hash;
  my $decode_hash = $huff->decode_hash;

  my $encode_of_hello = $huff->encode_bitstring("Hello");

  print "Look at the encoding bitstring of 'Hello': $encode_of_hello\n";
  print "The decoding of $encode_of_hello is '", $huff->decode_bitstring($encode_of_hello), "'";

=head1 DESCRIPTION

This modules implements the huffman algorithm.
The aim is to create a good coding scheme for a given list
of different characters (or even strings) and their occurence numbers.

=head2 ALGORITHM

Please have a look to a good data compression book for a detailed view.
However, the algorithm is like every good algorithm very easy.

Assume we have a heap (keys are the characters/strings; 
values are their occurencies). In each step of the algorithm, 
the two rarest characters are looked at. 
Both get a suffix (one "0", the other "1").
They are joined together and will occur from that time as one "element"
in the heap with their summed occurencies.
The joining creates a tree growing on while the heap is reducing.

Let's take an example. Given are the characters and occurencies.

  a (15) b(7) c(6) d(6) e(5)
  
In the first step e and d are the rarest characters,
so we create this new heap and tree structure:

  a(15) de(11) b(7) c(6)
  
        de
       /  \
   "0"/    \"1"
     d      e
     
Next Step:

  a(15) bc(13) de(11)
  
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
     
Next Step:

  a(15) bcde(24)
  
                bcde
              /      \
         "0"/          \"1"
          /              \
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
                      
Next Step unifies the rest:
 
                             Huffman-Table
                                /    \
                          "0"/          \"1"
                         /                  \
                     /                          \
                bcde                              a
              /      \
         "0"/          \"1"
          /              \
        de                bc
       /  \              /  \
   "0"/    \"1"      "0"/    \"1"
     d      e          b      c
     

Finally this encoding table would be created:

   a    1
   b    010
   c    011
   d    000
   e    001

Please note, that there is no rule defining what element in the tree
is ordered to left or to right. So it's also possible to get e.g. the coding
scheme:

   a    0
   b    100
   c    101
   d    110
   e    111

=head2 METHODS

=over

=item my $huff = Algorithm::Huffman->new( HASHREF )

Creates a new Huffman table,
based on the given occurencies of characters.
The keys of the given hashref are the characters/strings,
the values are their occurencies.

A hashref is used, as such a hash can become quite large
(e.g. all three letter combinations).

The passed hash must have at least 2 elements,
as a huffman algorithm for one or zero elements isn't
very useful for anything. 
Even for two elements, the one becomes "0",
the other "1", independent of their counting.

The counting (given as values in the counting hash),
must be greater or equal to zero. (Negative countings doesn't make
any sense). If one character/substring has a counting of zero,
it is still encoded. It's a feature thinking to a situation where you
would try to encode a large text. You count every character and 
most common substrings in the first part of this large text
(or from a dictionary) to get a good assumption of the whole 
character/substring counting. There could be some ASCII characters
(e.g. 'ä' in an english text), that didn't occur. To ensure that 
the whole text is encodable, you simply set the counting of every 
character not yet counted to zero. That guarantees that
there is an encoding/decoding bit sequences for these ones.
It also guarantees that these bit sequences are longer than
all other encoding/decoding sequences of counted characters/substrings.

The countings needn't be integers,
they could also be fractions (e.g. percentage).

=item $huff->encode_hash

Returns a reference to the encoding hash.
The keys of the encoding hash are the characters/strings passed
at the construction. The values are their bit representation.
Please note that the bit represantations are strings 
of ones and zeros is returned and not binary numbers.

=item $huff->decode_hash

Returns a reference to the decoding hash.
The keys of the decoding hash are the bit presentations,
while the values are the characters/strings the bitstrings stands for.
Please note that the bit represantations are strings 
of ones and zeros is returned and not binary numbers.

=item $huff->encode_bitstring($string)

Returns a bitstring of '1' and '0',
representing an encoded version (with the current huffman tree) 
of the given string.

There could be some ambiguities,
e.g. if there is an 'e' and an 'er' in the huffman tree.
This algorithm is greedy.
That means the given string is traversed from the beginning
and in every loop, the longest possible encoding from the huffman tree is taken.
In the above example,
that would be 'er' instead of 'e'.

The greedy way isn't guarantueed to exist also in future versions.
(E.g., I could imagine to look for the next two (or n) possible encoding
substrings from the huffman tree
and to select the one with the shortest encoding bitstring).

=item $huff->encode($string)

Returns the huffman encoded packed bitvector of C<$string>.

Please look to the description of C<encode_bitstring> for details.

=item $huff->decode_bitstring($bitstring)

Decodes a bitstring of '1' and '0' to the original string.
Allthough the encoding could be a bit ambigious,
the decoding is alway unambigious.

Please take care that only ones and zeroes are in the bitstring.
The method will die otherwise.

It will also die if the bitstring isnt complete.
E.g., assuming,
you have a Huffman-Table

  a => 1
  b => 01
  c => 00
  
and wanted to code 'abc'. The right coding is '10100'.
But '1010' (the last 0 is missing) will produce the error message:
C<Unknown bit sequence starting at index 3 in the bitstring>.

=item $huff->decode($bitvector)

Decodes a packed bitvector (encoded with the ->encode method).

Please look to the description of C<decode_bitstring> for details.

=back   

=head2 EXPORT

None by default.

=head1 BUGS

If a character/string has occurs zero times, it is still coded.
At the moment, you have to grep them out before.
I don't plan to change it,
as it can realistic happen and they would play a role.
(Imagine, you would code all three letter combinations found in some
english texts, you still would have to code all ASCII characters,
even if they don't occur in the texts you have analyzed.
Reason is that they could occur in other texts and
you would have to guarantee that you can code every text
without any lost information)

If you encode part for part your stream,
you could get the idea of doing stuff like:

  my $encode1 = $huff->encode_bitstring($chapter1);
  my $encode2 = $huff->encode_bitstring($chapter2);
  
  my $total_encode = $encode1 . $encode2;
  
  my $all_chapters = $huff->decode_bitstring($total_encode);
  
  # Now $all_chapter eq $chapter1 . $chapter2
  
That will work fine,
but I'm afraid, it won't work,
if you replace the C<..code_bitstring methods>
with the C<..code> methods.

It isn't tested with a big histogram of characters/strings.

There could be some others,
as this code is still in the ALPHA stadium.

=head1 TODO

Up till now, I didn't care a lot about the speed.
Some parts could still be improved in Perl and a lot of the parts
could be reimplemented in C.

=head1 THANKS

Thanks to Perry Leopold who found some problems
with the parameter validation and the synopsis.

=head1 SEE ALSO

Every good book about data compression.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
