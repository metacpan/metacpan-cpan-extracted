package Text::ASCIITable::FixANSI;

use strict;
use warnings;

use Text::ASCIITable ();

use Readonly;

our $VERSION = '1.0.0';

Readonly::Scalar my $VERIFIED_AGAINST => '0.22';
Readonly::Scalar my $ANSI_RE          => qr/\e\[[\d;]*[a-zA-Z]|\e\([0B]/;

BEGIN {
  if ( $Text::ASCIITable::VERSION ne '0.22' ) {
    warn sprintf
      "Text::ASCIITable::FixANSI: patch verified against 0.22, found %s\n",
      $Text::ASCIITable::VERSION;
  }
}

my $ORIG_COUNT = \&Text::ASCIITable::count;

########################################################################
sub _ansi_aware_wrap {
########################################################################
  my ( $text, $max_width, $nostrict ) = @_;

  return $text if !defined $max_width || $max_width <= 0;

  my @wrapped_lines;

  foreach my $line ( split /\n/xsm, $text ) {
    my $current_line   = q{};
    my $current_length = 0;

    my @tokens = $line =~ /($ANSI_RE|\s+|(?:(?!\e)[^\s])+)/gxsm;

    foreach my $token (@tokens) {
      if ( $token =~ /^\e/xsm ) {
        $current_line .= $token;  # zero visible width
        next;
      }

      if ( $token =~ /^\s+$/xsm ) {
        if ( $current_length + length($token) <= $max_width ) {
          $current_line .= $token;
          $current_length += length $token;
        }
        elsif ( $current_length > 0 ) {
          push @wrapped_lines, $current_line;
          ( $current_line, $current_length ) = ( q{}, 0 );
        }
        next;
      }

      my $word_len = length $token;

      if ( $current_length + $word_len <= $max_width ) {
        $current_line .= $token;
        $current_length += $word_len;
        next;
      }

      if ( $current_length > 0 ) {
        push @wrapped_lines, $current_line;
        ( $current_line, $current_length ) = ( q{}, 0 );
      }

      # hard-wrap over-long words, carrying pending zero-width ANSI
      my $remaining = $token;
      my $prefix    = $current_line;

      if ( !$nostrict ) {
        while ( length($remaining) > $max_width ) {
          push @wrapped_lines, $prefix . substr $remaining, 0, $max_width;
          $prefix    = q{};
          $remaining = substr $remaining, $max_width;
        }
      }

      $current_line   = $prefix . $remaining;
      $current_length = length $remaining;
    }

    push @wrapped_lines, $current_line
      if length($current_line) > 0 || !@tokens;
  }

  return join "\n", @wrapped_lines;
}

########################################################################
sub _ansi_aware_count {
########################################################################
  my ( $self, $str ) = @_;

  # preserve cb_count precedence and non-ANSI behavior
  if ( $self->{options}{cb_count} || !$self->{options}{allowANSI} ) {
    return $ORIG_COUNT->( $self, $str );
  }

  if ( $self->{options}{allowHTML} ) {
    $str =~ s/<.+?>//gxsm;
  }

  $str =~ s/$ANSI_RE//gxsm;

  return length $str;
}

{
  no warnings 'redefine'; ## no critic (ProhibitNoWarnings)

  *Text::ASCIITable::count = \&_ansi_aware_count;
  *Text::ASCIITable::wrap  = \&_ansi_aware_wrap;

  # keep Wrap.pm's slot consistent for anyone importing it directly
  *Text::ASCIITable::Wrap::wrap = \&_ansi_aware_wrap;
}

1;

__END__

=pod

=head1 NAME

Text::ASCIITable::FixANSI - ANSI-safe wrapping and width counting for Text::ASCIITable

=head1 SYNOPSIS

 use Text::ASCIITable;
 use Text::ASCIITable::FixANSI;

=head1 DESCRIPTION

Process-wide patch for Text::ASCIITable 0.22. Fixes C<wrap()> splitting
ANSI escape sequences (and discarding the remainder of over-long words),
and widens C<count()> to strip multi-parameter SGR sequences. Retire when
the upstream fix ships.

=cut
