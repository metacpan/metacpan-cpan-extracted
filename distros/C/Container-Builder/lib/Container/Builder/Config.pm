package Container::Builder::Config;

use v5.40;
use feature 'class';
no warnings 'experimental::class';

use Crypt::Digest::SHA256 qw(sha256_hex);
use JSON;
use DateTime;


class Container::Builder::Config {
	field $digest = '';
	field $size = '';

	method generate_config($user = 'root', $env = [], $entry = [], $cmd = [], $working_dir = '/', $layers = []) {
		my %config = (
			User => $user,
			Env => \@$env,
			Entrypoint => \@$entry,
			Cmd => \@$cmd,
			WorkingDir => $working_dir
		);
		my %rootfs = ( type => 'layers' );
		my @diff_ids = map { 'sha256:' . $_->get_unc_digest() } @$layers;
		$rootfs{diff_ids} = \@diff_ids;
		my %history = ( created => '0001-01-01T00:00:00Z' );
		my @histories = map { 
			my %history = ( created => '0001-01-01T00:00:00Z', comment => $_->get_comment(), created_by => $_->get_comment() );
			\%history;
		 } @$layers;
		my %json_pp = (
			created => DateTime->now() . 'Z',
			architecture => 'amd64',
			os => 'linux'
		);
		$json_pp{history} = \@histories;
		$json_pp{config} = \%config;
		$json_pp{rootfs} = \%rootfs;

		my $json =  encode_json(\%json_pp);
		$digest = Crypt::Digest::SHA256::sha256_hex($json);
		$size = length($json);
		return $json;
	}

	method get_digest() { return lc($digest) }
	method get_size() { return $size }
}

1;
__END__

=encoding utf-8

=pod

=head1 NAME

Container::Builder::Config - Class for the container Config specification.

=head1 DESCRIPTION

Container::Builder::Config provides a wrapper to generate a valid JSON configuration file for a Container.

=head1 METHODS

=over 1

=item generate_config($user = 'root', $env = ['PWD=/'], $entry = [], $cmd = [], $working_dir = '/', $layers = [])

Generate a JSON string for a OCI Config file. All arrays must be passed as array references. The C<layers> array must be a list of C<Container::Builder::Layer> objects.

=item get_digest()

Returns the SHA256 digest of the generated config.

=item get_size()

Returns the size (length) of the generated config.


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

=item L<https://github.com/opencontainers/image-spec/blob/main/config.md>

=back

=cut

