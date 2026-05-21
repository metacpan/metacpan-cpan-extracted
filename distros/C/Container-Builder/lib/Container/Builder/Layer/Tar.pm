package Container::Builder::Layer::Tar;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Crypt::Digest::SHA256 qw(sha256_hex);

use Container::Builder::Layer;

class Container::Builder::Layer::Tar :isa(Container::Builder::Layer) {
	field $data :param;

	method generate_artifact() {
		my $d = $self->_parent_does_stuff(\$data);
		return $$d;
	}
}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder::Layer::Tar - Make a container layer based upon a Tar file.

=head1 DESCRIPTION

Container::Builder::Layer::Tar implements Container::Builder::Layer and can be used to create container layers based upon a TAR archive file.

It actually doesn't do anything to the TAR archive being passed to it. It merely provides a way to create a valid C<Container::Builder::Layer> object for a given TAR file.

=head1 METHODS

=over 1

=item new(data => 'a valid TAR archive string')

Create a C<Container::Builder::Layer::Tar> object containing the TAR passed as data.

=item generate_artifact()

Returns the TAR archive.

=item get_media_type()

Return the media type of the container. This is the	mime type of the layer. Possibilities are C<application/vnd.oci.image.layer.v1.tar> or C<application/vnd.oci.image.layer.v1.tar+gzip>.

=item get_digest()

Returns the SHA256 digest of the generated layer.

=item get_size()

Returns the size (length) of the generated layer.

=back

=head1 AUTHOR

Adriaan Dens E<lt>adri@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2026- Adriaan Dens

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item Part of the L<Container::Builder> module.

=item L<https://github.com/opencontainers/image-spec/blob/main/layer.md>

=back

=cut

