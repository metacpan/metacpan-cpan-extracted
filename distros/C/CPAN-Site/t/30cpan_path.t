#!/usr/bin/env perl
# Verify generated CHECKCUMS has an appropriate 'cpan_path' member
#-------------------------------------------------------------------------------
$^W = 0;
use strict;
use warnings;
use FindBin qw($Bin);
use IO::Zlib ();
use Test::More tests => 2;
use Test::TempDir::Tiny;
use File::Spec::Functions qw(catdir catfile);
use File::Path qw(make_path);
use File::Copy;

# use Log::Report 'cpan-site', mode => 'DEBUG';

use_ok('CPAN::Site::Index');

test_cpan_path_generation();

exit;

#-------------------------------------------------------------------------------

sub test_cpan_path_generation {
    my $distro = 'Distro-With-Multi-Package-Module.tar.gz';

    my $tmpdir = tempdir();
    $tmpdir && -d $tmpdir or die "Something went horribly wrong!";

    my $mycpan  = catdir($tmpdir, 'site');
    my $distdir = catdir($mycpan, qw(authors id L LO LOCAL));

    make_path($distdir)
        or return diag "Failed to create temp directory";

    copy(catdir($Bin, 'test_data', $distro), $distdir)
        or return diag "Failed to copy distribution to temp directory: $!";

    # XXX: I don't know if there's a way to avoid pulling data from cpan.org in this test or not...
    CPAN::Site::Index::cpan_index($mycpan, 'https://cpan.org/', lazy => 0, fallback => 0, undefs => 0);

    -r catfile($distdir, "CHECKSUMS")
        or return diag "No CHECKSUMS file";

    open my $fh, '<', catfile($distdir, "CHECKSUMS")
        or return diag "Failed to open CHECKSUMS";

    read $fh, my $cksum, -s $fh
        or return diag "Failed to read CHECKSUMS";
    close $fh;

    $cksum = eval $cksum
        or return diag "Failed to eval CHECKSUMS";

    ok ref($cksum) eq 'HASH' && $cksum->{$distro} && ($cksum->{$distro}->{cpan_path}//'') eq 'L/LO/LOCAL';
}
