#
# This file is part of Array-IntSpan
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
##########################################################################
#
# Array::IntSpan::IP - a Module for arrays using IP addresses as indices
#
# Author: Toby Everett
# Revision: 1.01
# Last Change: Makefile.PL
##########################################################################
# Copyright 2000 Toby Everett.  All rights reserved.
#
# This module is distributed under the Artistic 2.0 License. See
# https://www.perlfoundation.org/artistic-license-20.html
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
##########################################################################

use strict;

use Array::IntSpan;

package Array::IntSpan::IP;
$Array::IntSpan::IP::VERSION = '2.004';
use vars qw($VERSION @ISA);

$VERSION = '1.01';

@ISA = ('Array::IntSpan');

sub new {
  my $class = shift;
  my(@temp) = @_;

  foreach my $i (@temp) {
    $i->[0] = &ip_as_int($i->[0]);
    $i->[1] = &ip_as_int($i->[1]);
  }

  return $class->SUPER::new(@temp);
}

sub set_range {
  my $self = shift;
  my(@temp) = @_;

  $temp[0] = &ip_as_int($temp[0]);
  $temp[1] = &ip_as_int($temp[1]);

  return $self->SUPER::set_range(@temp);
}

sub lookup {
  my $self = shift;
  my($key) = @_;

  return $self->SUPER::lookup(&ip_as_int($key));
}

sub ip_as_int {
  my($value) = @_;

  if ($value =~ /^(\d{1,3}\.){3}(\d{1,3})$/) {
    my(@values) = split(/\./, $value);
    scalar(grep {$_ > 255} @values) and croak("Unable to parse '$value' as an IP address.");
    return 16777216*$values[0]+65536*$values[1]+256*$values[2]+$values[3];
  } elsif (length($value) == 4) {
    return unpack('N', $value)
  } elsif ($value =~ /^\d+$/) {
    return int($value);
  } else {
    croak("Unable to parse '$value' as an IP address.");
  }
}

#The following code is courtesy of Mark Jacob-Dominus,

sub croak {
  require Carp;
  *croak = \&Carp::croak;
  goto &croak;
}

1;

__END__

=head1 NAME

Array::IntSpan::IP - a Module for arrays using IP addresses as indices

=head1 SYNOPSIS

  use Array::IntSpan::IP;

  my $foo = Array::IntSpan::IP->new(['123.45.67.0',   '123.45.67.255', 'Network 1'],
                                    ['123.45.68.0',   '123.45.68.127', 'Network 2'],
                                    ['123.45.68.128', '123.45.68.255', 'Network 3']);

  print "The address 123.45.68.37 is on network ".$foo->lookup("\173\105\150\45").".\n";
  unless (defined($foo->lookup(((123*256+45)*256+65)*256+67))) {
    print "The address 123.45.65.67 is not on a known network.\n";
  }

  print "The address 123.45.68.177 is on network ".$foo->lookup("123.45.68.177").".\n";

  $foo->set_range('123.45.68.128', '123.45.68.255', 'Network 4');
  print "The address 123.45.68.177 is now on network ".$foo->lookup("123.45.68.177").".\n";

=head1 DESCRIPTION

C<Array::IntSpan::IP> brings the advantages of C<Array::IntSpan> to IP
address indices.  Anywhere you use an index in C<Array::IntSpan>, you
can use an IP address in one of three forms in C<Array::IntSpan::IP>.
The three accepted forms are:

=over 4

=item Dotted decimal

This is the standard human-readable format for IP addresses.  The
conversion checks that the octets are in the range 0-255.  Example:
C<'123.45.67.89'>.

=item Network string

A four character string representing the octets in network
order. Example: C<"\173\105\150\131">.

=item Integer

A integer value representing the IP address. Example:
C<((123*256+45)*256+67)*256+89> or C<2066563929>.

=back

Note that the algorithm has no way of distinguishing between the
integer values 1000 through 9999 and the network string format.  It
will presume network string format in these instances.  For instance,
the integer C<1234> (representing the address C<'0.0.4.210'>) will be
interpreted as C<"\61\62\63\64">, or the IP address C<'49.50.51.52'>.
This is unavoidable since Perl does not strongly type integers and
strings separately and there is no other information available to
distinguish between the two in this situation.  I do not expect that
this will be a problem in most situations. Most users will probably
use dotted decimal or network string notations, and even if they do
use the integer notation the likelyhood that they will be using the
addresses C<'0.0.3.232'> through C<'0.0.39.15'> as indices is
relatively low.

=head1 METHODS

=head2 ip_as_int

The class method C<Array::IntSpan::IP::ip_as_int> takes as its one
parameter the IP address in one of the three formats mentioned above
and returns the integer notation.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=cut

