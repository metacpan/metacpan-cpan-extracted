package Dancer2::Plugin::Syntax::ParamKeywords;
# ABSTRACT: Parameter keywords for the lazy
# VERSION
$Dancer2::Plugin::Syntax::ParamKeywords::VERSION = '0.2.0';
use strict;
use warnings;
use Dancer2::Plugin;

plugin_keywords 
    route_param => sub {
        my ( $plugin, $param ) = @_;
        return $plugin->dsl->route_parameters->get( $param );
    },

    route_params => sub {
        my ( $plugin ) = @_;
        return $plugin->dsl->route_parameters;
    },

    query_param => sub {
        my ( $plugin, $param ) = @_;
        return $plugin->dsl->query_parameters->get( $param );
    },

    query_params => sub {
        my ( $plugin, $param ) = @_;
        my $params_hmv = $plugin->dsl->query_parameters;
        return $params_hmv->get_all( $param ) if defined $param;
        return $params_hmv;
    },

    body_param => sub {
        my ( $plugin, $param ) = @_;
        return $plugin->dsl->body_parameters->get( $param );
    },

    body_params => sub {
        my ( $plugin, $param ) = @_;
        my $params_hmv = $plugin->dsl->body_parameters;
        return $params_hmv->get_all( $param ) if defined $param;
        return $params_hmv;
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Syntax::ParamKeywords - Parameter keywords for the lazy

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Dancer2::Plugin::Syntax::ParamKeywords;

    # Sample URL: http://localhost:3000/my_route/baz/blah
    get '/my_route/:foo/:bar' => sub {
        my $params = route_params; # Hash::MultiValue object

        # This will show in your app log
        debug "We got us some foo!" if route_param( 'foo' ) eq 'baz';
    };

    # Sample URL: http://localhost:3000/my_other_route?foo=baz&bar=blah&bar=bah
    get '/my_other_route' => sub {
        my $params = query_params; # Hash::MultiValue object

        # This will show in your app log
        debug "We got us some foo!" if query_param( 'foo' ) eq 'baz';

        return join( ',', sort query_params( 'bar' ) ); # returns 'bah, blah'
    };

    # Sample URL: http://localhost:3000/my_post_route
    # Posted data: foo => 'bar', bar => 'baz', bar => 'quux'
    post '/my_last_route' => sub {
        my $params = body_params; # Hash::MultiValue object

        # This will show in your app log
        debug "We got us some foo!" if body_param( 'foo' ) eq 'bar';

        return join( ',', sort body_params( 'bar' ) ); # returns 'baz, quux'
    };

=head1 DESCRIPTION

Let's face it: L<Dancer2>'s parameter-fetching keywords take so much typing 
to use! Why can't they be shorter? Well now, dear reader, they are!

This module provides a little syntactic sugar to make getting query, route,
and body parameters just a little bit quicker. Instead of writing these:

    query_parameters->get( ... );
    query_parameters->get_all( ... );
    query_parameters
    body_parameters->get( ... );
    body_parameters->get_all( ... );
    body_parameters
    route_parameters->get( ... );
    route_parameters

You can write just these:

    query_param( ... );
    query_params( ... );
    query_params
    body_param( ... );
    body_params( ... );
    body_params
    route_param( ... );
    route_params

That's about 25-50% less typing in many cases. You're welcome.

=head1 KEYWORDS

=head2 query_param

This is the same as calling C<query_parameters-E<gt>get>. You must pass a
parameter name to get the value of.

=head2 query_params

If called without a parameter name, this is just like calling
C<query_parameters>. It will return a L<Hash::MultiValue> object containing
all of the query parameters that were passed.

When called with a parameter name, this is the same as calling 
C<query_parameters-E<gt>get_all>.

=head2 body_param

This is the equivalent of C<body_parameters-E<gt>get>. You must pass a
parameter name to get the value of.

=head2 body_params

When called without a parameter name, this is the same as calling
C<body_parameters>. It will return a L<Hash::MultiValue> object containing
all of the body parameters that were posted to your route.

When called with a parameter name, this acts the same as calling 
C<body_parameters-E<gt>get_all>.

=head2 route_param

This is the equivalent of C<route_parameters-E<gt>get>. You must pass a
parameter name to get.

=head2 route_params

When called without a parameter name, this is the equivalent of calling
C<route_parameters>. It will return a L<Hash::MultiValue> object containing
all of the route parameters that were passed.

Unlike C<query_params> and C<body_params>, you cannot assign multiple 
values to a single named parameter through route parameters in Dancer2.
As such, you cannot pass a parameter to C<route_params> as you can with
the other two methods - the underlying C<get_all> functionality for
route parameters does not exist.

=head1 SEE ALSO

=over 4

=item * L<Dancer2>

=back

=head1 AUTHOR

Jason A. Crome <cromedome@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Jason A. Crome.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
