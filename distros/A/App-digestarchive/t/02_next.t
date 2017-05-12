use strict;
use Test::More;
use App::digestarchive;
use File::Spec;

my $tar_archive = File::Spec->catfile(File::Spec->tmpdir, "test-archive.tar");

my $app = App::digestarchive->new;
$app->read($tar_archive);
my $f = $app->next;

isa_ok $f, "Archive::Tar::File", "\$f is Archive::Tar::File package" ;
foreach my $method (@App::digestarchive::ADD_ENTRY_METHODS) {
	ok eval { $f->can($method) } , "Archive::Tar::File $method method";
}
done_testing;
