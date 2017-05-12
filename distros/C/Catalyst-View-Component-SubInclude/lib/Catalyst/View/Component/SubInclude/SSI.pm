package Catalyst::View::Component::SubInclude::SSI;
use Moose;
use namespace::clean -except => 'meta';

=head1 NAME

Catalyst::View::Component::SubInclude::SSI - Server Side Includes (SSI) plugin for C::V::Component::SubInclude

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

In your view class:

  package MyApp::View::TT;
  use Moose;

  extends 'Catalyst::View::TT';
  with 'Catalyst::View::Component::SubInclude';

  __PACKAGE__->config( subinclude_plugin => 'SSI' );

Then, somewhere in your templates:

  [% subinclude('/my/widget') %]

=head1 DESCRIPTION

C<Catalyst::View::Component::SubInclude::SSI> renders C<subinclude> calls as 
Server Side Includes (SSI) include directives. This is a feature implemented by 
Apache (L<http://httpd.apache.org/>), nginx (L<http://wiki.nginx.org/Main>)
and many other web servers which allows cache-efficient uses of includes.

=head1 METHODS

=head2 C<generate_subinclude( $c, $path, @args )>

Note that C<$path> should be the private action path - translation to the public
path is handled internally. After translation, this will roughly translate to 
the following code:

  my $url = $c->uri_for( $translated_path, @args )->path_query;
  return '<!--#include virtual="$url" -->';

Notice that the stash will always be empty. This behavior could be configurable
in the future through an additional switch - for now, this behavior guarantees a
common interface for plugins.

=cut

sub generate_subinclude {
    my ($self, $c, $path, @params) = @_;

    my $uri = $c->uri_for_action( $path, @params );

    return '<!--#include virtual="' . $uri->path_query . '" -->';
}

=head1 SEE ALSO

L<Catalyst::View::Component::SubInclude|Catalyst::View::Component::SubInclude>, 

=head1 AUTHOR

Vladimir Timofeev, C<< <vovkasm at gmail.com> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
