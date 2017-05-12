package Data::BitStream::Code::EvenRodeh;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::EvenRodeh::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::EvenRodeh::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'EvenRodeh',
                  universal => 1,
                  params    => 0,
                  encodesub => sub {shift->put_evenrodeh(@_)},
                  decodesub => sub {shift->get_evenrodeh(@_)}, };

sub _floorlog2_er {
  my $d = shift;
  my $base = 0;
  $base++ while ($d >>= 1);
  $base;
}
sub _dec_to_bin_er {
  my $bits = shift;
  my $val = shift;
  if ($bits > 32) {
    return   substr(unpack("B32", pack("N", $val>>32)), -($bits-32))
           . unpack("B32", pack("N", $val));
  } else {
    #return substr(unpack("B32", pack("N", $val)), -$bits);
    return scalar reverse unpack("b$bits", pack("V", $val));
  }
}

use Moo::Role;
requires qw(read write put_string);

# Even-Rodeh code
#
# Similar in many ways to the Elias Omega code.  Very rarely used code.

sub put_evenrodeh {
  my $self = shift;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    if ($val <= 3) {
      $self->write(3, $val);
    } else {
      my $str = '0';
      my $v = $val;
      do {
        my $base = _floorlog2_er($v)+1;
        $str = _dec_to_bin_er($base, $v) . $str;
        $v = $base;
      } while ($v > 3);
      $self->put_string($str);
    }
  }
  1;
}

sub get_evenrodeh {
  my $self = shift;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  my $maxbits = $self->maxbits;
  $self->code_pos_start('EvenRodeh');
  while ($count-- > 0) {
    $self->code_pos_set;

    my $val = $self->read(3);
    last unless defined $val;

    if ($val > 3) {
      my $first_bit;
      while ($first_bit = $self->read(1)) {
        $self->error_code('overflow') if ($val-1) > $maxbits;
        my $next = $self->read($val-1);
        $self->error_off_stream unless defined $next;
        $val = (1 << ($val-1)) | $next;
      }
      $self->error_off_stream unless defined $first_bit;
    }
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Even-Rodeh codes

=pod

=head1 NAME

Data::BitStream::Code::EvenRodeh - A Role implementing Even-Rodeh codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the Even-Rodeh codes.  The role applies to a stream object.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_evenrodeh($value) >

=item B< put_evenrodeh(@values) >

Insert one or more values as Even-Rodeh codes.  Returns 1.

=item B< get_evenrodeh() >

=item B< get_evenrodeh($count) >

Decode one or more Even-Rodeh codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< put_string >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item S. Even, M. Rodeh, "Economical Encoding of Commas Between Strings", Comm ACM, Vol 21, No 4, pp 315-317, April 1978.

=item Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
