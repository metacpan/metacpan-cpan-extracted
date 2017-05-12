use strict;
use Test::More;
use App::digestarchive;
use File::Spec;

my $tar_archive = File::Spec->catfile(File::Spec->tmpdir, "test-archive.tar");
my $gzip_archive  = $tar_archive . ".gz";
my $bzip2_archive = $tar_archive . ".bz2";

my $app = App::digestarchive->new;
$app->read($tar_archive);
my $all = $app->all(sub {
						my $f = shift;
						return $f->type == 0 || $f->type == 1 ? 1 : 0 
					});

foreach my $f (@{$all}) {
	ok $f->type == 0 || $f->type == 1, "filter_cb ok";
}

# clean archive
my $num = unlink $tar_archive, $gzip_archive, $bzip2_archive;
ok $num == 3, "clean archive";

done_testing;
