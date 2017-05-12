package Catalyst::View::REST::YAML;

use strict;
use base 'Catalyst::Base';
use YAML;

our $VERSION = '0.01';

=head1 NAME

Catalyst::View::REST::YAML - YAML View Class

=head1 SYNOPSIS

    # lib/MyApp/View/REST.pm
    package MyApp::View::REST;

    use base 'Catalyst::View::REST::YAML';

    1;

    $c->forward('MyApp::View::REST');

=head1 DESCRIPTION

This is the C<YAML> view class.

=head2 OVERLOADED METHODS

=head3 process

Serializes $c->stash to $c->response->output.

=cut

sub process {
    my ( $self, $c ) = @_;
    $c->response->headers->content_type('text/yaml-1.0');
    $c->response->output( Dump $c->stash );
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
