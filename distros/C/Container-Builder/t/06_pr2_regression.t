use strict;
use Test::More;
use Container::Builder;
use Crypt::Digest::SHA256 qw(sha256_hex);
use JSON;

# https://github.com/adriaandens/Container-Builder/issues/2 regression test
# We're not implementing Diff_IDs correctly. They are being checked in newer
# versions of Podman.

# Diff IDs: the shasum of the uncompressed (tar) data, not of the gzip!

my $b = Container::Builder->new(debian_pkg_hostname => 'iaan.be');

# SingleFile layer
{
	# Making a TAR file ourselves so we have a checksum to validate against
	my $raw_data = "this is test data";
	my $t = Container::Builder::Tar->new();
	$t->add_file('/app/test.txt', $raw_data, 0644, 0, 0);
	my $expected_hex = sha256_hex($t->get_tar());

	# Create layer with this raw data (and enable compression)
	$b->add_file_from_string($raw_data, '/app/test.txt', 0644, 0, 0, 1);
	# Generate the artifact
	my @layers = $b->get_layers();
	$layers[0]->generate_artifact();
	ok($layers[0]->get_unc_digest() eq $expected_hex, 'Uncompressed digest is the expected hex');

	# Validate that Config gives back the uncompressed digest
	my $config = Container::Builder::Config->new();
	my @empty = ();
	my $config_json = $config->generate_config('root', \@empty, \@empty, \@empty, '/', \@layers);
	# Validate the diff ID of the layer
	my $c = decode_json($config_json);
	my $diffs = $c->{rootfs}->{diff_ids};
	my $layer_diff_id = $diffs->[0];
	ok('sha256:' . $expected_hex eq $layer_diff_id, 'Expected Diff ID: ' . $expected_hex . ' is not the same as received: ' . $layer_diff_id);
};

# Debian package file
{
	# TODO
};

# Directory
{
	# TODO
};

# Tar
{
	# TODO
};

done_testing();
