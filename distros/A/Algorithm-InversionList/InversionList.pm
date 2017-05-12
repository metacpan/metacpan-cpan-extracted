package Algorithm::InversionList;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
invlist data_from_invlist	
);
our $VERSION = '0.03';

sub invlist
{
 my $string = shift @_;

 # we need a valid string
 return undef unless defined $string;

 # handle trivial case of 0-length string
 return [] unless length $string;

 # this is suboptimal, we eventually want to do things in multiples of 8 (on byte boundaries)
 # $length is length in bits, we avoid b* because it will create a list 8 times larger than C*
 my @unpacked = unpack("C*", $string);
 my $length = scalar @unpacked * 8;
 my $current = vec($string, 0, 1);
 my $new;
 my @list;

 push @list, 0 if $current;

 foreach my $offset (0..$length)
 {  
  $new = vec($string, $offset, 1);
  if ($new != $current)
  {
   push @list, $offset;
  }
  $current = $new;
 }

 push @list, $length unless exists $list[-1] && $list[-1] == $length;

 return \@list;
}

sub data_from_invlist
{
 my $out = '';				# start with a blank string
 my $append = 0;			# we're appending '0' bits first
 my $list = shift @_;

 return undef unless defined $list;

 my $start_offset = 0;
 foreach my $end_offset (@$list)			# for each inversion list value
 {
  foreach my $offset ($start_offset .. $end_offset-1)
  {
   vec($out, $offset, 1) = $append;
  }

  $append++;				# 0 => 1, 1 => 2
  $append %= 2;				# 2 => 0, 1 => 1
  $start_offset = $end_offset;
 }

 return $out;				# return the data
}

1;
__END__

=head1 NAME

Algorithm::InversionList - Perl extension for generating an inversion
list from a bit sequence.

=head1 SYNOPSIS

  use Algorithm::InversionList;
  my $data = "Random data here";

  my $inv = invlist($data);
  print "The inversion list is: @$inv\n";

  my $out = data_from_invlist($inv);
  print "From data [$data] we reconstructed [$out]\n";


=head1 DESCRIPTION

Inversion lists are data structures that store a sequence of bits as
the numeric position of each switch between a run of 0 and 1 bits.
Thus, the data "111111100" is encoded as the list of numbers 0, 7 in
an inversion list.  This module begins the list with the start of the
run of 1's, so if the first 2 bits in the string are 0, the first
entry in the list will be a 2 (where we find the first bit that is 1).
The last number will always be the length of the string, so that we
know where to end it.

Inversion lists are very efficient.  Because of the way that Perl
stores scalars and lists and the various architectures to which Perl
has been ported, there is no definitive rule as to what's the exact
proportion of bit runs to bitstring length required to make inversion
lists efficient.  Generally, if you see long runs of repeated 0 or 1
bits, an inversion list may be appropriate.

This module stores inversion lists in an offset-based format which has
some nice properties, for instance searching is fast and you can
easily do boolean operations on two inversion lists stored in the
offset-based format.

=head2 EXPORT

invlist($DATA): Generate an inversion list from a scalar data string

data_from_invlist(@LIST): Generate the data back from an inversion
list

=head1 AUTHOR

Teodor Zlatanov E<lt>tzz@lifelogs.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
