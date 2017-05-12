package Convert::AnyBase;

use warnings;
use strict;

=head1 NAME

Convert::AnyBase - Convert (encode/decode) numbers to and from an arbitrary base

=head1 VERSION

Version 0.010

=cut

our $VERSION = '0.010';

=head1 SYNOPSIS

    use Convert::AnyBase

    # A hex encoder/decoder
    my $hex = Convert::AnyBase->new( set => '0123456789abcdef', normalize => sub { lc } )
    $hex->encode( 10 )  # a
    $hex->encode( 100 ) # 64
    $hex->decode( 4d2 ) # 1234

    # A Crockford encoder/decoder (http://www.crockford.com/wrmg/base32.html)
    Convert::AnyBase->new( set => ( join '', 0 .. 9, 'a' .. 'h', 'j', 'k', 'm', 'n', 'p' .. 't', 'v', 'w', 'x', 'y', 'z' ),
        normalize => sub { s/[oO]/0/g; s/[iIlL]/1/g; lc }, # o, O => 0 / i, I, l, L => 1
    )

=head1 DESCRIPTION

Convert::AnyBase is a tool for converting numbers to and from arbitrary symbol sets.

=head1 USAGE

=head2 $converter = Convert::AnyBase->new( ... )

Create a new converter for the given base. The arguments are:

    set     A string representing the base 'alphabet'. Each character is a different symbol for the base.
            The length of the string is the base of the system. The 0-value is the first character, the
            1-value is the second character, etc. For example, hexadecimal would be represented by the following:
    
                '0123456789abcdef'

    normalize   A code reference for normalizing a string before decoding. The code should operate on $_
                and return the sanitized string. The normalizer can be used to consistently lowercase, 
                uppercase, or canocalize input, etc. A normalizer for Crockford (base 32):
            
                    sub {
                        s/[oO]/0/g;     # Translate o/O to 0
                        s/[iIlL]/1/g;   # Translate i/I/l/L to 1
                        lc;             # Lowercase and return the result
                    }

=head2 $string = $converter->encode( <number> )

Encode <number> into a string 

=head2 $number = $converter->decode( <string> )

Decode <string> into a number

=head2 Convert::AnyBase->hex

A hex converter

=head2 Convert::AnyBase->decimal

A decimal (string) converter

=head2 Convert::AnyBase->crockford

A Crockford converter

=cut

sub new {
    shift;
    require Convert::AnyBase::Converter;
    return Convert::AnyBase::Converter->new( @_ );
}

{
    my ( $hex, $crockford, $decimal );
    
    sub hex {
        return $hex || __PACKAGE__->new( set => ( join '', 0 .. 9, 'a' .. 'f' ), normalize => sub { lc } );
    }
    
    sub crockford {
        return $crockford ||= __PACKAGE__->new( set => ( join '', 0 .. 9, 'a' .. 'h', 'j', 'k', 'm', 'n', 'p' .. 't', 'v', 'w', 'x', 'y', 'z' ),
            normalize => sub { s/[oO]/0/g; s/[iIlL]/1/g; lc },
        );
    }

    sub decimal {
        return $decimal ||= __PACKAGE__->new( set => ( join '', 0 .. 9, ) );
    }
}

=head1 SEE ALSO

L<Encode::Base32::Crockford>

L<Convert::BaseN>

L<Math::BaseCnv>

L<Math::NumberBase>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-anybase at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-AnyBase>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::AnyBase


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-AnyBase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-AnyBase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-AnyBase>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-AnyBase/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Convert::AnyBase
