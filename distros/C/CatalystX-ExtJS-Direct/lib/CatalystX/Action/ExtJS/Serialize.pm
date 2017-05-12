#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::Serialize;
$CatalystX::Action::ExtJS::Serialize::VERSION = '2.1.5';
# ABSTRACT: Handle responses from uploads
use strict;
use warnings;

use base 'Catalyst::Action::Serialize';

sub execute {
    my ( $self, $controller, $c ) = @_;
    $self->next::method( $controller, $c );
    if ( $c->stash->{upload} && $c->stash->{upload} eq 'true' ) {
        $c->res->content_type('text/html');
        my $body = $c->res->body;
        $body =~ s/&quot;/\&quot;/;
        $c->res->body(
            '<html><body><textarea>' . $body . '</textarea></body></html>' );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Action::ExtJS::Serialize - Handle responses from uploads

=head1 VERSION

version 2.1.5

=head1 PUBLIC METHODS

=head2 execute

Wrap the serialized response in a textarea field if there was a file upload.
Furthermore set the C<content-type> to C<< text/html >>.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
