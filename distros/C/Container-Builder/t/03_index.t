use strict;
use Test::More;

use JSON qw(decode_json);
use Crypt::Digest::SHA256 qw(sha256_hex);

use Container::Builder::Index;

my $index_builder = Container::Builder::Index->new();
my $digest = sha256_hex("hehehehe");
my $json = $index_builder->generate_index($digest, 8, '');
my $index = decode_json($json);

ok($index->{schemaVersion} == 2, 'version is 2');
ok(ref($index->{manifests}) eq 'ARRAY', 'layers is an array');
ok(@{$index->{manifests}} == 1, 'we have 1 manifest');
ok($index->{manifests}->[0]->{mediaType} eq 'application/vnd.oci.image.manifest.v1+json', 'media type is correct');
ok($index->{manifests}->[0]->{digest} eq 'sha256:' . $digest, 'digest is as expected');
ok($index->{manifests}->[0]->{size} == 8, 'size is as expected');
ok(!defined($index->{manifests}->[0]->{annotations}), 'annotations are not defined if string is empty');

$json = $index_builder->generate_index($digest, 8, 'localhost/ctr:latest');
$index = decode_json($json);
ok(defined($index->{manifests}->[0]->{annotations}->{"org.opencontainers.image.ref.name"}), 'org.opencontainers.image.ref.name is defined as annotation key');
ok($index->{manifests}->[0]->{annotations}->{"org.opencontainers.image.ref.name"} eq 'localhost/ctr:latest', 'org.opencontainers.image.ref.name has value "localhost/ctr:latest"');

done_testing;
