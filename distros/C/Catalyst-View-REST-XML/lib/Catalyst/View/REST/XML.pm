package Catalyst::View::REST::XML;

use strict;
use base 'Catalyst::View';
use XML::Simple;

our $VERSION = '0.02';

=head1 NAME

Catalyst::View::REST::XML - (DEPRECATED) XML View Class

=head1 SYNOPSIS

    # lib/MyApp/View/REST.pm
    package MyApp::View::REST;

    use base 'Catalyst::View::REST::XML';

    1;

    $c->forward('MyApp::View::REST');

=head1 DEPRECATION NOTICE

This module has been deprecated in favor of L<Catalyst::Action::REST>.

=head1 DESCRIPTION

This is the C<XML::Simple> view class.

=head2 OVERLOADED METHODS

=head3 process

Serializes $c->stash to $c->response->output.

=cut

sub process {
    my ( $self, $c ) = @_;
    $c->response->headers->content_type('text/xml');
    $c->response->output( XMLout $c->stash, RootName => 'response' );
    return 1;
}

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
