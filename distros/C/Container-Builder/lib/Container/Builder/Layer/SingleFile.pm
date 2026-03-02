package Container::Builder::Layer::SingleFile;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Container::Builder::Layer;
use Container::Builder::Tar;
use Crypt::Digest::SHA256 qw(sha256_hex);

class Container::Builder::Layer::SingleFile :isa(Container::Builder::Layer) {
	field $file :param = undef;
	field $data :param = undef;
	field $dest :param;
	field $mode :param;
	field $user :param;
	field $group :param;
	field $generated_artifact = 0;
	field $size = 0;
	field $digest = 0;

	method generate_artifact() {
		my $tar = Container::Builder::Tar->new();
		if(defined($file)) { # We gotta read the file
			local $/ = undef;
			open(my $f, '<', $file) or die "Cannot read $file\n";
			$data = <$f>;
			close($f);
		}
		if(!defined($data)) {
			$data = ""; # Set data to an empty string if nothing was passed (we want an empty file...)
		}
		$tar->add_file($dest, $data, $mode, $user, $group);
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

Container::Builder::Layer::SingleFile - Make a container layer with a single file.

=head1 DESCRIPTION

Container::Builder::Layer::SingleFile implements Container::Builder::Layer and can be used to create container layers that contain a single file.

=head1 METHODS

=over 1

=item new(file => 'file.txt', dest => '/app/file.txt', mode => 0644, user => 1337, group => 1337)

=item new(data => 'Hallo vriendjes en vriendinnetjes', dest => '/app/file.txt', mode => 0644, user => 1337, group => 1337)

Create a C<Container::Builder::Layer::SingleFile> object. Pass in either the filename with C<file> or pass the data directly as a scalar with C<data>. The C<dest> is the location of the file in the container layer and C<mode>, C<user> and C<group> control the permissions.

=item generate_artifact()

Returns a TAR file that contains the file.

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

