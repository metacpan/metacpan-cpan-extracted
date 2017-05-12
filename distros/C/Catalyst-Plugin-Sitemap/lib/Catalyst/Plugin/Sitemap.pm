package Catalyst::Plugin::Sitemap;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Sitemap support for Catalyst.
$Catalyst::Plugin::Sitemap::VERSION = '1.0.2';
use strict;
use warnings;

use Moose::Role;

no warnings qw/uninitialized/;

use WWW::Sitemap::XML;
use List::Util qw/ first /;

has sitemap => (
    is      => 'ro',
    builder => '_build_sitemap',
    lazy    => 1,
);

sub sitemap_as_xml {
    return $_[0]->sitemap->as_xml->toString;
}

sub _build_sitemap {
    my $self = shift;

    my $sitemap = WWW::Sitemap::XML->new;

    for my $controller ( map { $self->controller($_) } $self->controllers ) {
        for my $action ( $controller->get_action_methods ) {
            $self->_add_controller_action_to_sitemap( $sitemap, $controller, $action );
        }
    }

    return $sitemap;
}

sub _add_controller_action_to_sitemap {
    my( $self, $sitemap, $controller, $act ) = @_;

    my $action = $controller->action_for($act->name);

    my $attr = $action->attributes->{Sitemap} or return;

    die "more than one attribute 'Sitemap' for sub ", $act->fully_qualified_name
        if @$attr > 1;

    my @attr = split /\s*(?:,|=>)\s*/, $attr->[0];

    my %uri_params;

    if ( @attr == 1 ) {
        if ( $attr[0] eq '*' ) {
            my $sitemap_method = $action->name . "_sitemap";

            return $controller->$sitemap_method( $self, $sitemap )
                if  $controller->can($sitemap_method);
        }
        elsif ( $attr[0] + 0 > 0 ) { # it's a number
            $uri_params{priority} = $attr[0];
        }
    }
    elsif ( @attr > 0 ) {
        %uri_params = @attr;
    }

    $uri_params{loc} = $self->uri_for_action( $action->private_path );

    $sitemap->add(%uri_params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Sitemap - Sitemap support for Catalyst.

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    # in MyApp.pm

    use Catalyst qw/ Sitemap /;

    # in the controller
    
    sub alone :Local :Sitemap { 
        ... 
    }
    
    sub with_priority :Local :Sitemap(0.75) {
        ... 
    }
    
    sub with_args :Local
            :Sitemap( lastmod => 2010-09-27, changefreq => daily ) {
        ...
    }
    
    sub with_function :Local :Sitemap(*) { 
        ... 
    }
    
    sub with_function_sitemap {
        $_[2]->add( 'http://localhost/with_function' );
    }

    # and then...
    
    sub sitemap : Path('/sitemap') {
        my ( $self, $c ) = @_;
 
        $c->res->body( $c->sitemap_as_xml );
    }

=head1 DESCRIPTION

L<Catalyst::Plugin::Sitemap> provides a way to semi-automate the creation 
of the sitemap of a Catalyst application.

=head1 CONTEXT METHOD

=head2 sitemap()

Returns a L<WWW::Sitemap::XML> object. The sitemap object is populated by 
inspecting the controllers of the application for actions with the 
sub attribute C<:Sitemap>.

=head2 sitemap_as_xml()

Returns the sitemap as a string containing its XML representation.

=head1 C<:Sitemap> Subroutine Attribute

The sitemap is populated by actions ear-marked with the <:Sitemap> sub
attribute.  It can be invoked in different ways:

=over

=item C<:Sitemap>

    sub alone :Local :Sitemap {
        ...
    }

Adds the url of the action to the sitemap.  

If the action does not
resolves in a single url, this will results in an error.

=item C<:Sitemap($priority)>

    sub with_priority :Local :Sitemap(0.9) {
        ...
    }

Adds the url, with the given number, which has to be between 1 (inclusive)
and 0 (exclusive), as its priority.

If the action does not
resolves in a single url, this will results in an error.

=item C<:Sitemap( %attributes )>

    sub with_args :Local
            :Sitemap( lastmod => 2010-09-27, changefreq => daily ) {
        ...
    }

Adds the url with the given entry attributes (as defined by
L<WWW::Sitemap::XML::URL>).

If the action does not
resolves in a single url, this will results in an error.

=item C<:Sitemap(*)>

    sub with_function :Local :Sitemap(*) { }
    
    sub with_function_sitemap {
        my ( $self, $c, $sitemap ) = @_;

        $sitemap->add( 'http://localhost/with_function' );
    }

Calls the function 'I<action>_sitemap', if it exists, and passes it the
controller, context and sitemap objects.

This is currently the only way to invoke C<:Sitemap> on an action 
resolving to many urls. 

=back

=head1 SEE ALSO

=over

=item L<WWW::Sitemap::XML>

Module that C<Catalyst::Plugin::Sitemap> currently uses under the hood.

=item L<Search::Sitemap>

Original module that this plugin was using under the hood.

=item L<Dancer::Plugin::SiteMap>

Similar plugin for the L<Dancer> framework, which inspired
C<Catalyst::Plugin::Sitemap>. 

=item L<http://techblog.babyl.ca/entry/catalyst-plugin-sitemap>

Blog article introducing C<Catalyst::Plugin::Sitemap>.

=back

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
