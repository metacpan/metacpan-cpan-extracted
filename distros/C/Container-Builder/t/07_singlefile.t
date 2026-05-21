use strict;
use Test::More;
use Container::Builder;
use Crypt::Digest::SHA256 qw(sha256_hex);
use JSON;

# Single file moet compressie supporteren
my $builder = Container::Builder->new(debian_pkg_hostname => 'mirror.as35701.net');

my $data = "dit is enige data";

my $unc_digest;
my $tar_data;
# Without compression
{
	$builder->add_file_from_string($data, '/app/text.txt', 0644, 0, 0);
	my @layers = $builder->get_layers();
	my $mijn_laag = $layers[0];

	$tar_data = $mijn_laag->generate_artifact();
	my $digest = lc(sha256_hex($tar_data));
	$unc_digest = $mijn_laag->get_unc_digest();
	ok($digest eq $unc_digest, 'Uncompressed digest is correct');
	ok($digest eq $mijn_laag->get_digest(), 'Digest of layer is correct');
	ok($mijn_laag->get_digest() eq $mijn_laag->get_unc_digest(), 'Digest is the same as the Uncompressed digest');
}

# With compression
{
	$builder->add_file_from_string($data, '/app/text.txt', 0644, 0, 0, 1);
	my @layers = $builder->get_layers();
	my $mijn_laag = $layers[0];

	my $tgz_data = $mijn_laag->generate_artifact();
	my $uncompressed_digest = $mijn_laag->get_unc_digest();
	my $digest = $mijn_laag->get_digest();

	ok($uncompressed_digest eq $unc_digest, 'Uncompressed digest is the same as without compression flag');
	ok(sha256_hex($tgz_data) eq $digest, 'Compressed digest matches');
}

done_testing();
