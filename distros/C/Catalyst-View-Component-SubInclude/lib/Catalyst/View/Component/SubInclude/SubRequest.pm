package Catalyst::View::Component::SubInclude::SubRequest;
use Moose;
use Carp qw/croak/;
use MooseX::Types::Moose qw/ Bool /;
use namespace::clean -except => 'meta';

=head1 NAME

Catalyst::View::Component::SubInclude::SubRequest - Sub-requests plugin for C::V::Component::SubInclude

=head1 VERSION

Version 0.07_03

=cut

our $VERSION = '0.07_03';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

In your application class:

  package MyApp;

  use Catalyst qw/
    ConfigLoader
    Static::Simple
    ...
    SubRequest
  /;

In your view class:

  package MyApp::View::TT;
  use Moose;

  extends 'Catalyst::View::TT';
  with 'Catalyst::View::Component::SubInclude';

  __PACKAGE__->config( subinclude_plugin => 'SubRequest' );

Then, somewhere in your templates:

  [% subinclude('/my/widget') %]

=head1 DESCRIPTION

C<Catalyst::View::Component::SubInclude::SubRequest> uses Catalyst sub-requests
to render the subinclude contents. 

It requires L<Catalyst::Plugin::SubRequest>.

=head1 METHODS

=head2 C<generate_subinclude( $c, $path, @args )>

This will make a sub-request call to the action specified by C<$path>. Note that
C<$path> should be the private action path - translation to the public path is
handled internally.

So, after path translation, the call will be (roughly) equivalent to:

  $c->sub_request( $translated_path, {}, @args );

Notice that the stash will always be empty. This behavior could be configurable
in the future through an additional switch - for now, this behavior guarantees a
common interface for all plugins.

=cut

has keep_stash => (
    isa => Bool,
    is => 'ro',
    default => 0,
);

sub generate_subinclude {
    my ($self, $c, $path, @params) = @_;
    my $stash = $self->keep_stash ? { %{ $c->stash } } : {};

    croak "subincludes through subrequests require Catalyst::Plugin::SubRequest"
        unless $c->can('sub_request');

    my $query = ref $params[-1] eq 'HASH' ? pop @params : {};
    
    my $action = blessed($path)
          ? $path
          : $c->dispatcher->get_action_by_path($path);

    my $uri = $c->uri_for( $action, @params );

    $c->sub_request( $uri->path, $stash, $query );
}

=head1 SEE ALSO

L<Catalyst::View::Component::SubInclude|Catalyst::View::Component::SubInclude>, 
L<Catalyst::Plugin::SubRequest|Catalyst::Plugin::SubRequest>

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 SPONSORSHIP

Development sponsored by Ionzero LLC L<http://www.ionzero.com/>.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Nilson Santos Figueiredo Junior.

Copyright (C) 2009 Ionzero LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
