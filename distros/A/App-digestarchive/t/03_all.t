use strict;
use Test::More;
use App::digestarchive;
use File::Spec;

my $tar_archive = File::Spec->catfile(File::Spec->tmpdir, "test-archive.tar");

my $app = App::digestarchive->new;
$app->read($tar_archive);
my $all = $app->all;

ok scalar(@{$all}) == 5 , "file entries in archive";
foreach my $f (@{$all}) {

	if ($f->type == 0 || $f->type == 1) {
		# type is Archive::File::Constant::FILE or HARDLINK
		ok length $f->digest == 32, "digest length is 32 bytes";
	} else {
		ok $f->digest eq $App::digestarchive::NONE_DIGEST_MESSAGE, "digest is [** can not get digest **]";
		if ($f->type == 2) {
			# type is Archive::File::Constant::SYMLINK
			ok $f->link_or_real_name =~ /^.+\s+\-\>\s+.+$/, 'link_or_real_name regex [^.+\s+\-\>\s+.+$]';
		}
	}
}
done_testing;
