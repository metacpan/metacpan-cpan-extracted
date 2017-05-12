######################################################################
# Test suite for Archive::Tar::Merge
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;
use Archive::Tar::Merge;
use Archive::Tar::Wrapper;
use File::Temp qw(tempdir);
use Sysadm::Install qw(slurp);

plan tests => 12;

my $tmpdir = tempdir(CLEANUP => 1);
my $dsttar = "$tmpdir/foo.tgz";

my $DATA = "data";
$DATA = "t/data" unless -d $DATA;

  # No decider
my $merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar3.tgz"],
    dest_tarball    => $dsttar,
);

eval { $merger->merge(); };
like($@, qr/no decider defined/, "conflict without decider");

  # Decider favors first tarball
$merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar3.tgz"],
    dest_tarball    => $dsttar,
    decider         => sub {
        my($logical_src_path, @candidate_physical_paths) = @_;
        return { index => 0 };
    },
);

$merger->merge();

my $tar = Archive::Tar::Wrapper->new();
$tar->read($dsttar);

my @all_files = @{$tar->list_all()};

is(scalar @all_files, 3, "All files contained in tarball");

is(slurp($tar->locate("a")), "This is a.\n", "content of a");
is(slurp($tar->locate("b")), "This is b.\n", "content of b");
is(slurp($tar->locate("c")), "This is c.\n", "content of c");

  # Decider favors second tarball
$merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar3.tgz"],
    dest_tarball    => $dsttar,
    decider         => sub {
        my($logical_src_path, @candidate_physical_paths) = @_;
        return { index => 1 };
    },
);

$merger->merge();

$tar = Archive::Tar::Wrapper->new();
$tar->read($dsttar);

@all_files = @{$tar->list_all()};

is(scalar @all_files, 3, "All files contained in tarball");

is(slurp($tar->locate("a")), "This is the new a.\n", "content of a");
is(slurp($tar->locate("b")), "This is b.\n", "content of b");
is(slurp($tar->locate("c")), "This is c.\n", "content of c");

  # Merge two identical tarballs
$merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar1.tgz"],
    dest_tarball    => $dsttar,
);

$merger->merge();

$tar = Archive::Tar::Wrapper->new();
$tar->read($dsttar);

@all_files = @{$tar->list_all()};

is(scalar @all_files, 2, "All files contained in tarball");

is(slurp($tar->locate("a")), "This is a.\n", "content of a");
is(slurp($tar->locate("b")), "This is b.\n", "content of b");
