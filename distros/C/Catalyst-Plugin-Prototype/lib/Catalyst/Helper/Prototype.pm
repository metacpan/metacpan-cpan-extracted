package Catalyst::Helper::Prototype;

use strict;
use File::Spec;
use HTML::Prototype;

=head1 NAME

Catalyst::Helper::Prototype - Helper to generate Prototype library

=head1 SYNOPSIS

    script/myapp_create.pl Prototype

=head1 DESCRIPTION

Helper to generate Prototype library.

=head2 METHODS

=over 4

=item mk_stuff

Create javascript files for prototype/scriptalicious in your 
document root.

=back 

=cut

sub mk_stuff {
    my ( $self, $helper ) = @_;
    my $prototype =
      File::Spec->catfile( $helper->{base}, 'root', 'prototype.js' );
    $helper->mk_file( $prototype, $HTML::Prototype::prototype );
    my $controls =
      File::Spec->catfile( $helper->{base}, 'root', 'controls.js' );
    $helper->mk_file( $controls, $HTML::Prototype::controls );
    my $dragdrop =
      File::Spec->catfile( $helper->{base}, 'root', 'dragdrop.js' );
    $helper->mk_file( $dragdrop, $HTML::Prototype::dragdrop );
    my $effects = File::Spec->catfile( $helper->{base}, 'root', 'effects.js' );
    $helper->mk_file( $effects, $HTML::Prototype::effects );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut

1;
