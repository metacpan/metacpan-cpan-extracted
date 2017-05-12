package Business::SWIFT;

use warnings;
use strict;

use Locales ;

=head1 NAME

Business::SWIFT - Validate SWIFT/BIC Bank identifiers.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module implements the SWIFT BIC format validation.

It checks if the given SWIFT BIC code is well-formed according
to the ISO 9362 Specification. It does not check if the code is a
valid actual bank code.


    use Business::SWIFT;

    if ( Business::SWIFT->validateBIC('DEUTDEFF') ){
        .. do stuff ..
    }


Based on the following specification:
http://en.wikipedia.org/wiki/ISO_9362

=head1 FUNCTIONS

=head2 validateBIC

Returns a true value if the given BIC code is correct. False otherwise.

Code letters have to be uppercase.

This is a class method.


Usage example:
    
    if ( Business::SWIFT->validateBIC('DEUTDEFF') ){
       .. do stuff ..
    }
    

=cut

sub validateBIC{
    my ( $class , $candidate ) = @_ ;
    
    my $candLength = length($candidate) ;
    if( ( 8 != $candLength ) && ( 11 != $candLength ) ){
        return 0;
    }
    
    my ( $bankCode , $countryCode ,
         $locationCode , $branchCode ) = ( $candidate =~ /^([A-Z]{4})([A-Z]{2})([A-Z0-9]{2})([A-Z0-9]{3})?/  );
    if( ! $bankCode ){
        return 0;
    }
    
    my $en = Locales->new( "en" );
    
    if ( ! $en->get_territory_from_code( $countryCode ) ){
        return 0;
    }
    
    if ( ! $locationCode ){
        return 0;
    }
    
    if ( ( $candLength == 11 ) && ( ! $branchCode ) ){
        return 0;
    }
    
    ## All is correct
    return 1;
}


=head1 AUTHOR

Jerome Eteve C<< <jerome at eteve.net> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-business-swift at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-SWIFT>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::SWIFT

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-SWIFT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-SWIFT>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-SWIFT>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-SWIFT>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Careerjet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Business::SWIFT
