use strict;
use Test::More;
use Container::Builder;
use Crypt::Digest::SHA256 qw(sha256_hex);
use JSON;


my $package_file = 't/netbase.deb';

# Without compression
my $uncompressed_digest;
{
	my $builder = Container::Builder->new(debian_pkg_hostname => 'mirror.as35701.net', compress_deb_tar => 0);
	$builder->add_deb_package_from_file($package_file);
	my @layers = $builder->get_layers();
	my $mijn_laag = $layers[0];

	my $deb_tar_data = $mijn_laag->generate_artifact();
	my $digest = lc(sha256_hex($deb_tar_data));
	
	my $unc_digest = $mijn_laag->get_unc_digest();
	my $c_digest = $mijn_laag->get_digest();
	ok($digest eq $unc_digest, 'Digest is same as uncompressed digest');
	ok($digest eq $c_digest, 'Digest is the same as the digest from the layer');

	$uncompressed_digest = $unc_digest; # for the tests with compression, we need the uncompressed digest to compare against
}

# With compression
{
	my $builder = Container::Builder->new(debian_pkg_hostname => 'mirror.as35701.net', compress_deb_tar => 1);
	$builder->add_deb_package_from_file($package_file);
	my @layers = $builder->get_layers();
	my $mijn_laag = $layers[0];

	my $deb_tar_data = $mijn_laag->generate_artifact();
	my $digest = lc(sha256_hex($deb_tar_data));
	
	my $unc_digest = $mijn_laag->get_unc_digest();
	my $c_digest = $mijn_laag->get_digest();
	ok($uncompressed_digest eq $unc_digest, 'Uncompressed digest is same as uncompressed digest');
	ok($digest eq $c_digest, 'Digest is the same as the digest from the layer');
}

done_testing();
