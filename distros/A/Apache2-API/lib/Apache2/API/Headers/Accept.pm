##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Headers/Accept.pm
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
package Apache2::API::Headers::Accept;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( Apache2::API::Headers::AcceptCommon );
    use vars qw( $VERSION $MATCH_PRIORITY_0_01_STYLE );
    use Module::Generic::HeaderValue;
    our $VERSION = 'v0.1.0';
};

use v5.26.1;
use strict;
use warnings;
use feature 'try';
no warnings 'experimental';

# qvalue as per rfc2616 <https://datatracker.ietf.org/doc/html/rfc2616#section-4.2>, rfc7231 and then rfc9110
my $MEDIA_RANGE = qr/(?:[A-Za-z0-9*]+\/[A-Za-z0-9*]+|\*\/\*)/;
my $QVALUE      = qr/(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)/;

# Useful alias
sub media_types { return( shift->preferences ); }

sub _full_match
{
    my( $self, $their, $our ) = @_;

    # Exact match
    return(1) if( $their->{type} eq $our->{type} && $their->{subtype} eq $our->{subtype} );

    # type/* match
    return(1) if( $their->{type} eq $our->{type} && $their->{subtype} eq '*' );

    # */* match is process at the wildcard level to return the first supported value
    return(0);
}

sub _is_wildcard
{
    my( $self, $their ) = @_;
    return(1) if( $their->{type} eq '*' && $their->{subtype} eq '*' );
    return(0);
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
        my $media = $hv->value->first;
        unless( defined( $media ) && length( $media ) )
        {
            next;
        }
        $media = lc( $media );
        next unless( $media =~ m{\A$MEDIA_RANGE\z} );
        # Found a duplicate, so we skip.
        next if( ++$seen->{ $media } > 1 );
        my( $type, $subtype ) = split( /\//, $media, 2 );
        push( @norm,
        {
            raw     => $media,
            type    => $type,
            subtype => $subtype,
        });
    }
    return( \@norm );
}

sub _parse
{
    my $self = shift( @_ );
    my $header = shift( @_ );
    # We do not collapse all the spaces like we did in AcceptLanguage, because they are used as parameters seprators.
    # We split first using comma by respecting the simple format.

    # As per the Module::Generic::HeaderValue documentation:
    # "Takes a header value that contains potentially multiple values separated by a proper comma and this returns an array object (Module::Generic::Array) of Module::Generic::HeaderValue objects."
    my $all = Module::Generic::HeaderValue->new_from_multi( $header ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    my $elements = [];
    my %best_q_for;
    foreach my $hv ( @$all )
    {
        # $hv->value returns an array object
        my $media = $hv->value->first;
        next unless( defined( $media ) && $media =~  m{\A$MEDIA_RANGE\z} );
        $media = lc( $media );
        my( $type, $subtype ) = split( /\//, $media, 2 );
        my $q = 1.0;
        my $params = $hv->params;
        if( exists( $params->{'q'} ) &&
            defined( $params->{'q'} ) &&
            length( $params->{'q'} ) &&
            $params->{'q'} =~ m/\A$QVALUE\z/ )
        {
            $q = 0 + $params->{'q'};
        }
        next if( $q <= 0 );

        push( @$elements,
        {
            token       => $media,
            type        => $type,
            subtype     => $subtype,
            quality     => $q,
            # We save it for later use
            params      => $params,
        });

        if( !exists( $best_q_for{ $media } ) || $q > $best_q_for{ $media } )
        {
            $best_q_for{ $media } = $q;
        }
    }

    # Keep only the records that have the best 'q' for their exact tag.
    @$elements = grep
    {
        my $keep = 0;
        if( exists( $best_q_for{ $_->{token} } ) )
        {
            $keep = ( $best_q_for{ $_->{token} } == $_->{quality} ) ? 1 : 0;
            delete( $best_q_for{ $_->{token} } ) if( $keep );
        }
        $keep;
    } @$elements;
    return( $elements );
}

sub _partial_match
{
    my( $self, $their, $our ) = @_;
    # Here, nothing beyond the type/* already handled in _full_match.
    return(0);
}

sub _specificity
{
    my( $self, $their, $our ) = @_;
    # The more there are wildcard parts on the preferences side, the more it is specific.
    # */* => 0, type/* => 1, type/subtype => 2
    return(2) if( $their->{type} ne '*' && $their->{subtype} ne '*' && $their->{type} eq $our->{type} && $their->{subtype} eq $our->{subtype} );
    return(1) if( $their->{type} eq $our->{type} && $their->{subtype} eq '*' );
    return(0);
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::API::Headers::Accept - Parser and matcher for HTTP Accept header

=head1 SYNOPSIS

    use Apache2::API::Headers::Accept;
    my $accept = Apache2::API::Headers::Accept->new('text/html;q=0.9,application/json');
    my $mime = $accept->match(['text/html', 'application/json']); # => 'text/html'
    # inspect client preferences (by q, desc):
    my $prefs = $a->preferences; # [ 'application/json', 'text/html' ]

=head1 DESCRIPTION

Parses the C<Accept> header and selects the best media type among the types you can serve. It supports exact matches (C<type/subtype>), type wildcards (C<type/*>), and full wildcards (C<*/*>), with quality values (C<q>) per RFC 7231 and RFC 9110.

It inherits from L<Apache2::API::Headers::AcceptCommon>.

The algorithm is as follows:

=over 4

=item * Specificity order (highest first): C<type/subtype> E<gt> C<type/*> E<gt> C<*/*>

=item * C<q> value primary sort; on tie, prefer more specific matches.

=item * C<*/*> at same C<q> never outranks a specific match; at strictly higher C<q> it picks the first supported item.

=item * Non-C<q> parameters (e.g. C<charset>, C<version>) do not influence matching; they are parsed but ignored for selection.

=back

=head1 CONSTRUCTOR

=head2 new( $header )

Creates a new instance with the given C<Accept> header string, and returns it.

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 METHODS

=head2 match( \@supported_media_types )

Returns the best matching media type, as a string, from the provided list.

If no suitable media type could be found, it returns an empty string, so you need to check the return value if it is defined or not to differentiate from errors.

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head2 media_types

This is an alias to L</preferences>

=head2 preferences

Read-only.

Returns an array reference of media types, submitted by the user in his HTTP request, sorted by decreasing quality (C<q>), with duplicates removed (highest C<q> kept).

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 EXAMPLES

=head2 1. More specific beats wildcard at same q

    my $a = Apache2::API::Headers::Accept->new( 'text/html;q=0.9, text/*;q=0.9' );
    $a->match( [ 'text/plain', 'text/html' ] );
    # "text/html"

=head2 2. */* is a fallback only

    my $a = Apache2::API::Headers::Accept->new( '*/*;q=0.9, application/json;q=0.9' );
    $a->match( [ 'image/png', 'text/html', 'application/json' ] );
    # "application/json"

=head2 3. */* with higher q wins and chooses first supported

    my $a = Apache2::API::Headers::Accept->new( '*/*;q=1.0, application/json;q=0.9' );
    $a->match( [ 'image/png', 'text/html', 'application/json' ] );
    # "image/png"

=head1 LEGACY MATCH PRIORITY

Set C<$Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE> to true to make equal-C<q> ties follow the order of your offers (the array reference of supported medias), instead of the header order. Full matches still outrank partial ones. Wildcards in a bucket are only used if nothing else matches. (see L<Apache2::API::Headers::AcceptCommon/"MATCH PRIORITY MODE"> for details).

=head1 PERFORMANCE

The matchers called with L<Apache2::API::Headers::AcceptCommon/match> loops through the array reference of supported medias times the number of parsed acceptable medias as submitted by the client.

Typical HTTP C<Accept> headers are small, so the performance should be very good.

L<Apache2::API::Headers::AcceptCommon/preferences> and sorted results are cached per object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::Headers::AcceptCommon>, L<Apache2::API::Headers::AcceptLanguage>, RFC 7231, RFC 9110.

L<Apache2::API::DateTime>, L<Apache2::API::Query>, L<Apache2::API::Request>, L<Apache2::API::Request::Params>, L<Apache2::API::Request::Upload>, L<Apache2::API::Response>, L<Apache2::API::Status>

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
