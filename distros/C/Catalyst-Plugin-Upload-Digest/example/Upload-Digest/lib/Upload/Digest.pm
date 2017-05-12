package Upload::Digest;

=head1 NAME

Upload::Digest - L<Catalyst::Plugin::Upload::Digest> example application

=head1 DESCRIPTION

This Catalyst application demonstrates how to use L<the digest
plugin|Catalyst::Plugin::Upload::Digest>.

=cut

use strict;

use Catalyst;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'Upload::Digest' );

__PACKAGE__->setup( qw< Upload::Digest > );

=head1 METHODS

=cut

=head2 default

Redirects to F</upload>

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->res->redirect( '/upload' );
}

=head2 end

Uses L<Catalyst::Action::RenderView>

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
