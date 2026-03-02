package Container::Builder::Layer::Directory;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Container::Builder::Layer;
use Container::Builder::Tar;

use Crypt::Digest::SHA256 qw(sha256_hex);

class Container::Builder::Layer::Directory :isa(Container::Builder::Layer) {
	field $path :param;
	field $mode :param;
	field $uid :param;
	field $gid :param;
	field $digest = 0;
	field $size = 0;

	method generate_artifact() {
		my $tar = Container::Builder::Tar->new();
		$tar->add_dir($path, $mode, $uid, $gid);
		my $tar_content = $tar->get_tar();
		$digest = Crypt::Digest::SHA256::sha256_hex($tar_content);
		$size = length($tar_content);
		return $tar_content;
	}

	method get_media_type() { return "application/vnd.oci.image.layer.v1.tar" }
	method get_digest() { return lc($digest) }
	method get_size() { return $size }

}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder::Layer::Directory - Make a container layer consisting of a single directory.

=head1 DESCRIPTION

Container::Builder::Layer::Directory implements Container::Builder::Layer and can be used to create container layers which contain a single directory.

=head1 METHODS

=over 1

=item new(path => '/', mode => 0755, uid => 1337, gid => 1337)

Create a C<Container::Builder::Layer::Directory> object. As arguments pass in the details of the directory that you want to have in your container layer.

=item generate_artifact()

Returns a TAR file as a scalar, that contains a single directory.

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

