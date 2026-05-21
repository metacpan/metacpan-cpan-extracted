package Data::Printer::Filter::EscapeNonPrintable;

use v5.26.0;

use strict;
use warnings;
use feature qw< signatures >;
no warnings qw< experimental::signatures >;

use Data::Printer::Filter;

our $VERSION = 'v1.0.1';

filter 'SCALAR' => \&parse;

my $VT     = "\x{0b}";  # ASCII vertical tab
my $VT_ESC = '\v';      # "     (C escape)
my $ESC    = "\x{1b}";  # ASCII ESC
my $DEL    = "\x{7f}";  # ASCII DEL

# DDP's missing ASCII control chars + DEL.
# See ascii(7).
my $MISSING_CHARS_RGX = qr{
    [ \x{01}-\x{06} \x{0e}-\x{1a} \x{1c}-\x{1f} $DEL ]
}xx;

my $VT_OR_MISSING_RGX = qr{
    (?'VT' \Q$VT\E+)
    |
    ${MISSING_CHARS_RGX}+
}x;

# ANSI reset color code.
# See https://en.wikipedia.org/wiki/ANSI_escape_code.
my $RESET_COLOR_RGX = qr{
    $ESC \[ 0? m
}x;

sub parse ( $scalar_ref, $ddp )
{
    if ( defined $scalar_ref->$* && $ddp->print_escapes ) {
        # Only process the scalar after DDP filters it, otherwise all missing chars
        # will be recolorized.
        my $str = Data::Printer::Filter::SCALAR::parse( $scalar_ref, $ddp );

        # Escape the vertical tabs to '\v' and remaining missing chars to octal;
        # colorize them when required.
        $str =~ s{
            $VT_OR_MISSING_RGX
        }
        {
            # Escape multiple chars in one go, e.g. \x0b\x0b\x0b
            my $char = defined $+{VT}
              ? $& =~ s{$VT}{$VT_ESC}gr                                 # \v
              : sprintf( ('\\%03o') x length $&, unpack( 'C*', $& ) );  # Octal

            if ( $ddp->colored ) {
                # NOTE:
                #   'string' color must be restored because this filter is injecting colors
                #   in an already colored string, or else injected colors propagate until
                #   the end of string.

                # Strip trailing reset codes.
                my $escaped = $ddp->maybe_colorize( $char, 'escaped' ) =~ s{$RESET_COLOR_RGX\z}{}r;
                my $restore = $ddp->maybe_colorize( '',    'string' )  =~ s{$RESET_COLOR_RGX\z}{}r;

                $escaped . $restore;
            }
            else {
                $char;
            }
        }gex;

        return $str;
    }

    return;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

Data::Printer::Filter::EscapeNonPrintable - escape missing ASCII nonprintable characters

=head1 SYNOPSIS

In your F<.dataprinter>:

  print_escapes = 1
  filters       = EscapeNonPrintable

Alternatively:

  use DDP print_escapes => 1, filters => ['EscapeNonPrintable'];

=head1 DESCRIPTION

This module is a filter plugin for L<Data::Printer>.

=head2 Rationale

Since L<DDP> does not escape all ASCII control chars in L<print_escapes|Data::Printer::Object/print_escapes>,
this filter escapes them to octal notation. Vertical tab (C<\x0b>) and DEL (C<\x7f>)
chars are also missed, thus escaped.

All the missing chars are colorized to their C<escaped> L<color theme|Data::Printer::Theme>.

Note that this is a hack; the proper way to fix this should be to patch DDP.

See:

=over 4

=item *

L<https://github.com/garu/Data-Printer/issues/184>

=item *

L<https://github.com/garu/Data-Printer/pull/101>

=item *

L<https://github.com/garu/Data-Printer/pull/201>

=back

=head1 DECORATING

To call this filter and process its result from another filter, you can use:

  my $str = Data::Printer::Filter::EscapeNonPrintable::parse( $ref, $ddp );

Note that the loading order of filters matters, so ensure the caller is the last one in the chain.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/Data-Printer-Filter-EscapeNonPrintable/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<Data::Printer>

=item *

L<Data::Printer::Filter>

=item *

L<ascii(7)>

=item *

L<https://en.wikipedia.org/wiki/C0_and_C1_control_codes>

=item *

L<https://en.wikipedia.org/wiki/Escape_sequences_in_C>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut

1;
