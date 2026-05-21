package Container::Builder::Layer::DebianPackageFile;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Archive::Ar;
use IO::Uncompress::UnXz qw(unxz);
use IO::Compress::Gzip qw(gzip);
use Crypt::Digest::SHA256 qw(sha256_hex);

use Container::Builder::Layer;

class Container::Builder::Layer::DebianPackageFile :isa(Container::Builder::Layer) { 
	field $file :param = "";
	field $data :param = "";

	method generate_artifact() {
		my $ar;
		if($file) {
			die "Unable to read file $file\n" if !-r $file;
			$ar = Archive::Ar->new($file);
		} elsif($data) {
			$ar = Archive::Ar->new();
			my $result = $ar->read_memory($data);
			die "Couldn't read Ar archive from memory\n" if(!defined($result));
		} else {
			die "No file or data passed to DebianPackageFile\n";
		}
		## TODO: support data.tar, data.tar.gz, data.tgz, ...
		die "Unable to find data.tar.xz inside deb package\n" if !$ar->contains_file('data.tar.xz');
		my $xz_data = $ar->get_data('data.tar.xz');
		my $unxz_data;
		IO::Uncompress::UnXz::unxz(\$xz_data => \$unxz_data) or die "Unable to extract data using unxz\n";
		my $data_ref = $self->_parent_does_stuff(\$unxz_data);
		# TODO: We should actually return references! Less copying == faster!
		return $$data_ref;
	}
}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder::Layer::DebianPackageFile - Make a container layer based upon a Debian package file.

=head1 DESCRIPTION

Container::Builder::Layer::DebianPackageFile implements Container::Builder::Layer and can be used to create container layers based upon a debian package file.

=head1 METHODS

=over 1

=item new(file => 'mypackage.deb', compress => 1)

=item new(data => 'a valid deb archive string', compress => 1)

Create a C<Container::Builder::Layer::DebianPackageFile> object. Pass in either the filename with C<file> or pass the debian archive data as a scalar with C<data>. The C<compress> argument controls whether we return a Gzipped archive as a layer or a plain TAR file.

=item generate_artifact()

Returns a TAR (gzipped or not) file that is based upon the Debian package C<data.tar.xz> archive contents. This method will unpack the C<.deb> using Ar. And then decompress the XZ archive to get the TAR data from the Debian package.

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

