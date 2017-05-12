use strict;
use Test::More tests => 1;
use App::digestarchive;
use File::Spec;

my $tar_archive = File::Spec->catfile(File::Spec->tmpdir, "test-archive.tar");

my $app = App::digestarchive->new;
$app->digest_type("SHA1");
$app->read($tar_archive);
my $all = $app->all;

foreach my $f (@{$all}) {

	if ($f->type == 0 || $f->type == 1) {
		# type is Archive::File::Constant::FILE or HARDLINK
		ok length $f->digest == 40, "digest length is 40 bytes";
		last;
	}
}
