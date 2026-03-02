package Container::Builder::Index;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use JSON;

# https://specs.opencontainers.org/image-spec/image-index/?v=v1.1.1
class Container::Builder::Index {
	method generate_index($manifest_digest, $manifest_size) {
		# TODO: you can annotate and pass the container name
		return encode_json({
			schemaVersion => 2,
			manifests => [{
				mediaType => 'application/vnd.oci.image.manifest.v1+json',
				digest => 'sha256:' . $manifest_digest,
				size => int($manifest_size)
			}]
		});
	}
}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder::Index - Class for the container Index specification.

=head1 DESCRIPTION

Container::Builder::Index provides a JSON file of the container Index.

=head1 METHODS

=over 1

=item generate_index($manifest_digest, $manifest_size)

Generate a JSON string for a OCI Index file. The two parameters are used to refer to the container manifest file inside the JSON. C<$manifest_digest> needs to be a hex representation of the SHA256 digest of the manifest.

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

=item L<https://specs.opencontainers.org/image-spec/image-index/?v=v1.1.1>

=back

=cut

