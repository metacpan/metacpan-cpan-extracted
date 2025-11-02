##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Headers/AcceptCommon.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/10/14
## Modified 2025/10/15
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Headers::AcceptCommon;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use v5.26.1;
use strict;
use warnings;
use feature 'try';
no warnings 'experimental';

sub init
{
    my $self = shift( @_ );
    my $header = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $parsed = [];
    if( defined( $header ) && length( $header ) )
    {
        $parsed = $self->_parse( $header ) || return( $self->pass_error );
    }
    $self->{header} = $header;
    $self->{parsed_header}  = $parsed;
    # Cache
    $self->{_sorted} = undef;
    $self->{_prefs}  = undef;
    return( $self );
}

# Read-only
sub header { return( shift->_set_get_scalar( 'header' ) ); }

# Returns an empty string if no match, and undef upon error with the error object accessible with the 'error' method inherited from Module::Generic
sub match
{
    my $self = shift( @_ );
    my $supported = shift( @_ );
    if( !$supported )
    {
        return( $self->error( "No supported values was provided." ) );
    }
    # _is_array also returns true if this is an array object, such as Module::Generic::Array
    elsif( !$self->_is_array( $supported ) )
    {
        return( $self->error( "Value provided is not an array reference." ) );
    }
    elsif( !scalar( @$supported ) )
    {
        warn( "Warning only: no supported token were provided." ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
        return( '' );
    }

    # Si pas de header utilisable, RFC : tout est accepté => premier offert.
    # If no usable jeaders, RFC says that anything is acceptable, so we pick the first one supported
    if( !@{$self->{parsed_header}} )
    {
        return( $supported->[0] );
    }

    # Normalise les offres côté serveur (subclasses).
    my $norm = $self->_normalize_supported( @$supported ) ||
        return( $self->pass_error );
    if( !scalar( @$norm ) )
    {
        warn( "Warning only: Normalised token produced an empty list!" ) if( $self->_is_warnings_enabled( 'Apache2::API' ) );
        return( '' );
    }

    # Strategy:
    # 1) Iterate through the items sorted by q (client-side)
    # 2) For each equal 'q', two branches:
    #    - mode 0.01: we accumulate, then choose according to the order of the supported items
    #    - mode >= 0.02: we match in the order of the header (client)
    #
    # Get the symbol '$MATCH_PRIORITY_0_01_STYLE' in our object class namespace.
    # The symbol is in each respective class namespace, so the user can refer to $Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE for example, and NOT $Apache2::API::Headers::AcceptCommon::MATCH_PRIORITY_0_01_STYLE
    my $match_style_ref = $self->_get_symbol( '$MATCH_PRIORITY_0_01_STYLE' );
    my $match_style = $match_style_ref ? $$match_style_ref : undef;
    if( $match_style )
    {
        my $current_q = undef;
        my @bucket    = ();

        # NOTE: flush_bucket()
        my $flush_bucket = sub
        {
            return if( !@bucket );

            my $saw_wildcard = 0;

            # Prioritise full matches first
            for my $our ( @$norm )
            {
                for my $their ( @bucket )
                {
                    $saw_wildcard ||= $self->_is_wildcard( $their );
        
                    if( $self->_full_match( $their, $our ) )
                    {
                        return( $our->{raw} );
                    }
                }
            }

            # partial matches next
            for my $our ( @$norm )
            {
                for my $their ( @bucket )
                {
                    if( $self->_partial_match( $their, $our ) )
                    {
                        return( $our->{raw} );
                    }
                }
            }

            # nothing else in this q-bucket? fallback to wildcard if present
            return( $saw_wildcard ? $norm->[0]->{raw} : undef );
        };


        for my $their ( @{ $self->_sorted } )
        {
            if( !defined( $current_q ) ||
                $their->{quality} == $current_q )
            {
                push( @bucket, $their );
                $current_q = $their->{quality} if( !defined( $current_q ) );
                next;
            }

            # q a changé, vide le bucket précédent
            my $m = $flush_bucket->();
            return( $m ) if( defined( $m ) );

            @bucket    = ( $their );
            $current_q = $their->{quality};
        }

        # Last bucket
        my $m = $flush_bucket->();
        return( $m ) if( defined( $m ) );

        # Nothing found; return an empty string. undef is reserved for errors
        return( '' );
    }
    else
    {
        # Policy >= 0.02: for each preference on the client side (sorted by q), try a full match on all the supported items, then partial.
        # For the MIME types, we account for specificity.
        my $best_match     = undef;
        my $best_q         = -1;
        my $best_specific  = -1;

        PREFERENCE:
        for my $their ( @{$self->_sorted} )
        {
            # Wildcard immediate => first supported item
            # if( $self->_is_wildcard( $their ) )
            # {
            #     return( $supported->[0] );
            # }
            if( $self->_is_wildcard( $their ) )
            {
                # wildcard matches anything; pick the first supported as the “shape” of the match
                my $cand_raw  = $supported->[0];
                # */* is least specific
                my $cand_spec = 0;
                my $cand_q    = $their->{quality} + 0;

                # adopt only if it strictly beats current best q,
                # or if we have no candidate yet (best_specific < 0)
                if( $cand_q > $best_q || ( $cand_q == $best_q && $best_specific < 0 ) )
                {
                    $best_match    = $cand_raw;
                    $best_q        = $cand_q;
                    $best_specific = $cand_spec;
                }

                # continue; a later exact/type/* match at the same q may replace it
                next PREFERENCE;
            }

            # We search first for a full match
            my $found_exact = undef;
            my $found_spec  = -1;

            for my $our ( @$norm )
            {
                if( $self->_full_match( $their, $our ) )
                {
                    my $spec = $self->_specificity( $their, $our );
                    if( !defined( $found_exact ) || $spec > $found_spec )
                    {
                        $found_exact = $our->{raw};
                        $found_spec  = $spec;
                    }
                }
                else
                {
                    next;
                }
            }

            if( defined( $found_exact ) )
            {
                # For a better 'q' or a better specificity, we replace
                if( $their->{quality} > $best_q ||
                    ( $their->{quality} == $best_q && $found_spec > $best_specific ) )
                {
                    $best_match    = $found_exact;
                    $best_q        = $their->{quality};
                    $best_specific = $found_spec;
                }
                next PREFERENCE;
            }

            # Sinon partial match (si applicable)
            my $found_partial = undef;
            for my $our ( @$norm )
            {
                if( $self->_partial_match( $their, $our ) )
                {
                    $self->message( 4, "Our token '", $our->{raw}, "' is a partial match for the acceptable token '", $their->{token}, "'" ); 
                    # Specificity is weaker than the full one. We take note, but will remain < full
                    my $spec = $self->_specificity( $their, $our );
                    $found_partial = $our->{raw};
                    $found_spec    = $spec;
                    last;
                }
            }

            if( defined( $found_partial ) )
            {
                if( $their->{quality} > $best_q ||
                    ( $their->{quality} == $best_q && $found_spec > $best_specific ) )
                {
                    $best_match    = $found_partial;
                    $best_q        = $their->{quality};
                    $best_specific = $found_spec;
                }
            }
        }
        return( $best_match );
    }
}

sub preferences
{
    my $self = shift( @_ );

    # Cached
    return( [@{$self->{_prefs}}] ) if( $self->{_prefs} );

    my @pref = map{ $_->{token} } @{$self->_sorted};
    $self->{_prefs} = \@pref;
    # For safety, we return a copy
    return( [@pref] );
}

# Abstract – must be overridden by subclasses.
sub _full_match
{
    die( ref( $_[0] ) . "::_full_match() not implemented\n" );
}

# Abstract – must be overridden by subclasses.
sub _is_wildcard
{
    die( ref( $_[0] ) . "::_is_wildcard() not implemented\n" );
}

# Abstract – must be overridden by subclasses.
sub _normalize_supported
{
    die( ref( $_[0] ) . "::_normalize_supported() not implemented\n" );
}

# Abstract – must be overridden by subclasses.
sub _parse
{
    die( ref( $_[0] ) . "::_parse() not implemented\n" );
}

# Optional – subclasses may override. Default: no partial match.
sub _partial_match { return(0); }

sub _sorted
{
    my $self = shift( @_ );
    # Cached
    return( $self->{_sorted} ) if( $self->{_sorted} );

    # Decreasing sort
    my @s = sort{ $b->{quality} <=> $a->{quality} } @{$self->{parsed_header}};
    $self->{_sorted} = \@s;
    return( $self->{_sorted} );
}

# Optional – subclasses may override. Default specificity = 0 (languages
# utiliseront 2/1/0 implicitement via ordre; Accept l’overridera).
sub _specificity { return(0); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Apache2::API::Headers::AcceptCommon - Common base class for parsing HTTP Accept and Accept-Language headers

=head1 SYNOPSIS

    use Apache2::API::Headers::Accept;
    use Apache2::API::Headers::AcceptLanguage;

    my $accept = Apache2::API::Headers::Accept->new( 'text/html;q=0.9,application/json' );
    my $mime = $accept->match( ['text/html', 'application/json'] ); # => 'text/html'

    my $al = Apache2::API::Headers::AcceptLanguage->new( 'fr-FR;q=0.9,en;q=0.8' );
    my $locale = $lang->match( ['en', 'fr-FR'] ); # => 'fr-FR'

=head1 DESCRIPTION

L<Apache2::API::Headers::AcceptCommon> implements a base class for parsing, sorting, and matching rules for HTTP headers that carry I<quality values> (C<q>), such as C<Accept> and C<Accept-Language>. Subclasses provide the domain-specific details:

=over 4

=item * how to parse a token, such as C<type/subtype> vs. language tags

=item * what counts as a full match vs partial match

=item * how to detect wildcards and how C<specificity> is scored

=back

This base class guarantees:

=over 4

=item * Stable, decreasing sort by C<q> (highest first)

=item * Duplicate tokens keep the highest C<q>

=item * C<q=0> excludes a token

=item * Empty/absent header means “everything acceptable” → first supported wins

=item * Return values: empty string on “no match”, C<undef> on error (with L<Module::Generic/error>)

=back

=head1 CONSTRUCTOR

=head2 new( $header, %opts )

Creates a new matcher. C<$header> may be an empty string, but must always be provided. It returns a new object.

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 METHODS

=head2 header

Read-only

Returns the header value initially provided during object instantiation.

=head2 match( \@supported_tokens )

Given an array reference of server-supported tokens, returns the best match as a string, based on quality and specificity.

If none could be found, it returns an empty string, or if an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context. 

Semantics:

=over 4

=item * If no usable header was provided, the first entry in the array reference of supported tokens is returned.

=item * For each client preference (sorted by C<q> desc), exact matches are preferred over partial ones (as defined by the subclass), and then by specificity (subclasses implement C<_specificity>).

=item * Wildcards are treated as I<candidates> with the lowest specificity. They never preempt an equal-C<q> exact match.

=item * Legacy tie-breaking is available, see L</MATCH PRIORITY MODE>.

=back

=head2 preferences

Read-only.

Returns an array reference of the client tokens, sorted by decreasing quality weight (C<q>) as submitted upon the HTTP request, with duplicates removed (keeping highest C<q>). Always returns an array reference (even when cached).

So, for example:

    my $accept = Apache2::API::Headers::Accept->new( 'text/html;q=0.9,application/json' );
    my $prefs  = $accept->preferences; # ['application/json', 'text/html']

If an error occurred, it sets an error that can be retrieved with the L<error method|Module::Generic/error>, and it returns C<undef> in scalar context, or an empty list in list context.

=head1 MATCH PRIORITY MODE

Two policies are supported for tie-breaking when several tokens have the same C<q>. You can choose per subclass:

=over 4

=item * Modern (default): tie favors header order (client’s order) and specificity.

=item * Legacy C<0.01> style: set the package variable C<Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE = 1> or C<Apache2::API::Headers::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE = 1>. At each equal-C<q> bucket, the choice follows the I<server supported order> (first match in C<\@supported>), with full matches beating partial ones. Wildcards in the bucket are only used if nothing else is matched.

=back

=head1 DIAGNOSTICS

This module registers warnings in category C<Apache2::API>. With debugging enabled (via L<Module::Generic>), you will see trace messages such as parsing steps and why a candidate was chosen.

=head1 THREAD SAFETY

All state is per object; no shared mutable globals. Thus, this module is safe to use in threads.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::Headers::Accept>, L<Apache2::API::Headers::AcceptLanguage>, L<Module::Generic::HeaderValue>, RFC 7231, RFC 9110.

L<Apache2::API::DateTime>, L<Apache2::API::Query>, L<Apache2::API::Request>, L<Apache2::API::Request::Params>, L<Apache2::API::Request::Upload>, L<Apache2::API::Response>, L<Apache2::API::Status>

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
