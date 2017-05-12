#!/usr/bin/perl
package Catalyst::Plugin::Params::Nested;

use strict;
use warnings;
use 5.8.1;

use MRO::Compat;
use Catalyst::Plugin::Params::Nested::Expander ();

our $VERSION = "0.05";

sub prepare_uploads {
    my $c = shift;
    my $ret = $c->maybe::next::method( @_ );

    my $params = $c->req->params;

    %$params = (
        %$params,
        %{ Catalyst::Plugin::Params::Nested::Expander->expand_cgi( $c->req ) },
    );

    $ret;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Params::Nested - Nested form parameters (ala Ruby on Rails).

=head1 SYNOPSIS

    use Catalyst qw/Params::Nested/;

    # using this html

    <form ...>
        <!-- can be with either subscripted or dot notation -->
        <input name="foo[bar]" ... />
        <input name="foo.gorch" ... />
    </form>

    # turns params into hashrefs:

    $c->req->param('foo')->{bar};

    $c->req->params({
        # extra params
        foo => {
            bar => ...,
            gorch => ...
        },

        # original params untouched
        'foo[bar]' => ...,
        'foo.gorch' => ...,
    });

=head1 DESCRIPTION

Ruby on Rails has a nice feature to create nested parameters that help with
the organization of data in a form - parameters can be an arbitrarily deep
nested structure.

The way this structure is denoted is that when you construct a form the field
names have a special syntax which is parsed.

This plugin supports two syntaxes:

=over 4

=item dot notation

    <input name="foo.bar.gorch" />

=item subscript notation

    <input name="foo[bar][gorch]" />

=back

When reading query parameters from C<< $c->req >> you can now access the all the items starting
with "foo" as one entity using C<< $c->req->param('foo'); >>. Each subitem, denoted by
either the dot or the square brackets, will be returned as a further deeper hashref.

=head1 INTERNAL METHODS

=over 4

=item prepare_uploads

Overrides L<Catalyst/prepare_uploads> to expand the parameter data structure
post factum.

=back

=head1 CAVEATS

No attempt is made to merge data intelligently. If you do this:

    <input name="foo" />
    <input name="foo.bar" />

the C<foo> parameter will stay untouched, and you'll have to access C<foo.bar>
using its full string name:

    $c->req->param("foo.bar");

=head1 AUTHORS

Yuval Kogman, C<nothingmuch@woobling.org>

Jess Robinson

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2005 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Expand>

=cut

