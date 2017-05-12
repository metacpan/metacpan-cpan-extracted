package Algorithm::RabinKarp::Util;

use base qw(Exporter);
our @EXPORT_OK = qw( filter_regexp stream_fh stream_string); 

=head1 NAME

Algorithm::RabinKarp::Util - utility methods for use with Rabin-Karp hash generation.


=head1 GENERATORS 

=over 4

These are generator functions that all create a subroutine closure which
produce pairs of ( value, position ) until their source is exhaused, and undef
when no values remain.

=item filter_regexp ( REGEXP, CODEREF )

Given a coderef matching the signature given for L<Algorithm::RabinKarp>,
this method will create a generator that skips all characters that match a
given regexp.

=cut

sub filter_regexp {
  my $regexp = shift;
  my $coderef = shift;
  sub {
    my ($c, $pos);
    CHAR: while (($c, @rest) = $coderef->()) {
       last CHAR if chr($c) !~ $regexp;
    } 
    return unless $c;
    return $c, @rest;
  };  
}

=item stream_fh ( FileHandle )

Iterates across values in a file handle.

=cut

sub stream_fh { 
  my $fh = shift;
  my $line = 0;
  my $col = -1;
  my $nl = ord("\n");
  sub {
      return if $fh->eof;
      use bytes;
      my $pos = tell($fh);
      my $char = ord($fh->getc);
      if ($char == $nl)  {
        $col = 0; $line++;
      } else {
        $col ++;
      }
      ($char, $pos, $col, $line);
  };
}

=item stream_string ( $scalar )

Iterates across characters in a string.

=cut 

sub stream_string {
  my $string = shift;
  my $pos = 0;
  sub {
      return if ($pos >= length($string));
      my @ret = (ord(substr($string, $pos, 1)), $pos);
      $pos++;
      return @ret;
  };
}

=back

=head1 AUTHOR

  Norman Nunley, Jr <nnunley@cpan.org>

1;
