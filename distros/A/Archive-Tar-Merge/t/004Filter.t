######################################################################
# Test suite for Archive::Tar::Merge
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More qw(no_plan);
use Archive::Tar::Merge;
use Archive::Tar::Wrapper;
use File::Temp qw(tempdir);
use Sysadm::Install qw(slurp);

my $tmpdir = tempdir(CLEANUP => 1);
my $dsttar = "$tmpdir/foo.tgz";

my $DATA = "data";
$DATA = "t/data" unless -d $DATA;

  # Decider/hook creates customized content
my $merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar3.tgz"],
    dest_tarball    => $dsttar,
    decider         => sub {
        my($logical_src_path, $candidate_physical_paths) = @_;
        return { content => "Booh!" };
    },
    hook            => sub {
        my($logical_src_path, $candidate_physical_paths) = @_;
        return { content => "Baah!" };
    },
);

$merger->merge();

my $tar = Archive::Tar::Wrapper->new();
$tar->read($dsttar);

my @all_files = @{$tar->list_all()};

is(scalar @all_files, 3, "All files contained in tarball");

is(slurp($tar->locate("a")), "Booh!", "content of a");
is(slurp($tar->locate("b")), "Baah!", "content of b");
is(slurp($tar->locate("c")), "Baah!", "content of c");

  # Decider/hooks ignore files
$merger = Archive::Tar::Merge->new(
    source_tarballs => ["$DATA/tar1.tgz", "$DATA/tar3.tgz"],
    dest_tarball    => $dsttar,
    decider         => sub {
        my($logical_src_path, $candidate_physical_paths) = @_;
        return { action => "ignore" };
    },
    hook            => sub {
        my($logical_src_path, $candidate_physical_paths) = @_;
        if($logical_src_path =~ /b$/) {
            return { action => "ignore" };
        }
        return undef;
    },
);

$merger->merge();

$tar = Archive::Tar::Wrapper->new();
$tar->read($dsttar);

@all_files = @{$tar->list_all()};

is(scalar @all_files, 1, "All files contained in tarball");

ok(!$tar->locate("a"), "a is gone");
ok(!$tar->locate("b"), "b is gone");
is(slurp($tar->locate("c")), "This is c.\n", "content of c");
