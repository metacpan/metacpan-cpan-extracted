use strict;
use warnings;
use Test::More;
use App::karr;

# The executables in bin/ must each carry their own `our $VERSION`, in sync
# with the main module.
#
# It is not enough that PodWeaver puts a `=head1 VERSION` into the woven POD --
# that section is generated from $zilla->version and says nothing about the
# code. Without a literal `our $VERSION = '...';` line the installed executable
# is versionless.
#
# This line is also what keeps itself current: RewriteVersion::Transitional and
# BumpVersionAfterRelease only ever *rewrite* an existing assignment (their
# assign_re requires one). Their insert fallback runs through PkgVersion, which
# needs a `package` statement -- these scripts have none, so nothing would ever
# be inserted here. Delete the line and no future release puts it back.

for my $script ( 'bin/karr', 'bin/karr-foundation' ) {
    ok( -f $script, "$script exists" ) or next;

    open my $fh, '<', $script or die "Could not open $script: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    my ($bin_version) = $content =~ /^our \$VERSION = '([^']+)';/m;

    ok( defined $bin_version, "$script declares our \$VERSION" )
        or next;

    is( $bin_version, $App::karr::VERSION,
        "$script \$VERSION ($bin_version) matches App::karr ($App::karr::VERSION)" );
}

done_testing;
