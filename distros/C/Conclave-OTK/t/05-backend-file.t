#!perl -T

use Test::More tests => 7;
use Test::File;

use Conclave::OTK;
use Conclave::OTK::Backend::File;
use File::Temp qw/tempfile tempdir/;
use File::Touch;

my $base_uri = 'http://local/example';
my $rdfxml = Conclave::OTK::empty_owl($base_uri);
my (undef, $filename) = tempfile('onto_test_XXXXXXXX', TMPDIR=>1, SUFFIX=>'.rdf', OPEN=>0, UNLINK=>1);

my $b1 = Conclave::OTK::Backend::File->new($base_uri);
is( $b1->{base_uri}, $base_uri, 'base uri arg');
is( $b1->{filename}, 'model.xml', 'default file name');

my $b2 = Conclave::OTK::Backend::File->new($base_uri, filename=>$filename );
is( $b2->{base_uri}, $base_uri, 'base uri arg');
is( $b2->{filename}, $filename, "file name arg: $filename");

file_not_exists_ok($filename);
$b2->init($rdfxml);
file_exists_ok($filename);

(undef, $filename) = tempfile('onto_test_XXXXXXXX', TMPDIR=>1, SUFFIX=>'.rdf', OPEN=>0, UNLINK=>1);

my $b3 = Conclave::OTK::Backend::File->new($base_uri, filename=>$filename );
touch($filename);
file_exists_ok($filename);
$b3->init($rdfxml);

