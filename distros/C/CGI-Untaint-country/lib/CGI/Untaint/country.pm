package CGI::Untaint::country;

use warnings;
use strict;

use Locale::Country();

use base 'CGI::Untaint::printable';

=head1 NAME

CGI::Untaint::country - validate a country code or name

=cut

our $VERSION = 0.2;

=head1 SYNOPSIS

    use CGI::Untaint;
    my $handler = CGI::Untaint->new($q->Vars);
                                                                                # submit:
    $country_code2   = $handler->extract(-as_country          => 'country');    # 2 letter code e.g. 'uk'
    $country_code2   = $handler->extract(-as_countrycode      => 'country');    # same as above 
    $country_name    = $handler->extract(-as_countryname      => 'country');    # name e.g. 'United Kingdom'
    $country_code3   = $handler->extract(-as_countrycode3     => 'country');    # 3 letter code e.g. 'gbr'
    $country_code2   = $handler->extract(-as_to_countrycode   => 'country');    # name
    $country_code3   = $handler->extract(-as_to_countrycode3  => 'country');    # name
    $country_codenum = $handler->extract(-as_countrynumber    => 'country');    # numeric code e.g. '064'
    $country_codenum = $handler->extract(-as_to_countrynumber => 'country');    # name
    

=head1 DESCRIPTION

Verifies that the submitted value is a valid ISO 3166-1 country code, or a known name.
See L<Locale::Country|Locale::Country>.

=head1 METHODS

=over 4

=item is_valid

=back

=cut

sub is_valid {
    my ( $self ) = @_;
    
    my $codeset = $self->_codeset;
    
    # code in, code out
    return Locale::Country::code2country( $self->value, $codeset );
}

sub _codeset { Locale::Constants::LOCALE_CODE_ALPHA_2 }

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-untaint-country@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
