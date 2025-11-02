##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Headers/AcceptLanguage.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/10/14
## Modified 2025/10/14
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Headers::AcceptLanguage;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( Apache2::API::Headers::AcceptCommon );
    use vars qw( $VERSION $MATCH_PRIORITY_0_01_STYLE );
    use Locale::Unicode;
    use Module::Generic::HeaderValue;
    our $VERSION = 'v0.1.0';
};

use v5.26.1;
use strict;
use warnings;
use feature 'try';
no warnings 'experimental';

# Patterns for accept language
# my $LANGUAGE_RANGE = qr/(?:[A-Za-z0-9]{1,8}(?:-[A-Za-z0-9]{1,8})*|\*)/;
# No need to re-invent the wheel, but instead of using this regular expression, best to use Locale::Unicode->matches that returns an hash reference of locale parts upon success or an empty string in scalar context, or an empty list in list context.
my $LANGUAGE_RANGE = $Locale::Unicode::LOCALE_RE;
my $QVALUE         = qr/(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)/;

# Useful alias, similar to HTTP::AcceptLanguage
sub languages { return( shift->preferences ); }

sub locales { return( shift->preferences ); }

sub _full_match
{
    my( $self, $their, $our ) = @_;
    return( ( $their->{locale_lc} eq $our->{locale_lc} ) ? 1 : 0 );
}

sub _is_wildcard
{
    my( $self, $ph ) = @_;
    return( ( $ph->{locale} && $ph->{locale} eq '*' ) ? 1 : 0 );
}

sub _normalize_supported
{
    my( $self, @supported ) = @_;
    my @norm;

    my $seen = {};
    for my $token ( @supported )
    {
        next unless( defined( $token ) && length( $token ) );
        my $hv = Module::Generic::HeaderValue->new_from_header( $token ) || next;
        my $l = $hv->value->first;
        unless( defined( $l ) && length( $l ) )
        {
            next;
        }
        my $locale = Locale::Unicode->new( $l );
        if( !$locale )
        {
            warn( "Locale provided '$l' is not a valid locale." ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
        }
        my $base = $locale->base;
        # Locale with the same base are considered identical, which means their BCP47 or Unicode CLDR extension are rightfully ignored.
        next if( ++$seen->{ lc( $base ) } > 1 );
        my $lang = $locale->language;
        push( @norm,
        {
            raw         => $locale,
            # en-Latn-US-posix-t-de-AT-t0-und-x0-medical -> en
            language    => $lang,
            language_lc => lc( $lang ),
            # en-Latn-US-posix-t-de-AT-t0-und-x0-medical -> en-Latn-US-posix
            # en-US -> en-US
            locale      => $base,
            locale_lc   => lc( $base ),
        });
    }
    return( \@norm );
}

sub _parse
{
    my $self = shift( @_ );
    my $header = shift( @_ );
    my $h = $header;
    $h =~ s/[[:blank:]]+//g;

    # As per the Module::Generic::HeaderValue documentation:
    # "Takes a header value that contains potentially multiple values separated by a proper comma and this returns an array object (Module::Generic::Array) of Module::Generic::HeaderValue objects."
    my $all = Module::Generic::HeaderValue->new_from_multi( $header ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );

    my $elements = [];
    my %best_q_for;

    foreach my $hv ( @$all )
    {
        my $token = $hv->value->first;
        my $q = 1;
        my $params = $hv->params;
        if( exists( $params->{'q'} ) &&
            defined( $params->{'q'} ) &&
            length( $params->{'q'} ) &&
            $params->{'q'} =~ m/\A$QVALUE\z/ )
        {
            $q = 0 + $params->{'q'};
        }
        next unless( $token && $q > 0 );

        # We need to clarify the vocabulary here, as per the BCP47, and the Unicode CLDR
        # A language is a 2 or 3-characters code, such as fr or fra, oe en or eng
        # A locale carries more information, such as, but not limited to, the country. It could also have a script, and much more information.
        # For example, a valid locale: fr-BE, ja-JP, or en-Latn-AU or even ja-Kana-t-it
        my $locale = Locale::Unicode->new( $token );
        if( !$locale )
        {
            warn( "Locale provided '$token' is not a valid locale." ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
            next;
        }

        # en-Latn-US-posix-t-de-AT-t0-und-x0-medical -> en-Latn-US
        my $base = $locale->base;
        # The 2 to 3-characters code
        # en-Latn-US-posix-t-de-AT-t0-und-x0-medical -> en
        my $lang = $locale->language;
        my $locale_lc = lc( $base );
        push( @$elements,
        {
            token       => $token,
            # The Locale::Unicode object
            locale      => $locale,
            locale_lc   => $locale_lc,
            language_lc => lc( $lang ),
            quality     => $q + 0,
        });

        if( !exists( $best_q_for{ $locale_lc } ) || $q > $best_q_for{ $locale_lc } )
        {
            $best_q_for{ $locale_lc } = $q;
        }
    }

    # Keep only the records that have the best 'q' for their exact tag.
    @$elements = grep{
        my $keep = 0;
        if( exists( $best_q_for{ $_->{locale_lc} } ) )
        {
            $keep = ( $best_q_for{ $_->{locale_lc} } == $_->{quality} ) ? 1 : 0;
            delete( $best_q_for{ $_->{locale_lc} } ) if( $keep );
        }
        $keep;
    } @$elements;

    return( $elements );
}

sub _partial_match
{
    my( $self, $their, $our ) = @_;
    # ex: "en" (language part of the locale) matches "en-GB"
    return( ( $their->{language_lc} eq $our->{language_lc} ) ? 1 : 0 );
}

# For the locales, we do not use a granularity of numbered specificity;
# we return 2 for full, and 1 for partial in order to remain coherent with Accept.
sub _specificity
{
    my( $self, $their, $our ) = @_;
    return(2) if( $self->_full_match( $their, $our ) );
    return(1) if( $self->_partial_match( $their, $our ) );
    return(0);
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::API::Headers::AcceptLanguage - Parser and matcher for HTTP Accept-Language header

=head1 SYNOPSIS

    use Apache2::API::Headers::AcceptLanguage;
    my $al = Apache2::API::Headers::AcceptLanguage->new( 'fr-FR;q=0.9,en;q=0.8' );
    my $locale = $al->match( ['en', 'fr-FR'] ); # => 'fr-FR'
    my $prefs = $al->prefs; # => ['fr-FR', 'en']

=head1 DESCRIPTION

Parses HTTP C<Accept-Language> header and provides the L<Apache2::API::Headers::AcceptCommon/match> method to match against supported locales (languages).

Full tag matches (e.g. C<fr-FR>) trump primary-language matches (e.g. C<fr> matching C<fr-CA>), with quality values (C<q>) per RFC 7231 and RFC 9110. Language/locale parsing is done with L<Locale::Unicode>.

It inherits from L<Apache2::API::Headers::AcceptCommon>.

The algorithm is as follows:

=over 4

=item * Exact C<locale> match beats primary language match at the same C<q>. For example, C<fr-CA> beats C<fr>

=item * Primary language tokens, such as C<en>, can match more specific locales, such as C<en-GB>.

=item * C<*> wildcard is a low-specificity fallback and never outranks an equal-C<q> specific match.

=item * Duplicates keep highest C<q>; C<q=0> excludes a tag.

=back

=head1 CONSTRUCTOR

=head2 new( $header )

Creates a new instance with the given C<Accept-Language> header string, and returns it.

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 METHODS

=head2 languages

As per BCP47, and Unicode CLDR, a C<language> is just a 2 to 3-characters code ths is possibly part of a L<locale|Locale::Unicode>. Yet, this method is defined here for convenience.

This is an alias to L</preferences>

=head2 locales

This is an alias to L</preferences>

=head2 match( \@supported_locales )

Returns the best matching L<locale|Locale::Unicode> from the provided list of supported locales.

It returns an empty string if nothing matched, or sets an L<error|Module::Generic/error> and returns C<undef> in scalar context, or returns an empty list in list context.

=head2 preferences

Read-only.

Returns an array reference of locales, submitted by the user C<Accept-Language> header in his HTTP request, sorted by decreasing quality, with duplicates removed (keeping highest C<q>).

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 EXAMPLES

=head2 1. Exact beats primary language at same q

    my $al = Apache2::API::Headers::AcceptLanguage->new('fr-FR;q=0.9, fr;q=0.9');
    $al->match([ 'fr-CA', 'fr-FR' ]);
    # "fr-FR"

=head2 2. Primary language matches a more specific server locale

    my $al = Apache2::API::Headers::AcceptLanguage->new('en;q=0.9, fr;q=0.8');
    $al->match([ 'fr-FR', 'en-GB' ]);
    # "en-GB"

=head2 3. Wildcard at higher q picks first supported

    my $al = Apache2::API::Headers::AcceptLanguage->new('*;q=1.0, en;q=0.9');
    $al->match([ 'fr-FR', 'en-GB' ]);
    # "fr-FR"

=head1 LEGACY MATCH PRIORITY

Set C<$Apache2::API::Headers::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE> to true to apply “offer order” tie-breaking within equal-C<q> buckets (see L<Apache2::API::Headers::AcceptCommon/"MATCH PRIORITY MODE"> for details).

=head1 NOTES ON TAGS

Tags are parsed using L<Locale::Unicode>. Invalid tags are discarded. For robust behavior, pass your supported locales in the same syntax you intend to serve, such as C<en>, C<en-GB>, C<ja-JP>.

=head1 PERFORMANCE

The matchers called with L<Apache2::API::Headers::AcceptCommon/match> loops through the array reference of supported locales times the number of parsed acceptable locales as submitted by the client.

Typical HTTP C<Accept-Language> headers are small, so the performance should be very good.

L<Apache2::API::Headers::AcceptCommon/preferences> and sorted results are cached per object.

=head1 CREDITS

Based on L<HTTP::AcceptLanguage> by Kazuhiro Osawa

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::Headers::Accept>, L<Apache2::API::Headers::AcceptCommon>, L<Locale::Unicode>, RFC 5646 (BCP 47), RFC 7231, RFC 9110.

L<Apache2::API::DateTime>, L<Apache2::API::Query>, L<Apache2::API::Request>, L<Apache2::API::Request::Params>, L<Apache2::API::Request::Upload>, L<Apache2::API::Response>, L<Apache2::API::Status>

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
