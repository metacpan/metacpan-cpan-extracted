package Catalyst::Helper::Graphics;

use warnings;
use strict;

our $VERSION = '0.1';

use Catalyst::Helper::Graphics::Files;

=head1 NAME

Catalyst::Helper::Graphics

=head1 SYNOPSIS

    script/myapp_create.pl Graphics

See L<Catalyst::Manual::Intro> for more details

=head2 METHODS

=over

=item mk_stuff

Creates the individual files.  To add another graphic file, place it in the
images/ directory and run C<pack_images.pl> to update the auto-generated
C<Catalyst::Helper::Graphics::Files>.  Make sure to update @images as well.

=cut

sub mk_stuff {
    my ( $self, $helper, @args ) = @_;

    my @images = qw/cat_loading.gif/;
    my $image_path = File::Spec->catdir($helper->{base}, 'root', 'static', 'images');

    for my $name ( @images ) {
        my $hex   = $helper->get_file(
            'Catalyst::Helper::Graphics::Files',
            $name );
        my $image = pack "H*", $hex;
        $helper->mk_file( File::Spec->catfile( $image_path, $name ),
            $image );
    }
}

=head1 AUTHOR

J. Shirley, <jshirley@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
