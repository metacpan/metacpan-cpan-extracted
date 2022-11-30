#!perl -w
use strict;
use Archive::7zip;
use File::Basename;
use Test::More;
use File::Temp 'tempfile';
use Data::Dumper;

my $testcount = 6;
plan tests => 6;

my $version = Archive::7zip->find_7z_executable();
if( ! $version ) {
    SKIP: { skip "7z binary not found (not installed?)", $testcount; }
    exit;
};
diag "7-zip version $version";

sub slurp {
    my( $fh ) = @_;
    binmode $fh;
    local $/;
    return <$fh>
};

sub data_matches_ok {
    my( $memory, $name, $original, $originalname) = @_;
    if( length($memory) == -s $originalname) {
        cmp_ok $memory, 'eq', $original, "extracted data matches ($name)";
    } else {
        fail "extracted data matches ($name)";
        diag "Got      [$memory]";
        diag "expected [$original]";
    };
}

my $base = dirname($0) . '/data';

for my $archivename ("$base/def.zip", "$base/fred.7z") {

    my $ar = Archive::7zip->new(
        archivename => $archivename,
        verbose => $ENV{TEST_ARCHIVE_7Z_VERBOSE},
    );

    # Check that extraction to scalar and extraction to file
    # result in the same output

    my $originalname = "$base/fred";
    open my $fh, '<', $originalname
        or die "Couldn't read '$originalname': $!";
    my $original= slurp($fh);

    my $memory = slurp( $ar->openMemberFH("fred"));
    data_matches_ok( $memory, "Memory extraction", $original, $originalname );

    {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $fn = [$ar->members]->[0]->fileName;
        if(! is_deeply \@warnings, [], "We have no warnings when accessing the ->fileName ($archivename)") {
            diag Dumper \@warnings;
        }
    }

    ( $fh, my $tempname)= tempfile();
    close $fh;
    $ar->extractMember("fred",$tempname);
    open $fh, '<', $tempname
        or die "Couldn't read '$tempname': $!";
    my $disk   = slurp($fh);
    data_matches_ok( $disk, "Direct disk extraction ($archivename)", $original, $originalname );
}

done_testing(6);
